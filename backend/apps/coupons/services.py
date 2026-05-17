import logging
from decimal import Decimal
from django.core.exceptions import ValidationError
from django.utils import timezone
from apps.coupons.models import UserCoupon, CouponDefinition, CouponSource

logger = logging.getLogger(__name__)

class CouponValidationService:
    """
    Centralized service for coupon validation and discount calculation.
    Ensures DRY principle by serving both the standalone API and CheckoutService.
    """

    @staticmethod
    def validate_and_calculate_discount(user, coupon_code: str, subtotal: Decimal = Decimal("0.00")) -> dict:
        if not coupon_code:
            return {
                "is_valid": False,
                "discount_amount": Decimal("0.00"),
                "coupon_type": None,
                "definition_discount_value": Decimal("0.00"),
                "message": "Coupon code is missing or empty."
            }

        code_clean = coupon_code.strip()
        
        # Check if the code matches a public Marketing Campaign
        marketing_campaign = CouponDefinition.objects.filter(code__iexact=code_clean, source=CouponSource.MARKETING).first()

        if marketing_campaign:
            if not marketing_campaign.is_active:
                raise ValidationError("This marketing campaign is currently paused.")
            if marketing_campaign.expiration_date and timezone.now() > marketing_campaign.expiration_date:
                raise ValidationError("This campaign has expired.")
                
            if marketing_campaign.max_usage > 0:
                current_usage = UserCoupon.objects.filter(definition=marketing_campaign, is_used=True).count()
                if current_usage >= marketing_campaign.max_usage:
                    raise ValidationError("This coupon has reached its maximum usage limit.")

            if UserCoupon.objects.filter(user=user, definition=marketing_campaign, is_used=True).exists():
                raise ValidationError("You have already redeemed this offer.")

            definition = marketing_campaign
        else:
            # Check if it matches a private Loyalty Code assigned to the user
            try:
                user_coupon = UserCoupon.objects.select_related('definition').get(
                    code=code_clean, 
                    user=user, 
                    is_used=False
                )
                user_coupon.validate_usability()
                definition = user_coupon.definition
            except UserCoupon.DoesNotExist:
                raise ValidationError("Invalid or previously used coupon code.")
            
        discount_amount = Decimal("0.00")
        
        if subtotal > Decimal("0.00"):
            if definition.coupon_type == "percentage":
                calculated_discount = (subtotal * definition.discount_value) / Decimal("100.00")
                discount_amount = min(calculated_discount, subtotal)
            elif definition.coupon_type == "fixed_amount":
                discount_amount = min(definition.discount_value, subtotal)

        return {
            "is_valid": True,
            "discount_amount": discount_amount,
            "coupon_type": definition.coupon_type,
            "definition_discount_value": definition.discount_value,
            "message": "Coupon is valid and ready to use."
        }