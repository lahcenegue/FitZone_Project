"""
API Serializers for Gyms application.
Handles structured data representation for sports, amenities, branches, and multi-metric reviews.
"""

from rest_framework import serializers
from django.db.models import Avg
from apps.gyms.models import (
    GymBranch, SubscriptionPlan, GymSport, GymAmenity, 
    GymReview, GymReviewTag, BranchImage, GymBranchSchedule,
    GymSubscription, RoamingPass
)

class GymSportSerializer(serializers.ModelSerializer):
    class Meta:
        model = GymSport
        fields = ['id', 'name', 'translations', 'image']

class GymAmenitySerializer(serializers.ModelSerializer):
    class Meta:
        model = GymAmenity
        fields = ['id', 'name', 'translations', 'icon_image']

class BranchImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = BranchImage
        fields = ['id', 'image', 'is_primary']

class GymBranchScheduleSerializer(serializers.ModelSerializer):
    day_display = serializers.CharField(source='get_day_display', read_only=True)

    class Meta:
        model = GymBranchSchedule
        fields = ['id', 'day', 'day_display', 'opening_time', 'closing_time', 'is_closed']

class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = ['id', 'name', 'description', 'price', 'duration_days', 'is_active']


# ==========================================
# NEW VIBE REVIEW SUBSYSTEM SERIALIZERS
# ==========================================

class GymReviewTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = GymReviewTag
        fields = ['id', 'slug', 'name', 'translations']


class GymReviewDetailSerializer(serializers.ModelSerializer):
    """
    Serializer representing individual customer text reviews, multi-axis scales, 
    and linked description tags for full transparency in the mobile exploration sheet.
    """
    customer_name = serializers.CharField(source='user.full_name', default='FitZone Member', read_only=True)
    customer_email = serializers.EmailField(source='user.email', read_only=True)
    tags = GymReviewTagSerializer(many=True, read_only=True)

    class Meta:
        model = GymReview
        fields = [
            'id', 'customer_name', 'customer_email', 'cleanliness_rating', 
            'equipment_rating', 'vibe_rating', 'review_text', 'tags', 'created_at'
        ]


class GymReviewSubmissionSerializer(serializers.ModelSerializer):
    """
    Validates input ranges for the multi-axis rating scales.
    Handles verification of Many-to-Many tag identifiers safely.
    """
    cleanliness_rating = serializers.IntegerField(min_value=1, max_value=5)
    equipment_rating = serializers.IntegerField(min_value=1, max_value=5)
    vibe_rating = serializers.IntegerField(min_value=1, max_value=5)
    review_text = serializers.CharField(required=False, allow_blank=True, allow_null=True, default="")
    tags = serializers.PrimaryKeyRelatedField(queryset=GymReviewTag.objects.all(), many=True, required=False)

    class Meta:
        model = GymReview
        fields = ['cleanliness_rating', 'equipment_rating', 'vibe_rating', 'review_text', 'tags']

    def validate(self, attrs):
        """Sanitizes comment to ensure clean text representation if null was supplied."""
        if 'review_text' not in attrs or attrs['review_text'] is None:
            attrs['review_text'] = ""
        return attrs


class GymBranchDetailSerializer(serializers.ModelSerializer):
    images = BranchImageSerializer(many=True, read_only=True)
    amenities = GymAmenitySerializer(many=True, read_only=True)
    sports = GymSportSerializer(many=True, read_only=True)
    schedules = GymBranchScheduleSerializer(many=True, read_only=True)
    available_plans = SubscriptionPlanSerializer(many=True, read_only=True)
    
    # Injected customer reviews text list explicitly into the branch payload response
    customer_reviews = GymReviewDetailSerializer(source='reviews', many=True, read_only=True)
    ratings_data = serializers.SerializerMethodField()

    class Meta:
        model = GymBranch
        fields = [
            'id', 'name', 'description', 'phone_number', 'operating_hours',
            'city', 'address', 'location', 'branch_logo', 'gender',
            'max_capacity', 'estimated_stay_duration', 'is_active',
            'is_temporarily_closed', 'is_roaming_enabled', 'roaming_visit_price',
            'images', 'amenities', 'sports', 'schedules', 'available_plans', 
            'ratings_data', 'customer_reviews'
        ]

    def get_ratings_data(self, obj) -> dict:
        """
        Calculates mathematical averages and weighted analytics for the gym profile.
        Applies Min-Max Normalization so a score of 1 maps cleanly to 0%.
        Weights configuration constants: Cleanliness 35%, Equipment 35%, Vibe 30%.
        """
        WEIGHT_CLEANLINESS = 0.35
        WEIGHT_EQUIPMENT = 0.35
        WEIGHT_VIBE = 0.30
        
        reviews_queryset = obj.reviews.all()
        reviews_count = reviews_queryset.count()

        if reviews_count == 0:
            return {
                "overall_rating": 0.0,
                "reviews_count": 0,
                "vibe_score_pct": 0,
                "breakdown": {
                    "cleanliness_pct": 0,
                    "equipment_pct": 0,
                    "vibe_pct": 0
                }
            }

        averages = reviews_queryset.aggregate(
            avg_cleanliness=Avg('cleanliness_rating'),
            avg_equipment=Avg('equipment_rating'),
            avg_vibe=Avg('vibe_rating')
        )

        avg_clean = averages['avg_cleanliness'] or 1.0
        avg_equip = averages['avg_equipment'] or 1.0
        avg_vibe = averages['avg_vibe'] or 1.0

        overall_rating = round((avg_clean + avg_equip + avg_vibe) / 3.0, 1)

        cleanliness_pct = int(round(((avg_clean - 1.0) / 4.0) * 100))
        equipment_pct = int(round(((avg_equip - 1.0) / 4.0) * 100))
        vibe_pct = int(round(((avg_vibe - 1.0) / 4.0) * 100))

        vibe_score_pct = int(round(
            (cleanliness_pct * WEIGHT_CLEANLINESS) +
            (equipment_pct * WEIGHT_EQUIPMENT) +
            (vibe_pct * WEIGHT_VIBE)
        ))

        return {
            "overall_rating": overall_rating,
            "reviews_count": reviews_count,
            "vibe_score_pct": vibe_score_pct,
            "breakdown": {
                "cleanliness_pct": cleanliness_pct,
                "equipment_pct": equipment_pct,
                "vibe_pct": vibe_pct
            }
        }


# ==========================================
# UNIFIED GEOGRAPHICAL SEARCH SERIALIZER
# ==========================================

class GymBranchSearchSerializer(serializers.ModelSerializer):
    distance_km = serializers.FloatField(read_only=True, required=False)

    class Meta:
        model = GymBranch
        fields = ['id', 'name', 'city', 'address', 'gender', 'branch_logo', 'is_active', 'distance_km']


# ==========================================
# REPLICATED MASTER INLINE CORE SERIALIZERS
# ==========================================

class GymCheckoutSerializer(serializers.Serializer):
    plan_id = serializers.IntegerField()
    gateway = serializers.CharField()
    points_to_use = serializers.IntegerField(required=False, default=0)

class GymSubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = GymSubscription
        fields = '__all__'

class RoamingCheckoutSerializer(serializers.Serializer):
    branch_id = serializers.IntegerField()
    payment_method = serializers.CharField()
    gateway = serializers.CharField(required=False)

class RoamingPassSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoamingPass
        fields = '__all__'

class QRScanSerializer(serializers.Serializer):
    qr_code_id = serializers.UUIDField()
    branch_id = serializers.IntegerField()