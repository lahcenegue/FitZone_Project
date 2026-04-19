"""
Business logic for Gym operations.
Handles QR scanning, live occupancy, auto-checkout, and subscription validation.
"""

import logging
from datetime import timedelta
from decimal import Decimal
from django.utils import timezone
from django.db import transaction

from apps.gyms.models import GymVisit, GymBranch, SubscriptionPlan, GymSubscription, GymGlobalSetting
from apps.payments.services import PaymentService
from apps.payments.models import ProviderWallet, WalletTransaction, WalletTransactionType

logger = logging.getLogger(__name__)


class GymAccessService:
    """Service handling real-time gym access and occupancy tracking."""

    @staticmethod
    def auto_checkout_visitors(branch_id: int = None):
        """
        Automatically check out visitors who exceeded the allowed duration.
        Called before calculating live occupancy.
        """
        settings = GymGlobalSetting.load()
        expiry_time = timezone.now() - timedelta(hours=settings.auto_checkout_hours)

        query = GymVisit.objects.filter(is_active=True, check_in_time__lt=expiry_time)
        
        if branch_id:
            query = query.filter(branch_id=branch_id)

        checked_out_count = query.update(
            is_active=False, 
            check_out_time=timezone.now()
        )
        
        if checked_out_count > 0:
            logger.info("Auto-checked out %s visitors.", checked_out_count)

    @staticmethod
    def get_live_occupancy(branch_id: int) -> int:
        """
        Returns the current number of active visitors in a specific branch.
        """
        # 1. Clean up old visits first
        GymAccessService.auto_checkout_visitors(branch_id=branch_id)
        
        # 2. Return accurate count
        return GymVisit.objects.filter(branch_id=branch_id, is_active=True).count()

    @staticmethod
    @transaction.atomic
    def process_qr_scan(*, qr_code_id: str, branch_id: int) -> dict:
        """
        Validates QR code, checks subscription rules, and creates a check-in visit.
        Returns user details (including photo) for visual verification by receptionist.
        """
        try:
            subscription = GymSubscription.objects.select_related(
                'user', 'plan'
            ).get(qr_code_id=qr_code_id)
        except GymSubscription.DoesNotExist:
            raise ValueError("Invalid QR Code.")

        # 1. Check if subscription is active
        if subscription.status != "active":
            raise ValueError(f"Subscription is {subscription.status}.")

        # 2. Check date validity
        today = timezone.now().date()
        if today < subscription.start_date:
            raise ValueError("Subscription has not started yet.")
        if today > subscription.end_date:
            raise ValueError("Subscription has expired.")

        # 3. Check branch access privileges
        branch = GymBranch.objects.get(id=branch_id)
        if not subscription.plan.branches.filter(id=branch_id).exists():
            raise ValueError("This subscription does not grant access to this branch.")

        # 4. Prevent double check-in (auto-checkout previous active visit for this user)
        GymVisit.objects.filter(
            subscription__user=subscription.user, 
            is_active=True
        ).update(is_active=False, check_out_time=timezone.now())

        # 5. Create new visit (Check-in)
        visit = GymVisit.objects.create(
            subscription=subscription,
            branch=branch,
            is_active=True
        )

        # 6. Return data for visual verification in the frontend/app
        profile_pic_url = None
        if hasattr(subscription.user, 'profile_picture') and subscription.user.profile_picture:
            profile_pic_url = subscription.user.profile_picture.url

        return {
            "visit_id": visit.id,
            "user_name": subscription.user.full_name,
            "user_image": profile_pic_url,
            "plan_name": subscription.plan.name,
            "end_date": subscription.end_date.strftime("%Y-%m-%d"),
            "days_remaining": (subscription.end_date - today).days
        }


class GymSubscriptionService:
    """
    Business logic for purchasing and managing Gym Subscriptions.
    """

    @staticmethod
    @transaction.atomic
    def checkout(user, plan_id: int, gateway_name: str) -> GymSubscription:
        # 1. Validate User Identity Documents
        if not user.profile_complete:
            raise ValueError("Profile is incomplete. Identity documents (Face and ID) are required before purchasing a subscription.")

        # 2. Validate Plan
        try:
            plan = SubscriptionPlan.objects.get(id=plan_id, is_active=True)
        except SubscriptionPlan.DoesNotExist:
            raise ValueError("The selected subscription plan is invalid or currently inactive.")

        # 3. Process Financial Transaction (via Payments App)
        payment_txn = PaymentService.process_payment(
            user=user,
            amount=plan.price,
            currency="SAR",
            gateway_name=gateway_name
        )

        # 4. Calculate Subscription Dates (Handle overlapping/extensions)
        now = timezone.now().date()
        existing_sub = GymSubscription.objects.filter(
            user=user,
            plan=plan,
            status="active"
        ).order_by('-end_date').first()

        if existing_sub and existing_sub.end_date >= now:
            # Extension: Start exactly the day after the current one ends
            start_date = existing_sub.end_date + timedelta(days=1)
        else:
            # New Subscription: Start today
            start_date = now

        end_date = start_date + timedelta(days=plan.duration_days - 1)

        # 5. Create Subscription Record
        subscription = GymSubscription.objects.create(
            user=user,
            plan=plan,
            payment=payment_txn,
            start_date=start_date,
            end_date=end_date,
            status="active"
        )

        # 6. Allocate Net Revenue to Provider Wallet (Ledger Integration)
        provider = plan.provider
        gross_amount = plan.price
        
        commission_type = getattr(provider, 'commission_type', 'percentage')
        commission_value = getattr(provider, 'commission_value', Decimal('0.00'))

        if commission_type == 'percentage':
            commission = gross_amount * (commission_value / Decimal('100.00'))
        else:
            commission = commission_value

        net_revenue = max(Decimal('0.00'), gross_amount - commission)

        if net_revenue > 0:
            # select_for_update() locks the row to prevent race conditions during concurrent checkouts
            wallet, _ = ProviderWallet.objects.select_for_update().get_or_create(provider=provider)
            
            wallet.pending_balance += net_revenue
            wallet.save(update_fields=['pending_balance', 'updated_at'])

            WalletTransaction.objects.create(
                wallet=wallet,
                transaction_type=WalletTransactionType.EARNING_PENDING,
                amount=net_revenue,
                is_cleared=False,
                source_payment=payment_txn,
                description=f"Revenue from subscription: {plan.name}"
            )

        # 7. Calculate and Add Loyalty Points
        global_settings = GymGlobalSetting.load()
        points_rate = global_settings.points_conversion_rate
        
        if points_rate and points_rate > 0:
            points_earned = int(plan.price / points_rate)
            if points_earned > 0:
                user.add_points(amount=points_earned, reason=f"Purchased Gym Plan: {plan.name}")

        logger.info(f"Subscription {subscription.id} successfully created for user {user.email}.")
        return subscription