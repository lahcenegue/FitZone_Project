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
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

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

    Success 201:
        { "message": "...", "provider": { ... } }

    Error 400:
        { "field": ["error"] }
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
            return Response(
                {"email": [str(exc)]},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "message": (
                    "Registration successful. "
                    "A verification email has been sent to your address. "
                    "Please verify your email to proceed."
                ),
                "provider": ProviderStatusSerializer(provider).data,
            },
            status=status.HTTP_201_CREATED,
        )


class VerifyEmailView(APIView):
    """
    POST /api/v1/providers/verify-email/

    Verify a provider's email using the token from the email link.
    Public — no authentication required.

    Request:  { "token": "<64-char hex>" }
    Success:  { "message": "...", "provider": { ... } }
    Error:    { "detail": "..." }
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
            return Response(
                {"detail": str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "message": (
                    "Email verified successfully. "
                    "Your application is now under review. "
                    "We will notify you by email once a decision has been made."
                ),
                "provider": ProviderStatusSerializer(provider).data,
            },
            status=status.HTTP_200_OK,
        )


class ResendVerificationView(APIView):
    """
    POST /api/v1/providers/resend-verification/

    Resend the verification email.
    Public — always returns 200 to prevent email enumeration.

    Request:  { "email": "provider@example.com" }
    Response: { "message": "..." }
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

    Success:  { "provider": { ... } }
    Error:    { "detail": "No provider profile found." }
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