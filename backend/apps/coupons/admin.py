"""
Django Admin interface for Coupons ecosystem.
Provides a clean UI to manage rules and monitor generated coupons.
"""

from django.contrib import admin
from apps.coupons.models import CouponDefinition, UserCoupon


class UserCouponInline(admin.TabularInline):
    """
    Displays generated coupons inside the parent definition.
    Provides monitoring capabilities for admins without allowing direct edits.
    """
    model = UserCoupon
    extra = 0
    readonly_fields = ('code', 'user', 'is_used', 'used_at', 'expires_at', 'created_at')
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(CouponDefinition)
class CouponDefinitionAdmin(admin.ModelAdmin):
    list_display = ['title', 'coupon_type', 'discount_value', 'validity_days', 'is_active', 'created_at']
    list_filter = ['coupon_type', 'is_active']
    search_fields = ['title']
    list_editable = ['is_active']
    inlines = [UserCouponInline]
    
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
    search_fields = ['code', 'user__email', 'user__phone_number', 'definition__title']
    readonly_fields = ['code', 'user', 'definition', 'is_used', 'used_at', 'expires_at', 'created_at']
    
    def has_add_permission(self, request):
        """
        Prevents manual creation. Coupons must be generated via the system rules.
        """
        return False