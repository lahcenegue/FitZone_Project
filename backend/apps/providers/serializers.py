"""
Serializers for the providers app.

Input validation and output formatting only.
No business logic here — that belongs in services.py.
"""

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from .constants import ProviderType
from .models import Provider


# ---------------------------------------------------------------------------
# Registration input
# ---------------------------------------------------------------------------

class ProviderRegistrationSerializer(serializers.Serializer):
    """Validates all input for POST /api/v1/providers/register/."""

    # Account credentials
    email = serializers.EmailField(label=_("Email address"), max_length=254)
    password = serializers.CharField(
        label=_("Password"),
        write_only=True,
        min_length=8,
        style={"input_type": "password"},
    )
    password_confirm = serializers.CharField(
        label=_("Confirm password"),
        write_only=True,
        style={"input_type": "password"},
    )
    full_name = serializers.CharField(
        label=_("Full name"), max_length=255, min_length=2
    )
    phone_number = serializers.CharField(
        label=_("Phone number"), max_length=20, min_length=7
    )

    # Business details
    provider_type = serializers.ChoiceField(
        label=_("Provider type"), choices=ProviderType.choices
    )
    business_name = serializers.CharField(
        label=_("Business name"), max_length=255, min_length=2
    )
    business_phone = serializers.CharField(
        label=_("Business phone"), max_length=20, min_length=7
    )
    city = serializers.CharField(label=_("City"), max_length=100, min_length=2)
    address = serializers.CharField(
        label=_("Address"),
        max_length=512,
        required=False,
        allow_blank=True,
        default="",
    )
    description = serializers.CharField(
        label=_("Description"),
        max_length=2000,
        required=False,
        allow_blank=True,
        default="",
    )

    def validate_email(self, value: str) -> str:
        """Normalize to lowercase."""
        return value.lower().strip()

    def validate_password(self, value: str) -> str:
        """Run Django AUTH_PASSWORD_VALIDATORS."""
        try:
            validate_password(value)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(list(exc.messages))
        return value

    def validate_phone_number(self, value: str) -> str:
        return self._clean_phone(value, "Phone number")

    def validate_business_phone(self, value: str) -> str:
        return self._clean_phone(value, "Business phone")

    @staticmethod
    def _clean_phone(value: str, label: str) -> str:
        """Accept digits, spaces, +, -, ( ) only."""
        cleaned = value.strip()
        allowed = set("0123456789 +-() ")
        if not all(c in allowed for c in cleaned):
            raise serializers.ValidationError(
                _(f"{label} may only contain digits, spaces, +, -, and parentheses.")
            )
        return cleaned

    def validate(self, data: dict) -> dict:
        """Passwords must match."""
        if data.get("password") != data.get("password_confirm"):
            raise serializers.ValidationError(
                {"password_confirm": _("Passwords do not match.")}
            )
        return data


# ---------------------------------------------------------------------------
# Email verification input
# ---------------------------------------------------------------------------

class EmailVerificationSerializer(serializers.Serializer):
    """Input for POST /api/v1/providers/verify-email/."""

    token = serializers.CharField(
        label=_("Verification token"),
        min_length=64,
        max_length=64,
    )


# ---------------------------------------------------------------------------
# Resend verification input
# ---------------------------------------------------------------------------

class ResendVerificationSerializer(serializers.Serializer):
    """Input for POST /api/v1/providers/resend-verification/."""

    email = serializers.EmailField(label=_("Email address"), max_length=254)

    def validate_email(self, value: str) -> str:
        return value.lower().strip()


# ---------------------------------------------------------------------------
# Provider status response
# ---------------------------------------------------------------------------

class ProviderStatusSerializer(serializers.ModelSerializer):
    """
    Read-only serializer for provider registration responses.
    Returns the minimum needed for the frontend to render the status page.
    """

    email              = serializers.EmailField(source="user.email",            read_only=True)
    full_name          = serializers.CharField(source="user.full_name",          read_only=True)
    status_display     = serializers.CharField(source="get_status_display",      read_only=True)
    type_display       = serializers.CharField(source="get_provider_type_display", read_only=True)

    class Meta:
        model = Provider
        fields = [
            "id",
            "email",
            "full_name",
            "provider_type",
            "type_display",
            "business_name",
            "city",
            "status",
            "status_display",
            "email_verified",
            "can_access_dashboard",
            "created_at",
        ]
        read_only_fields = fields