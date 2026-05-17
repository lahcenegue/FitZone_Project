# apps/resale/services.py

import logging
from decimal import Decimal, ROUND_HALF_UP
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
    def calculate_current_fair_price(listing: SubscriptionResaleListing) -> dict:
        """
        Dynamically calculates the decayed price and fair value based on real-time elapsed days.
        Ensures perfect alignment across discovery APIs and the core payment processing tunnel.
        """
        today = timezone.now().date()
        sub = listing.subscription

        # Days remaining right now
        if sub.start_date > today:
            current_days_left = (sub.end_date - sub.start_date).days + 1
        else:
            current_days_left = (sub.end_date - today).days
        
        current_days_left = max(0, current_days_left)

        # Days remaining when originally listed
        listing_date = listing.created_at.date()
        if sub.start_date > listing_date:
            days_at_listing = (sub.end_date - sub.start_date).days + 1
        else:
            days_at_listing = (sub.end_date - listing_date).days
        
        days_at_listing = max(1, days_at_listing)

        # Calculate proportional price decay scale
        if current_days_left <= 0:
            return {
                "current_asking_price": Decimal("0.00"),
                "current_fair_value": Decimal("0.00"),
                "days_left": 0
            }

        # Mathematical proportional decay formula to maintain consumer fairness
        decay_factor = Decimal(str(current_days_left)) / Decimal(str(days_at_listing))
        
        current_fair_value = (listing.fair_value_at_listing * decay_factor).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
        current_asking_price = (listing.asking_price * decay_factor).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

        return {
            "current_asking_price": current_asking_price,
            "current_fair_value": current_fair_value,
            "days_left": current_days_left
        }

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
        
        decayed_pricing = ResaleMarketService.calculate_current_fair_price(listing)
        final_decayed_price = decayed_pricing["current_asking_price"]
        days_left = decayed_pricing["days_left"]

        if days_left < settings.minimum_days_buffer:
            listing.status = ResaleListingStatus.EXPIRED
            listing.save(update_fields=['status', 'updated_at'])
            # Trigger smart hook notification for dynamic execution on purchase attempt failure
            ResaleMarketService._send_listing_expiry_notification(listing.seller, listing)
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
            amount=final_decayed_price,
            currency="SAR",
            gateway_name=gateway_name
        )

        commission_rate = Decimal(str(settings.app_commission_percentage)) / Decimal('100.0')
        app_commission = (final_decayed_price * commission_rate).quantize(Decimal('0.01'))
        seller_earnings = final_decayed_price - app_commission

        resale_txn = ResaleTransaction.objects.create(
            listing=listing,
            buyer=buyer,
            payment=payment_txn,
            sale_price=final_decayed_price,
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
        if final_decayed_price > 0 and earn_rate > Decimal('0.00'):
            points_earned = int(final_decayed_price / earn_rate)
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

    @staticmethod
    def _send_listing_expiry_notification(user, listing: SubscriptionResaleListing) -> None:
        """
        Architecture Notification Hook. Acts as a strict future-proof event placeholder.
        When the Notification System is fully implemented, trigger push/SMS pipelines here.
        """
        # Right now we log the intent as required for clean architecture decoupling
        logger.info(
            f"Notification Event Triggered: Resale Listing #{listing.id} for "
            f"Subscription #{listing.subscription.id} has expired. "
            f"Target recipient: {user.email}"
        )
        # TODO: Connect with NotificationService when initialized:
        # NotificationService.send_push(user=user, title="Listing Expired", body="...")

    @staticmethod
    @transaction.atomic
    def expire_invalid_listings() -> int:
        """
        Automated cron service function to parse all active listings, verify remaining days
        against dynamic marketplace configuration rules, and flag violations as EXPIRED.
        """
        resale_settings = ResaleGlobalSetting.load()
        buffer_days = resale_settings.minimum_days_buffer
        today = timezone.now().date()

        active_listings = SubscriptionResaleListing.objects.filter(
            status=ResaleListingStatus.ACTIVE
        ).select_for_update()

        expired_count = 0
        for listing in active_listings:
            sub = listing.subscription
            if sub.start_date > today:
                days_left = (sub.end_date - sub.start_date).days + 1
            else:
                days_left = (sub.end_date - today).days

            if days_left < buffer_days:
                listing.status = ResaleListingStatus.EXPIRED
                listing.save(update_fields=['status', 'updated_at'])
                
                # Execute the architecture hook to log/notify the seller instantly
                ResaleMarketService._send_listing_expiry_notification(listing.seller, listing)
                
                expired_count += 1
                logger.info(f"Listing #{listing.id} for sub #{sub.id} automatically marked EXPIRED. Days left: {days_left}")

        return expired_count