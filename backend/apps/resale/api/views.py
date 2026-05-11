import logging
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.pagination import PageNumberPagination
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _
from django.utils import timezone

from apps.resale.models import SubscriptionResaleListing, ResaleListingStatus
from apps.resale.services import ResaleMarketService
from .serializers import (
    ResaleListingSerializer, CreateResaleListingSerializer, 
    PurchaseResaleSerializer
)

logger = logging.getLogger(__name__)

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'limit'
    max_page_size = 100

class MarketplaceListView(ListAPIView):
    """
    GET /api/v1/resale/discover/
    Returns all active resale listings with optional branch filtering.
    """
    permission_classes = [AllowAny]
    serializer_class = ResaleListingSerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        queryset = SubscriptionResaleListing.objects.filter(
            status=ResaleListingStatus.ACTIVE,
            subscription__end_date__gt=timezone.now().date()
        ).select_related('subscription__plan').prefetch_related('subscription__plan__branches')
        
        branch_id = self.request.query_params.get('branch_id')
        if branch_id:
            queryset = queryset.filter(subscription__plan__branches__id=branch_id)
            
        return queryset


class CreateListingAPIView(APIView):
    """
    POST /api/v1/resale/list/
    Enables a user to put their subscription for sale.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CreateResaleListingSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            listing = ResaleMarketService.list_subscription_for_resale(
                seller=request.user,
                subscription_id=serializer.validated_data['subscription_id'],
                asking_price=serializer.validated_data['asking_price']
            )
            return Response({
                "message": str(_("Subscription listed successfully in the marketplace.")),
                "listing_id": listing.id
            }, status=status.HTTP_201_CREATED)
        except ValidationError as e:
            return Response({"detail": list(e) if hasattr(e, 'messages') else str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Error creating listing for user {request.user.id}: {str(e)}")
            return Response({"detail": str(_("An internal error occurred."))}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CancelListingAPIView(APIView):
    """
    POST /api/v1/resale/cancel/
    Enables a seller to remove their listing.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        listing_id = request.data.get('listing_id')
        if not listing_id:
            return Response({"detail": "listing_id is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            ResaleMarketService.cancel_listing(request.user, listing_id)
            return Response({"message": str(_("Listing cancelled successfully."))}, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PurchaseListingAPIView(APIView):
    """
    POST /api/v1/resale/purchase/
    Enables a user to buy a resold subscription.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PurchaseResaleSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            transaction = ResaleMarketService.purchase_listing(
                buyer=request.user,
                listing_id=serializer.validated_data['listing_id'],
                gateway_name=serializer.validated_data['gateway']
            )
            return Response({
                "message": str(_("Purchase successful. Subscription has been transferred to your account.")),
                "transaction_id": transaction.id,
                "status": transaction.status
            }, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"detail": list(e) if hasattr(e, 'messages') else str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Purchase error for user {request.user.id}: {str(e)}")
            return Response({"detail": str(_("An internal error occurred during purchase."))}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)