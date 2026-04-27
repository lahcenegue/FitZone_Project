import logging
from rest_framework.views import APIView
from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import status
from django.core.exceptions import ValidationError

from apps.loyalty.services import LoyaltyService
from apps.loyalty.models import PointPackage, Milestone, UserMilestone
from .serializers import (
    PurchasePointsSerializer, MilestoneUsageSerializer, 
    PointPackageSerializer, MilestoneSerializer, UserMilestoneSerializer
)

logger = logging.getLogger(__name__)

class PointPackageListAPIView(ListAPIView):
    """
    GET /api/v1/loyalty/packages/
    Returns a list of all active point packages available for purchase.
    """
    permission_classes = [AllowAny]
    queryset = PointPackage.objects.filter(is_active=True)
    serializer_class = PointPackageSerializer
    pagination_class = None

class MilestoneRoadmapAPIView(ListAPIView):
    """
    GET /api/v1/loyalty/milestones/
    Returns the complete, active milestone roadmap for the mobile app UI.
    """
    permission_classes = [AllowAny]
    queryset = Milestone.objects.filter(is_active=True)
    serializer_class = MilestoneSerializer
    pagination_class = None

class UserMilestonesAPIView(ListAPIView):
    """
    GET /api/v1/loyalty/my-milestones/
    Returns all milestones unlocked by the current user.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = UserMilestoneSerializer
    pagination_class = None

    def get_queryset(self):
        return UserMilestone.objects.filter(user=self.request.user).select_related('milestone')


class WalletSummaryAPIView(APIView):
    """
    GET /api/v1/loyalty/wallet/
    Returns the user's loyalty summary, points balance, and milestone progression.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            summary = LoyaltyService.get_wallet_summary(request.user)
            return Response(summary, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error fetching wallet summary for user {request.user.id}: {str(e)}")
            return Response(
                {"detail": "Failed to retrieve wallet summary."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PurchasePointsAPIView(APIView):
    """
    POST /api/v1/loyalty/purchase/
    Process fiat payment to buy loyalty points directly.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PurchasePointsSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            LoyaltyService.purchase_points(
                user=request.user,
                package_id=serializer.validated_data['package_id'],
                gateway_name=serializer.validated_data['gateway']
            )
            return Response({"message": "Points purchased successfully."}, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Points purchase error for user {request.user.id}: {str(e)}")
            return Response(
                {"detail": "An internal error occurred during the transaction."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ConsumeMilestoneAPIView(APIView):
    """
    POST /api/v1/loyalty/milestones/consume/
    Consumes a specific milestone reward that the user has unlocked.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = MilestoneUsageSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            LoyaltyService.use_milestone_reward(
                user=request.user,
                user_milestone_id=serializer.validated_data['user_milestone_id']
            )
            return Response({"message": "Milestone reward consumed successfully."}, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"detail": list(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Error consuming milestone for user {request.user.id}: {str(e)}")
            return Response(
                {"detail": "Failed to consume milestone reward."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )