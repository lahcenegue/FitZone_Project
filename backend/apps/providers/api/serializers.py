"""
Serializers for the providers app API.
Input validation and output formatting only.
No business logic here — that belongs in services.
"""

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers
from apps.gyms.models import GymBranch

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

class GymBranchSearchSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer specifically optimized for search and discovery lists.
    Returns minimal payload with distance calculations and simple array formats.
    """
    provider_name = serializers.CharField(source='provider.business_name', read_only=True)
    branch_logo = serializers.SerializerMethodField()
    distance_km = serializers.SerializerMethodField()
    min_price = serializers.FloatField(source='min_plan_price', read_only=True, default=None)
    sports = serializers.SerializerMethodField()
    amenities = serializers.SerializerMethodField()
    lat = serializers.SerializerMethodField()
    lng = serializers.SerializerMethodField()

    class Meta:
        model = GymBranch
        fields = [
            'id', 'provider_name', 'name', 'city', 'address', 'gender',
            'lat', 'lng', 'branch_logo', 'is_active',
            'distance_km', 'min_price', 'sports', 'amenities'
        ]

    def get_branch_logo(self, obj):
        request = self.context.get('request')
        if obj.branch_logo and request:
            return request.build_absolute_uri(obj.branch_logo.url)
        return None

    def get_distance_km(self, obj):
        if hasattr(obj, 'distance') and obj.distance is not None:
            return round(obj.distance.km, 2)
        return None

    def get_sports(self, obj):
        return [sport.name for sport in obj.sports.all()]

    def get_amenities(self, obj):
        return [amenity.name for amenity in obj.amenities.all()]

    def get_lat(self, obj):
        return obj.location.y if obj.location else None

    def get_lng(self, obj):
        return obj.location.x if obj.location else None