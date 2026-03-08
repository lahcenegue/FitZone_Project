"""
Authentication service for the Provider Portal.
Handles registration, login, logout, and email verification.
All business logic lives here — views only call these functions.
"""

import logging
from django.contrib.auth import authenticate, login, logout, get_user_model
from django.db import transaction
from django.utils.translation import gettext_lazy as _
from django.core.mail import send_mail
from django.conf import settings
from django.urls import reverse

from apps.providers.models import Provider, ProviderType, ProviderStatus, EmailVerificationToken
from apps.users.models import UserRole
from ..constants import SESSION_EXPIRY_SECONDS

logger = logging.getLogger(__name__)
User = get_user_model()


class AuthenticationError(Exception):
    """Raised when authentication fails for a known, user-facing reason."""
    pass


class RegistrationError(Exception):
    """Raised when registration fails for a known, user-facing reason."""
    pass


def send_verification_email(request, provider: Provider, token_obj: EmailVerificationToken) -> None:
    """
    Generate the verification URL and send the email to the provider.
    The message parameter must contain text, otherwise the email body will be blank.
    """
    verification_url = request.build_absolute_uri(
        reverse("provider_portal:verify_email", kwargs={"token": token_obj.token})
    )
    
    subject = _("Verify your FitZone account")
    
    # This is the body of the email that will print in the console
    message = (
        f"Welcome {provider.business_name},\n\n"
        f"Please click the link below to verify your email address and activate your account:\n\n"
        f"{verification_url}\n\n"
        f"If you did not request this, please ignore this email."
    )
    
    try:
        send_mail(
            subject=str(subject),
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[provider.user.email],
            fail_silently=False,
        )
        logger.info("Verification email sent | email: %s", provider.user.email)
    except Exception as exc:
        logger.error("Failed to send verification email | email: %s | error: %s", provider.user.email, str(exc))


def register_provider(request, step1_data: dict, step2_data: dict, step3_data: dict) -> Provider:
    """
    Create a User and Provider from validated registration form data.
    Generates a verification token and sends the email.
    """
    email = step1_data["email"]

    if User.objects.filter(email=email).exists():
        raise RegistrationError(_("This email address is already registered."))

    try:
        with transaction.atomic():
            user = User(
                email=email,
                full_name=step1_data["full_name"],
                phone_number=step1_data["phone_number"],
                role=UserRole.PROVIDER,
            )
            user.password = step1_data["password"]
            user.save()

            provider = Provider.objects.create(
                user=user,
                provider_type=step2_data["provider_type"],
                status=ProviderStatus.PENDING,
                business_name=step3_data["business_name"],
                city=step3_data["city"],
                commercial_registration=step3_data.get("commercial_registration", ""),
                tax_id=step3_data.get("tax_id", ""),
                description=step3_data.get("description", ""),
            )
            
            # Generate token and trigger the email with the link
            token_obj = EmailVerificationToken.create_for_provider(provider)
            send_verification_email(request, provider, token_obj)

            logger.info(
                "Provider registered | user: %s | type: %s | business: %s",
                email, step2_data["provider_type"], step3_data["business_name"],
            )

        # Auto-login after registration (Session starts, but user is redirected to Pending)
        login(request, user, backend="django.contrib.auth.backends.ModelBackend")
        request.session.set_expiry(SESSION_EXPIRY_SECONDS)

        return provider

    except RegistrationError:
        raise
    except Exception as exc:
        logger.error("Registration failed for %s: %s", email, str(exc))
        raise RegistrationError(
            _("Registration failed due to a system error. Please try again.")
        ) from exc


def login_provider(request, email: str, password: str) -> Provider:
    """Authenticate and log in a provider."""
    user = authenticate(request, username=email, password=password)

    if user is None:
        raise AuthenticationError(_("Invalid email or password. Please try again."))

    if not user.is_active and not hasattr(user, "provider_profile"):
        raise AuthenticationError(_("This account has been deactivated."))

    if user.role != UserRole.PROVIDER:
        raise AuthenticationError(_("Invalid email or password. Please try again."))

    login(request, user, backend="django.contrib.auth.backends.ModelBackend")
    request.session.set_expiry(SESSION_EXPIRY_SECONDS)

    return user.provider_profile


def logout_provider(request) -> None:
    """Log out the current provider and clear the session."""
    logout(request)


def change_provider_password(request, current_password: str, new_password: str) -> None:
    """Change the authenticated provider's password."""
    user = request.user

    if not user.check_password(current_password):
        raise AuthenticationError(_("Current password is incorrect."))

    user.set_password(new_password)
    user.save(update_fields=["password"])

    login(request, user, backend="django.contrib.auth.backends.ModelBackend")
    request.session.set_expiry(SESSION_EXPIRY_SECONDS)