"""
Serializers for the providers app API.
Input validation and output formatting only.
No business logic here — that belongs in services.
"""

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from ..constants import ProviderType
from ..models import Provider

class ProviderRegistrationSerializer(serializers.Serializer):
    email = serializers.EmailField(label=_("Email address"), max_length=254)
    password = serializers.CharField(write_only=True, min_length=8, style={"input_type": "password"})
    password_confirm = serializers.CharField(write_only=True, style={"input_type": "password"})
    full_name = serializers.CharField(max_length=255, min_length=2)
    phone_number = serializers.CharField(max_length=20, min_length=7)
    provider_type = serializers.ChoiceField(choices=ProviderType.choices)
    business_name = serializers.CharField(max_length=255, min_length=2)
    business_phone = serializers.CharField(max_length=20, min_length=7)
    city = serializers.CharField(max_length=100)
    address = serializers.CharField(max_length=512, required=False, allow_blank=True)
    description = serializers.CharField(max_length=2000, required=False, allow_blank=True)

    def validate(self, data: dict) -> dict:
        if data.get("password") != data.get("password_confirm"):
            raise serializers.ValidationError({"password_confirm": "Passwords do not match."})
        try:
            validate_password(data["password"])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({"password": list(exc.messages)})
        return data

class EmailVerificationSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=64)

class ResendVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=254)
    def validate_email(self, value: str) -> str:
        return value.lower().strip()

class ProviderStatusSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source="user.email", read_only=True)
    full_name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = Provider
        fields = [
            "id", "email", "full_name", "provider_type", "business_name",
            "city", "status", "email_verified", "can_access_dashboard", "created_at",
        ]

class ProviderLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, style={"input_type": "password"})

class ProviderLogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()