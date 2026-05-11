import logging
from decimal import Decimal
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.pagination import PageNumberPagination
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _
from django.utils import timezone
from django.contrib.gis.geos import Point, Polygon
from django.contrib.gis.measure import D
from django.contrib.gis.db.models.functions import Distance
from django.db.models.functions import ExtractDay
from django.db.models import Avg, F, Q, Case, When, ExpressionWrapper, FloatField, IntegerField, Value

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
    Returns active resale listings with unified advanced dynamic filtering, 
    geospatial routing, and custom sorting.
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
        
        queryset = self._annotate_dynamic_fields(queryset)
        queryset = self._apply_filters(queryset)
        queryset = self._apply_sorting(queryset)
        
        return queryset.distinct()

    def _annotate_dynamic_fields(self, queryset):
        """
        Calculates dynamic values (Days Left, Discount Percentage, Distance, Rating) 
        directly at the database level for high performance.
        """
        today = timezone.now().date()

        queryset = queryset.annotate(
            branch_rating=Avg('subscription__plan__branches__reviews__rating')
        )

        queryset = queryset.annotate(
            duration_interval=Case(
                When(subscription__start_date__gt=today, then=F('subscription__end_date') - F('subscription__start_date')),
                default=F('subscription__end_date') - today
            )
        ).annotate(
            days_left_count=ExtractDay('duration_interval')
        )

        queryset = queryset.annotate(
            discount_pct=Case(
                When(fair_value_at_listing__gt=0, then=ExpressionWrapper(
                    ((F('fair_value_at_listing') - F('asking_price')) / F('fair_value_at_listing')) * 100.0,
                    output_field=FloatField()
                )),
                default=Value(0.0),
                output_field=FloatField()
            )
        )

        lat = self.request.query_params.get('lat') or self.request.query_params.get('user_lat')
        lng = self.request.query_params.get('lng') or self.request.query_params.get('user_lng')

        if lat and lng:
            try:
                user_point = Point(float(lng), float(lat), srid=4326)
                queryset = queryset.annotate(
                    distance=Distance('subscription__plan__branches__location', user_point)
                ).annotate(
                    distance_km=ExpressionWrapper(F('distance') / 1000.0, output_field=FloatField())
                )
            except (ValueError, TypeError):
                logger.warning("Invalid coordinate types passed to marketplace discover API.")

        return queryset

    def _apply_filters(self, queryset):
        """
        Applies unified business requirements filters (Matches UnifiedSearchService).
        """
        params = self.request.query_params

        # 1. Text Search (Gym Brand or Branch Name)
        search_query = params.get('q') or params.get('search')
        if search_query:
            queryset = queryset.filter(
                Q(subscription__plan__provider__business_name__icontains=search_query) | 
                Q(subscription__plan__branches__name__icontains=search_query)
            )

        # 2. Gender Filter (Smart Inclusion)
        gender = params.get('gender')
        if gender == 'men':
            queryset = queryset.filter(Q(subscription__plan__branches__gender='men') | Q(subscription__plan__branches__gender='mixed'))
        elif gender == 'women':
            queryset = queryset.filter(Q(subscription__plan__branches__gender='women') | Q(subscription__plan__branches__gender='mixed'))
        elif gender == 'mixed':
            queryset = queryset.filter(subscription__plan__branches__gender='mixed')

        # 3. Price Range Filter
        min_price = params.get('min_price')
        if min_price:
            queryset = queryset.filter(asking_price__gte=min_price)
            
        max_price = params.get('max_price')
        if max_price:
            queryset = queryset.filter(asking_price__lte=max_price)

        # 4. Days Left Filter
        min_days = params.get('min_days')
        if min_days:
            queryset = queryset.filter(days_left_count__gte=min_days)
            
        max_days = params.get('max_days')
        if max_days:
            queryset = queryset.filter(days_left_count__lte=max_days)

        # 5. Discount Percentage Filter
        min_discount = params.get('min_discount')
        if min_discount:
            queryset = queryset.filter(discount_pct__gte=min_discount)

        # 6. Specific Branch ID
        branch_id = params.get('branch_id')
        if branch_id:
            queryset = queryset.filter(subscription__plan__branches__id=branch_id)

        # 7. Spatial Query Priority (City > Radius > Bounding Box)
        city_id = params.get('city_id') or params.get('city')
        lat = params.get('lat') or params.get('user_lat')
        lng = params.get('lng') or params.get('user_lng')
        radius_km = params.get('radius_km')

        min_lat = params.get('min_lat')
        min_lng = params.get('min_lng')
        max_lat = params.get('max_lat')
        max_lng = params.get('max_lng')

        if city_id:
            queryset = queryset.filter(subscription__plan__branches__city__iexact=city_id)
            lat = lng = radius_km = None
        elif radius_km and lat and lng:
            min_lat = min_lng = max_lat = max_lng = None

        if min_lat and min_lng and max_lat and max_lng:
            try:
                geom = Polygon.from_bbox((
                    float(min_lng), float(min_lat),
                    float(max_lng), float(max_lat)
                ))
                queryset = queryset.filter(subscription__plan__branches__location__within=geom)
            except (ValueError, TypeError):
                logger.error("Invalid bounding box coordinates provided.")

        if lat and lng and radius_km:
            try:
                user_point = Point(float(lng), float(lat), srid=4326)
                if str(radius_km).replace('.', '', 1).isdigit():
                    queryset = queryset.filter(
                        subscription__plan__branches__location__distance_lte=(user_point, D(km=float(radius_km)))
                    )
            except (ValueError, TypeError):
                logger.error("Invalid center coordinates passed to search service.")

        return queryset

    def _apply_sorting(self, queryset):
        """
        Applies requested sorting. Defaults to newest first.
        """
        sort_by = self.request.query_params.get('sort_by')
        lat = self.request.query_params.get('lat') or self.request.query_params.get('user_lat')
        lng = self.request.query_params.get('lng') or self.request.query_params.get('user_lng')

        if sort_by == 'price_asc':
            return queryset.order_by('asking_price')
        elif sort_by == '-discount':
            return queryset.order_by('-discount_pct')
        elif sort_by == '-days_left':
            return queryset.order_by('-days_left_count')
        elif sort_by == 'distance' and lat and lng:
            return queryset.order_by('distance')
        
        return queryset.order_by('-created_at')


class CreateListingAPIView(APIView):
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