"""
Serializers for the Gyms app API.
Includes logic for real-time crowd calculation, dynamic schedules, and reviews.
"""

from rest_framework import serializers
from django.utils import timezone
from django.db.models import Avg

from apps.gyms.models import (
    GymBranch, BranchImage, GymAmenity, GymSport, SubscriptionPlan, 
    PlanFeature, GymBranchSchedule, GymReview
)


class GymAmenitySerializer(serializers.ModelSerializer):
    icon_image = serializers.SerializerMethodField()
    class Meta:
        model = GymAmenity
        fields = ['id', 'name', 'icon_image']

    def get_icon_image(self, obj):
        request = self.context.get('request')
        if obj.icon_image and request:
            return request.build_absolute_uri(obj.icon_image.url)
        return None

class GymSportSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = GymSport
        fields = ['id', 'name', 'image']
    
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
        Conversion rate is set by the Admin in GymGlobalSetting.
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
    
    # Computed Dynamic Fields
    rating = serializers.SerializerMethodField()
    total_reviews = serializers.SerializerMethodField()
    is_open_now = serializers.SerializerMethodField()
    crowd_level = serializers.SerializerMethodField()
    weekly_hours = serializers.SerializerMethodField()
    reviews = serializers.SerializerMethodField()

    class Meta:
        model = GymBranch
        fields = [
            'id', 'provider_name', 'name', 'description', 'phone_number',
            'opening_time', 'closing_time', 'city', 'address', 'lat', 'lng',
            'branch_logo', 'images', 'amenities', 'sports',
            'is_temporarily_closed',
            'rating', 'total_reviews', 'is_open_now', 'crowd_level', 'weekly_hours', 'reviews',
            'plans'
        ]

    def get_images(self, obj):
        """Retrieve absolute URLs for all images related to this branch."""
        request = self.context.get('request')
        if not request:
            return []
        return [request.build_absolute_uri(img.image.url) for img in obj.images.all() if img.image]

    def get_plans(self, obj):
        """Retrieve all active subscription plans available at this specific branch."""
        active_plans = obj.available_plans.all() 
        return SubscriptionPlanSerializer(active_plans, many=True, context=self.context).data

    def get_rating(self, obj):
        """Calculate the average rating dynamically."""
        avg = obj.reviews.aggregate(Avg('rating'))['rating__avg']
        return round(avg, 1) if avg else 0.0

    def get_total_reviews(self, obj):
        """Count total reviews."""
        return obj.reviews.count()

    def get_is_open_now(self, obj):
        """
        Smart check if the gym is open right now.
        Prioritizes Emergency Close, then today's schedule, then general times.
        """
        # 1. التحقق من الإغلاق الطارئ أولاً
        if getattr(obj, 'is_temporarily_closed', False):
            return False

        from django.utils import timezone
        local_now = timezone.localtime()
        current_time = local_now.time()
        current_weekday = local_now.weekday()

        # 2. التحقق من جدول اليوم المخصص
        if hasattr(obj, 'schedules'):
            today_schedules = [s for s in obj.schedules.all() if s.day == current_weekday]
            if today_schedules:
                today_schedule = today_schedules[0]
                if today_schedule.is_closed:
                    return False
                if today_schedule.opening_time and today_schedule.closing_time:
                    open_t = today_schedule.opening_time
                    close_t = today_schedule.closing_time
                    if open_t <= close_t:
                        return open_t <= current_time <= close_t
                    else:
                        return current_time >= open_t or current_time <= close_t

        # 3. الاعتماد على الأوقات العامة
        if not obj.opening_time or not obj.closing_time:
            return True
            
        if obj.opening_time <= obj.closing_time:
            return obj.opening_time <= current_time <= obj.closing_time
        else:
            return current_time >= obj.opening_time or current_time <= obj.closing_time

    def get_crowd_level(self, obj):
        """
        Calculate live crowd level based on active visits and branch maximum capacity.
        Uses the dynamic thresholds defined by the gym provider for this specific branch.
        """
        capacity = obj.max_capacity if obj.max_capacity and obj.max_capacity > 0 else 100 
        
        # FIXED: Using the explicitly defined related_name 'visits' instead of 'gymvisit_set'
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
        """Format weekly schedule into a clean dictionary for the frontend."""
        days_map = {
            0: "Monday", 1: "Tuesday", 2: "Wednesday",
            3: "Thursday", 4: "Friday", 5: "Saturday", 6: "Sunday"
        }
        schedules = obj.schedules.all()
        
        if not schedules:
            open_str = obj.opening_time.strftime("%H:%M") if obj.opening_time else "00:00"
            close_str = obj.closing_time.strftime("%H:%M") if obj.closing_time else "23:59"
            return {day_name: f"{open_str} - {close_str}" for day_name in days_map.values()}

        weekly = {}
        for schedule in schedules:
            day_name = days_map[schedule.day]
            if schedule.is_closed:
                weekly[day_name] = "Closed"
            else:
                open_str = schedule.opening_time.strftime("%H:%M") if schedule.opening_time else "00:00"
                close_str = schedule.closing_time.strftime("%H:%M") if schedule.closing_time else "23:59"
                weekly[day_name] = f"{open_str} - {close_str}"
                
        return weekly

    def get_reviews(self, obj):
        """Fetch the top 5 most recent reviews for preview."""
        latest_reviews = obj.reviews.all()[:5]
        return GymReviewSerializer(latest_reviews, many=True).data