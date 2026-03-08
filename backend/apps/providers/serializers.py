"""
Serializers for the providers app API.

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

    provider_type = serializers.ChoiceField(
        label=_("Provider type"), choices=ProviderType.choices
    )
    business_name = serializers.CharField(
        label=_("Business name"), max_length=255, min_length=2
    )
    business_phone = serializers.CharField(
        label=_("Business phone"), max_length=20, min_length=7
    )
    city = serializers.CharField(label=_("City"), max_length=100)
    address = serializers.CharField(
        label=_("Address"), max_length=512, required=False, allow_blank=True
    )
    description = serializers.CharField(
        label=_("Description"), max_length=2000, required=False, allow_blank=True
    )

    def validate(self, data: dict) -> dict:
        """Ensure passwords match and meet security requirements."""
        if data.get("password") != data.get("password_confirm"):
            raise serializers.ValidationError(
                {"password_confirm": "Passwords do not match."}
            )
        
        try:
            validate_password(data["password"])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({"password": list(exc.messages)})
            
        return data


# ---------------------------------------------------------------------------
# Email verification input
# ---------------------------------------------------------------------------

class EmailVerificationSerializer(serializers.Serializer):
    """Input for POST /api/v1/providers/verify-email/."""

    token = serializers.CharField(label=_("Verification token"), max_length=64)


class ResendVerificationSerializer(serializers.Serializer):
    """Input for POST /api/v1/providers/resend-verification/."""

    email = serializers.EmailField(label=_("Email address"), max_length=254)

    def validate_email(self, value: str) -> str:
        """Normalize email address to lowercase."""
        return value.lower().strip()


# ---------------------------------------------------------------------------
# Provider status response
# ---------------------------------------------------------------------------

class ProviderStatusSerializer(serializers.ModelSerializer):
    """
    Read-only serializer for provider responses.
    Returns raw, un-translated constants (provider_type, status) 
    for robust client-side logic in Flutter.
    """

    email     = serializers.EmailField(source="user.email", read_only=True)
    full_name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = Provider
        fields = [
            "id",
            "email",
            "full_name",
            "provider_type",
            "business_name",
            "city",
            "status",
            "email_verified",
            "can_access_dashboard",
            "created_at",
        ]

# ---------------------------------------------------------------------------
# Login input
# ---------------------------------------------------------------------------

class ProviderLoginSerializer(serializers.Serializer):
    """Input validation for POST /api/v1/providers/login/."""

    email = serializers.EmailField(label=_("Email address"))
    password = serializers.CharField(
        label=_("Password"),
        write_only=True,
        style={"input_type": "password"}
    )

# ---------------------------------------------------------------------------
# Logout input
# ---------------------------------------------------------------------------

class ProviderLogoutSerializer(serializers.Serializer):
    """Input validation for POST /api/v1/providers/logout/."""

    refresh = serializers.CharField(label=_("Refresh token"))