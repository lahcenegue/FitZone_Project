"""
Serializers for the Gyms app API.
Includes logic for real-time crowd calculation, dynamic schedules, and reviews.
"""

import json
import logging
from datetime import datetime
from django.utils import timezone
from rest_framework import serializers
from django.db.models import Avg

from apps.payments.models import PaymentGateway
from apps.gyms.models import (
    GymBranch, GymAmenity, GymSport, SubscriptionPlan, 
    PlanFeature, GymReview, GymSubscription
)

logger = logging.getLogger(__name__)


def get_localized_name(obj, request):
    """
    Helper function to extract the correctly translated name from a JSONField
    based on the Accept-Language HTTP header.
    """
    lang = request.META.get('HTTP_ACCEPT_LANGUAGE', 'en').lower() if request else 'en'
    primary_lang = 'ar' if 'ar' in lang else 'en'
    
    if obj.translations and isinstance(obj.translations, dict):
        return obj.translations.get(primary_lang, obj.name)
    return obj.name


class GymAmenitySerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()
    icon_image = serializers.SerializerMethodField()
    
    class Meta:
        model = GymAmenity
        fields = ['id', 'name', 'icon_image']

    def get_name(self, obj):
        return get_localized_name(obj, self.context.get('request'))

    def get_icon_image(self, obj):
        request = self.context.get('request')
        if obj.icon_image and request:
            return request.build_absolute_uri(obj.icon_image.url)
        return None


class GymSportSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()
    
    class Meta:
        model = GymSport
        fields = ['id', 'name', 'image']

    def get_name(self, obj):
        return get_localized_name(obj, self.context.get('request'))

    def get_image(self, obj):
        request = self.context.get('request')
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        return None


class PlanFeatureSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlanFeature
        fields = ['name']


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    features = PlanFeatureSerializer(many=True, read_only=True)
    reward_points = serializers.SerializerMethodField()
    
    class Meta:
        model = SubscriptionPlan
        fields = ['id', 'name', 'description', 'price', 'duration_days', 'reward_points', 'features']
    
    def get_reward_points(self, obj):
        """
        Dynamically calculate reward points: (Plan Price / Conversion Rate).
        """
        setting = self.context.get('gym_setting')
        if setting and setting.points_conversion_rate > 0:
            return int(obj.price / setting.points_conversion_rate)
        return 0


class GymReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    date = serializers.DateField(source='created_at__date', read_only=True)

    class Meta:
        model = GymReview
        fields = ['id', 'user_name', 'rating', 'comment', 'date']


class GymBranchDetailSerializer(serializers.ModelSerializer):
    provider_name = serializers.CharField(source='provider.business_name', read_only=True)
    amenities = GymAmenitySerializer(many=True, read_only=True)
    sports = GymSportSerializer(many=True, read_only=True)
    plans = serializers.SerializerMethodField()
    images = serializers.SerializerMethodField()
    lat = serializers.FloatField(source='location.y', read_only=True)
    lng = serializers.FloatField(source='location.x', read_only=True)
    branch_logo = serializers.SerializerMethodField()
    
    # Computed Dynamic Fields
    rating = serializers.SerializerMethodField()
    total_reviews = serializers.SerializerMethodField()
    is_open_now = serializers.SerializerMethodField()
    crowd_level = serializers.SerializerMethodField()
    weekly_hours = serializers.SerializerMethodField()
    reviews = serializers.SerializerMethodField()

    class Meta:
        model = GymBranch
        # Note: 'operating_hours' has been completely removed from the output
        fields = [
            'id', 'provider_name', 'name', 'description', 'phone_number', 'city', 'address', 
            'lat', 'lng', 'branch_logo', 'images', 'amenities', 'sports', 'gender',
            'is_temporarily_closed', 'rating', 'total_reviews', 'is_open_now', 
            'crowd_level', 'weekly_hours', 'reviews', 'plans'
        ]

    def get_branch_logo(self, obj):
        logo = obj.branch_logo
        if not logo and hasattr(obj, 'provider') and obj.provider.logo:
            logo = obj.provider.logo

        if not logo:
            return None
            
        try:
            if not logo.name:
                return None
                
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(logo.url)
            
            from django.conf import settings
            return f"{settings.SITE_URL}{logo.url}"
        except Exception as e:
            logger.error(f"Error resolving logo for GymBranch {obj.id}: {str(e)}")
            return None

    def get_images(self, obj):
        request = self.context.get('request')
        if not request:
            return []
        return [request.build_absolute_uri(img.image.url) for img in obj.images.all() if img.image]

    def get_plans(self, obj):
        active_plans = obj.available_plans.all() 
        return SubscriptionPlanSerializer(active_plans, many=True, context=self.context).data

    def get_rating(self, obj):
        avg = obj.reviews.aggregate(Avg('rating'))['rating__avg']
        return round(avg, 1) if avg else 0.0

    def get_total_reviews(self, obj):
        return obj.reviews.count()

    def get_is_open_now(self, obj):
        """
        Smart check using `days_values` to avoid language mismatch.
        0=Sunday, 1=Monday, ..., 6=Saturday.
        """
        if getattr(obj, 'is_temporarily_closed', False):
            return False

        schedule = obj.operating_hours
        if not schedule:
            return False

        if isinstance(schedule, str):
            try:
                schedule = json.loads(schedule)
            except json.JSONDecodeError:
                return False

        if not isinstance(schedule, list):
            return False

        now_dt = timezone.localtime()
        current_time = now_dt.time()
        current_day_val = now_dt.strftime('%w')

        for period in schedule:
            days_values = [str(val) for val in period.get('days_values', [])]
            
            if current_day_val in days_values:
                try:
                    start_str = period.get('start')
                    end_str = period.get('end')
                    
                    if start_str and end_str:
                        start_t = datetime.strptime(start_str, '%H:%M').time()
                        end_t = datetime.strptime(end_str, '%H:%M').time()
                        
                        if start_t <= end_t:
                            if start_t <= current_time <= end_t:
                                return True
                        else: # Overnight shift handling
                            if current_time >= start_t or current_time <= end_t:
                                return True
                except (ValueError, TypeError):
                    continue

        return False

    def get_crowd_level(self, obj):
        capacity = obj.max_capacity if obj.max_capacity and obj.max_capacity > 0 else 100 
        active_visits = obj.visits.filter(is_active=True).count() if hasattr(obj, 'visits') else 0
        occupancy_rate = (active_visits / capacity) * 100

        if occupancy_rate <= obj.crowd_level_low:
            return "low"
        elif occupancy_rate <= obj.crowd_level_medium:
            return "medium"
        elif occupancy_rate <= obj.crowd_level_high:
            return "high"
        else:
            return "full"

    def get_weekly_hours(self, obj):
        """
        Smart merging algorithm:
        1. Reads raw JSON schedule.
        2. Maps mixed shifts into both men and women schedules secretly.
        3. Returns a clean grouped response based on the branch's actual gender.
        """
        DAY_MAP = {
            '0': 'Sunday', '1': 'Monday', '2': 'Tuesday', '3': 'Wednesday', 
            '4': 'Thursday', '5': 'Friday', '6': 'Saturday'
        }
        
        men_sched = {day: "Closed" for day in DAY_MAP.values()}
        women_sched = {day: "Closed" for day in DAY_MAP.values()}
        mixed_sched = {day: "Closed" for day in DAY_MAP.values()}

        schedule = obj.operating_hours
        if not schedule:
            return {"men": men_sched, "women": women_sched} if obj.gender == 'mixed' else {obj.gender: men_sched}

        if isinstance(schedule, str):
            try:
                schedule = json.loads(schedule)
            except json.JSONDecodeError:
                return {"men": men_sched, "women": women_sched} if obj.gender == 'mixed' else {obj.gender: men_sched}

        if isinstance(schedule, list):
            for period in schedule:
                gender_shift = period.get('gender', 'mixed').lower()
                start_str = period.get('start', '00:00')
                end_str = period.get('end', '23:59')
                days_vals = period.get('days_values', [])
                
                for val in days_vals:
                    day_name = DAY_MAP.get(str(val))
                    if day_name:
                        time_str = f"{start_str} - {end_str}"
                        
                        if gender_shift == 'men':
                            if men_sched[day_name] == "Closed":
                                men_sched[day_name] = time_str
                            else:
                                men_sched[day_name] += f" & {time_str}"
                        elif gender_shift == 'women':
                            if women_sched[day_name] == "Closed":
                                women_sched[day_name] = time_str
                            else:
                                women_sched[day_name] += f" & {time_str}"
                        else:
                            if mixed_sched[day_name] == "Closed":
                                mixed_sched[day_name] = time_str
                            else:
                                mixed_sched[day_name] += f" & {time_str}"
                                
        # MERGE LOGIC: Inject 'mixed' shifts into 'men' and 'women'
        for day in DAY_MAP.values():
            if mixed_sched[day] != "Closed":
                if men_sched[day] == "Closed":
                    men_sched[day] = mixed_sched[day]
                else:
                    men_sched[day] += f" & {mixed_sched[day]}"
                    
                if women_sched[day] == "Closed":
                    women_sched[day] = mixed_sched[day]
                else:
                    women_sched[day] += f" & {mixed_sched[day]}"

        # Format output based on the Branch's main gender flag
        if obj.gender == 'men':
            return {"men": men_sched}
        elif obj.gender == 'women':
            return {"women": women_sched}
        else: # mixed
            return {
                "men": men_sched,
                "women": women_sched
            }

    def get_reviews(self, obj):
        latest_reviews = obj.reviews.all()[:5]
        return GymReviewSerializer(latest_reviews, many=True).data
    

class GymBranchSearchSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer specifically optimized for search and discovery lists.
    """
    provider_id = serializers.IntegerField(source='provider.id', read_only=True)
    provider_name = serializers.CharField(source='provider.business_name', read_only=True)
    branch_logo = serializers.SerializerMethodField()
    distance_km = serializers.SerializerMethodField()
    min_price = serializers.FloatField(source='min_plan_price', read_only=True, default=None)
    sports = serializers.SerializerMethodField()
    amenities = serializers.SerializerMethodField()
    lat = serializers.SerializerMethodField()
    lng = serializers.SerializerMethodField()
    
    type = serializers.SerializerMethodField()
    rating = serializers.SerializerMethodField()
    is_open_now = serializers.SerializerMethodField()
    crowd_level = serializers.SerializerMethodField()

    class Meta:
        model = GymBranch
        fields = [
            'id', 'provider_id', 'provider_name', 'name', 'city', 'address', 'gender',
            'lat', 'lng', 'branch_logo', 'is_active', 'is_temporarily_closed',
            'distance_km', 'min_price', 'sports', 'amenities',
            'type', 'rating', 'is_open_now', 'crowd_level'
        ]

    def get_branch_logo(self, obj):
        logo = obj.branch_logo
        if not logo and hasattr(obj, 'provider') and obj.provider.logo:
            logo = obj.provider.logo

        if not logo:
            return None
            
        try:
            if not logo.name:
                return None
                
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(logo.url)
            
            from django.conf import settings
            return f"{settings.SITE_URL}{logo.url}"
        except Exception as e:
            logger.error(f"Error resolving logo for GymBranch {obj.id}: {str(e)}")
            return None

    def get_type(self, obj):
        return "gym"

    def get_rating(self, obj):
        return 4.5

    def get_crowd_level(self, obj):
        return "low"

    def get_is_open_now(self, obj):
        if getattr(obj, 'is_temporarily_closed', False):
            return False

        schedule = obj.operating_hours
        if not schedule:
            return False

        if isinstance(schedule, str):
            try:
                schedule = json.loads(schedule)
            except json.JSONDecodeError:
                return False

        if not isinstance(schedule, list):
            return False

        now_dt = timezone.localtime()
        current_time = now_dt.time()
        current_day_val = now_dt.strftime('%w')

        for period in schedule:
            days_values = [str(val) for val in period.get('days_values', [])]
            if current_day_val in days_values:
                try:
                    start_str = period.get('start')
                    end_str = period.get('end')
                    
                    if start_str and end_str:
                        start_t = datetime.strptime(start_str, '%H:%M').time()
                        end_t = datetime.strptime(end_str, '%H:%M').time()
                        
                        if start_t <= end_t:
                            if start_t <= current_time <= end_t:
                                return True
                        else:
                            if current_time >= start_t or current_time <= end_t:
                                return True
                except (ValueError, TypeError):
                    continue

        return False

    def get_distance_km(self, obj):
        if hasattr(obj, 'distance') and obj.distance is not None:
            return round(obj.distance.km, 2)
        return None

    def get_sports(self, obj):
        return [sport.name for sport in obj.sports.all()]

    def get_amenities(self, obj):
        return [amenity.name for amenity in obj.amenities.all()]

    def get_lat(self, obj):
        if obj.location:
            return obj.location.y
        return None

    def get_lng(self, obj):
        if obj.location:
            return obj.location.x
        return None


class GymCheckoutSerializer(serializers.Serializer):
    """Payload for initiating a subscription checkout."""
    plan_id = serializers.IntegerField(required=True)
    gateway = serializers.ChoiceField(
        choices=PaymentGateway.choices, 
        default=PaymentGateway.MOCK
    )

class GymSubscriptionSerializer(serializers.ModelSerializer):
    """Returns the subscription details including the cryptographic QR signature."""
    plan_name = serializers.CharField(source='plan.name', read_only=True)
    provider_name = serializers.CharField(source='plan.provider.business_name', read_only=True)
    qr_code_signature = serializers.SerializerMethodField()
    price = serializers.DecimalField(source='plan.price', max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = GymSubscription
        fields = [
            'id', 'plan_name', 'provider_name', 'price', 'start_date', 'end_date', 
            'status', 'purchased_at', 'is_resold', 'qr_code_signature'
        ]

    def get_qr_code_signature(self, obj):
        return obj.get_signed_qr_code()