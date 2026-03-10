"""
API views for Gym access and management operations.
"""

import logging

from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import QRScanSerializer
from .services import GymAccessService

logger = logging.getLogger(__name__)


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
            # Execute business logic
            scan_result = GymAccessService.process_qr_scan(
                qr_code_id=str(serializer.validated_data["qr_code_id"]),
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
            # Business rule violations (e.g., expired, wrong branch, invalid QR)
            return Response(
                {"detail": str(exc)},
                status=status.HTTP_403_FORBIDDEN
            )
        except Exception as exc:
            logger.error("QR Scan failed: %s", exc)
            return Response(
                {"detail": "An internal server error occurred."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class LiveOccupancyView(APIView):
    """
    GET /api/v1/gyms/branches/<int:branch_id>/occupancy/

    Returns the real-time active visitor count for a specific branch.
    Public endpoint - anyone using the app can check gym crowdedness.
    """
    authentication_classes = []  # Explicitly disable JWT authentication for this view
    permission_classes = [AllowAny]

    def get(self, request, branch_id):
        from .services import GymAccessService
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