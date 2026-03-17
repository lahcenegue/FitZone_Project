"""
Service for handling unified geospatial discovery across all provider types.
Uses PostGIS Bounding Box queries to fetch map points efficiently.
"""
import logging
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
        now = timezone.localtime().time()
        
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
                active_visits_prefetch
            )

            for gym in gyms:
                logo_url = request.build_absolute_uri(gym.branch_logo.url) if (gym.branch_logo and request) else None
                
                # --- 1. Calculate Rating ---
                rating = round(gym.avg_rating, 1) if gym.avg_rating else 0.0

                # --- 2. Calculate Open Status (With Emergency Close Check) ---
                if gym.is_temporarily_closed:
                    is_open_now = False
                else:
                    is_open_now = True
                    if gym.opening_time and gym.closing_time:
                        if gym.opening_time <= gym.closing_time:
                            is_open_now = gym.opening_time <= now <= gym.closing_time
                        else:
                            is_open_now = now >= gym.opening_time or now <= gym.closing_time

                # --- 3. Calculate Live Crowd Level ---
                capacity = gym.max_capacity if gym.max_capacity and gym.max_capacity > 0 else 100
                # Access the pre-filtered list in memory
                active_visits_count = len(gym.live_visits) 
                occupancy_rate = (active_visits_count / capacity) * 100

                if occupancy_rate <= gym.crowd_level_low:
                    crowd_level = "low"
                elif occupancy_rate <= gym.crowd_level_medium:
                    crowd_level = "medium"
                elif occupancy_rate <= gym.crowd_level_high:
                    crowd_level = "high"
                else:
                    crowd_level = "full"

                # --- 4. Append to Results (Without Description) ---
                results.append({
                    "id": gym.id,
                    "provider_id": gym.provider.id,
                    "type": "gym",
                    "name": gym.name,
                    "lat": gym.location.y,
                    "lng": gym.location.x,
                    "image_url": logo_url,
                    "is_active": gym.is_active,
                    "rating": rating,
                    "is_open_now": is_open_now,
                    "crowd_level": crowd_level
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
            logger.error(f"Error fetching map points: {str(e)}")
        
        return results