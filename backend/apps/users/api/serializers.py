from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from apps.users.models import User, UserGender

class UserRegistrationSerializer(serializers.Serializer):
    """Step 1: Quick Registration (5 fields only)"""
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(write_only=True, min_length=8)
    full_name = serializers.CharField(max_length=255, min_length=2)
    gender = serializers.ChoiceField(
        choices=[(UserGender.MALE, "Male"), (UserGender.FEMALE, "Female")]
    )
    city = serializers.CharField(max_length=100)

    def validate(self, data):
        try:
            validate_password(data["password"])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({"password": list(exc.messages)})
        
        if User.objects.filter(email=data['email']).exists():
            raise serializers.ValidationError({"email": "This email is already registered."})
            
        return data

class UserProfileCompletionSerializer(serializers.Serializer):
    """Step 2: Profile Completion (Required before subscribing)"""
    phone_number = serializers.CharField(max_length=20, min_length=7)
    address = serializers.CharField(max_length=512, required=False, allow_blank=True)
    lat = serializers.FloatField(required=False)
    lng = serializers.FloatField(required=False)
    
    # Files
    avatar = serializers.ImageField(required=False)
    real_face_image = serializers.ImageField(required=True)
    id_card_image = serializers.ImageField(required=True)

class UserProfileSerializer(serializers.ModelSerializer):
    """Returns safe user data to the mobile app."""
    lat = serializers.SerializerMethodField()
    lng = serializers.SerializerMethodField()
    profile_is_complete = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone_number', 'gender', 
            'avatar', 'address', 'city', 'lat', 'lng', 
            'is_active', 'is_verified', 'points_balance', 'profile_is_complete'
        ]

    def get_lat(self, obj):
        return obj.location.y if obj.location else None

    def get_lng(self, obj):
        return obj.location.x if obj.location else None

    def get_profile_is_complete(self, obj):
        """Helper for the mobile app to know if it should show the completion screen"""
        return bool(obj.phone_number and obj.real_face_image and obj.id_card_image)

class UserLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

class UserEmailVerificationSerializer(serializers.Serializer):
    otp = serializers.CharField(
        max_length=6, 
        min_length=6, 
        error_messages={
            "invalid": "Invalid OTP format.",
            "min_length": "OTP must be exactly 6 digits.",
            "max_length": "OTP must be exactly 6 digits."
        }
    )

class UserResendVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField()