"""
API views for Gym access and management operations.
"""

import logging
from rest_framework import status
from rest_framework.generics import ListAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.db.models import Prefetch

from apps.gyms.models import GymBranch, SubscriptionPlan, GymSport, GymAmenity
from apps.gyms.api.serializers import (
    GymSportSerializer, GymAmenitySerializer, GymBranchDetailSerializer, 
    GymCheckoutSerializer, GymSubscriptionSerializer, RoamingCheckoutSerializer,
    RoamingPassSerializer, QRScanSerializer
)
from .services import GymSubscriptionService, GymAccessService


logger = logging.getLogger(__name__)


class GymBranchDetailView(APIView):
    """
    GET /api/v1/gyms/branches/<int:branch_id>/
    """
    permission_classes = [AllowAny]

    def get(self, request, branch_id):
        branch = get_object_or_404(
            GymBranch.objects.select_related('tier').prefetch_related(
                'images',
                'amenities',
                'sports',
                'schedules',
                'reviews__user',
                'visits',
                Prefetch(
                    'available_plans', 
                    queryset=SubscriptionPlan.objects.filter(is_active=True)
                )
            ),
            id=branch_id,
            is_active=True
        )

        from apps.gyms.models import GymGlobalSetting
        gym_setting = GymGlobalSetting.load()
        
        serializer = GymBranchDetailSerializer(
            branch, 
            context={'request': request, 'gym_setting': gym_setting}
        )
        return Response(serializer.data, status=status.HTTP_200_OK)
    
class GymSportListAPIView(ListAPIView):
    queryset = GymSport.objects.all().order_by('name')
    serializer_class = GymSportSerializer
    authentication_classes = []  
    permission_classes = []
    pagination_class = None

class GymAmenityListAPIView(ListAPIView):
    queryset = GymAmenity.objects.all().order_by('name')
    serializer_class = GymAmenitySerializer
    authentication_classes = [] 
    permission_classes = []
    pagination_class = None

class GymCheckoutAPIView(APIView):
    """
    POST /api/v1/gyms/checkout/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = GymCheckoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            subscription = GymSubscriptionService.checkout_subscription(
                user=request.user,
                plan_id=serializer.validated_data['plan_id'],
                gateway_name=serializer.validated_data['gateway'],
                points_to_use=serializer.validated_data.get('points_to_use', 0)
            )
            return Response({
                "message": "Payment successful. Subscription activated.",
                "subscription": GymSubscriptionSerializer(subscription).data
            }, status=status.HTTP_201_CREATED)
            
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Checkout error for user {request.user.email}: {str(e)}", exc_info=True)
            return Response(
                {"detail": "An internal error occurred during checkout."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class RoamingCheckoutAPIView(APIView):
    """
    POST /api/v1/gyms/roaming/checkout/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = RoamingCheckoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            roaming_pass = GymSubscriptionService.checkout_roaming_pass(
                user=request.user,
                branch_id=serializer.validated_data['branch_id'],
                payment_method=serializer.validated_data['payment_method'],
                gateway_name=serializer.validated_data.get('gateway')
            )
            return Response({
                "message": "Roaming Pass purchased successfully.",
                "roaming_pass": RoamingPassSerializer(roaming_pass).data
            }, status=status.HTTP_201_CREATED)
            
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Roaming checkout error for user {request.user.email}: {str(e)}", exc_info=True)
            return Response(
                {"detail": "An internal error occurred during roaming checkout."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class QRScanView(APIView):
    """
    POST /api/v1/gyms/scan-qr/

    Process a user's QR code for gym check-in.
    Requires an authenticated provider/receptionist.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = QRScanSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            scan_result = GymAccessService.process_qr_scan(
                qr_code_id=serializer.validated_data["qr_code_id"],
                branch_id=serializer.validated_data["branch_id"]
            )
            
            return Response(
                {
                    "message": "Access granted.",
                    "data": scan_result
                },
                status=status.HTTP_200_OK
            )
            
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_403_FORBIDDEN)
        except Exception as exc:
            logger.error("QR Scan failed: %s", exc)
            return Response(
                {"detail": "An internal server error occurred."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class LiveOccupancyView(APIView):
    """
    GET /api/v1/gyms/branches/<int:branch_id>/occupancy/
    """
    authentication_classes = []
    permission_classes = [AllowAny]

    def get(self, request, branch_id):
        try:
            count = GymAccessService.get_live_occupancy(branch_id=branch_id)
            return Response(
                {
                    "branch_id": branch_id,
                    "current_occupancy": count
                },
                status=status.HTTP_200_OK
            )
        except Exception as exc:
            logger.error("Failed to get occupancy for branch %s: %s", branch_id, exc)
            return Response(
                {"detail": "Failed to retrieve live occupancy."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )