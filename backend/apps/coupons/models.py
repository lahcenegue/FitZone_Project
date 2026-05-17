"""
Database models for the dynamic Coupons ecosystem.
Provides highly flexible coupon definitions managed by admins,
and tracks generated coupons for users.
"""

import logging
import secrets
import string
from django.db import models
from django.conf import settings
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

logger = logging.getLogger(__name__)

class CouponType(models.TextChoices):
    PERCENTAGE_DISCOUNT = "percentage", _("Percentage Discount (%)")
    FIXED_AMOUNT_DISCOUNT = "fixed_amount", _("Fixed Amount Discount (SAR)")
    FREE_SHIPPING = "free_shipping", _("Free Shipping")
    BUY_ONE_GET_ONE = "bogo", _("Buy One Get One Free (BOGO)")
    FREE_ITEM = "free_item", _("Free Specific Item")


class CouponSource(models.TextChoices):
    MARKETING = "marketing", _("Marketing Campaign")
    LOYALTY = "loyalty", _("Loyalty System Reward")


class CouponDefinition(models.Model):
    title = models.CharField(max_length=255, verbose_name=_("Internal Title"))
    coupon_type = models.CharField(max_length=50, choices=CouponType.choices)
    source = models.CharField(max_length=50, choices=CouponSource.choices, default=CouponSource.MARKETING, verbose_name=_("Coupon Source"))
    
    code = models.CharField(max_length=50, unique=True, null=True, blank=True, verbose_name=_("Public Coupon Code"), help_text=_("Required for Marketing campaigns. Leave blank for Loyalty."))
    max_usage = models.PositiveIntegerField(default=0, verbose_name=_("Maximum Total Usages"), help_text=_("0 means unlimited usage."))
    expiration_date = models.DateTimeField(null=True, blank=True, verbose_name=_("Campaign Expiration Date"))
    
    discount_value = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=0.00,
        verbose_name=_("Discount Value"),
        help_text=_("Value based on type (e.g., 20 for 20%, or 50 for 50 SAR. Use 0 for Free Shipping/BOGO).")
    )
    
    validity_days = models.PositiveIntegerField(
        default=30,
        verbose_name=_("Validity Duration (Days)"),
        help_text=_("How many days the coupon remains valid after being generated for a user.")
    )
    
    rules_payload = models.JSONField(
        default=dict, 
        blank=True,
        verbose_name=_("Dynamic Rules & Constraints"),
        help_text=_("JSON format for extra flexibility. e.g., {'min_cart_value': 100, 'target_product_id': 5}")
    )
    
    is_active = models.BooleanField(default=True, verbose_name=_("Is Active"))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("Coupon Definition")
        verbose_name_plural = _("Coupon Definitions")
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.get_coupon_type_display()})"

    def clean(self):
        if self.coupon_type == CouponType.PERCENTAGE_DISCOUNT and self.discount_value > 100:
            raise ValidationError({"discount_value": _("Percentage discount cannot exceed 100.")})
        
        if self.coupon_type in [CouponType.PERCENTAGE_DISCOUNT, CouponType.FIXED_AMOUNT_DISCOUNT]:
            if self.discount_value <= 0:
                raise ValidationError({"discount_value": _("This coupon type requires a discount value greater than 0.")})

        if self.source == CouponSource.MARKETING and not self.code:
            raise ValidationError({"code": _("Marketing campaigns require a specific public coupon code.")})

    def generate_coupon_code(self, length=8):
        """Generates a secure, readable random string for the coupon code."""
        alphabet = string.ascii_uppercase + string.digits
        safe_alphabet = alphabet.translate(str.maketrans('', '', '0O1I'))
        return ''.join(secrets.choice(safe_alphabet) for _ in range(length))

    def create_coupon_for_user(self, user):
        """
        Instantiates a real coupon for a specific user based on this definition.
        """
        if not self.is_active:
            raise ValidationError(_("Cannot generate a coupon from an inactive definition."))

        unique_code = self.generate_coupon_code()
        expiration_date = timezone.now() + timezone.timedelta(days=self.validity_days)

        user_coupon = UserCoupon.objects.create(
            user=user,
            definition=self,
            code=unique_code,
            expires_at=expiration_date
        )
        
        logger.info(f"Generated coupon {unique_code} for user {user.id} from definition {self.id}")
        return user_coupon


class UserCoupon(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="coupons")
    definition = models.ForeignKey(CouponDefinition, on_delete=models.PROTECT, related_name="generated_coupons")
    
    code = models.CharField(max_length=50, db_index=True, verbose_name=_("Coupon Code"))
    
    is_used = models.BooleanField(default=False, verbose_name=_("Is Used"))
    used_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Used At"))
    fiat_discount_applied = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name=_("Fiat Discount Applied (SAR)"))
    expires_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Expiration Date"))
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("User Coupon")
        verbose_name_plural = _("User Coupons")
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.code} - {self.user.email}"

    def validate_usability(self):
        """Checks if the coupon is ready to be consumed."""
        if self.is_used:
            raise ValidationError(_("This coupon has already been used."))
        if self.expires_at and timezone.now() > self.expires_at:
            raise ValidationError(_("This coupon has expired."))
        if not self.definition.is_active:
            raise ValidationError(_("The base definition for this coupon is no longer active."))
        return True

    def mark_as_used(self, discount_amount):
        """Marks the coupon as consumed and records the actual fiat value saved."""
        self.validate_usability()
        self.is_used = True
        self.used_at = timezone.now()
        self.fiat_discount_applied = discount_amount
        self.save(update_fields=['is_used', 'used_at', 'fiat_discount_applied'])
        logger.info(f"Coupon {self.code} marked as used by user {self.user.id}, saving {discount_amount} SAR")