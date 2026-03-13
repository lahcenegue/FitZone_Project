"""
Service for handling unified geospatial discovery across all provider types.
Uses PostGIS Bounding Box queries to fetch map points efficiently.
"""
import logging
from django.contrib.gis.geos import Polygon
from apps.gyms.models import GymBranch

logger = logging.getLogger(__name__)

class MapDiscoveryService:
    @staticmethod
    def get_points_in_bounds(min_lat: float, min_lng: float, max_lat: float, max_lng: float, request=None) -> list:
        """
        Fetches all active provider locations within the given map boundaries.
        Returns a unified list of dictionaries ready for JSON serialization.
        """
        results = []
        try:
            # 1. Create a PostGIS Polygon from the Bounding Box (Viewport)
            # Order must be: (min_lng, min_lat), (max_lng, min_lat), (max_lng, max_lat), (min_lng, max_lat), (min_lng, min_lat)
            bbox_geom = Polygon.from_bbox((min_lng, min_lat, max_lng, max_lat))

            # -------------------------------------------------------------
            # A. FETCH GYM BRANCHES
            # -------------------------------------------------------------
            gyms = GymBranch.objects.filter(
                is_active=True,
                location__within=bbox_geom
            ).select_related('provider')

            for gym in gyms:
                logo_url = request.build_absolute_uri(gym.branch_logo.url) if (gym.branch_logo and request) else None
                results.append({
                    "id": gym.id,
                    "provider_id": gym.provider.id,
                    "type": "gym",
                    "name": gym.name,
                    "description": gym.description,
                    "lat": gym.location.y, # Latitude
                    "lng": gym.location.x, # Longitude
                    "image_url": logo_url,
                    "is_active": gym.is_active
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
            # In a production environment, you might want to raise a custom exception here
        
        return results