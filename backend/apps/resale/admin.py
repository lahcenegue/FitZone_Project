from django.contrib import admin
from apps.resale.models import ResaleGlobalSetting, SubscriptionResaleListing, ResaleTransaction

@admin.register(ResaleGlobalSetting)
class ResaleGlobalSettingAdmin(admin.ModelAdmin):
    list_display = ['app_commission_percentage', 'depreciation_percentage', 'minimum_days_buffer', 'escrow_hold_hours']

    def has_add_permission(self, request):
        if self.model.objects.exists():
            return False
        return super().has_add_permission(request)

    def has_delete_permission(self, request, obj=None):
        return False

@admin.register(SubscriptionResaleListing)
class SubscriptionResaleListingAdmin(admin.ModelAdmin):
    list_display = ['id', 'subscription', 'seller', 'asking_price', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['seller__email', 'subscription__id']
    readonly_fields = ['fair_value_at_listing']

@admin.register(ResaleTransaction)
class ResaleTransactionAdmin(admin.ModelAdmin):
    list_display = ['id', 'listing', 'buyer', 'sale_price', 'status', 'purchased_at']
    list_filter = ['status', 'purchased_at']
    search_fields = ['buyer__email', 'listing__id']