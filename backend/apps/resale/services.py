import logging
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _

from apps.gyms.models import GymSubscription
from apps.payments.services import PaymentService
from apps.loyalty.models import CustomerWallet, WalletTransaction, TransactionType, TransactionStatus, LoyaltyGlobalSetting
from apps.resale.models import (
    ResaleGlobalSetting, SubscriptionResaleListing, 
    ResaleListingStatus, ResaleTransaction, ResaleTransactionStatus
)

logger = logging.getLogger(__name__)

class ResaleMarketService:
    """
    Core business logic for the secondary market (Resale).
    """

    @staticmethod
    def _calculate_earned_points(subscription: GymSubscription) -> int:
        actual_paid = subscription.payment.amount if subscription.payment else Decimal('0.00')
        if actual_paid <= 0:
            return 0
            
        loyalty_settings = LoyaltyGlobalSetting.load()
        earn_rate = Decimal(str(loyalty_settings.gym_earn_rate))
        if earn_rate > Decimal('0.00'):
            return int(actual_paid / earn_rate)
        return 0

    @staticmethod
    def calculate_fair_value(subscription: GymSubscription) -> Decimal:
        today = timezone.now().date()
        
        if subscription.start_date > today:
            remaining_days = (subscription.end_date - subscription.start_date).days + 1
        else:
            remaining_days = (subscription.end_date - today).days

        if remaining_days <= 0:
            return Decimal('0.00')

        actual_paid = subscription.payment.amount if subscription.payment else Decimal('0.00')
        
        total_days = subscription.plan.duration_days
        if total_days <= 0:
            total_days = 1

        daily_rate = Decimal(str(actual_paid)) / Decimal(str(total_days))
        raw_fair_value = daily_rate * Decimal(str(remaining_days))
        
        # Applying dynamic depreciation from global settings
        resale_settings = ResaleGlobalSetting.load()
        depreciation_percentage = Decimal(str(resale_settings.depreciation_percentage))
        depreciation_rate = Decimal('1.00') - (depreciation_percentage / Decimal('100.0'))
        
        fair_value = raw_fair_value * depreciation_rate
        
        return fair_value.quantize(Decimal('0.01'))

    @staticmethod
    @transaction.atomic
    def list_subscription_for_resale(seller, subscription_id: int, asking_price: Decimal) -> SubscriptionResaleListing:
        try:
            subscription = GymSubscription.objects.select_for_update().get(id=subscription_id, user=seller)
        except GymSubscription.DoesNotExist:
            raise ValidationError(_("Subscription not found or does not belong to you."))

        if hasattr(subscription, 'resale_listing') and subscription.resale_listing.status == ResaleListingStatus.ACTIVE:
            raise ValidationError(_("This subscription is already listed in the marketplace."))

        fair_value = ResaleMarketService.calculate_fair_value(subscription)
        
        if asking_price > fair_value:
            raise ValidationError(_("Asking price cannot exceed the fair value (%(val)s SAR).") % {'val': fair_value})
            
        min_allowed_price = (fair_value * Decimal('0.20')).quantize(Decimal('0.01'))
        if asking_price < min_allowed_price:
            raise ValidationError(_("Asking price is too low. Minimum allowed is %(val)s SAR.") % {'val': min_allowed_price})

        points_to_clawback = ResaleMarketService._calculate_earned_points(subscription)
        if points_to_clawback > 0:
            wallet, created = CustomerWallet.objects.get_or_create(user=seller)
            if wallet.points_balance < points_to_clawback:
                raise ValidationError(
                    _("Cannot list this subscription. You have consumed the points earned from it. You need at least %(pts)d points in your balance to return them.") % {'pts': points_to_clawback}
                )

        listing = SubscriptionResaleListing(
            seller=seller,
            subscription=subscription,
            asking_price=asking_price,
            fair_value_at_listing=fair_value,
            status=ResaleListingStatus.ACTIVE
        )
        
        listing.clean()
        listing.save()

        logger.info(f"User {seller.email} listed sub #{subscription.id} for {asking_price} SAR.")
        return listing

    @staticmethod
    @transaction.atomic
    def cancel_listing(seller, listing_id: int):
        try:
            listing = SubscriptionResaleListing.objects.select_for_update().get(
                id=listing_id, seller=seller, status=ResaleListingStatus.ACTIVE
            )
        except SubscriptionResaleListing.DoesNotExist:
            raise ValidationError(_("Active listing not found."))

        listing.status = ResaleListingStatus.CANCELLED
        listing.save(update_fields=['status', 'updated_at'])
        
        logger.info(f"User {seller.email} cancelled listing #{listing_id}.")
        return listing

    @staticmethod
    @transaction.atomic
    def purchase_listing(buyer, listing_id: int, gateway_name: str) -> ResaleTransaction:
        try:
            listing = SubscriptionResaleListing.objects.select_for_update().get(
                id=listing_id, status=ResaleListingStatus.ACTIVE
            )
        except SubscriptionResaleListing.DoesNotExist:
            raise ValidationError(_("This listing is no longer available."))

        if listing.seller == buyer:
            raise ValidationError(_("You cannot purchase your own listing."))

        settings = ResaleGlobalSetting.load()
        days_left = (listing.subscription.end_date - timezone.now().date()).days
        if days_left < settings.minimum_days_buffer:
            listing.status = ResaleListingStatus.EXPIRED
            listing.save(update_fields=['status', 'updated_at'])
            raise ValidationError(_("This subscription has expired from the marketplace due to minimum days rule."))

        points_to_clawback = ResaleMarketService._calculate_earned_points(listing.subscription)
        if points_to_clawback > 0:
            seller_wallet = CustomerWallet.objects.select_for_update().get(user=listing.seller)
            if seller_wallet.points_balance < points_to_clawback:
                listing.status = ResaleListingStatus.CANCELLED
                listing.save(update_fields=['status', 'updated_at'])
                raise ValidationError(_("Transaction failed. The seller no longer has enough points to cover the transfer. Listing has been removed."))
            
            WalletTransaction.execute_transaction(
                wallet=seller_wallet,
                t_type=TransactionType.REFUND,
                points=-points_to_clawback,
                fiat=0.00,
                description=f"Clawback points for selling subscription #{listing.subscription.id}",
                status=TransactionStatus.COMPLETED
            )

        payment_txn = PaymentService.process_payment(
            user=buyer,
            amount=listing.asking_price,
            currency="SAR",
            gateway_name=gateway_name
        )

        commission_rate = Decimal(str(settings.app_commission_percentage)) / Decimal('100.0')
        app_commission = (listing.asking_price * commission_rate).quantize(Decimal('0.01'))
        seller_earnings = listing.asking_price - app_commission

        resale_txn = ResaleTransaction.objects.create(
            listing=listing,
            buyer=buyer,
            payment=payment_txn,
            sale_price=listing.asking_price,
            app_commission=app_commission,
            seller_earnings=seller_earnings,
            status=ResaleTransactionStatus.ESCROW
        )

        old_subscription = listing.subscription
        old_subscription.status = "transferred"
        old_subscription.is_resold = True
        old_subscription.save(update_fields=['status', 'is_resold'])

        listing.status = ResaleListingStatus.SOLD
        listing.save(update_fields=['status', 'updated_at'])

        today = timezone.now().date()
        new_start_date = old_subscription.start_date if old_subscription.start_date > today else today

        new_subscription = GymSubscription.objects.create(
            user=buyer,
            plan=old_subscription.plan,
            payment=payment_txn, 
            start_date=new_start_date,
            end_date=old_subscription.end_date,
            status="active",
            is_resold=True 
        )

        loyalty_settings = LoyaltyGlobalSetting.load()
        earn_rate = Decimal(str(loyalty_settings.gym_earn_rate))
        if listing.asking_price > 0 and earn_rate > Decimal('0.00'):
            points_earned = int(listing.asking_price / earn_rate)
            if points_earned > 0:
                buyer_wallet, created = CustomerWallet.objects.get_or_create(user=buyer)
                WalletTransaction.execute_transaction(
                    wallet=buyer_wallet, 
                    t_type=TransactionType.EARN_PURCHASE, 
                    points=points_earned,
                    fiat=Decimal('0.00'),
                    description=f"Earned from marketplace purchase: {new_subscription.plan.name}",
                    status=TransactionStatus.COMPLETED
                )
                from apps.loyalty.services import LoyaltyService
                LoyaltyService.check_and_unlock_milestones(buyer)

        logger.info(f"Buyer {buyer.email} purchased listing #{listing.id} from {listing.seller.email}.")
        return resale_txn

    @staticmethod
    @transaction.atomic
    def release_escrow_funds():
        settings = ResaleGlobalSetting.load()
        hold_duration = timezone.timedelta(hours=settings.escrow_hold_hours)
        release_threshold = timezone.now() - hold_duration

        matured_txns = ResaleTransaction.objects.filter(
            status=ResaleTransactionStatus.ESCROW,
            purchased_at__lte=release_threshold
        ).select_for_update()

        released_count = 0
        for txn in matured_txns:
            seller = txn.listing.seller
            wallet, created = CustomerWallet.objects.get_or_create(user=seller)
            
            WalletTransaction.execute_transaction(
                wallet=wallet,
                t_type=TransactionType.SELL_SUBSCRIPTION,
                points=0,
                fiat=txn.seller_earnings,
                description=f"Earnings from resale of subscription #{txn.listing.subscription.id}",
                status=TransactionStatus.COMPLETED
            )
            
            txn.status = ResaleTransactionStatus.COMPLETED
            txn.cleared_at = timezone.now()
            txn.save(update_fields=['status', 'cleared_at'])
            released_count += 1

        if released_count > 0:
            logger.info(f"Escrow release complete: {released_count} transactions cleared to sellers.")
        return released_count