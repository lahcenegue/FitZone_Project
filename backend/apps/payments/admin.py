"""
Django Admin interface for the Payments ecosystem.
Manages global financial settings, tracks transactions, and handles provider withdrawals.
"""

from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from apps.payments.models import (
    PaymentTransaction, PaymentGlobalSetting, ProviderWallet,
    WalletTransaction, WithdrawalRequest
)

@admin.register(PaymentGlobalSetting)
class PaymentGlobalSettingAdmin(admin.ModelAdmin):
    list_display = ['__str__', 'vat_percentage', 'earnings_hold_days']

    def has_add_permission(self, request):
        if self.model.objects.exists():
            return False
        return super().has_add_permission(request)

@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'amount', 'currency', 'gateway', 'status', 'created_at']
    list_filter = ['status', 'gateway', 'currency']
    search_fields = ['id', 'user__email', 'gateway_transaction_id']
    readonly_fields = ['id', 'created_at', 'updated_at']

@admin.register(ProviderWallet)
class ProviderWalletAdmin(admin.ModelAdmin):
    list_display = ['provider', 'pending_balance', 'available_balance', 'total_withdrawn', 'updated_at']
    search_fields = ['provider__business_name', 'provider__user__email']
    readonly_fields = ['updated_at']

@admin.register(WalletTransaction)
class WalletTransactionAdmin(admin.ModelAdmin):
    list_display = ['wallet', 'transaction_type', 'amount', 'is_cleared', 'clearance_date', 'created_at']
    list_filter = ['transaction_type', 'is_cleared']
    search_fields = ['wallet__provider__business_name', 'description']
    readonly_fields = ['created_at']

@admin.register(WithdrawalRequest)
class WithdrawalRequestAdmin(admin.ModelAdmin):
    list_display = ['provider', 'amount', 'status', 'bank_name', 'created_at']
    list_filter = ['status']
    search_fields = ['provider__business_name', 'iban', 'account_name']
    readonly_fields = ['created_at', 'updated_at']