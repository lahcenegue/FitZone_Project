from decimal import Decimal
from rest_framework import serializers
from django.utils import timezone
from apps.resale.models import SubscriptionResaleListing, ResaleGlobalSetting
from apps.gyms.models import GymSubscription
from apps.payments.models import PaymentGateway

class ResaleListingSerializer(serializers.ModelSerializer):
    """
    Serializer for displaying active listings in the marketplace.
    Provides a nested, structured JSON including geospatial data, 
    financial transparency, and trust indicators.
    """
    seller = serializers.SerializerMethodField()
    gym = serializers.SerializerMethodField()
    plan = serializers.SerializerMethodField()
    pricing = serializers.SerializerMethodField()

    class Meta:
        model = SubscriptionResaleListing
        fields = ['id', 'seller', 'gym', 'plan', 'pricing', 'created_at']

    def get_seller(self, obj):
        user = obj.seller
        request = self.context.get('request')
        avatar_url = request.build_absolute_uri(user.avatar.url) if getattr(user, 'avatar', None) and request else None
        
        # Note: Seller rating can be implemented here in the future if a seller rating system is added.
        return {
            "name": getattr(user, 'full_name', user.email),
            "avatar": avatar_url
        }

    def get_gym(self, obj):
        branch = obj.subscription.plan.branches.first()
        if not branch:
            return None
            
        request = self.context.get('request')
        logo_url = request.build_absolute_uri(branch.branch_logo.url) if getattr(branch, 'branch_logo', None) and request else None

        # Fetch annotated distance and rating from queryset
        distance_km = getattr(obj, 'distance_km', None)
        branch_rating = getattr(obj, 'branch_rating', 0.0)

        return {
            "brand_name": branch.provider.business_name,
            "branch_name": branch.name,
            "logo": logo_url,
            "gender_allowed": branch.gender,
            "latitude": branch.location.y if branch.location else None,
            "longitude": branch.location.x if branch.location else None,
            "distance_km": round(distance_km, 2) if distance_km is not None else None,
            "rating": round(branch_rating, 1) if branch_rating else 0.0
        }

    def get_plan(self, obj):
        today = timezone.now().date()
        sub = obj.subscription
        
        if sub.start_date > today:
            days_left = (sub.end_date - sub.start_date).days + 1
        else:
            days_left = (sub.end_date - today).days

        return {
            "name": sub.plan.name,
            "days_left": max(0, days_left)
        }

    def get_pricing(self, obj):
        asking = obj.asking_price
        fair = obj.fair_value_at_listing
        
        discount = Decimal('0.00')
        if fair > 0:
            discount = ((fair - asking) / fair) * Decimal('100.0')

        return {
            "asking_price": float(asking),
            "fair_value": float(fair),
            "discount_percentage": int(discount)
        }


class CreateResaleListingSerializer(serializers.Serializer):
    subscription_id = serializers.IntegerField(required=True)
    asking_price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('1.00'))


class PurchaseResaleSerializer(serializers.Serializer):
    listing_id = serializers.IntegerField(required=True)
    gateway = serializers.ChoiceField(choices=PaymentGateway.choices, default=PaymentGateway.MOCK)