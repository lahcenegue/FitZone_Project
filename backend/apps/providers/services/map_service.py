"""
Service for handling unified geospatial discovery across all provider types.
Uses PostGIS Bounding Box queries to fetch map points efficiently.
"""
import json
import logging
from datetime import datetime
from django.contrib.gis.geos import Polygon
from django.db.models import Prefetch, Avg
from django.utils import timezone

from apps.gyms.models import GymBranch, GymVisit

logger = logging.getLogger(__name__)

class MapDiscoveryService:
    @staticmethod
    def get_points_in_bounds(min_lat: float, min_lng: float, max_lat: float, max_lng: float, request=None) -> list:
        """
        Fetches all active provider locations within the given map boundaries.
        Returns a unified list of dictionaries ready for JSON serialization.
        Includes optimized real-time calculations for crowd levels and ratings.
        """
        results = []
        now_dt = timezone.localtime()
        current_time = now_dt.time()
        current_day = now_dt.strftime('%A')
        
        try:
            # 1. Create a PostGIS Polygon from the Bounding Box (Viewport)
            bbox_geom = Polygon.from_bbox((min_lng, min_lat, max_lng, max_lat))

            # -------------------------------------------------------------
            # A. FETCH GYM BRANCHES (Optimized Query)
            # -------------------------------------------------------------
            
            # Prefetch ONLY currently active visits to save memory (no historical data)
            active_visits_prefetch = Prefetch(
                'visits',
                queryset=GymVisit.objects.filter(is_active=True),
                to_attr='live_visits'
            )

            gyms = GymBranch.objects.filter(
                is_active=True,
                location__within=bbox_geom
            ).select_related('provider').annotate(
                # Calculate average rating directly in the database
                avg_rating=Avg('reviews__rating')
            ).prefetch_related(
                active_visits_prefetch,
                'sports'
            )

            for gym in gyms:
                logo_url = request.build_absolute_uri(gym.branch_logo.url) if (gym.branch_logo and request) else None
                
                # --- 1. Calculate Rating ---
                rating = round(gym.avg_rating, 1) if gym.avg_rating else 0.0

                # --- 2. Calculate Open Status (Adapted for JSON operating_hours) ---
                is_open_now = False
                if not gym.is_temporarily_closed:
                    schedule = getattr(gym, 'operating_hours', [])
                    if isinstance(schedule, str):
                        try:
                            schedule = json.loads(schedule)
                        except json.JSONDecodeError:
                            schedule = []
                    
                    if isinstance(schedule, list):
                        for period in schedule:
                            days = period.get('days', [])
                            if current_day in days:
                                try:
                                    start_str = period.get('start')
                                    end_str = period.get('end')
                                    if start_str and end_str:
                                        start_t = datetime.strptime(start_str, '%H:%M').time()
                                        end_t = datetime.strptime(end_str, '%H:%M').time()
                                        
                                        if start_t <= end_t:
                                            if start_t <= current_time <= end_t:
                                                is_open_now = True
                                                break
                                        else:
                                            if current_time >= start_t or current_time <= end_t:
                                                is_open_now = True
                                                break
                                except (ValueError, TypeError):
                                    continue

                # --- 3. Calculate Live Crowd Level ---
                capacity = gym.max_capacity if gym.max_capacity and gym.max_capacity > 0 else 100
                active_visits_count = len(gym.live_visits) 
                occupancy_rate = (active_visits_count / capacity) * 100

                # Secure fallback if crowd levels are not strictly defined
                lvl_low = getattr(gym, 'crowd_level_low', 30)
                lvl_medium = getattr(gym, 'crowd_level_medium', 60)
                lvl_high = getattr(gym, 'crowd_level_high', 90)

                if occupancy_rate <= lvl_low:
                    crowd_level = "low"
                elif occupancy_rate <= lvl_medium:
                    crowd_level = "medium"
                elif occupancy_rate <= lvl_high:
                    crowd_level = "high"
                else:
                    crowd_level = "full"

                # --- 4. Append to Results (Without Description) ---
                branch_sports = []
                for sport in gym.sports.all():
                    branch_sports.append(sport.name)

                results.append({
                    "id": gym.id,
                    "provider_id": gym.provider.id,
                    "type": "gym",
                    "name": gym.name,
                    "lat": gym.location.y,
                    "lng": gym.location.x,
                    "image_url": logo_url,
                    "is_active": gym.is_active,
                    "is_temporarily_closed": gym.is_temporarily_closed,
                    "rating": rating,
                    "is_open_now": is_open_now,
                    "crowd_level": crowd_level,
                    "sports": branch_sports
                })

            # -------------------------------------------------------------
            # B. FETCH TRAINERS (Placeholder for future MVP steps)
            # -------------------------------------------------------------
            # trainers = TrainerProfile.objects.filter(is_active=True, location__within=bbox_geom)
            # for trainer in trainers: ...

            # -------------------------------------------------------------
            # C. FETCH RESTAURANTS (Placeholder)
            # -------------------------------------------------------------
            # restaurants = RestaurantBranch.objects.filter(...)
            
            # -------------------------------------------------------------
            # D. FETCH STORES (Placeholder)
            # -------------------------------------------------------------
            # stores = StoreBranch.objects.filter(...)

        except Exception as e:
            logger.error(f"Error fetching map points: {str(e)}", exc_info=True)
        
        return results