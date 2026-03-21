# apps/core/api/views.py
import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from apps.core.models import AppConfiguration, City
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
    Returns a list of supported cities dynamically translated via JSONField.
    """
    authentication_classes = []
    permission_classes = []

    def get(self, request, *args, **kwargs):
        cities = City.objects.filter(is_active=True)
        
        # Detect language from header
        lang = request.META.get('HTTP_ACCEPT_LANGUAGE', 'en').lower()
        primary_lang = 'ar' if 'ar' in lang else 'en'

        cities_data = []
        for city in cities:
            # Extract translation or fallback to default
            if city.translations and isinstance(city.translations, dict):
                translated_name = city.translations.get(primary_lang, city.name)
            else:
                translated_name = city.name
                
            cities_data.append({
                "id": city.code, 
                "name": translated_name
            })

        return Response(cities_data, status=status.HTTP_200_OK)