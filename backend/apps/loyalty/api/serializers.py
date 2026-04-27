from rest_framework import serializers
from apps.payments.models import PaymentGateway
from apps.loyalty.models import PointPackage, MilestoneReward, Milestone, UserMilestone

class PointPackageSerializer(serializers.ModelSerializer):
    """Serializer for displaying available point packages."""
    class Meta:
        model = PointPackage
        fields = ['id', 'name', 'points', 'price']

class MilestoneRewardSerializer(serializers.ModelSerializer):
    """Details of the reward."""
    class Meta:
        model = MilestoneReward
        fields = ['id', 'name', 'action_type', 'action_value']

class MilestoneSerializer(serializers.ModelSerializer):
    """Serializer for displaying the milestone roadmap."""
    reward = MilestoneRewardSerializer(read_only=True)
    
    class Meta:
        model = Milestone
        fields = ['id', 'title', 'required_lifetime_points', 'reward', 'description']

class UserMilestoneSerializer(serializers.ModelSerializer):
    """Serializer for displaying a user's progress and unlocked rewards."""
    milestone = MilestoneSerializer(read_only=True)
    
    class Meta:
        model = UserMilestone
        fields = ['id', 'milestone', 'is_consumed', 'unlocked_at', 'consumed_at']

class PurchasePointsSerializer(serializers.Serializer):
    """Payload for purchasing points via payment gateway."""
    package_id = serializers.IntegerField(required=True, help_text="ID of the PointPackage being purchased.")
    gateway = serializers.ChoiceField(
        choices=PaymentGateway.choices, 
        default=PaymentGateway.MOCK
    )

class MilestoneUsageSerializer(serializers.Serializer):
    """Payload to consume a rewarded milestone."""
    user_milestone_id = serializers.IntegerField()