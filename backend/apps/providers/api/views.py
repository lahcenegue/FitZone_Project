"""
API views for Provider Auth and Unified Map Discovery.
"""

import logging
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

from .serializers import (
    EmailVerificationSerializer,
    ProviderRegistrationSerializer,
    ProviderStatusSerializer,
    ResendVerificationSerializer,
    ProviderLoginSerializer,
    ProviderLogoutSerializer,
)
from ..services.provider_service import ProviderRegistrationService, EmailNotVerifiedError

logger = logging.getLogger(__name__)


class ProviderRegisterView(APIView):
    """
    POST /api/v1/providers/register/
    Registers a new provider account.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ProviderRegistrationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        try:
            provider = ProviderRegistrationService.register(
                email=data["email"],
                password=data["password"],
                full_name=data["full_name"],
                phone_number=data["phone_number"],
                provider_type=data["provider_type"],
                business_name=data["business_name"],
                business_phone=data["business_phone"],
                city=data["city"],
                address=data.get("address", ""),
                description=data.get("description", "")
            )
            logger.info(f"Provider registered successfully: {provider.user.email}")
            return Response(
                {
                    "message": "Registration successful. A verification email has been sent.",
                    "provider": ProviderStatusSerializer(provider).data
                },
                status=status.HTTP_201_CREATED,
            )
        except ValueError as exc:
            logger.warning(f"Provider registration failed: {str(exc)}")
            return Response({"email": [str(exc)]}, status=status.HTTP_400_BAD_REQUEST)


class VerifyEmailView(APIView):
    """
    POST /api/v1/providers/verify-email/
    Verifies provider email using a token.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = EmailVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            provider = ProviderRegistrationService.verify_email(token_string=serializer.validated_data["token"])
            refresh = RefreshToken.for_user(provider.user)
            logger.info(f"Email verified successfully for: {provider.user.email}")
            return Response(
                {
                    "message": "Email verified successfully.",
                    "provider": ProviderStatusSerializer(provider).data,
                    "tokens": {
                        "refresh": str(refresh),
                        "access": str(refresh.access_token)
                    }
                },
                status=status.HTTP_200_OK,
            )
        except ValueError as exc:
            logger.warning(f"Email verification failed: {str(exc)}")
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)


class ResendVerificationView(APIView):
    """
    POST /api/v1/providers/resend-verification/
    Resends the verification email if the account exists and is unverified.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ResendVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        ProviderRegistrationService.resend_verification(email=serializer.validated_data["email"])
        return Response(
            {"message": "If this email address is registered, a new link has been sent."},
            status=status.HTTP_200_OK
        )


class ProviderRegistrationStatusView(APIView):
    """
    GET /api/v1/providers/status/
    Retrieves the registration and approval status of the authenticated provider.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            provider = request.user.provider_profile
            return Response({"provider": ProviderStatusSerializer(provider).data}, status=status.HTTP_200_OK)
        except Exception as exc:
            logger.error(f"Provider profile retrieval failed for user {request.user.id}: {str(exc)}")
            return Response({"detail": "No provider profile found."}, status=status.HTTP_404_NOT_FOUND)


class ProviderLoginView(APIView):
    """
    POST /api/v1/providers/login/
    Authenticates a provider and returns JWT tokens.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ProviderLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            provider = ProviderRegistrationService.authenticate_provider(
                email=serializer.validated_data["email"],
                password=serializer.validated_data["password"]
            )
            refresh = RefreshToken.for_user(provider.user)
            logger.info(f"Provider logged in successfully: {provider.user.email}")
            return Response(
                {
                    "message": "Login successful.",
                    "provider": ProviderStatusSerializer(provider).data,
                    "tokens": {
                        "refresh": str(refresh),
                        "access": str(refresh.access_token),
                    }
                },
                status=status.HTTP_200_OK,
            )
        except EmailNotVerifiedError as exc:
            logger.warning(f"Login attempt with unverified email: {serializer.validated_data['email']}")
            return Response(
                {
                    "detail": str(exc),
                    "code": "EMAIL_NOT_VERIFIED",
                    "email": serializer.validated_data["email"]
                },
                status=status.HTTP_403_FORBIDDEN
            )
        except ValueError as exc:
            logger.warning(f"Login failed for {serializer.validated_data['email']}: {str(exc)}")
            return Response({"detail": str(exc)}, status=status.HTTP_401_UNAUTHORIZED)


class ProviderLogoutView(APIView):
    """
    POST /api/v1/providers/logout/
    Blacklists the given refresh token.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ProviderLogoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            token = RefreshToken(serializer.validated_data["refresh"])
            token.blacklist()
            logger.info(f"Provider logged out successfully: {request.user.email}")
            return Response({"message": "Successfully logged out."}, status=status.HTTP_205_RESET_CONTENT)
        except TokenError as exc:
            logger.error(f"Logout failed, invalid token: {str(exc)}")
            return Response({"detail": "Token is invalid or already blacklisted."}, status=status.HTTP_400_BAD_REQUEST)