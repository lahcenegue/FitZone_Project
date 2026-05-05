"""
Database models for the Loyalty and Wallet ecosystem.
Manages customer wallets, point transactions, fiat balances, 
milestone roadmaps, global conversion settings, and Point Packages.
"""

import uuid
import logging
from django.db import models, transaction
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError
from django.utils import timezone

logger = logging.getLogger(__name__)

class LoyaltyGlobalSetting(models.Model):
    roadmap_version = models.PositiveIntegerField(default=1, verbose_name=_("Roadmap Version"))
    gym_earn_rate = models.DecimalField(max_digits=10, decimal_places=2, default=20.00, verbose_name=_("Gym Earn Rate (SAR per Point)"))
    trainer_earn_rate = models.DecimalField(max_digits=10, decimal_places=2, default=40.00, verbose_name=_("Trainer Earn Rate (SAR per Point)"))
    store_earn_rate = models.DecimalField(max_digits=10, decimal_places=2, default=100.00, verbose_name=_("Store Earn Rate (SAR per Point)"))
    restaurant_earn_rate = models.DecimalField(max_digits=10, decimal_places=2, default=50.00, verbose_name=_("Restaurant Earn Rate (SAR per Point)"))
    point_to_fiat_rate = models.DecimalField(max_digits=10, decimal_places=2, default=100.00, verbose_name=_("Point to Fiat Rate (Points per SAR)"))
    max_global_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=10.00, verbose_name=_("Max Global Discount (%)"))
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("Loyalty Global Setting")
        verbose_name_plural = _("Loyalty Global Settings")

    def save(self, *args, **kwargs):
        if self.pk:
            try:
                old = LoyaltyGlobalSetting.objects.get(pk=self.pk)
                if (old.gym_earn_rate != self.gym_earn_rate or
                    old.trainer_earn_rate != self.trainer_earn_rate or
                    old.store_earn_rate != self.store_earn_rate or
                    old.restaurant_earn_rate != self.restaurant_earn_rate or
                    old.point_to_fiat_rate != self.point_to_fiat_rate or
                    old.max_global_discount_percent != self.max_global_discount_percent):
                    self.roadmap_version += 1
            except Exception:
                pass
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f"Loyalty & Economic Settings (v{self.roadmap_version})"


class PointPackage(models.Model):
    name = models.CharField(max_length=100, verbose_name=_("Package Name"))
    points = models.PositiveIntegerField(verbose_name=_("Points Amount"))
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Price (SAR)"))
    is_active = models.BooleanField(default=True, verbose_name=_("Is Active"))
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("Point Package")
        verbose_name_plural = _("Point Packages")
        ordering = ['price']

    def __str__(self):
        return f"{self.name} ({self.points} Pts for {self.price} SAR)"


class CustomerWallet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="customer_wallet")
    fiat_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Fiat Balance (SAR)"))
    points_balance = models.PositiveIntegerField(default=0, verbose_name=_("Spendable Points"))
    lifetime_points = models.PositiveIntegerField(default=0, verbose_name=_("Lifetime Points"))
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("Customer Wallet")
        verbose_name_plural = _("Customer Wallets")

    def __str__(self):
        return f"Wallet - {self.user.email}"


class TransactionType(models.TextChoices):
    EARN_PURCHASE = "earn_purchase", _("Earned from Purchase")
    BUY_POINTS = "buy_points", _("Bought Points via Gateway")
    SPEND_ROAMING = "spend_roaming", _("Spent on Roaming Visit")
    SPEND_DISCOUNT = "spend_discount", _("Spent on Discount")
    SELL_SUBSCRIPTION = "sell_sub", _("Fiat Earned from Selling Sub")
    WITHDRAW_FIAT = "withdraw_fiat", _("Fiat Withdrawal")
    REFUND = "refund", _("Refunded")


class TransactionStatus(models.TextChoices):
    PENDING = "pending", _("Pending")
    COMPLETED = "completed", _("Completed")
    FAILED = "failed", _("Failed")
    REFUNDED = "refunded", _("Refunded")


class WalletTransaction(models.Model):
    wallet = models.ForeignKey(CustomerWallet, on_delete=models.CASCADE, related_name="transactions")
    transaction_type = models.CharField(max_length=30, choices=TransactionType.choices)
    status = models.CharField(max_length=20, choices=TransactionStatus.choices, default=TransactionStatus.COMPLETED)
    points_amount = models.IntegerField(default=0)
    fiat_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    description = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = _("Wallet Transaction")
        verbose_name_plural = _("Wallet Transactions")
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.transaction_type} - Points: {self.points_amount} - Fiat: {self.fiat_amount} ({self.get_status_display()})"

    @classmethod
    @transaction.atomic
    def execute_transaction(cls, wallet, t_type, points=0, fiat=0.00, description="", status=TransactionStatus.COMPLETED):
        wallet_obj = CustomerWallet.objects.select_for_update().get(pk=wallet.pk)
        
        if status == TransactionStatus.COMPLETED:
            if wallet_obj.points_balance + points < 0:
                raise ValidationError("Insufficient points balance.")
            if float(wallet_obj.fiat_balance) + float(fiat) < 0.0:
                raise ValidationError("Insufficient fiat balance.")

            wallet_obj.points_balance += points
            wallet_obj.fiat_balance = float(wallet_obj.fiat_balance) + float(fiat)
            
            # --- STRICT LIFETIME POINTS LOGIC ---
            if points > 0 and t_type in [TransactionType.EARN_PURCHASE, TransactionType.BUY_POINTS]:
                # 1. Earned points increase lifetime points
                wallet_obj.lifetime_points += points
            elif points < 0 and t_type == TransactionType.REFUND:
                # 2. Refunds strictly decrease lifetime points to prevent exploitation
                wallet_obj.lifetime_points = max(0, wallet_obj.lifetime_points + points)
            # 3. Normal spending (SPEND_ROAMING, SPEND_DISCOUNT) leaves lifetime_points untouched
                
            wallet_obj.save(update_fields=['points_balance', 'fiat_balance', 'lifetime_points', 'updated_at'])

        ledger_entry = cls.objects.create(
            wallet=wallet_obj,
            transaction_type=t_type,
            status=status,
            points_amount=points,
            fiat_amount=fiat,
            description=description
        )
        return ledger_entry


class RewardActionType(models.TextChoices):
    SYSTEM_ROAMING = "sys_roaming", _("Free Roaming Visits")
    SYSTEM_EXTENSION = "sys_extension", _("Subscription Extension (Days)")
    GENERATE_COUPON = "gen_coupon", _("Discount Coupon")
    MANUAL_FULFILLMENT = "manual", _("Physical Gift (e.g. T-Shirt, Meal)")


class FulfillmentType(models.TextChoices):
    IMMEDIATE = 'IMMEDIATE', _('Immediate / System Applied')
    CONTEXTUAL = 'CONTEXTUAL', _('Contextual / Checkout')
    QR_VERIFIED = 'QR_VERIFIED', _('In-Person / QR Scanned')
    DELIVERY = 'DELIVERY', _('Shipped / Delivered')


class MilestoneReward(models.Model):
    name = models.CharField(max_length=255, verbose_name=_("Reward Name"))
    action_type = models.CharField(max_length=50, choices=RewardActionType.choices, default=RewardActionType.GENERATE_COUPON)
    
    action_value = models.PositiveIntegerField(default=1, verbose_name=_("Days / Visits Amount"), help_text=_("Ignore this field if you are creating a Discount Coupon."))
    
    coupon_definition = models.ForeignKey(
        'coupons.CouponDefinition', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name="milestone_rewards",
        verbose_name=_("Coupon Template"),
        help_text=_("Required ONLY if you selected 'Discount Coupon' above.")
    )
    
    fulfillment_type = models.CharField(max_length=20, choices=FulfillmentType.choices, default=FulfillmentType.IMMEDIATE)
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("Milestone Reward Definition")
        verbose_name_plural = _("Milestone Reward Definitions")

    def __str__(self):
        return f"{self.name} ({self.get_action_type_display()})"


class Milestone(models.Model):
    title = models.CharField(max_length=255, verbose_name=_("Milestone Title"))
    required_lifetime_points = models.PositiveIntegerField(unique=True)
    reward = models.ForeignKey(MilestoneReward, on_delete=models.RESTRICT, related_name="milestones", null=True, blank=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("Milestone")
        verbose_name_plural = _("Milestones")
        ordering = ['required_lifetime_points']

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        LoyaltyGlobalSetting.objects.filter(pk=1).update(roadmap_version=models.F('roadmap_version') + 1)

    def delete(self, *args, **kwargs):
        super().delete(*args, **kwargs)
        LoyaltyGlobalSetting.objects.filter(pk=1).update(roadmap_version=models.F('roadmap_version') + 1)

    def __str__(self):
        return f"{self.title} ({self.required_lifetime_points} Pts)"


class UserMilestone(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="unlocked_milestones")
    milestone = models.ForeignKey(Milestone, on_delete=models.CASCADE, related_name="unlocked_by_users")
    
    is_claimed = models.BooleanField(default=False)
    claimed_at = models.DateTimeField(null=True, blank=True)
    
    reward_payload = models.JSONField(default=dict, blank=True, verbose_name=_("Reward Payload (QR/Coupon)"))
    
    is_consumed = models.BooleanField(default=False)
    consumed_at = models.DateTimeField(null=True, blank=True)
    
    unlocked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("User Milestone")
        verbose_name_plural = _("User Milestones")
        unique_together = ('user', 'milestone')
        ordering = ['-unlocked_at']

    def __str__(self):
        return f"{self.user.email} - {self.milestone.title}"

    @transaction.atomic
    def claim_reward(self, payload: dict = None):
        if self.is_claimed:
            raise ValidationError("This reward has already been claimed.")
        self.is_claimed = True
        self.claimed_at = timezone.now()
        self.reward_payload = payload or {}
        self.save(update_fields=['is_claimed', 'claimed_at', 'reward_payload'])
        logger.info(f"User {self.user.email} claimed milestone reward: {self.milestone.title}")

    @transaction.atomic
    def consume_reward(self):
        if not self.is_claimed:
            raise ValidationError("You must claim the reward before consuming it.")
        if self.is_consumed:
            raise ValidationError("This reward has already been consumed.")
            
        self.is_consumed = True
        self.consumed_at = timezone.now()
        self.save(update_fields=['is_consumed', 'consumed_at'])
        logger.info(f"User {self.user.email} consumed milestone reward: {self.milestone.title}")