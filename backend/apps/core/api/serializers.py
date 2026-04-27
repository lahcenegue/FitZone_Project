from rest_framework import serializers
from apps.core.models import AppConfiguration
from apps.loyalty.models import LoyaltyGlobalSetting

class AppInitSerializer(serializers.ModelSerializer):
    """
    Serializer for the /init/ endpoint. 
    Returns data versions, update configurations, and dynamic loyalty roadmap version.
    """
    loyalty_roadmap_version = serializers.SerializerMethodField()

    class Meta:
        model = AppConfiguration
        fields = [
            'sports_version', 'amenities_version', 'cities_version', 'service_types_version',
            'loyalty_roadmap_version',
            'android_version', 'ios_version', 'force_update', 'update_message'
        ]

    def get_loyalty_roadmap_version(self, obj):
        """
        Dynamically fetches the latest roadmap version from the Loyalty application.
        This forces the mobile app to refresh the milestones map when changed by admin.
        """
        try:
            loyalty_settings = LoyaltyGlobalSetting.load()
            return loyalty_settings.roadmap_version
        except Exception:
            # Fallback version if loyalty settings are not yet initialized
            return 1