import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

from .serializers import (
    UserRegistrationSerializer, 
    UserLoginSerializer, 
    UserProfileSerializer,
    UserProfileCompletionSerializer,
    UserEmailVerificationSerializer, 
    UserResendVerificationSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
    UserChangePasswordSerializer,
    UserAvatarUpdateSerializer,
    UserProfileUpdateSerializer,
    UserAccountDeleteSerializer,
    UserLogoutSerializer,
    AggregatedSubscriptionSerializer
)
from ..services.user_service import UserAuthService, UserDashboardService

logger = logging.getLogger(__name__)

class CustomerRegisterView(APIView):
    """
    POST /api/v1/users/register/
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = UserRegistrationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = UserAuthService.register_customer(serializer.validated_data)
            return Response({
                "message": "Registration successful. Please verify your email.",
                "user": UserProfileSerializer(user, context={'request': request}).data
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class CustomerLoginView(APIView):
    """
    POST /api/v1/users/login/
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = UserLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = UserAuthService.authenticate_customer(
                email=serializer.validated_data["email"],
                password=serializer.validated_data["password"]
            )
        except PermissionError:
            return Response({
                "detail": "Email is not verified.",
                "code": "EMAIL_NOT_VERIFIED",
                "email": serializer.validated_data["email"]
            }, status=status.HTTP_403_FORBIDDEN)
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_401_UNAUTHORIZED)

        refresh = RefreshToken.for_user(user)

        return Response({
            "message": "Login successful.",
            "user": UserProfileSerializer(user, context={'request': request}).data,
            "tokens": {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
            }
        }, status=status.HTTP_200_OK)
    
class CustomerVerifyEmailView(APIView):
    """
    POST /api/v1/users/verify-email/
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = UserEmailVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = UserAuthService.verify_email(serializer.validated_data['otp'])
            refresh = RefreshToken.for_user(user)
            
            return Response({
                "message": "Email verified successfully.",
                "user": UserProfileSerializer(user, context={'request': request}).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                }
            }, status=status.HTTP_200_OK)
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

class CustomerResendVerificationView(APIView):
    """
    POST /api/v1/users/resend-verification/
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = UserResendVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        UserAuthService.resend_verification(serializer.validated_data['email'])
        return Response({
            "message": "If this email is registered, a new OTP has been sent."
        }, status=status.HTTP_200_OK)

class CustomerProfileCompletionView(APIView):
    """
    POST /api/v1/users/profile/complete/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = UserProfileCompletionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = UserAuthService.complete_profile(request.user, serializer.validated_data)
            return Response({
                "message": "Profile completed successfully.",
                "user": UserProfileSerializer(user, context={'request': request}).data
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class CustomerPasswordResetRequestView(APIView):
    """
    POST /api/v1/users/password-reset/request/
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        UserAuthService.request_password_reset(serializer.validated_data['email'])
        
        return Response({
            "message": "If this email is registered, a password reset OTP has been sent."
        }, status=status.HTTP_200_OK)

class CustomerPasswordResetConfirmView(APIView):
    """
    POST /api/v1/users/password-reset/confirm/
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            UserAuthService.confirm_password_reset(
                email=serializer.validated_data['email'],
                otp_code=serializer.validated_data['otp'],
                new_password=serializer.validated_data['new_password']
            )
            return Response({
                "message": "Password has been reset successfully. You can now login."
            }, status=status.HTTP_200_OK)
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

class CustomerChangePasswordView(APIView):
    """
    POST /api/v1/users/profile/change-password/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = UserChangePasswordSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            UserAuthService.change_password(
                user=request.user,
                old_password=serializer.validated_data['old_password'],
                new_password=serializer.validated_data['new_password']
            )
            return Response({"message": "Password changed successfully."}, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class CustomerAvatarUpdateView(APIView):
    """
    POST /api/v1/users/profile/avatar/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = UserAvatarUpdateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        user = UserAuthService.update_user_avatar(request.user, serializer.validated_data['avatar'])
        
        avatar_url = request.build_absolute_uri(user.avatar.url) if user.avatar else None
        
        return Response({
            "message": "Avatar updated successfully.",
            "avatar": avatar_url
        }, status=status.HTTP_200_OK)

class CustomerProfileUpdateView(APIView):
    """
    PATCH /api/v1/users/profile/update/
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        serializer = UserProfileUpdateSerializer(data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            user, email_changed = UserAuthService.update_user_profile(request.user, serializer.validated_data)
            return Response({
                "message": "Profile updated successfully.",
                "email_changed": email_changed,
                "user": UserProfileSerializer(user, context={'request': request}).data
            }, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class CustomerAccountDeleteView(APIView):
    """
    DELETE /api/v1/users/profile/delete/
    """
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        serializer = UserAccountDeleteSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            UserAuthService.delete_user_account(request.user, serializer.validated_data['password'])
            return Response({
                "message": "Account has been permanently deleted."
            }, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class CustomerLogoutView(APIView):
    """
    POST /api/v1/users/logout/
    Blacklists the provided refresh token.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = UserLogoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            token = RefreshToken(serializer.validated_data["refresh"])
            token.blacklist()
            return Response(
                {"message": "Successfully logged out."}, 
                status=status.HTTP_205_RESET_CONTENT
            )
        except TokenError:
            return Response(
                {"detail": "Token is invalid or already blacklisted."}, 
                status=status.HTTP_400_BAD_REQUEST
            )

class UserSubscriptionsAPIView(APIView):
    """
    GET /api/v1/users/my-subscriptions/
    Retrieves an enriched unified list of all subscriptions for the user.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            subs_data = UserDashboardService.get_all_subscriptions(request.user, request=request)
            serializer = AggregatedSubscriptionSerializer(subs_data, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error fetching subscriptions for {request.user.email}: {str(e)}", exc_info=True)
            return Response(
                {"detail": "An internal error occurred while fetching subscriptions."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )