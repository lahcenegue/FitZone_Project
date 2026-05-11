from rest_framework import serializers
from django.utils import timezone
from decimal import Decimal
from apps.resale.models import SubscriptionResaleListing, ResaleGlobalSetting
from apps.gyms.models import GymSubscription
from apps.payments.models import PaymentGateway

class ResaleListingSerializer(serializers.ModelSerializer):
    """
    Serializer for displaying active listings in the marketplace.
    Strictly hides seller identity and displays relevant subscription/branch info.
    """
    branch_name = serializers.CharField(source='subscription.plan.branches.first.name', read_only=True)
    branch_logo = serializers.SerializerMethodField()
    plan_name = serializers.CharField(source='subscription.plan.name', read_only=True)
    days_left = serializers.SerializerMethodField()
    fair_value = serializers.DecimalField(source='fair_value_at_listing', max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = SubscriptionResaleListing
        fields = [
            'id', 'branch_name', 'branch_logo', 'plan_name', 
            'asking_price', 'fair_value', 'days_left', 'created_at'
        ]

    def get_branch_logo(self, obj):
        branch = obj.subscription.plan.branches.first()
        request = self.context.get('request')
        if branch and branch.branch_logo and request:
            return request.build_absolute_uri(branch.branch_logo.url)
        return None

    def get_days_left(self, obj):
        today = timezone.now().date()
        # BUG FIX: Display the correct days left even if it hasn't started yet
        if obj.subscription.start_date > today:
            delta = obj.subscription.end_date - obj.subscription.start_date
            return max(0, delta.days + 1)
        else:
            delta = obj.subscription.end_date - today
            return max(0, delta.days)


class CreateResaleListingSerializer(serializers.Serializer):
    """
    Serializer for sellers to list their subscription.
    """
    subscription_id = serializers.IntegerField(required=True)
    asking_price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('1.00'))


class PurchaseResaleSerializer(serializers.Serializer):
    """
    Serializer for buyers to purchase a listing.
    """
    listing_id = serializers.IntegerField(required=True)
    gateway = serializers.ChoiceField(choices=PaymentGateway.choices, default=PaymentGateway.MOCK)