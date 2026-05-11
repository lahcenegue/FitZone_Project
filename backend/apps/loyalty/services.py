import logging
from decimal import Decimal
from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _

from apps.loyalty.models import (
    CustomerWallet, WalletTransaction, TransactionType, 
    Milestone, UserMilestone, PointPackage,
    TransactionStatus
)
from apps.payments.services import PaymentService
from apps.users.models import UserBankAccount
from apps.loyalty.fulfillment import FulfillmentFactory

logger = logging.getLogger(__name__)

class LoyaltyService:
    @staticmethod
    @transaction.atomic
    def purchase_points(user, package_id: int, gateway_name: str):
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

        wallet, created = CustomerWallet.objects.get_or_create(user=user)
        
        ledger_entry = WalletTransaction.execute_transaction(
            wallet=wallet,
            t_type=TransactionType.BUY_POINTS,
            points=package.points,
            fiat=0.00,
            description=f"Purchased package: {package.name} via {gateway_name}",
            status=TransactionStatus.COMPLETED
        )

        LoyaltyService.check_and_unlock_milestones(user)
        logger.info(f"Points package purchase successful: {package.name} for user {user.email}")
        return ledger_entry

    @staticmethod
    def check_and_unlock_milestones(user):
        wallet, created = CustomerWallet.objects.get_or_create(user=user)
        current_lifetime_pts = wallet.lifetime_points

        available_milestones = Milestone.objects.filter(
            is_active=True,
            required_lifetime_points__lte=current_lifetime_pts
        ).exclude(unlocked_by_users__user=user)

        for milestone in available_milestones:
            UserMilestone.objects.create(
                user=user,
                milestone=milestone,
                is_claimed=False,
                is_consumed=False
            )
            logger.info(f"Milestone Unlocked: {milestone.title} for user {user.email}")

        ineligible_milestones = UserMilestone.objects.filter(
            user=user,
            is_claimed=False,
            milestone__required_lifetime_points__gt=current_lifetime_pts
        )
        
        if ineligible_milestones.exists():
            revoked_count = ineligible_milestones.count()
            ineligible_milestones.delete()
            logger.info(f"Revoked {revoked_count} locked milestones for user {user.email} due to points reduction.")

    @staticmethod
    @transaction.atomic
    def claim_milestone_reward(user, user_milestone_id: int) -> dict:
        try:
            user_milestone = UserMilestone.objects.select_for_update().get(id=user_milestone_id, user=user)
        except UserMilestone.DoesNotExist:
            raise ValidationError("Reward not found or does not belong to user.")
            
        if user_milestone.is_claimed:
            raise ValidationError("This reward has already been claimed.")

        reward = user_milestone.milestone.reward
        
        strategy = FulfillmentFactory.resolve_strategy(reward.action_type)
        generated_payload = strategy.execute_fulfillment(user, reward)

        user_milestone.claim_reward(payload=generated_payload)
        
        return generated_payload

    @staticmethod
    @transaction.atomic
    def use_milestone_reward(user, user_milestone_id: int):
        try:
            user_milestone = UserMilestone.objects.select_for_update().get(id=user_milestone_id, user=user)
        except UserMilestone.DoesNotExist:
            raise ValidationError("Reward not found or does not belong to user.")

        user_milestone.consume_reward()
        return True

    @staticmethod
    @transaction.atomic
    def apply_subscription_extension(user, user_milestone_id: int, subscription_id: int):
        try:
            user_milestone = UserMilestone.objects.select_for_update().get(id=user_milestone_id, user=user)
        except UserMilestone.DoesNotExist:
            raise ValidationError("Reward not found.")

        if not user_milestone.is_claimed or user_milestone.is_consumed:
            raise ValidationError("Reward must be claimed and not yet consumed.")

        payload = user_milestone.reward_payload
        if payload.get('fulfillment_type') != 'subscription_extension':
            raise ValidationError("This reward is not a subscription extension.")

        from apps.gyms.models import GymSubscription
        from datetime import timedelta
        
        try:
            subscription = GymSubscription.objects.select_for_update().get(id=subscription_id, user=user, status="active")
        except GymSubscription.DoesNotExist:
            raise ValidationError("Active subscription not found.")

        days_added = payload.get('days_added', 0)
        if days_added <= 0:
            raise ValidationError("Invalid extension days in payload.")

        subscription.end_date = subscription.end_date + timedelta(days=days_added)
        subscription.save(update_fields=['end_date'])

        user_milestone.consume_reward()
        logger.info(f"Extended sub {subscription.id} by {days_added} days for user {user.email}")
        
        return subscription.end_date

    @staticmethod
    @transaction.atomic
    def process_gift_qr_scan(staff_user, qr_code_data: str):
        if not qr_code_data.startswith("FZ-GIFT-"):
            raise ValidationError("Invalid QR Code prefix for physical gifts.")

        from django.core.signing import Signer, BadSignature
        signer = Signer(salt="fitzone_gift_qr_auth")
        try:
            raw_data = signer.unsign(qr_code_data)
            qr_uuid = raw_data.replace("FZ-GIFT-", "")
        except BadSignature:
            raise ValidationError("Invalid or tampered gift QR code.")

        user_milestone = UserMilestone.objects.filter(
            reward_payload__qr_id=qr_uuid,
            is_claimed=True,
            is_consumed=False
        ).first()

        if not user_milestone:
            raise ValidationError("Gift not found, already consumed, or invalid.")

        user_milestone.consume_reward()
        logger.info(f"Gift {user_milestone.reward_payload.get('item_name')} handed over to user {user_milestone.user.email} by staff {staff_user.email}")
        
        return {
            "item_name": user_milestone.reward_payload.get('item_name'),
            "customer_name": getattr(user_milestone.user, 'full_name', user_milestone.user.email)
        }

    @staticmethod
    def calculate_milestone_progress(user) -> dict:
        wallet, created = CustomerWallet.objects.get_or_create(user=user)
        current_lifetime_pts = wallet.lifetime_points

        current_milestone = Milestone.objects.filter(
            is_active=True,
            required_lifetime_points__lte=current_lifetime_pts
        ).order_by('-required_lifetime_points').first()

        current_title = str(_(current_milestone.title)) if current_milestone else str(_("Starter"))

        next_milestone = Milestone.objects.filter(
            is_active=True,
            required_lifetime_points__gt=current_lifetime_pts
        ).order_by('required_lifetime_points').first()

        points_to_next = 0
        progress_pct = 100

        if next_milestone:
            points_to_next = next_milestone.required_lifetime_points - current_lifetime_pts
            
            base_points = current_milestone.required_lifetime_points if current_milestone else 0
            tier_total = next_milestone.required_lifetime_points - base_points
            tier_progress = current_lifetime_pts - base_points
            progress_pct = int((tier_progress / tier_total) * 100) if tier_total > 0 else 100
            next_title = str(_(next_milestone.title))
        else:
            next_title = str(_("MAX"))

        return {
            "lifetime_points": current_lifetime_pts,
            "current_milestone_title": current_title,
            "next_milestone_title": next_title,
            "points_to_next_milestone": points_to_next,
            "progress_pct": progress_pct
        }

    @staticmethod
    def get_wallet_summary(user):
        """Returns only financial and basic point balances to prevent data over-fetching."""
        wallet, created = CustomerWallet.objects.get_or_create(user=user)
        LoyaltyService.check_and_unlock_milestones(user)
        
        unlocked_rewards_count = UserMilestone.objects.filter(
            user=user, 
            is_claimed=False
        ).count()

        bank_account_data = None
        if hasattr(user, 'bank_account'):
            bank = user.bank_account
            acc_num = bank.account_number
            masked_acc = f"****{acc_num[-4:]}" if len(acc_num) > 4 else "****"
            
            bank_account_data = {
                "bank_name": bank.bank_name,
                "account_number": masked_acc,
                "iban": bank.iban,
                "beneficiary_name": bank.beneficiary_name
            }

        # Calculate pending escrow balance from Resale Market
        from apps.resale.models import ResaleTransaction, ResaleTransactionStatus
        from django.db.models import Sum
        pending_escrow = ResaleTransaction.objects.filter(
            listing__seller=user,
            status=ResaleTransactionStatus.ESCROW
        ).aggregate(total=Sum('seller_earnings'))['total'] or Decimal('0.00')

        return {
            "spendable_points": wallet.points_balance,
            "lifetime_points": wallet.lifetime_points,
            "fiat_balance": wallet.fiat_balance,
            "pending_fiat_balance": float(pending_escrow),
            "unlocked_rewards_count": unlocked_rewards_count,
            "bank_account": bank_account_data
        }

    @staticmethod
    def save_bank_account(user, data: dict):
        bank_account, created = UserBankAccount.objects.update_or_create(
            user=user,
            defaults={
                'bank_name': data['bank_name'],
                'account_number': data['account_number'],
                'iban': data['iban'],
                'beneficiary_name': data['beneficiary_name']
            }
        )
        logger.info(f"Bank account {'created' if created else 'updated'} for user {user.email}")
        return bank_account

    @staticmethod
    @transaction.atomic
    def request_withdrawal(user, amount: Decimal):
        if not hasattr(user, 'bank_account'):
            raise ValidationError("Please link a bank account first before requesting a withdrawal.")

        wallet = CustomerWallet.objects.select_for_update().get(user=user)
        
        if float(wallet.fiat_balance) < float(amount):
            raise ValidationError("The available balance is insufficient to complete the transaction.")

        wallet.fiat_balance = float(wallet.fiat_balance) - float(amount)
        wallet.save(update_fields=['fiat_balance', 'updated_at'])

        ledger_entry = WalletTransaction.objects.create(
            wallet=wallet,
            transaction_type=TransactionType.WITHDRAW_FIAT,
            status=TransactionStatus.PENDING,
            points_amount=0,
            fiat_amount=-amount, 
            description=f"Withdrawal request to {user.bank_account.bank_name}"
        )
        
        logger.info(f"Withdrawal request of {amount} SAR created for user {user.email}")
        return ledger_entry, wallet.fiat_balance