import logging
from django.contrib.auth import get_user_model
from django.db import transaction
from django.contrib.gis.geos import Point
from apps.users.models import UserRole, UserVerificationToken

logger = logging.getLogger(__name__)
User = get_user_model()

class UserAuthService:
    @staticmethod
    @transaction.atomic
    def register_customer(validated_data):
        email = validated_data['email']
        
        user = User.objects.create_user(
            email=email,
            password=validated_data['password'],
            full_name=validated_data['full_name'],
            gender=validated_data['gender'],
            city=validated_data['city'],
            role=UserRole.CUSTOMER,
            is_verified=False 
        )

        # Generate Verification Token and simulate sending email
        token_obj = UserVerificationToken.objects.create(user=user)
        logger.info(f"\n========== SIMULATED EMAIL ==========")
        logger.info(f"To: {user.email}")
        logger.info(f"Subject: Verify your FitZone Account")
        logger.info(f"Token: {token_obj.token}")
        logger.info(f"=====================================\n")

        logger.info(f"New customer registered: {email}")
        return user

    @staticmethod
    def verify_email(token_string):
        """Verifies the email and activates the user."""
        try:
            token_obj = UserVerificationToken.objects.get(token=token_string)
        except UserVerificationToken.DoesNotExist:
            raise ValueError("Invalid verification token.")

        if not token_obj.is_valid():
            raise ValueError("Verification token has expired.")

        user = token_obj.user
        if user.is_verified:
            raise ValueError("Email is already verified.")

        user.is_verified = True
        user.save(update_fields=['is_verified', 'updated_at'])
        
        token_obj.delete()
        return user

    @staticmethod
    def resend_verification(email):
        """Generates a new token if the user is not verified."""
        try:
            user = User.objects.get(email=email, role=UserRole.CUSTOMER)
            if user.is_verified:
                return
            
            UserVerificationToken.objects.filter(user=user).delete()
            token_obj = UserVerificationToken.objects.create(user=user)
            
            logger.info(f"\n========== SIMULATED RESEND EMAIL ==========")
            logger.info(f"To: {user.email}")
            logger.info(f"Token: {token_obj.token}")
            logger.info(f"============================================\n")
        except User.DoesNotExist:
            pass

    @staticmethod
    @transaction.atomic
    def complete_profile(user, validated_data):
        user.phone_number = validated_data.get('phone_number', user.phone_number)
        user.address = validated_data.get('address', user.address)
        
        lat = validated_data.get('lat')
        lng = validated_data.get('lng')
        if lat is not None and lng is not None:
            user.location = Point(lng, lat, srid=4326)
            
        if 'avatar' in validated_data:
            user.avatar = validated_data['avatar']
        if 'real_face_image' in validated_data:
            user.real_face_image = validated_data['real_face_image']
        if 'id_card_image' in validated_data:
            user.id_card_image = validated_data['id_card_image']

        user.save()
        return user

    @staticmethod
    def authenticate_customer(email, password):
        try:
            user = User.objects.get(email=email, role=UserRole.CUSTOMER)
        except User.DoesNotExist:
            raise ValueError("Invalid email or password.")

        if not user.check_password(password):
            raise ValueError("Invalid email or password.")

        if not user.is_verified:
            raise PermissionError("EMAIL_NOT_VERIFIED")

        if not user.is_active:
            raise ValueError("This account has been disabled.")

        return user