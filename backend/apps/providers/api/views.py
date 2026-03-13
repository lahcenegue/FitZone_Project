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
from django.utils.translation import gettext_lazy as _

from .serializers import (
    EmailVerificationSerializer,
    ProviderRegistrationSerializer,
    ProviderStatusSerializer,
    ResendVerificationSerializer,
    ProviderLoginSerializer,
    ProviderLogoutSerializer,
)

from ..services.provider_service import ProviderRegistrationService, EmailNotVerifiedError
# Import Map Service
from ..services.map_service import MapDiscoveryService

logger = logging.getLogger(__name__)

# ==========================================
# AUTHENTICATION APIs
# ==========================================

class ProviderRegisterView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = ProviderRegistrationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        data = serializer.validated_data
        try:
            provider = ProviderRegistrationService.register(
                email=data["email"], password=data["password"], full_name=data["full_name"],
                phone_number=data["phone_number"], provider_type=data["provider_type"],
                business_name=data["business_name"], business_phone=data["business_phone"],
                city=data["city"], address=data.get("address", ""), description=data.get("description", ""),
            )
        except ValueError as exc:
            return Response({"email": [str(exc)]}, status=status.HTTP_400_BAD_REQUEST)
        return Response(
            {"message": "Registration successful. A verification email has been sent.", "provider": ProviderStatusSerializer(provider).data},
            status=status.HTTP_201_CREATED,
        )

class VerifyEmailView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = EmailVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        try:
            provider = ProviderRegistrationService.verify_email(token_string=serializer.validated_data["token"])
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        refresh = RefreshToken.for_user(provider.user)
        return Response(
            {"message": "Email verified successfully.", "provider": ProviderStatusSerializer(provider).data, "tokens": {"refresh": str(refresh), "access": str(refresh.access_token)}},
            status=status.HTTP_200_OK,
        )

class ResendVerificationView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = ResendVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        ProviderRegistrationService.resend_verification(email=serializer.validated_data["email"])
        return Response({"message": "If this email address is registered, a new link has been sent."}, status=status.HTTP_200_OK)

class ProviderRegistrationStatusView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        try:
            provider = request.user.provider_profile
        except Exception:
            return Response({"detail": "No provider profile found."}, status=status.HTTP_404_NOT_FOUND)
        return Response({"provider": ProviderStatusSerializer(provider).data}, status=status.HTTP_200_OK)
    
class ProviderLoginView(APIView):
    """
    POST /api/v1/providers/login/
    Authenticate a provider and return JWT tokens.
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
        except EmailNotVerifiedError as exc:
            # THE SMART RESPONSE FOR FLUTTER APP
            return Response(
                {
                    "detail": str(exc),
                    "code": "EMAIL_NOT_VERIFIED",
                    "email": serializer.validated_data["email"]
                }, 
                status=status.HTTP_403_FORBIDDEN
            )
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_401_UNAUTHORIZED)

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
    permission_classes = [IsAuthenticated]
    def post(self, request):
        serializer = ProviderLogoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        try:
            token = RefreshToken(serializer.validated_data["refresh"])
            token.blacklist()
            return Response({"message": "Successfully logged out."}, status=status.HTTP_205_RESET_CONTENT)
        except TokenError:
            return Response({"detail": "Token is invalid or already blacklisted."}, status=status.HTTP_400_BAD_REQUEST)

# ==========================================
# MAP DISCOVERY API
# ==========================================

class UnifiedMapDiscoveryView(APIView):
    """
    GET /api/v1/providers/map/discover/
    Retrieves all active providers within the user's current map viewport.
    """
    permission_classes = [AllowAny] 

    def get(self, request, *args, **kwargs):
        try:
            min_lat = float(request.query_params.get('min_lat'))
            min_lng = float(request.query_params.get('min_lng'))
            max_lat = float(request.query_params.get('max_lat'))
            max_lng = float(request.query_params.get('max_lng'))
        except (TypeError, ValueError):
            return Response(
                {"detail": _("Invalid or missing bounding box parameters. Require: min_lat, min_lng, max_lat, max_lng.")},
                status=status.HTTP_400_BAD_REQUEST
            )

        if min_lat > max_lat or min_lng > max_lng:
            return Response(
                {"detail": _("Invalid coordinate bounds. min values cannot be greater than max values.")},
                status=status.HTTP_400_BAD_REQUEST
            )

        points = MapDiscoveryService.get_points_in_bounds(
            min_lat=min_lat, min_lng=min_lng, max_lat=max_lat, max_lng=max_lng, request=request
        )

        return Response({
            "count": len(points),
            "results": points
        }, status=status.HTTP_200_OK)