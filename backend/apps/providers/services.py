"""
Business logic for provider registration and admin review.

Rules:
    Views call services.
    Services call model methods.
    Model methods touch only their own fields.
    No business logic lives in views or serializers.
"""

import logging

from django.contrib.auth import get_user_model
from django.db import transaction

from apps.users.models import UserRole

from .constants import ProviderStatus
from .emails import (
    send_approval_email,
    send_rejection_email,
    send_verification_email,
)
from .models import EmailVerificationToken, Provider

logger = logging.getLogger(__name__)
User = get_user_model()


def _frontend_base_url() -> str:
    """Return the configured frontend base URL for use in email links."""
    from django.conf import settings
    return getattr(settings, "FRONTEND_URL", "http://localhost:8000")


# ---------------------------------------------------------------------------
# Registration service
# ---------------------------------------------------------------------------

class ProviderRegistrationService:
    """
    Handles the complete provider registration flow.

    Step 1 — register():
        Create User (is_active=False) + Provider (status=PENDING)
        + EmailVerificationToken + send verification email.

    Step 2 — verify_email():
        Validate token → activate User (is_active=True)
        + set email_verified=True on Provider.
        Provider stays PENDING — admin must still review.

    Step 3 — resend_verification():
        Invalidate old token, create new one, resend email.
        Always returns True (prevents email enumeration).
    """

    @staticmethod
    @transaction.atomic
    def register(
        *,
        email: str,
        password: str,
        full_name: str,
        phone_number: str,
        provider_type: str,
        business_name: str,
        business_phone: str,
        city: str,
        address: str = "",
        description: str = "",
    ) -> Provider:
        """
        Create a new provider account.

        The User is created with is_active=False and cannot log in until
        they click the email verification link. After verification they
        stay PENDING until an admin approves the application.

        Args:
            email:          Login email for the provider account.
            password:       Plain-text password (hashed inside User.set_password).
            full_name:      Owner's full name.
            phone_number:   Owner's personal phone number.
            provider_type:  One of ProviderType constants.
            business_name:  The legal or trading name of the business.
            business_phone: Business contact phone number.
            city:           City where the business operates.
            address:        Street address (optional at registration).
            description:    Brief business description (optional).

        Returns:
            The newly created Provider instance.

        Raises:
            ValueError: If a user with this email already exists.
        """
        if User.objects.filter(email=email).exists():
            raise ValueError(
                "An account with this email address already exists."
            )

        # Create the User — inactive until email is verified
        user = User.objects.create_user(
            email=email,
            password=password,
            full_name=full_name,
            phone_number=phone_number,
            role=UserRole.PROVIDER,
            is_active=False,
            is_verified=False,
            city=city,
        )

        # Create the Provider profile
        provider = Provider.objects.create(
            user=user,
            provider_type=provider_type,
            business_name=business_name,
            business_phone=business_phone,
            city=city,
            address=address,
            description=description,
            status=ProviderStatus.PENDING,
            email_verified=False,
        )

        # Create verification token
        token_instance = EmailVerificationToken.create_for_provider(provider)

        # Send verification email
        # Email failure is logged but does NOT roll back the transaction.
        # The provider can request a resend via /resend-verification/.
        send_verification_email(
            recipient_email=email,
            recipient_name=full_name,
            business_name=business_name,
            verification_token=token_instance.token,
            frontend_base_url=_frontend_base_url(),
        )

        logger.info(
            "Provider registered | business: %s | type: %s | user: %s",
            business_name,
            provider_type,
            email,
        )
        return provider

    @staticmethod
    @transaction.atomic
    def verify_email(*, token_string: str) -> Provider:
        """
        Verify a provider's email using the token from the email link.

        Activates the User account and sets email_verified=True on Provider.
        Provider status stays PENDING — admin still needs to review.

        Args:
            token_string: The raw 64-character hex token from the URL.

        Returns:
            The updated Provider instance.

        Raises:
            ValueError: If token is invalid, expired, or already consumed.
        """
        try:
            token = EmailVerificationToken.objects.select_related(
                "provider__user"
            ).get(token=token_string)
        except EmailVerificationToken.DoesNotExist:
            raise ValueError("Invalid verification link.")

        if token.is_used:
            raise ValueError(
                "This verification link has already been used. "
                "Please log in or request a new link."
            )
        if token.is_expired:
            raise ValueError(
                "This verification link has expired. "
                "Please request a new one."
            )

        token.consume()

        provider = token.provider
        provider.mark_email_verified()

        logger.info(
            "Email verified | provider: %s | user: %s",
            provider.business_name,
            provider.user.email,
        )
        return provider

    @staticmethod
    def resend_verification(*, email: str) -> bool:
        """
        Resend the verification email for a provider whose email is unverified.

        Always returns True to prevent email enumeration — the caller cannot
        determine from the response whether the email exists.

        Args:
            email: The registered email address.

        Returns:
            True always.
        """
        try:
            user = User.objects.get(email=email)
            provider = Provider.objects.get(
                user=user,
                email_verified=False,
                status=ProviderStatus.PENDING,
            )
        except (User.DoesNotExist, Provider.DoesNotExist):
            logger.warning(
                "Resend verification: no eligible account for email %s", email
            )
            return True

        token_instance = EmailVerificationToken.create_for_provider(provider)

        send_verification_email(
            recipient_email=email,
            recipient_name=user.full_name,
            business_name=provider.business_name,
            verification_token=token_instance.token,
            frontend_base_url=_frontend_base_url(),
        )

        logger.info(
            "Verification email resent | provider: %s | user: %s",
            provider.business_name,
            email,
        )
        return True
    
    @staticmethod
    def authenticate_provider(email: str, password: str) -> Provider:
        """Authenticate a provider by email and password."""
        from django.contrib.auth import authenticate
        
        user = authenticate(username=email, password=password)
        
        if user is None:
            raise ValueError("Invalid email or password.")
            
        if getattr(user, "role", None) != UserRole.PROVIDER:
            raise ValueError("This account is not a provider account.")
            
        if not hasattr(user, "provider_profile"):
            raise ValueError("Provider profile not found.")
            
        provider = user.provider_profile
        
        if provider.status == ProviderStatus.SUSPENDED:
            raise ValueError("This account has been suspended by the administration.")
            
        return provider


# ---------------------------------------------------------------------------
# Admin review service
# ---------------------------------------------------------------------------

class ProviderReviewService:
    """
    Handles admin approval and rejection of provider applications.

    Called from the Django admin and (in future) from a dedicated admin API.
    Business logic lives here — the admin class only calls these methods.
    """

    @staticmethod
    @transaction.atomic
    def approve(*, provider: Provider, reviewed_by) -> Provider:
        """
        Approve a pending provider application.

        Sets status=APPROVED and sends an approval notification email.
        The provider can then log in and access a limited dashboard.

        Args:
            provider:    The Provider instance to approve.
            reviewed_by: The admin User performing the action.

        Returns:
            The updated Provider instance.
        """
        provider.approve(reviewed_by=reviewed_by)

        send_approval_email(
            recipient_email=provider.user.email,
            recipient_name=provider.user.full_name,
            business_name=provider.business_name,
            frontend_base_url=_frontend_base_url(),
        )
        return provider

    @staticmethod
    @transaction.atomic
    def reject(*, provider: Provider, reviewed_by, note: str = "") -> Provider:
        """
        Reject a pending provider application.

        Sets status=REJECTED and sends a rejection email with the note.

        Args:
            provider:    The Provider instance to reject.
            reviewed_by: The admin User performing the action.
            note:        Reason for rejection, shown to the provider.

        Returns:
            The updated Provider instance.
        """
        provider.reject(reviewed_by=reviewed_by, note=note)

        send_rejection_email(
            recipient_email=provider.user.email,
            recipient_name=provider.user.full_name,
            business_name=provider.business_name,
            rejection_note=note,
            frontend_base_url=_frontend_base_url(),
        )
        return provider
    
