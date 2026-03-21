# apps/core/api/views.py
import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from apps.core.models import AppConfiguration
from apps.core.api.serializers import AppInitSerializer
from apps.core.constants import SAUDI_CITIES

logger = logging.getLogger(__name__)

class InitAPIView(APIView):
    """
    GET /api/v1/init/
    Provides the mobile app with the latest data versions and update requirements.
    """
    authentication_classes = []  # Public endpoint
    permission_classes = []

    def get(self, request, *args, **kwargs):
        try:
            config = AppConfiguration.get_solo()
            serializer = AppInitSerializer(config)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error fetching App Init config: {e}")
            return Response(
                {"error": "Internal Server Error"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class CityListAPIView(APIView):
    """
    GET /api/v1/cities/
    Returns a list of supported cities. 
    Translates automatically based on 'Accept-Language' header.
    """
    authentication_classes = []
    permission_classes = []

    def get(self, request, *args, **kwargs):
        # SAUDI_CITIES is imported from constants (e.g., (("riyadh", _("Riyadh")), ...))
        # The str() cast combined with Django's LocaleMiddleware handles the translation automatically.
        cities_data = [
            {"id": city_key, "name": str(city_name)} 
            for city_key, city_name in SAUDI_CITIES
        ]
        return Response(cities_data, status=status.HTTP_200_OK)