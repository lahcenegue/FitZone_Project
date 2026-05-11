from decimal import Decimal
from rest_framework import serializers
from django.utils.translation import gettext as _
from apps.payments.models import PaymentGateway
from apps.loyalty.models import PointPackage, MilestoneReward, Milestone, UserMilestone, WalletTransaction
from apps.users.models import UserBankAccount

class PointPackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PointPackage
        fields = ['id', 'name', 'points', 'price']

class MilestoneRewardSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()
    coupon_type = serializers.SerializerMethodField()
    discount_value = serializers.SerializerMethodField()
    
    class Meta:
        model = MilestoneReward
        fields = ['id', 'name', 'action_type', 'action_value', 'fulfillment_type', 'coupon_type', 'discount_value']

    def get_name(self, obj):
        return str(_(obj.name))

    def get_coupon_type(self, obj):
        if obj.action_type == 'gen_coupon' and hasattr(obj, 'coupon_definition') and obj.coupon_definition:
            return obj.coupon_definition.coupon_type
        return None

    def get_discount_value(self, obj):
        if obj.action_type == 'gen_coupon' and hasattr(obj, 'coupon_definition') and obj.coupon_definition:
            return float(obj.coupon_definition.discount_value)
        return None

class MilestoneSerializer(serializers.ModelSerializer):
    reward = MilestoneRewardSerializer(read_only=True)
    title = serializers.SerializerMethodField()
    description = serializers.SerializerMethodField()
    user_milestone_data = serializers.SerializerMethodField()
    
    class Meta:
        model = Milestone
        fields = ['id', 'title', 'required_lifetime_points', 'reward', 'description', 'user_milestone_data']

    def get_title(self, obj):
        return str(_(obj.title))

    def get_description(self, obj):
        return str(_(obj.description))
        
    def get_user_milestone_data(self, obj):
        request = self.context.get('request')
        
        if not request or not request.user.is_authenticated:
            return None
        
        user_milestone = UserMilestone.objects.filter(user=request.user, milestone=obj).first()
        
        if not user_milestone:
            return {
                "status": "locked",
                "user_milestone_id": None
            }
            
        if user_milestone.is_consumed:
            status_value = "consumed"
        elif user_milestone.is_claimed:
            status_value = "claimed"
        else:
            status_value = "unlocked"
            
        return {
            "status": status_value,
            "user_milestone_id": user_milestone.id
        }

class UserMilestoneSerializer(serializers.ModelSerializer):
    milestone = MilestoneSerializer(read_only=True)
    reward_payload = serializers.SerializerMethodField()
    
    class Meta:
        model = UserMilestone
        fields = ['id', 'milestone', 'is_claimed', 'claimed_at', 'is_consumed', 'unlocked_at', 'consumed_at', 'reward_payload']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if not instance.is_claimed:
            data['claimed_at'] = None
            data['reward_payload'] = None
        if not instance.is_consumed:
            data['consumed_at'] = None
        return data

    def get_reward_payload(self, obj):
        if not obj.is_claimed or not obj.reward_payload:
            return None
        return obj.reward_payload

class PurchasePointsSerializer(serializers.Serializer):
    package_id = serializers.IntegerField(required=True)
    gateway = serializers.ChoiceField(choices=PaymentGateway.choices, default=PaymentGateway.MOCK)

class MilestoneClaimSerializer(serializers.Serializer):
    user_milestone_id = serializers.IntegerField()

class MilestoneUsageSerializer(serializers.Serializer):
    user_milestone_id = serializers.IntegerField()
    consumed_details = serializers.JSONField(required=False, allow_null=True)

# UPDATED: Enriched Serializer for the merged UI requirements
class AggregatedFiatTransactionSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField()
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    type = serializers.CharField()
    status = serializers.CharField()
    status_label = serializers.CharField()
    created_at = serializers.DateTimeField()
    expected_release_date = serializers.DateTimeField(required=False, allow_null=True)
    impact = serializers.CharField()

class WalletTransactionSerializer(serializers.ModelSerializer):
    title = serializers.SerializerMethodField()
    amount = serializers.DecimalField(source='fiat_amount', max_digits=10, decimal_places=2)
    type = serializers.SerializerMethodField()

    class Meta:
        model = WalletTransaction
        fields = ['id', 'title', 'amount', 'type', 'status', 'created_at']

    def get_title(self, obj):
        t_type = obj.transaction_type
        if t_type == 'withdraw_fiat':
            return str(_("Bank Withdrawal Request"))
        elif t_type == 'sell_sub':
            return str(_("Subscription Resale Revenue"))
        elif t_type == 'refund':
            return str(_("Refund Issued"))
        return str(_(obj.get_transaction_type_display()))

    def get_type(self, obj):
        if obj.transaction_type in ['sell_sub', 'refund']:
            return "deposit"
        elif obj.transaction_type == 'withdraw_fiat':
            return "withdrawal"
        return "deposit"

class PointsHistorySerializer(serializers.ModelSerializer):
    title = serializers.SerializerMethodField()
    amount = serializers.IntegerField(source='points_amount')
    type = serializers.SerializerMethodField()

    class Meta:
        model = WalletTransaction
        fields = ['id', 'title', 'amount', 'type', 'created_at']

    def get_title(self, obj):
        t_type = obj.transaction_type
        if t_type == 'buy_points':
            return str(_("Points Package Purchase"))
        elif t_type == 'earn_purchase':
            return str(_("Earned from Purchase"))
        elif t_type == 'spend_roaming':
            return str(_("Roaming Visit Applied"))
        elif t_type == 'spend_discount':
            return str(_("Discount Coupon Applied"))
        return str(_(obj.get_transaction_type_display()))

    def get_type(self, obj):
        return "earn" if obj.points_amount > 0 else "redeem"

class UserBankAccountSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserBankAccount
        fields = ['bank_name', 'account_number', 'iban', 'beneficiary_name']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        acc_num = data.get('account_number', '')
        if len(acc_num) > 4:
            data['account_number'] = f"****{acc_num[-4:]}"
        else:
            data['account_number'] = "****"
        return data

class WithdrawalRequestSerializer(serializers.Serializer):
    amount = serializers.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        min_value=Decimal('1.00'),
        error_messages={"min_value": "Withdrawal amount must be at least 1.00"}
    )