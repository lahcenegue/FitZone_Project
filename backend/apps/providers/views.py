"""
API views for provider registration.

Each view does exactly three things:
    1. Validate input via serializer
    2. Call the service method
    3. Return the response

No business logic lives here.
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
)
from .services import ProviderRegistrationService

logger = logging.getLogger(__name__)


class ProviderRegisterView(APIView):
    """
    POST /api/v1/providers/register/

    Register a new service provider.
    Public — no authentication required.
    """

    authentication_classes = []
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
                description=data.get("description", ""),
            )
        except ValueError as exc:
            return Response({"email": [str(exc)]}, status=status.HTTP_400_BAD_REQUEST)

        return Response(
            {
                "message": "Registration successful. A verification email has been sent.",
                "provider": ProviderStatusSerializer(provider).data,
            },
            status=status.HTTP_201_CREATED,
        )


class VerifyEmailView(APIView):
    """
    POST /api/v1/providers/verify-email/

    Verify email using the token and return JWT tokens
    for auto-login in the Flutter application.
    """

    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = EmailVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            provider = ProviderRegistrationService.verify_email(
                token_string=serializer.validated_data["token"]
            )
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

        # Generate JWT tokens for auto-login
        refresh = RefreshToken.for_user(provider.user)

        return Response(
            {
                "message": "Email verified successfully. Your account is under review.",
                "provider": ProviderStatusSerializer(provider).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                }
            },
            status=status.HTTP_200_OK,
        )


class ResendVerificationView(APIView):
    """
    POST /api/v1/providers/resend-verification/

    Generate and send a new verification email.
    """

    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ResendVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        ProviderRegistrationService.resend_verification(
            email=serializer.validated_data["email"]
        )

        return Response(
            {
                "message": (
                    "If this email address is registered and pending verification, "
                    "a new link has been sent."
                )
            },
            status=status.HTTP_200_OK,
        )


class ProviderRegistrationStatusView(APIView):
    """
    GET /api/v1/providers/registration-status/

    Return registration status for the authenticated provider.
    Requires a valid JWT Bearer token.
    """

    def get(self, request):
        try:
            provider = request.user.provider_profile
        except Exception:
            return Response(
                {"detail": "No provider profile found for this account."},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(
            {"provider": ProviderStatusSerializer(provider).data},
            status=status.HTTP_200_OK,
        )
    
class ProviderLoginView(APIView):
    """
    POST /api/v1/providers/login/

    Authenticate a provider and return JWT tokens for Flutter app.
    Public — no authentication required.
    """

    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        from .serializers import ProviderLoginSerializer
        
        serializer = ProviderLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            provider = ProviderRegistrationService.authenticate_provider(
                email=serializer.validated_data["email"],
                password=serializer.validated_data["password"]
            )
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_401_UNAUTHORIZED)

        # Generate JWT tokens for the mobile app
        refresh = RefreshToken.for_user(provider.user)

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
    
class ProviderLogoutView(APIView):
    """
    POST /api/v1/providers/logout/

    Blacklist the given refresh token to end the session securely.
    Requires a valid JWT Bearer token.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        from .serializers import ProviderLogoutSerializer
        
        serializer = ProviderLogoutSerializer(data=request.data)
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
                {"detail": "Token is invalid or has already been blacklisted."}, 
                status=status.HTTP_400_BAD_REQUEST
            )