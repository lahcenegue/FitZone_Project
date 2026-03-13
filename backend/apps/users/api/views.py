from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken


from .serializers import (
    UserRegistrationSerializer, 
    UserLoginSerializer, 
    UserProfileSerializer,
    UserProfileCompletionSerializer,
    UserEmailVerificationSerializer, 
    UserResendVerificationSerializer
)
from ..services.user_service import UserAuthService

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
                "user": UserProfileSerializer(user).data
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
            "user": UserProfileSerializer(user).data,
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
            user = UserAuthService.verify_email(serializer.validated_data['token'])
            refresh = RefreshToken.for_user(user)
            
            return Response({
                "message": "Email verified successfully.",
                "user": UserProfileSerializer(user).data,
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
            "message": "If this email is registered, a new link has been sent."
        }, status=status.HTTP_200_OK)


class CustomerProfileCompletionView(APIView):
    """
    POST /api/v1/users/profile/complete/
    Requires valid JWT token. 
    Accepts multipart/form-data for image uploads.
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
                "user": UserProfileSerializer(user).data
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)