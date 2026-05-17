from rest_framework import serializers
from decimal import Decimal

class CouponValidationRequestSerializer(serializers.Serializer):
    coupon_code = serializers.CharField(max_length=20, required=True, trim_whitespace=True)
    subtotal = serializers.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        required=False, 
        default=Decimal("0.00"),
        min_value=Decimal("0.00")
    )

class CouponValidationResponseSerializer(serializers.Serializer):
    is_valid = serializers.BooleanField()
    discount_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    coupon_type = serializers.CharField(allow_null=True)
    definition_discount_value = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    message = serializers.CharField()