from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.validators import RegexValidator
from apps.users.models import User, UserGender

phone_regex = RegexValidator(
    regex=r'^\+?[0-9]{9,15}$',
    message="Phone number must be valid, between 9 and 15 digits, and can start with '+'."
)

class UserRegistrationSerializer(serializers.Serializer):
    """Step 1: Quick Registration"""
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(write_only=True, min_length=8)
    full_name = serializers.CharField(max_length=255, min_length=2)
    gender = serializers.ChoiceField(
        choices=[(UserGender.MALE, "Male"), (UserGender.FEMALE, "Female")]
    )
    city = serializers.CharField(max_length=100)
    phone_number = serializers.CharField(validators=[phone_regex], max_length=20)
    address = serializers.CharField(max_length=512, required=False, allow_blank=True)
    lat = serializers.FloatField(required=False)
    lng = serializers.FloatField(required=False)

    def validate(self, data):
        try:
            validate_password(data["password"])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({"password": list(exc.messages)})
        
        if User.objects.filter(email=data['email']).exists():
            raise serializers.ValidationError({"email": "This email is already registered."})
            
        return data

class UserProfileCompletionSerializer(serializers.Serializer):
    """Step 2: Profile Completion (Documents Only)"""
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
            'avatar', 'real_face_image', 'id_card_image',
            'address', 'city', 'lat', 'lng', 
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

class PasswordResetRequestSerializer(serializers.Serializer):
    """Serializer for requesting a password reset OTP."""
    email = serializers.EmailField()

class PasswordResetConfirmSerializer(serializers.Serializer):
    """Serializer for confirming the OTP and setting a new password."""
    email = serializers.EmailField()
    otp = serializers.CharField(
        max_length=6, 
        min_length=6, 
        error_messages={
            "invalid": "Invalid OTP format.",
            "min_length": "OTP must be exactly 6 digits.",
            "max_length": "OTP must be exactly 6 digits."
        }
    )
    new_password = serializers.CharField(write_only=True, min_length=8)

    def validate(self, data):
        try:
            validate_password(data["new_password"])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({"new_password": list(exc.messages)})
        return data

class UserChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=8)

    def validate_new_password(self, value):
        validate_password(value)
        return value

class UserAvatarUpdateSerializer(serializers.Serializer):
    avatar = serializers.ImageField(required=True)

class UserProfileUpdateSerializer(serializers.Serializer):
    """Supports partial updates for all profile fields."""
    email = serializers.EmailField(required=False)
    full_name = serializers.CharField(required=False, min_length=2)
    gender = serializers.ChoiceField(choices=UserGender.choices, required=False)
    city = serializers.CharField(required=False)
    phone_number = serializers.CharField(validators=[phone_regex], max_length=20, required=False)
    address = serializers.CharField(required=False, allow_blank=True)
    real_face_image = serializers.ImageField(required=False)
    id_card_image = serializers.ImageField(required=False)

class UserAccountDeleteSerializer(serializers.Serializer):
    """Serializer for account deletion, requiring password confirmation."""
    password = serializers.CharField(required=True, write_only=True)

class UserLogoutSerializer(serializers.Serializer):
    """Serializer for logging out and blacklisting the refresh token."""
    refresh = serializers.CharField(
        required=True, 
        error_messages={"required": "Refresh token is required."}
    )

class AggregatedSubscriptionSerializer(serializers.Serializer):
    """
    Serializer for the unified user subscriptions list.
    Enhanced to include detailed branch information for UI cards.
    """
    service_type = serializers.CharField()
    id = serializers.IntegerField()
    plan_name = serializers.CharField(required=False)
    provider_name = serializers.CharField(required=False)
    
    # Branch Details
    branch_id = serializers.IntegerField(required=False)
    branch_logo = serializers.URLField(required=False, allow_null=True)
    address = serializers.CharField(required=False)
    lat = serializers.FloatField(required=False, allow_null=True)
    lng = serializers.FloatField(required=False, allow_null=True)
    
    status = serializers.CharField()
    qr_code_signature = serializers.CharField(required=False)
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)