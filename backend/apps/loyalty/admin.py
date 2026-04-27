"""
Django Admin interface for Loyalty & Wallet ecosystem.
Allows management of global settings, point packages, milestones, and monitoring wallets.
"""

from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from apps.loyalty.models import (
    LoyaltyGlobalSetting, PointPackage, CustomerWallet, 
    WalletTransaction, MilestoneReward, Milestone, UserMilestone
)

@admin.register(LoyaltyGlobalSetting)
class LoyaltyGlobalSettingAdmin(admin.ModelAdmin):
    list_display = ['__str__', 'roadmap_version', 'point_to_fiat_rate', 'max_global_discount_percent', 'updated_at']
    fieldsets = (
        (_("Roadmap Versioning"), {
            'fields': ('roadmap_version',),
            'description': _("Auto-increments when settings or milestones change.")
        }),
        (_("Earning Rates (Spend to get 1 Point)"), {
            'fields': ('gym_earn_rate', 'trainer_earn_rate', 'store_earn_rate', 'restaurant_earn_rate')
        }),
        (_("Redemption Rates & Limits"), {
            'fields': ('point_to_fiat_rate', 'max_global_discount_percent')
        }),
    )

    def has_add_permission(self, request):
        if self.model.objects.exists():
            return False
        return super().has_add_permission(request)


@admin.register(PointPackage)
class PointPackageAdmin(admin.ModelAdmin):
    list_display = ['name', 'points', 'price', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['name']
    list_editable = ['is_active', 'price', 'points']


@admin.register(MilestoneReward)
class MilestoneRewardAdmin(admin.ModelAdmin):
    list_display = ['name', 'action_type', 'action_value', 'is_active']
    list_filter = ['action_type', 'is_active']
    search_fields = ['name']
    list_editable = ['is_active', 'action_value']


@admin.register(Milestone)
class MilestoneAdmin(admin.ModelAdmin):
    list_display = ['title', 'required_lifetime_points', 'reward', 'is_active']
    list_filter = ['is_active', 'reward__action_type']
    search_fields = ['title', 'description']
    list_editable = ['is_active']
    ordering = ['required_lifetime_points']


class WalletTransactionInline(admin.TabularInline):
    model = WalletTransaction
    extra = 0
    readonly_fields = ['transaction_type', 'points_amount', 'fiat_amount', 'description', 'created_at']
    can_delete = False
    ordering = ['-created_at']

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(CustomerWallet)
class CustomerWalletAdmin(admin.ModelAdmin):
    list_display = ['user', 'points_balance', 'fiat_balance', 'lifetime_points', 'updated_at']
    search_fields = ['user__email', 'user__full_name', 'user__phone_number']
    readonly_fields = ['id', 'user', 'updated_at']
    inlines = [WalletTransactionInline]

    fieldsets = (
        (_("Customer Info"), {
            'fields': ('id', 'user')
        }),
        (_("Balances"), {
            'fields': ('points_balance', 'fiat_balance', 'lifetime_points')
        }),
    )


@admin.register(UserMilestone)
class UserMilestoneAdmin(admin.ModelAdmin):
    list_display = ['user', 'milestone', 'is_consumed', 'unlocked_at', 'consumed_at']
    list_filter = ['is_consumed', 'milestone']
    search_fields = ['user__email', 'user__full_name', 'milestone__title']
    readonly_fields = ['unlocked_at', 'consumed_at']
    
    def get_readonly_fields(self, request, obj=None):
        if obj:
            return self.readonly_fields + ['user', 'milestone']
        return self.readonly_fields