"""
Authentication service for the Provider Portal.
Handles registration, login, logout, and password change.
All business logic lives here — views only call these functions.
"""

import logging
from django.contrib.auth import authenticate, login, logout, get_user_model
from django.db import transaction
from django.utils.translation import gettext_lazy as _
from apps.providers.models import Provider, ProviderType, ProviderStatus
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


def register_provider(request, step1_data: dict, step2_data: dict, step3_data: dict) -> Provider:
    """
    Create a User and Provider from validated registration form data.
    Wrapped in a transaction — both records created or neither.
    Auto-logs the user in after successful registration.

    Args:
        request: The HTTP request (needed for login).
        step1_data: Cleaned data from RegistrationStep1Form.
        step2_data: Cleaned data from RegistrationStep2Form.
        step3_data: Cleaned data from RegistrationStep3Form.

    Returns:
        The newly created Provider instance.

    Raises:
        RegistrationError: If email already exists or creation fails.
    """
    email = step1_data["email"]

    if User.objects.filter(email=email).exists():
        raise RegistrationError(_("This email address is already registered."))

    try:
        with transaction.atomic():
            user = User.objects.create_user(
                email=email,
                password=step1_data["password"],
                full_name=step1_data["full_name"],
                phone_number=step1_data["phone_number"],
                role=UserRole.PROVIDER,
            )

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

            logger.info(
                "Provider registered | user: %s | type: %s | business: %s",
                email, step2_data["provider_type"], step3_data["business_name"],
            )

        # Auto-login after registration
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
    """
    Authenticate and log in a provider.
    Validates credentials, checks role, and sets session expiry.

    Args:
        request: The HTTP request.
        email: Provider email address.
        password: Provider password.

    Returns:
        The authenticated Provider instance.

    Raises:
        AuthenticationError: If credentials are invalid or user is not a provider.
    """
    user = authenticate(request, username=email, password=password)

    if user is None:
        logger.warning("Failed login attempt | email: %s", email)
        raise AuthenticationError(
            _("Invalid email or password. Please try again.")
        )

    if not user.is_active:
        logger.warning("Inactive user login attempt | email: %s", email)
        raise AuthenticationError(
            _("This account has been deactivated. Please contact support.")
        )

    if user.role != UserRole.PROVIDER:
        logger.warning(
            "Non-provider login attempt on portal | email: %s | role: %s",
            email, user.role,
        )
        raise AuthenticationError(
            _("Invalid email or password. Please try again.")
        )

    if not hasattr(user, "provider_profile"):
        logger.error("Provider user has no provider profile | email: %s", email)
        raise AuthenticationError(
            _("Account setup is incomplete. Please contact support.")
        )

    login(request, user, backend="django.contrib.auth.backends.ModelBackend")
    request.session.set_expiry(SESSION_EXPIRY_SECONDS)

    logger.info(
        "Provider logged in | email: %s | status: %s",
        email, user.provider_profile.status,
    )

    return user.provider_profile


def logout_provider(request) -> None:
    """
    Log out the current provider and clear the session.

    Args:
        request: The HTTP request.
    """
    email = request.user.email if request.user.is_authenticated else "anonymous"
    logout(request)
    logger.info("Provider logged out | email: %s", email)


def change_provider_password(request, current_password: str, new_password: str) -> None:
    """
    Change the authenticated provider's password.
    Verifies current password before applying the change.

    Args:
        request: The HTTP request (must be authenticated).
        current_password: The user's existing password for verification.
        new_password: The new password to set.

    Raises:
        AuthenticationError: If current password is incorrect.
    """
    user = request.user

    if not user.check_password(current_password):
        logger.warning("Password change failed — wrong current password | email: %s", user.email)
        raise AuthenticationError(_("Current password is incorrect."))

    user.set_password(new_password)
    user.save(update_fields=["password"])

    # Re-login to maintain session after password change
    login(request, user, backend="django.contrib.auth.backends.ModelBackend")
    request.session.set_expiry(SESSION_EXPIRY_SECONDS)

    logger.info("Password changed successfully | email: %s", user.email)