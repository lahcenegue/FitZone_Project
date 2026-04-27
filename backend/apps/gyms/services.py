"""
Business logic for Gym operations.
Handles QR scanning, live occupancy, auto-checkout, subscription validation, and Roaming.
"""

import logging
from datetime import timedelta
from decimal import Decimal
from django.utils import timezone
from django.db import transaction
from django.db.models import Max, Sum

from apps.gyms.models import (
    GymVisit, GymBranch, SubscriptionPlan, GymSubscription, 
    GymGlobalSetting, ProviderRoamingPool, RoamingPass
)
from apps.payments.services import PaymentService
from apps.payments.models import (
    ProviderWallet, WalletTransaction as ProviderWalletTxn, 
    PaymentTransaction
)
from apps.loyalty.models import (
    CustomerWallet, WalletTransaction as CustomerWalletTxn, 
    TransactionType as CustomerTxnType, LoyaltyGlobalSetting
)

logger = logging.getLogger(__name__)


class GymAccessService:
    """Service handling real-time gym access, occupancy, and roaming entries."""

    @staticmethod
    def auto_checkout_visitors(branch_id: int = None):
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
        GymAccessService.auto_checkout_visitors(branch_id=branch_id)
        return GymVisit.objects.filter(branch_id=branch_id, is_active=True).count()

    @staticmethod
    def _get_user_current_tier_level(user) -> int:
        active_subs = GymSubscription.objects.filter(
            user=user, status="active", end_date__gte=timezone.now().date()
        ).select_related('plan')
        
        if not active_subs.exists():
            return 0
            
        max_level = active_subs.aggregate(
            max_lvl=Max('plan__branches__tier__level')
        )['max_lvl']
        
        return max_level or 0

    @staticmethod
    def _check_provider_suspension(user, provider):
        """
        Checks if the user has any suspended subscriptions with the given provider.
        If yes, blocks access to all branches of this provider.
        """
        has_suspended = GymSubscription.objects.filter(
            user=user, 
            plan__provider=provider, 
            status="suspended"
        ).exists()
        
        if has_suspended:
            raise ValueError("Access Denied. Your account is suspended by this provider for all branches.")

    @staticmethod
    @transaction.atomic
    def process_qr_scan(*, qr_code_id: str, branch_id: int) -> dict:
        """
        Validates QR code. Checks if it's a Subscription QR or a Roaming Pass QR.
        Burns the roaming pass immediately upon successful entry.
        """
        branch = GymBranch.objects.get(id=branch_id)

        try:
            subscription = GymSubscription.objects.select_related('user', 'plan').get(qr_code_id=qr_code_id)
            return GymAccessService._process_subscription_scan(subscription, branch)
        except GymSubscription.DoesNotExist:
            pass

        try:
            roaming_pass = RoamingPass.objects.select_related('user', 'branch').get(qr_code_id=qr_code_id)
            return GymAccessService._process_roaming_scan(roaming_pass, branch)
        except RoamingPass.DoesNotExist:
            raise ValueError("Invalid or unknown QR Code.")

    @staticmethod
    def _process_subscription_scan(subscription: GymSubscription, branch: GymBranch) -> dict:
        GymAccessService._check_provider_suspension(subscription.user, branch.provider)

        today = timezone.now().date()
        target_sub = subscription

        if subscription.status != "active" or today < subscription.start_date or today > subscription.end_date:
            active_fallback = GymSubscription.objects.filter(
                user=subscription.user,
                plan__branches=branch,
                status="active",
                start_date__lte=today,
                end_date__gte=today
            ).first()
            
            if active_fallback:
                target_sub = active_fallback
            else:
                if subscription.status != "active":
                    raise ValueError(f"Subscription is {subscription.status}.")
                if today < subscription.start_date:
                    raise ValueError("Subscription has not started yet.")
                if today > subscription.end_date:
                    raise ValueError("Subscription has expired.")

        has_access = target_sub.plan.branches.filter(id=branch.id).exists()
        if not has_access:
            raise ValueError("Access Denied. Your subscription does not cover this branch. Please purchase a Roaming Pass.")

        return GymAccessService._finalize_checkin(
            user=target_sub.user, branch=branch, subscription=target_sub
        )

    @staticmethod
    def _process_roaming_scan(roaming_pass: RoamingPass, branch: GymBranch) -> dict:
        GymAccessService._check_provider_suspension(roaming_pass.user, branch.provider)

        if roaming_pass.branch_id != branch.id:
            raise ValueError("This roaming pass is not valid for this branch.")
        
        if roaming_pass.is_used:
            raise ValueError("This roaming pass has already been used.")

        roaming_pass.is_used = True
        roaming_pass.used_at = timezone.now()
        roaming_pass.save(update_fields=['is_used', 'used_at'])

        return GymAccessService._finalize_checkin(
            user=roaming_pass.user, branch=branch, roaming_pass=roaming_pass
        )

    @staticmethod
    def _finalize_checkin(user, branch, subscription=None, roaming_pass=None):
        GymVisit.objects.filter(
            subscription__user=user, 
            is_active=True
        ).update(is_active=False, check_out_time=timezone.now())
        
        GymVisit.objects.filter(
            roaming_pass__user=user, 
            is_active=True
        ).update(is_active=False, check_out_time=timezone.now())

        visit = GymVisit.objects.create(
            subscription=subscription,
            roaming_pass=roaming_pass,
            branch=branch,
            is_active=True
        )

        profile_pic_url = getattr(user.avatar, 'url', None) if getattr(user, 'avatar', None) else None
        user_name = getattr(user, 'full_name', getattr(user, 'email', 'Unknown'))
        
        visit_type = "Roaming" if roaming_pass else "Regular"
        plan_name = "One-Time Roaming Pass"
        days_remaining = 0
        total_days = 1
        plan_price = roaming_pass.fiat_paid if roaming_pass else Decimal('0.00')

        if subscription:
            agg = GymSubscription.objects.filter(
                user=user,
                plan__provider=subscription.plan.provider,
                status="active"
            ).aggregate(
                latest_end=Max('end_date'),
                total_duration=Sum('plan__duration_days')
            )
            
            latest_end_date = agg['latest_end']
            total_duration = agg['total_duration']

            if latest_end_date:
                days_remaining = max(0, (latest_end_date - timezone.now().date()).days)
            else:
                days_remaining = max(0, (subscription.end_date - timezone.now().date()).days)
                
            plan_name = subscription.plan.name
            total_days = total_duration or subscription.plan.duration_days
            plan_price = subscription.plan.price

        return {
            "visit_id": visit.id,
            "user_name": user_name,
            "user_image": profile_pic_url,
            "visit_type": visit_type,
            "plan_name": plan_name,
            "days_remaining": days_remaining,
            "total_days": total_days,
            "plan_price": str(plan_price),
            "is_roaming": roaming_pass is not None,
            "subscription_id": subscription.id if subscription else None
        }


class GymSubscriptionService:
    """
    Business logic for purchasing Gym Subscriptions and Roaming Passes.
    """

    @staticmethod
    @transaction.atomic
    def checkout_subscription(user, plan_id: int, gateway_name: str, points_to_use: int = 0) -> GymSubscription:
        phone = getattr(user, 'phone_number', None)
        face = getattr(user, 'real_face_image', None)
        id_card = getattr(user, 'id_card_image', None)
        
        if not (phone and face and id_card):
            raise ValueError("Profile is incomplete. Identity documents are required.")

        try:
            plan = SubscriptionPlan.objects.get(id=plan_id, is_active=True, is_archived=False)
        except SubscriptionPlan.DoesNotExist:
            raise ValueError("The selected subscription plan is invalid or inactive.")

        wallet, _ = CustomerWallet.objects.select_for_update().get_or_create(user=user)
        loyalty_settings = LoyaltyGlobalSetting.load()
        
        gross_amount = Decimal(str(plan.price))
        discount_fiat = Decimal('0.00')
        
        if points_to_use > 0:
            rate = Decimal(str(loyalty_settings.point_to_fiat_rate))
            if rate <= Decimal('0.00'):
                raise ValueError("System error: Conversion rate is invalid.")
            if points_to_use > wallet.points_balance:
                raise ValueError("Insufficient points balance for this discount.")
            
            calculated_discount_fiat = Decimal(str(points_to_use)) / rate
            max_percent = Decimal(str(loyalty_settings.max_points_discount_percent))
            max_allowed_discount_fiat = gross_amount * (max_percent / Decimal('100.0'))
            
            if calculated_discount_fiat > max_allowed_discount_fiat:
                raise ValueError(f"Discount exceeds the maximum allowed limit of {max_percent}%.")
                
            discount_fiat = calculated_discount_fiat

        amount_to_pay = max(Decimal('0.00'), gross_amount - discount_fiat)

        if amount_to_pay > 0:
            payment_txn = PaymentService.process_payment(
                user=user, amount=amount_to_pay, currency="SAR", gateway_name=gateway_name
            )
        else:
            payment_txn = PaymentTransaction.objects.create(
                user=user, amount=Decimal('0.00'), currency="SAR", 
                gateway="mock", status="success"
            )

        if points_to_use > 0:
            CustomerWalletTxn.execute_transaction(
                wallet=wallet, t_type=CustomerTxnType.SPEND_DISCOUNT, points=-points_to_use,
                description=f"Discount on plan: {plan.name}"
            )

        now = timezone.now().date()
        existing_sub = GymSubscription.objects.filter(
            user=user, plan=plan, status="active"
        ).order_by('-end_date').first()

        if existing_sub and existing_sub.end_date >= now:
            start_date = existing_sub.end_date + timedelta(days=1)
        else:
            start_date = now

        end_date = start_date + timedelta(days=plan.duration_days - 1)

        subscription = GymSubscription.objects.create(
            user=user, plan=plan, payment=payment_txn,
            start_date=start_date, end_date=end_date, status="active"
        )

        provider = plan.provider
        is_roaming_provider = plan.branches.filter(is_roaming_enabled=True).exists()
        base_comm_rate = Decimal(str(getattr(provider, 'commission_value', '10.0')))
        
        actual_comm_rate = base_comm_rate * Decimal('0.8') if is_roaming_provider else base_comm_rate
        commission = gross_amount * (actual_comm_rate / Decimal('100.0'))
        net_revenue = max(Decimal('0.00'), gross_amount - commission)

        user_name = getattr(user, 'full_name', getattr(user, 'email', 'Unknown User'))

        if net_revenue > 0:
            p_wallet, _ = ProviderWallet.objects.select_for_update().get_or_create(provider=provider)
            p_wallet.pending_balance += net_revenue
            p_wallet.save(update_fields=['pending_balance', 'updated_at'])

            ProviderWalletTxn.objects.create(
                wallet=p_wallet, transaction_type="earning_pending",
                amount=net_revenue, is_cleared=False,
                description=f"Revenue from subscription: {plan.name}"
            )

        pool, _ = ProviderRoamingPool.objects.select_for_update().get_or_create(provider=provider)
        free_visits_earned = max(1, plan.duration_days // 30)
        pool.free_visits_balance += free_visits_earned
        pool.total_earned_visits += free_visits_earned
        pool.save(update_fields=['free_visits_balance', 'total_earned_visits', 'updated_at'])

        earn_rate = Decimal(str(loyalty_settings.gym_earn_rate))
        if amount_to_pay > 0 and earn_rate > Decimal('0.00'):
            points_earned = int(amount_to_pay / earn_rate)
            if points_earned > 0:
                CustomerWalletTxn.execute_transaction(
                    wallet=wallet, t_type=CustomerTxnType.EARN_PURCHASE, points=points_earned,
                    description=f"Earned from purchasing: {plan.name}"
                )
                from apps.loyalty.services import LoyaltyService
                LoyaltyService.check_and_unlock_milestones(user)

        logger.info(f"Subscription {subscription.id} successfully created for user {getattr(user, 'email', '')}.")
        return subscription

    @staticmethod
    @transaction.atomic
    def checkout_roaming_pass(user, branch_id: int, payment_method: str, gateway_name: str = None) -> RoamingPass:
        branch = GymBranch.objects.select_related('provider', 'tier').get(id=branch_id)
        
        if not branch.is_roaming_enabled:
            raise ValueError("This branch does not participate in the roaming system.")

        branch_tier_level = branch.tier.level if branch.tier else 1
        user_tier_level = GymAccessService._get_user_current_tier_level(user)

        if user_tier_level < branch_tier_level:
            tier_name = branch.tier.name if branch.tier else "Basic"
            raise ValueError(f"Access Denied. Your subscription tier is too low for this {tier_name} branch.")

        loyalty_settings = LoyaltyGlobalSetting.load()
        wallet, _ = CustomerWallet.objects.select_for_update().get_or_create(user=user)

        gross_amount = Decimal(str(branch.roaming_visit_price))
        points_used = 0
        fiat_paid = Decimal('0.00')

        if payment_method == "points":
            rate = Decimal(str(loyalty_settings.point_to_fiat_rate))
            if rate <= Decimal('0.00'):
                raise ValueError("System error: Point to fiat conversion rate is invalid.")
                
            required_points = int(gross_amount * rate)
            if wallet.points_balance < required_points:
                raise ValueError(f"Insufficient points balance. You need {required_points} points.")
            
            CustomerWalletTxn.execute_transaction(
                wallet=wallet, t_type=CustomerTxnType.SPEND_ROAMING, points=-required_points,
                description=f"Roaming pass at {branch.name} (Points)"
            )
            points_used = required_points
            
            payment_txn = PaymentTransaction.objects.create(
                user=user, amount=Decimal('0.00'), currency="SAR", 
                gateway="mock", status="success"
            )
            
        elif payment_method == "fiat":
            if not gateway_name:
                raise ValueError("Gateway name is required for fiat payment.")
            
            fiat_paid = gross_amount
            payment_txn = PaymentService.process_payment(
                user=user, amount=fiat_paid, currency="SAR", gateway_name=gateway_name
            )
        else:
            raise ValueError("Invalid payment method. Must be 'points' or 'fiat'.")

        roaming_pass = RoamingPass.objects.create(
            user=user, branch=branch, payment=payment_txn, 
            points_used=points_used, fiat_paid=fiat_paid
        )

        user_name = getattr(user, 'full_name', getattr(user, 'email', 'Unknown User'))

        pool, _ = ProviderRoamingPool.objects.select_for_update().get_or_create(provider=branch.provider)
        if pool.free_visits_balance > 0:
            pool.free_visits_balance -= 1
            pool.total_consumed_visits += 1
            pool.save(update_fields=['free_visits_balance', 'total_consumed_visits', 'updated_at'])
        else:
            comm_rate = Decimal(str(getattr(branch.provider, 'commission_value', '10.0')))
            discounted_comm = gross_amount * (comm_rate / Decimal('100.0')) * Decimal('0.5')
            net_revenue = max(Decimal('0.00'), gross_amount - discounted_comm)

            if net_revenue > 0:
                p_wallet, _ = ProviderWallet.objects.select_for_update().get_or_create(provider=branch.provider)
                p_wallet.pending_balance += net_revenue
                p_wallet.save(update_fields=['pending_balance', 'updated_at'])

                ProviderWalletTxn.objects.create(
                    wallet=p_wallet, transaction_type="earning_pending",
                    amount=net_revenue, is_cleared=False,
                    description=f"Roaming pass revenue (User: {user_name})"
                )

        earn_rate = Decimal(str(loyalty_settings.gym_earn_rate))
        if payment_method == "fiat" and earn_rate > Decimal('0.00'):
            points_earned = int(fiat_paid / earn_rate)
            if points_earned > 0:
                CustomerWalletTxn.execute_transaction(
                    wallet=wallet, t_type=CustomerTxnType.EARN_PURCHASE, points=points_earned,
                    description=f"Earned from Roaming Pass at: {branch.name}"
                )

        return roaming_pass