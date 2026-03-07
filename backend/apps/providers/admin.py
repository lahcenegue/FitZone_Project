"""
Django admin registration for the Provider app.
"""

from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import Provider, ProviderType, ProviderStatus


@admin.register(Provider)
class ProviderAdmin(admin.ModelAdmin):
    """
    Admin interface for Provider model.
    Displays key fields, supports filtering by type and status,
    and allows status changes directly from the list view.
    """

    list_display = [
        "business_name",
        "user",
        "provider_type",
        "status",
        "city",
        "created_at",
    ]
    list_filter = ["provider_type", "status", "city"]
    search_fields = ["business_name", "user__email", "user__full_name", "commercial_registration"]
    readonly_fields = ["created_at", "updated_at"]
    ordering = ["-created_at"]

    fieldsets = (
        (_("Account"), {
            "fields": ("user", "provider_type", "status"),
        }),
        (_("Business"), {
            "fields": ("business_name", "description", "logo", "city", "address"),
        }),
        (_("Legal"), {
            "fields": ("commercial_registration", "tax_id"),
        }),
        (_("Financial"), {
            "fields": ("bank_name", "iban", "bank_account_number"),
            "classes": ("collapse",),
        }),
        (_("Timestamps"), {
            "fields": ("created_at", "updated_at"),
        }),
    )

    actions = ["action_activate", "action_suspend", "action_approve"]

    @admin.action(description=_("Activate selected providers"))
    def action_activate(self, request, queryset):
        """Bulk activate selected providers."""
        for provider in queryset:
            provider.activate(reason="bulk admin action")
        self.message_user(request, _("Selected providers have been activated."))

    @admin.action(description=_("Suspend selected providers"))
    def action_suspend(self, request, queryset):
        """Bulk suspend selected providers."""
        for provider in queryset:
            provider.suspend(reason="bulk admin action")
        self.message_user(request, _("Selected providers have been suspended."))

    @admin.action(description=_("Approve selected providers"))
    def action_approve(self, request, queryset):
        """Bulk approve selected providers."""
        for provider in queryset:
            provider.approve(reason="bulk admin action")
        self.message_user(request, _("Selected providers have been approved."))