"""
Admin configuration for the User model.
Includes inline editing for related One-To-One models like Wallets and Bank Accounts.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _

from .models import User, UserBankAccount
from apps.loyalty.models import CustomerWallet


class UserBankAccountInline(admin.StackedInline):
    """
    Allows admin to view and edit the user's bank account directly 
    from the User admin page.
    """
    model = UserBankAccount
    can_delete = False
    verbose_name_plural = _("Bank Account Details")
    fk_name = 'user'
    extra = 0
    classes = ('collapse',) # Makes it collapsible for a cleaner UI


class CustomerWalletInline(admin.StackedInline):
    """
    Allows admin to view and edit the user's loyalty and fiat balances 
    directly from the User admin page.
    """
    model = CustomerWallet
    can_delete = False
    verbose_name_plural = _("Customer Wallet & Points")
    fk_name = 'user'
    readonly_fields = ['id', 'updated_at']
    extra = 0
    classes = ('collapse',)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin panel configuration for the custom User model."""

    list_display = ["email", "full_name", "role", "is_active", "is_verified", "date_joined"]
    list_filter = ["role", "is_active", "is_verified", "is_premium", "gender"]
    search_fields = ["email", "full_name", "phone_number"]
    ordering = ["-date_joined"]

    # Injecting the related models into the User editing page
    inlines = [CustomerWalletInline, UserBankAccountInline]

    fieldsets = (
        (_("Credentials"), {"fields": ("email", "password")}),
        (_("Personal info"), {"fields": ("full_name", "phone_number", "phone_verified", "avatar", "gender")}),
        (_("Location"), {"fields": ("location", "address", "city")}),
        (_("Role & Status"), {"fields": ("role", "is_active", "is_staff", "is_superuser", "is_verified")}),
        (_("Premium"), {"fields": ("is_premium", "premium_since")}),
        (_("Points"), {"fields": ("points_balance", "points_total")}),
        (_("Permissions"), {"fields": ("groups", "user_permissions")}),
        (_("Timestamps"), {"fields": ("date_joined", "updated_at")}),
    )

    readonly_fields = ["date_joined", "updated_at"]

    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("email", "full_name", "password1", "password2", "role"),
        }),
    )