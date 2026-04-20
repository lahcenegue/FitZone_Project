import json
import logging
from datetime import datetime
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
    and geo-spatial sorting. Isolated by provider type.
    """

    @staticmethod
    def search_providers(params: dict):
        """
        Master method to route search based on provider type.
        """
        service_type = params.get('type', 'gym').lower()
        
        if service_type == 'gym':
            return UnifiedSearchService._search_gyms(params)
        # Placeholder for future service types
        # elif service_type == 'trainer':
        #     return UnifiedSearchService._search_trainers(params)
        else:
            raise ValueError(f"Unsupported service type: {service_type}")

    @staticmethod
    def _search_gyms(params: dict):
        """
        Search logic specifically tailored and isolated for Gyms.
        """
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

        # 2. Gender Filter (Gym Specific - Smart Inclusion)
        gender = params.get('gender')
        if gender == 'men':
            queryset = queryset.filter(Q(gender='men') | Q(gender='mixed'))
        elif gender == 'women':
            queryset = queryset.filter(Q(gender='women') | Q(gender='mixed'))
        elif gender == 'mixed':
            queryset = queryset.filter(gender='mixed')

        # 3. City Filter (Supports 'city_id' or legacy 'city')
        city_id = params.get('city_id') or params.get('city')
        if city_id:
            queryset = queryset.filter(city__iexact=city_id)

        # 4. Amenities & Sports Filters (Gym Specific)
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

        # 6. Open Now Status (Adapted for JSON operating_hours)
        is_open = params.get('is_open')
        if is_open and str(is_open).lower() == 'true':
            open_gym_ids = []
            now_dt = timezone.localtime()
            current_day = now_dt.strftime('%w') # 0=Sunday, 1=Monday
            current_time = now_dt.time()

            for gym in queryset:
                if gym.is_temporarily_closed:
                    continue
                
                is_gym_open = False
                schedule = getattr(gym, 'operating_hours', [])
                
                if isinstance(schedule, str):
                    try:
                        schedule = json.loads(schedule)
                    except json.JSONDecodeError:
                        schedule = []
                
                if isinstance(schedule, list):
                    for period in schedule:
                        days_values = [str(val) for val in period.get('days_values', [])]
                        if current_day in days_values:
                            try:
                                start_str = period.get('start')
                                end_str = period.get('end')
                                if start_str and end_str:
                                    start_t = datetime.strptime(start_str, '%H:%M').time()
                                    end_t = datetime.strptime(end_str, '%H:%M').time()
                                    
                                    if start_t <= end_t:
                                        if start_t <= current_time <= end_t:
                                            is_gym_open = True
                                            break
                                    else:
                                        if current_time >= start_t or current_time <= end_t:
                                            is_gym_open = True
                                            break
                            except (ValueError, TypeError):
                                continue
                
                if is_gym_open:
                    open_gym_ids.append(gym.id)
            
            queryset = queryset.filter(id__in=open_gym_ids)

        # 7. Map Bounding Box Filtering
        min_lat = params.get('min_lat')
        min_lng = params.get('min_lng')
        max_lat = params.get('max_lat')
        max_lng = params.get('max_lng')

        if min_lat and min_lng and max_lat and max_lng:
            try:
                geom = Polygon.from_bbox((
                    float(min_lng), float(min_lat),
                    float(max_lng), float(max_lat)
                ))
                queryset = queryset.filter(location__within=geom)
            except (ValueError, TypeError):
                logger.error("Invalid bounding box coordinates provided.")

        # 8. Exact Distance Calculation & Radius (If center coords provided)
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