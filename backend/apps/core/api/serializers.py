from rest_framework import serializers
from apps.core.models import AppConfiguration

class AppInitSerializer(serializers.ModelSerializer):
    """
    Serializer for the /init/ endpoint. 
    Returns data versions, update configurations, and loyalty points configs.
    """
    class Meta:
        model = AppConfiguration
        fields = [
            'sports_version', 'amenities_version', 'cities_version', 'service_types_version',
            'points_config_version', 'premium_points_required',
            'android_version', 'ios_version', 'force_update', 'update_message'
        ]