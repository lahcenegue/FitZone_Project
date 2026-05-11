"""
Database models for the Secondary Market (Resale) application.
Handles the listing, pricing, and transactions of transferring subscriptions
from one user to another.
"""

import logging
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError
from django.utils import timezone

from apps.gyms.models import GymSubscription

logger = logging.getLogger(__name__)

class ResaleGlobalSetting(models.Model):
    """
    Singleton model for admin controls over the resale marketplace.
    """
    app_commission_percentage = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=10.00,
        verbose_name=_("App Commission (%)"),
        help_text=_("The percentage of the resale price the app takes as commission.")
    )
    depreciation_percentage = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=10.00,
        verbose_name=_("Immediate Depreciation (%)"),
        help_text=_("The immediate value reduction percentage applied to a subscription to prevent selling at the original purchase price.")
    )
    minimum_days_buffer = models.PositiveIntegerField(
        default=7,
        verbose_name=_("Minimum Days Buffer"),
        help_text=_("Subscriptions cannot be listed if the remaining days are less than this value.")
    )
    escrow_hold_hours = models.PositiveIntegerField(
        default=24,
        verbose_name=_("Escrow Hold Duration (Hours)"),
        help_text=_("How long the funds are held after purchase before being released to the seller.")
    )

    class Meta:
        verbose_name = _("Resale Global Setting")
        verbose_name_plural = _("Resale Global Settings")

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return str(_("Resale Settings"))


class ResaleListingStatus(models.TextChoices):
    ACTIVE = "active", _("Active / Listed")
    SOLD = "sold", _("Sold")
    CANCELLED = "cancelled", _("Cancelled by Seller")
    EXPIRED = "expired", _("Expired (Removed by System)")


class SubscriptionResaleListing(models.Model):
    """
    Represents an active or historical listing in the secondary market.
    """
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name="resale_listings",
        verbose_name=_("Seller")
    )
    subscription = models.OneToOneField(
        GymSubscription, 
        on_delete=models.CASCADE, 
        related_name="resale_listing",
        verbose_name=_("Original Subscription")
    )
    
    asking_price = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        verbose_name=_("Asking Price (SAR)"),
        help_text=_("The price the seller is asking for. Must be <= fair value.")
    )
    fair_value_at_listing = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        verbose_name=_("Fair Value at Listing"),
        help_text=_("System calculated pro-rata value when listed to prevent scalping.")
    )
    
    status = models.CharField(
        max_length=20, 
        choices=ResaleListingStatus.choices, 
        default=ResaleListingStatus.ACTIVE,
        verbose_name=_("Listing Status")
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("Subscription Resale Listing")
        verbose_name_plural = _("Subscription Resale Listings")
        ordering = ['-created_at']

    def __str__(self):
        return f"Listing: Sub #{self.subscription.id} for {self.asking_price} SAR"

    def clean(self):
        if self.status == ResaleListingStatus.ACTIVE:
            if self.subscription.is_resold:
                raise ValidationError(_("This subscription has already been resold and cannot be listed again."))
            
            if self.subscription.status != "active":
                raise ValidationError(_("Only active subscriptions can be listed for resale."))
            
            settings = ResaleGlobalSetting.load()
            days_left = (self.subscription.end_date - timezone.now().date()).days
            
            if days_left < settings.minimum_days_buffer:
                raise ValidationError(
                    _("Cannot list subscription. Remaining days (%(days)d) is less than the required buffer (%(buffer)d).") % {
                        'days': days_left, 'buffer': settings.minimum_days_buffer
                    }
                )

            if self.asking_price > self.fair_value_at_listing:
                raise ValidationError(_("Asking price cannot exceed the current fair value of the subscription."))


class ResaleTransactionStatus(models.TextChoices):
    ESCROW = "escrow", _("In Escrow (Pending Clearance)")
    COMPLETED = "completed", _("Completed (Funds Released)")
    REFUNDED = "refunded", _("Disputed & Refunded")


class ResaleTransaction(models.Model):
    """
    Records the actual financial transaction of a resale.
    Links the buyer, the listing, and tracks the app commission.
    """
    listing = models.OneToOneField(
        SubscriptionResaleListing, 
        on_delete=models.PROTECT, 
        related_name="transaction",
        verbose_name=_("Resale Listing")
    )
    buyer = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.PROTECT, 
        related_name="resale_purchases",
        verbose_name=_("Buyer")
    )
    
    payment = models.OneToOneField(
        'payments.PaymentTransaction', 
        on_delete=models.PROTECT, 
        related_name="resale_transaction",
        verbose_name=_("Payment Record")
    )
    
    sale_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Final Sale Price"))
    app_commission = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("App Commission"))
    seller_earnings = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Seller Earnings"))
    
    status = models.CharField(
        max_length=20, 
        choices=ResaleTransactionStatus.choices, 
        default=ResaleTransactionStatus.ESCROW,
        verbose_name=_("Transaction Status")
    )
    
    purchased_at = models.DateTimeField(auto_now_add=True)
    cleared_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Funds Cleared At"))

    class Meta:
        verbose_name = _("Resale Transaction")
        verbose_name_plural = _("Resale Transactions")
        ordering = ['-purchased_at']

    def __str__(self):
        return f"Resale TXN: Listing #{self.listing.id} - Buyer: {self.buyer.email}"

    def save(self, *args, **kwargs):
        """
        Overrides save to ensure funds are released to the seller's wallet
        automatically when status changes from ESCROW to COMPLETED (e.g., via Admin).
        """
        release_funds = False
        
        if self.pk:
            old_instance = ResaleTransaction.objects.filter(pk=self.pk).first()
            if old_instance and old_instance.status == ResaleTransactionStatus.ESCROW and self.status == ResaleTransactionStatus.COMPLETED:
                release_funds = True
                self.cleared_at = timezone.now()

        super().save(*args, **kwargs)

        if release_funds:
            from apps.loyalty.models import CustomerWallet, WalletTransaction, TransactionType, TransactionStatus
            
            wallet, _ = CustomerWallet.objects.get_or_create(user=self.listing.seller)
            WalletTransaction.execute_transaction(
                wallet=wallet,
                t_type=TransactionType.SELL_SUBSCRIPTION,
                points=0,
                fiat=self.seller_earnings,
                description=f"Earnings from resale of subscription #{self.listing.subscription.id}",
                status=TransactionStatus.COMPLETED
            )
            logger.info(f"Escrow funds automatically released on status change for TXN #{self.pk} to {self.listing.seller.email}")