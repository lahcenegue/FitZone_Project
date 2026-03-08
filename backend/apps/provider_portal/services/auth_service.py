"""
Authentication service for the Provider Portal.
Handles registration, login, logout, and email verification.
"""

import logging
from django.contrib.auth import authenticate, login, logout, get_user_model
from django.db import transaction
from django.utils.translation import gettext_lazy as _
from django.core.mail import send_mail
from django.conf import settings
from django.urls import reverse
from apps.providers.models import Provider, ProviderStatus, EmailVerificationToken
from apps.users.models import UserRole
from ..constants import SESSION_EXPIRY_SECONDS

logger = logging.getLogger(__name__)
User = get_user_model()


class AuthenticationError(Exception):
    """Raised for known authentication failures."""
    pass


class RegistrationError(Exception):
    """Raised for known registration failures."""
    pass


def send_verification_email(request, provider: Provider, token_obj: EmailVerificationToken) -> None:
    """Generate the URL and send the verification email to the provider."""
    verification_url = request.build_absolute_uri(
        reverse("provider_portal:verify_email", kwargs={"token": token_obj.token})
    )
    
    subject = _("Verify your FitZone account")
    message = _("Welcome to FitZone! Please click the link below to verify your email address:\n\n") + verification_url
    
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[provider.user.email],
            fail_silently=False,
        )
        logger.info("Verification email sent | email: %s", provider.user.email)
    except Exception as exc:
        logger.error("Failed to send verification email | email: %s | error: %s", provider.user.email, str(exc))
        # We don't raise an exception here so the registration process can still complete successfully.
        # The user can request a new token from the pending page.


def register_provider(request, step1_data: dict, step2_data: dict, step3_data: dict) -> Provider:
    """Create User, Provider, generate token, and send verification email."""
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
            
            # Generate token and send email
            token_obj = EmailVerificationToken.create_for_provider(provider)
            send_verification_email(request, provider, token_obj)

            logger.info("Provider registered | email: %s", email)

        login(request, user, backend="django.contrib.auth.backends.ModelBackend")
        request.session.set_expiry(SESSION_EXPIRY_SECONDS)

        return provider

    except RegistrationError:
        raise
    except Exception as exc:
        logger.error("Registration failed | email: %s | error: %s", email, str(exc))
        raise RegistrationError(_("Registration failed due to a system error. Please try again.")) from exc


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

    logger.info("Provider logged in | email: %s", email)
    return user.provider_profile


def logout_provider(request) -> None:
    """Log out the current provider."""
    email = request.user.email if request.user.is_authenticated else "anonymous"
    logout(request)
    logger.info("Provider logged out | email: %s", email)


def change_provider_password(request, current_password: str, new_password: str) -> None:
    """Change provider password."""
    user = request.user

    if not user.check_password(current_password):
        raise AuthenticationError(_("Current password is incorrect."))

    user.set_password(new_password)
    user.save(update_fields=["password"])

    login(request, user, backend="django.contrib.auth.backends.ModelBackend")
    request.session.set_expiry(SESSION_EXPIRY_SECONDS)

    logger.info("Password changed | email: %s", user.email)