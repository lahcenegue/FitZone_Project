"""
Django Admin interface for Coupons ecosystem.
"""

from django.contrib import admin
from apps.coupons.models import CouponDefinition, UserCoupon

@admin.register(CouponDefinition)
class CouponDefinitionAdmin(admin.ModelAdmin):
    list_display = ['title', 'coupon_type', 'discount_value', 'validity_days', 'is_active', 'created_at']
    list_filter = ['coupon_type', 'is_active']
    search_fields = ['title']
    list_editable = ['is_active']
    
    # Hide complex JSON field from admins
    exclude = ('rules_payload',)
    
    fieldsets = (
        ("Basic Details", {
            'fields': ('title', 'coupon_type', 'is_active')
        }),
        ("Values & Expiration", {
            'fields': ('discount_value', 'validity_days')
        }),
    )

@admin.register(UserCoupon)
class UserCouponAdmin(admin.ModelAdmin):
    list_display = ['code', 'user', 'definition', 'is_used', 'expires_at', 'created_at']
    list_filter = ['is_used', 'definition__coupon_type']
    search_fields = ['code', 'user__email', 'user__phone_number']
    readonly_fields = ['code', 'user', 'definition', 'is_used', 'used_at', 'expires_at', 'created_at']
    
    def has_add_permission(self, request):
        return False