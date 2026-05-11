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
from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from django.db.models import Avg, F

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

    def get_paginated_response(self, data):
        """
        Overrides the default DRF pagination response to strictly match 
        the unified application standard (results + meta).
        """
        return Response({
            "results": data,
            "meta": {
                "total_items": self.page.paginator.count,
                "total_pages": self.page.paginator.num_pages,
                "current_page": self.page.number,
                "has_next": self.page.has_next(),
                "has_previous": self.page.has_previous()
            }
        })

class MarketplaceListView(ListAPIView):
    """
    GET /api/v1/resale/discover/
    Returns all active resale listings.
    Supports geospatial filtering if 'user_lat' and 'user_lng' are provided.
    """
    permission_classes = [AllowAny]
    serializer_class = ResaleListingSerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        queryset = SubscriptionResaleListing.objects.filter(
            status=ResaleListingStatus.ACTIVE,
            subscription__end_date__gt=timezone.now().date()
        ).select_related(
            'seller',
            'subscription__plan',
            'subscription__plan__provider'
        ).prefetch_related('subscription__plan__branches')
        
        # 1. Annotate Branch Average Rating
        queryset = queryset.annotate(
            branch_rating=Avg('subscription__plan__branches__reviews__rating')
        )

        # 2. Handle Geospatial Queries & Distance Calculation
        user_lat = self.request.query_params.get('user_lat')
        user_lng = self.request.query_params.get('user_lng')

        if user_lat and user_lng:
            try:
                user_point = Point(float(user_lng), float(user_lat), srid=4326)
                queryset = queryset.annotate(
                    distance=Distance('subscription__plan__branches__location', user_point)
                ).annotate(
                    distance_km=F('distance') / 1000.0
                ).order_by('distance')
            except (ValueError, TypeError):
                logger.warning("Invalid coordinate types passed to marketplace discover API.")
                queryset = queryset.order_by('-created_at')
        else:
            queryset = queryset.order_by('-created_at')

        # 3. Handle specific branch filtering
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
            transaction_obj = ResaleMarketService.purchase_listing(
                buyer=request.user,
                listing_id=serializer.validated_data['listing_id'],
                gateway_name=serializer.validated_data['gateway']
            )
            return Response({
                "message": str(_("Purchase successful. Subscription has been transferred to your account.")),
                "transaction_id": transaction_obj.id,
                "status": transaction_obj.status
            }, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"detail": list(e) if hasattr(e, 'messages') else str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Purchase error for user {request.user.id}: {str(e)}")
            return Response({"detail": str(_("An internal error occurred during purchase."))}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)