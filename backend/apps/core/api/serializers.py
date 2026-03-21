# apps/core/api/serializers.py
from rest_framework import serializers
from apps.core.models import AppConfiguration

class AppInitSerializer(serializers.ModelSerializer):
    """
    Serializer for the /init/ endpoint. 
    Returns data versions and app update configurations.
    """
    class Meta:
        model = AppConfiguration
        fields = [
            'sports_version', 'amenities_version', 'cities_version',
            'android_version', 'ios_version', 'force_update', 'update_message'
        ]