from rest_framework import serializers
from apps.gyms.models import GymBranch, BranchImage, GymAmenity, SubscriptionPlan, PlanFeature

class GymAmenitySerializer(serializers.ModelSerializer):
    class Meta:
        model = GymAmenity
        fields = ['id', 'name', 'icon_name']

class PlanFeatureSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlanFeature
        fields = ['name']

class SubscriptionPlanSerializer(serializers.ModelSerializer):
    features = PlanFeatureSerializer(many=True, read_only=True)
    
    class Meta:
        model = SubscriptionPlan
        fields = ['id', 'name', 'description', 'price', 'duration_days', 'features']

class GymBranchDetailSerializer(serializers.ModelSerializer):
    provider_name = serializers.CharField(source='provider.business_name', read_only=True)
    amenities = GymAmenitySerializer(many=True, read_only=True)
    plans = serializers.SerializerMethodField()
    images = serializers.SerializerMethodField()
    lat = serializers.FloatField(source='location.y', read_only=True)
    lng = serializers.FloatField(source='location.x', read_only=True)

    class Meta:
        model = GymBranch
        fields = [
            'id', 'provider_name', 'name', 'description', 'phone_number',
            'opening_time', 'closing_time', 'city', 'address', 'lat', 'lng',
            'branch_logo', 'images', 'amenities', 'plans'
        ]

    def get_images(self, obj):
        """Retrieve absolute URLs for all images related to this branch."""
        request = self.context.get('request')
        if not request:
            return []
        return [request.build_absolute_uri(img.image.url) for img in obj.images.all() if img.image]

    def get_plans(self, obj):
        """Retrieve all active subscription plans available at this specific branch."""
        active_plans = obj.available_plans.filter(is_active=True)
        return SubscriptionPlanSerializer(active_plans, many=True).data