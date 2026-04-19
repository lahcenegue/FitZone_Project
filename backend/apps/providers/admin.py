"""
Django admin for the providers app.

Admins review, approve, and reject provider applications here.
All state transitions go through ProviderReviewService — no direct model
manipulation from the admin class.
"""

import logging

from django.contrib import admin, messages
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _

from .constants import ProviderStatus, PROVIDER_APPROVABLE_STATES, PROVIDER_REJECTABLE_STATES
from .models import EmailVerificationToken, Provider
from .services import ProviderReviewService

logger = logging.getLogger(__name__)


class EmailVerificationTokenInline(admin.TabularInline):
    """Show token history on the provider detail page (read-only)."""

    model = EmailVerificationToken
    extra = 0
    readonly_fields = ["token", "expires_at", "is_used", "created_at"]
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(Provider)
class ProviderAdmin(admin.ModelAdmin):
    """
    Provider admin with coloured status badge, commission control, and bulk approve/reject actions.
    """

    list_display  = [
        "business_name", "provider_type", "owner_email",
        "city", "status_badge", "commission_type", "commission_value", "created_at",
    ]
    list_filter   = ["status", "provider_type", "commission_type", "city"]
    search_fields = ["business_name", "user__email", "user__full_name", "city"]
    ordering      = ["-created_at"]
    readonly_fields = [
        "user", "email_verified", "verified_at",
        "reviewed_by", "reviewed_at",
        "created_at", "updated_at",
    ]
    inlines = [EmailVerificationTokenInline]
    actions = ["action_approve", "action_reject"]

    fieldsets = [
        (
            _("Business"),
            {"fields": [
                "user", "provider_type", "business_name", "business_phone",
                "city", "address", "description", "logo",
            ]},
        ),
        (
            _("Legal & Financial"),
            {
                "fields": [
                    "commercial_registration", "tax_id",
                    "commission_type", "commission_value",
                    "bank_name", "iban", "bank_account_number",
                ],
                "classes": ["collapse"],
            },
        ),
        (
            _("Registration status"),
            {"fields": [
                "status", "email_verified", "verified_at",
                "reviewed_by", "reviewed_at", "rejection_note",
            ]},
        ),
        (
            _("Timestamps"),
            {"fields": ["created_at", "updated_at"], "classes": ["collapse"]},
        ),
    ]

    # --- Custom columns ---

    @admin.display(description=_("Owner email"), ordering="user__email")
    def owner_email(self, obj):
        return obj.user.email

    @admin.display(description=_("Status"))
    def status_badge(self, obj):
        colour_map = {
            ProviderStatus.PENDING:   "#F59E0B",
            ProviderStatus.APPROVED:  "#3B82F6",
            ProviderStatus.ACTIVE:    "#10B981",
            ProviderStatus.SUSPENDED: "#6B7280",
            ProviderStatus.REJECTED:  "#EF4444",
        }
        colour = colour_map.get(obj.status, "#6B7280")
        return format_html(
            '<span style="background:{c};color:#fff;padding:3px 10px;'
            'border-radius:12px;font-size:11px;font-weight:600;">{l}</span>',
            c=colour,
            l=obj.get_status_display(),
        )

    # --- Bulk actions ---

    @admin.action(description=_("Approve selected providers"))
    def action_approve(self, request, queryset):
        approved = 0
        skipped  = 0
        for provider in queryset:
            if provider.status in PROVIDER_APPROVABLE_STATES:
                try:
                    ProviderReviewService.approve(
                        provider=provider,
                        reviewed_by=request.user,
                    )
                    approved += 1
                except Exception as exc:
                    logger.error(
                        "Admin approve error | provider: %s | %s",
                        provider.business_name, exc,
                    )
                    skipped += 1
            else:
                skipped += 1

        if approved:
            self.message_user(
                request,
                _(f"{approved} provider(s) approved."),
                messages.SUCCESS,
            )
        if skipped:
            self.message_user(
                request,
                _(f"{skipped} provider(s) skipped (not in PENDING state)."),
                messages.WARNING,
            )

    @admin.action(description=_("Reject selected providers"))
    def action_reject(self, request, queryset):
        """
        Bulk rejection without a note.
        For a rejection with a custom note, use the provider detail page.
        """
        rejected = 0
        skipped  = 0
        for provider in queryset:
            if provider.status in PROVIDER_REJECTABLE_STATES:
                try:
                    ProviderReviewService.reject(
                        provider=provider,
                        reviewed_by=request.user,
                        note="",
                    )
                    rejected += 1
                except Exception as exc:
                    logger.error(
                        "Admin reject error | provider: %s | %s",
                        provider.business_name, exc,
                    )
                    skipped += 1
            else:
                skipped += 1

        if rejected:
            self.message_user(
                request,
                _(f"{rejected} provider(s) rejected."),
                messages.SUCCESS,
            )
        if skipped:
            self.message_user(
                request,
                _(f"{skipped} provider(s) skipped (not in PENDING state)."),
                messages.WARNING,
            )