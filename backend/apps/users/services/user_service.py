import logging
from django.contrib.auth import get_user_model
from django.db import transaction
from django.contrib.gis.geos import Point
from django.core.mail import send_mail
from django.conf import settings
from apps.users.models import UserRole, UserVerificationToken, PasswordResetToken
from apps.core.constants import OTP_EXPIRATION_MINUTES

logger = logging.getLogger(__name__)
User = get_user_model()

class UserAuthService:

    @staticmethod
    def _send_verification_email(user, otp_code):
        """
        Constructs and sends the OTP verification email.
        """
        subject = "Your FitZone OTP Verification Code"
        message = f"""Hello {user.full_name},

Welcome to FitZone!
To activate your account, please enter the following One-Time Password (OTP) in the app:

{otp_code}

This code is valid for {OTP_EXPIRATION_MINUTES} minutes.
If you did not request this, please ignore this email.

Best regards,
FitZone Team
"""
        from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@fitzone.sa')

        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=from_email,
                recipient_list=[user.email],
                fail_silently=False,
            )
            logger.info(f"OTP email successfully dispatched for: {user.email}")
        except Exception as e:
            logger.error(f"Failed to send OTP email to {user.email}: {str(e)}")

    @staticmethod
    def _send_password_reset_email(user, otp_code):
        """
        Constructs and sends the OTP email for password reset.
        """
        subject = "FitZone Password Reset OTP"
        message = f"""Hello {user.full_name},

We received a request to reset your FitZone password.
Please use the following OTP to create a new password:

{otp_code}

This code is valid for {OTP_EXPIRATION_MINUTES} minutes.
If you did not request a password reset, please ignore this email to keep your account secure.

Best regards,
FitZone Team
"""
        from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@fitzone.sa')

        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=from_email,
                recipient_list=[user.email],
                fail_silently=False,
            )
            logger.info(f"Password reset OTP email dispatched for: {user.email}")
        except Exception as e:
            logger.error(f"Failed to send password reset email to {user.email}: {str(e)}")

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

        token_obj = UserVerificationToken.objects.create(user=user)
        
        UserAuthService._send_verification_email(user, token_obj.otp)

        logger.info(f"New customer registered: {email}")
        return user

    @staticmethod
    def verify_email(otp_code):
        """Verifies the email and activates the user using OTP."""
        try:
            token_obj = UserVerificationToken.objects.get(otp=otp_code)
        except UserVerificationToken.DoesNotExist:
            raise ValueError("Invalid or missing verification code.")

        if not token_obj.is_valid():
            raise ValueError("Verification code has expired.")

        user = token_obj.user
        if user.is_verified:
            raise ValueError("Account is already verified.")

        user.is_verified = True
        user.save(update_fields=['is_verified', 'updated_at'])
        
        token_obj.delete()
        return user

    @staticmethod
    def resend_verification(email):
        """Generates a new OTP if the user is not verified."""
        try:
            user = User.objects.get(email=email, role=UserRole.CUSTOMER)
            if user.is_verified:
                return
            
            UserVerificationToken.objects.filter(user=user).delete()
            token_obj = UserVerificationToken.objects.create(user=user)
            
            UserAuthService._send_verification_email(user, token_obj.otp)
            
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

    @staticmethod
    def request_password_reset(email):
        """
        Generates a new password reset OTP and sends it to the user.
        Fails silently if the email does not exist to prevent email enumeration attacks.
        """
        try:
            user = User.objects.get(email=email, role=UserRole.CUSTOMER)
            
            # Remove any existing reset tokens
            PasswordResetToken.objects.filter(user=user).delete()
            
            token_obj = PasswordResetToken.objects.create(user=user)
            UserAuthService._send_password_reset_email(user, token_obj.otp)
            
        except User.DoesNotExist:
            # Security best practice: Do not reveal whether the email is registered or not
            logger.warning(f"Password reset attempted for non-existent email: {email}")
            pass

    @staticmethod
    @transaction.atomic
    def confirm_password_reset(email, otp_code, new_password):
        """
        Validates the OTP and updates the user's password.
        """
        try:
            user = User.objects.get(email=email, role=UserRole.CUSTOMER)
        except User.DoesNotExist:
            raise ValueError("Invalid request.")

        try:
            token_obj = PasswordResetToken.objects.get(user=user, otp=otp_code)
        except PasswordResetToken.DoesNotExist:
            raise ValueError("Invalid or missing reset code.")

        if not token_obj.is_valid():
            raise ValueError("Reset code has expired.")

        # Update password
        user.set_password(new_password)
        user.save(update_fields=['password', 'updated_at'])
        
        # Invalidate token after successful use
        token_obj.delete()


    @staticmethod
    @transaction.atomic
    def change_password(user, old_password, new_password):
        """
        Changes the password for an authenticated user after verifying the old password.
        """
        if not user.check_password(old_password):
            raise ValueError("Current password is incorrect.")
        
        user.set_password(new_password)
        user.save(update_fields=['password', 'updated_at'])
        logger.info(f"Password successfully changed for user: {user.email}")

    @staticmethod
    @transaction.atomic
    def update_user_avatar(user, avatar_file):
        """
        Updates only the user's avatar image.
        """
        user.avatar = avatar_file
        user.save(update_fields=['avatar', 'updated_at'])
        logger.info(f"Avatar updated for user: {user.email}")
        return user

    @staticmethod
    @transaction.atomic
    def update_user_profile(user, data):
        """
        Updates one or multiple profile fields. 
        Triggers re-verification if email is changed.
        """
        email_changed = False
        new_email = data.get('email')

        if new_email and new_email != user.email:
            if User.objects.filter(email=new_email).exists():
                raise ValueError("This email is already registered with another account.")
            
            user.email = new_email
            user.is_verified = False
            email_changed = True

        # Update fields only if they are present in the data
        user.full_name = data.get('full_name', user.full_name)
        user.gender = data.get('gender', user.gender)
        user.city = data.get('city', user.city)
        user.phone_number = data.get('phone_number', user.phone_number)
        user.address = data.get('address', user.address)
        
        if 'real_face_image' in data:
            user.real_face_image = data['real_face_image']
        if 'id_card_image' in data:
            user.id_card_image = data['id_card_image']

        user.save()

        if email_changed:
            # Clear old tokens and send new verification OTP
            UserVerificationToken.objects.filter(user=user).delete()
            token_obj = UserVerificationToken.objects.create(user=user)
            UserAuthService._send_verification_email(user, token_obj.otp)
            logger.info(f"Email changed. Verification OTP sent to: {new_email}")

        return user, email_changed
    
    
    @staticmethod
    @transaction.atomic
    def delete_user_account(user, password):
        """
        Permanently deletes the user account after verifying the password.
        """
        if not user.check_password(password):
            raise ValueError("Incorrect password. Account deletion failed.")

        user_email = user.email
        user.delete()
        logger.info(f"User account permanently deleted for: {user_email}")