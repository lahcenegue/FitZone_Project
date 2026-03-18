import logging
from django.contrib.gis.geos import Point, Polygon
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from django.db.models import Q, F, Min
from django.utils import timezone
from apps.gyms.models import GymBranch

logger = logging.getLogger(__name__)

class UnifiedSearchService:
    """
    Service layer for handling complex search, filtering, bounding-box map discovery, 
    and geo-spatial sorting in a single unified query.
    """

    @staticmethod
    def search_gyms(params: dict):
        queryset = GymBranch.objects.filter(is_active=True).select_related('provider')

        # 1. Text Search
        q = params.get('q')
        if q:
            queryset = queryset.filter(
                Q(name__icontains=q) |
                Q(address__icontains=q) |
                Q(description__icontains=q) |
                Q(provider__business_name__icontains=q)
            )

        # 2. Gender Filter
        gender = params.get('gender')
        if gender in ['men', 'women', 'mixed']:
            queryset = queryset.filter(gender=gender)

        # 3. City Filter
        city = params.get('city')
        if city:
            queryset = queryset.filter(city__iexact=city)

        # 4. Amenities & Sports Filters
        sports = params.get('sports')
        if sports:
            sport_ids = [int(s) for s in sports.split(',') if s.isdigit()]
            if sport_ids:
                queryset = queryset.filter(sports__id__in=sport_ids).distinct()

        amenities = params.get('amenities')
        if amenities:
            amenity_ids = [int(a) for a in amenities.split(',') if a.isdigit()]
            if amenity_ids:
                queryset = queryset.filter(amenities__id__in=amenity_ids).distinct()

        # 5. Price Range Filter
        min_price = params.get('min_price')
        max_price = params.get('max_price')
        if min_price or max_price:
            queryset = queryset.annotate(min_plan_price=Min('available_plans__price'))
            if min_price and min_price.replace('.', '', 1).isdigit():
                queryset = queryset.filter(min_plan_price__gte=float(min_price))
            if max_price and max_price.replace('.', '', 1).isdigit():
                queryset = queryset.filter(min_plan_price__lte=float(max_price))

        # 6. Open Now Status
        is_open = params.get('is_open')
        if is_open and str(is_open).lower() == 'true':
            now_time = timezone.localtime().time()
            standard_hours = Q(opening_time__lte=now_time, closing_time__gte=now_time, opening_time__lt=F('closing_time'))
            overnight_hours = Q(opening_time__gt=F('closing_time')) & (Q(opening_time__lte=now_time) | Q(closing_time__gte=now_time))
            queryset = queryset.filter(is_temporarily_closed=False).filter(standard_hours | overnight_hours)

        # 7. Map Bounding Box Filtering (Crucial for Map View in Flutter)
        min_lat = params.get('min_lat')
        min_lng = params.get('min_lng')
        max_lat = params.get('max_lat')
        max_lng = params.get('max_lng')

        if min_lat and min_lng and max_lat and max_lng:
            try:
                # Create a polygon representing the phone screen's map area
                geom = Polygon.from_bbox((
                    float(min_lng), float(min_lat),
                    float(max_lng), float(max_lat)
                ))
                queryset = queryset.filter(location__within=geom)
            except (ValueError, TypeError):
                logger.error("Invalid bounding box coordinates provided.")

        # 8. Exact Distance Calculation & Radius (If user center location is provided)
        lat = params.get('lat')
        lng = params.get('lng')
        radius_km = params.get('radius_km')
        
        if lat and lng:
            try:
                user_location = Point(float(lng), float(lat), srid=4326)
                queryset = queryset.annotate(distance=Distance('location', user_location))
                
                if radius_km and radius_km.replace('.', '', 1).isdigit():
                    queryset = queryset.filter(location__distance_lte=(user_location, D(km=float(radius_km))))
            except (ValueError, TypeError):
                logger.error("Invalid center coordinates passed to search service.")

        # 9. Sorting Logic
        sort_by = params.get('sort_by')
        if sort_by == 'distance' and lat and lng:
            queryset = queryset.order_by('distance')
        else:
            queryset = queryset.order_by('-created_at')

        return queryset