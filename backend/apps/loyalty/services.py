"""
Business logic for Loyalty and Progression systems.
Handles points purchasing, milestone unlocking, and balance operations.
"""

import logging
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from django.core.exceptions import ValidationError
from apps.loyalty.models import (
    CustomerWallet, WalletTransaction, TransactionType, 
    Milestone, UserMilestone, LoyaltyGlobalSetting, PointPackage,
    RewardActionType
)
from apps.payments.services import PaymentService

logger = logging.getLogger(__name__)

class LoyaltyService:
    """Core service for managing customer loyalty, points, and milestones."""

    @staticmethod
    @transaction.atomic
    def purchase_points(user, package_id: int, gateway_name: str):
        """
        Allows a user to buy a specific points package using the payment gateway.
        """
        try:
            package = PointPackage.objects.get(id=package_id, is_active=True)
        except PointPackage.DoesNotExist:
            raise ValueError("The selected points package is invalid or currently unavailable.")

        payment_txn = PaymentService.process_payment(
            user=user,
            amount=Decimal(str(package.price)),
            currency="SAR",
            gateway_name=gateway_name
        )

        wallet, _ = CustomerWallet.objects.get_or_create(user=user)
        
        ledger_entry = WalletTransaction.execute_transaction(
            wallet=wallet,
            t_type=TransactionType.BUY_POINTS,
            points=package.points,
            fiat=0.00,
            description=f"Purchased package: {package.name} via {gateway_name}"
        )

        LoyaltyService.check_and_unlock_milestones(user)

        logger.info(f"Points package purchase successful: {package.name} for user {user.email}")
        return ledger_entry

    @staticmethod
    def check_and_unlock_milestones(user):
        """
        Checks if user's lifetime_points have reached any new milestones.
        Automatically unlocks them if not already unlocked.
        """
        wallet, _ = CustomerWallet.objects.get_or_create(user=user)
        current_lifetime_pts = wallet.lifetime_points

        available_milestones = Milestone.objects.filter(
            is_active=True,
            required_lifetime_points__lte=current_lifetime_pts
        ).exclude(unlocked_by_users__user=user)

        for milestone in available_milestones:
            UserMilestone.objects.create(
                user=user,
                milestone=milestone,
                is_consumed=False
            )
            logger.info(f"Milestone Unlocked: {milestone.title} for user {user.email}")

    @staticmethod
    @transaction.atomic
    def use_milestone_reward(user, user_milestone_id: int):
        """
        Consumes a reward from an unlocked milestone safely.
        Executes System Logic if defined, otherwise marks as manually fulfilled.
        """
        try:
            user_milestone = UserMilestone.objects.select_related('milestone__reward').get(id=user_milestone_id, user=user)
        except UserMilestone.DoesNotExist:
            raise ValidationError("Reward not found or does not belong to user.")

        if user_milestone.is_consumed:
            raise ValidationError("This reward has already been used.")

        reward = user_milestone.milestone.reward
        
        if reward.action_type == RewardActionType.SYSTEM_ROAMING:
            # Future Engine Hook: Add Roaming Pass Logic here
            pass
        elif reward.action_type == RewardActionType.SYSTEM_EXTENSION:
            # Future Engine Hook: Extend Subscription Logic here
            pass

        user_milestone.consume_reward()
        return True

    @staticmethod
    def get_wallet_summary(user):
        """Returns simplified wallet and progress data for the mobile frontend."""
        wallet, _ = CustomerWallet.objects.get_or_create(user=user)
        
        next_milestone = Milestone.objects.filter(
            is_active=True,
            required_lifetime_points__gt=wallet.lifetime_points
        ).order_by('required_lifetime_points').first()

        unlocked_milestones = UserMilestone.objects.filter(user=user).select_related('milestone__reward')

        return {
            "spendable_points": wallet.points_balance,
            "lifetime_points": wallet.lifetime_points,
            "fiat_balance": wallet.fiat_balance,
            "unlocked_rewards_count": unlocked_milestones.filter(is_consumed=False).count(),
            "next_milestone": {
                "title": next_milestone.title if next_milestone else "MAX",
                "required": next_milestone.required_lifetime_points if next_milestone else 0,
                "progress_pct": int((wallet.lifetime_points / next_milestone.required_lifetime_points) * 100) if next_milestone else 100
            }
        }