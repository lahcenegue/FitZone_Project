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
            phone_number=validated_data['phone_number'],
            role=UserRole.CUSTOMER,
            is_verified=False 
        )

        user.address = validated_data.get('address', '')
        
        lat = validated_data.get('lat')
        lng = validated_data.get('lng')
        if lat is not None and lng is not None:
            user.location = Point(lng, lat, srid=4326)
            
        user.save()

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
        if 'real_face_image' in validated_data:
            user.real_face_image = validated_data['real_face_image']
        if 'id_card_image' in validated_data:
            user.id_card_image = validated_data['id_card_image']

        user.save(update_fields=['real_face_image', 'id_card_image', 'updated_at'])
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
            
            PasswordResetToken.objects.filter(user=user).delete()
            
            token_obj = PasswordResetToken.objects.create(user=user)
            UserAuthService._send_password_reset_email(user, token_obj.otp)
            
        except User.DoesNotExist:
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

        user.set_password(new_password)
        user.save(update_fields=['password', 'updated_at'])
        
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


class UserDashboardService:
    """
    Aggregator service responsible for fetching and unifying data across 
    different app modules (Gyms, Trainers, Restaurants) for the user's dashboard.
    """

    @staticmethod
    def get_all_subscriptions(user, request=None):
        """
        Fetches all active and historical subscriptions (including Roaming Passes) 
        with full metadata, unified into a single list.
        """
        unified_subscriptions = []
        from django.utils import timezone
        now_date = timezone.now().date()

        # 1. Fetch Regular Gym Subscriptions
        from apps.gyms.models import GymSubscription
        gym_subs = GymSubscription.objects.filter(user=user).select_related(
            'plan', 'plan__provider'
        ).prefetch_related('plan__branches').order_by('-end_date')

        for sub in gym_subs:
            plan = sub.plan
            branch = plan.branches.first()
            
            sub_entry = {
                "id": sub.id,
                "service_type": "gym",
                "type": "regular",
                "provider_id": plan.provider.id,
                "provider_name": plan.provider.business_name,
                "branch_id": branch.id if branch else None,
                "branch_name": branch.name if branch else plan.provider.business_name,
                "address": branch.address if branch else plan.provider.business_name,
                "lat": branch.location.y if branch and branch.location else None,
                "lng": branch.location.x if branch and branch.location else None,
                "status": sub.status,
                "qr_code_signature": sub.get_signed_qr_code(),
                "start_date": sub.start_date,
                "end_date": sub.end_date,
                "branch_logo": None
            }

            if branch and getattr(branch, 'branch_logo', None) and getattr(branch.branch_logo, 'url', None) and request:
                sub_entry["branch_logo"] = request.build_absolute_uri(branch.branch_logo.url)
            elif plan.provider.logo and getattr(plan.provider.logo, 'url', None) and request:
                sub_entry["branch_logo"] = request.build_absolute_uri(plan.provider.logo.url)

            unified_subscriptions.append(sub_entry)

        # 2. Fetch Roaming Passes
        from apps.gyms.models import RoamingPass
        roaming_passes = RoamingPass.objects.filter(user=user).select_related(
            'branch', 'branch__provider'
        ).order_by('-purchased_at')

        for rp in roaming_passes:
            branch = rp.branch
            provider = branch.provider
            
            # Determine status based on 'is_used'. Roaming passes don't technically "expire"
            # but we treat them as active if not used.
            status_val = "expired" if rp.is_used else "active"
            
            rp_entry = {
                "id": rp.id,
                "service_type": "gym",
                "type": "roaming",
                "provider_id": provider.id,
                "provider_name": provider.business_name,
                "branch_id": branch.id,
                "branch_name": branch.name,
                "address": branch.address,
                "lat": branch.location.y if branch.location else None,
                "lng": branch.location.x if branch.location else None,
                "status": status_val,
                "qr_code_signature": rp.get_signed_qr_code(),
                "start_date": rp.purchased_at.date(),
                "end_date": rp.purchased_at.date(), # Roaming pass is a 1-day pass technically
                "branch_logo": None
            }

            if getattr(branch, 'branch_logo', None) and getattr(branch.branch_logo, 'url', None) and request:
                rp_entry["branch_logo"] = request.build_absolute_uri(branch.branch_logo.url)
            elif provider.logo and getattr(provider.logo, 'url', None) and request:
                rp_entry["branch_logo"] = request.build_absolute_uri(provider.logo.url)

            unified_subscriptions.append(rp_entry)

        # Sort the unified list by end_date (most recent first)
        unified_subscriptions.sort(key=lambda x: x["end_date"], reverse=True)
        
        return unified_subscriptions