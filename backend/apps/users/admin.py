"""
Admin configuration for the User model.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin panel configuration for the custom User model."""

    list_display = ["email", "full_name", "role", "is_active", "is_verified", "date_joined"]
    list_filter = ["role", "is_active", "is_verified", "is_premium", "gender"]
    search_fields = ["email", "full_name", "phone_number"]
    ordering = ["-date_joined"]

    fieldsets = (
        (_("Credentials"), {"fields": ("email", "password")}),
        (_("Personal info"), {"fields": ("full_name", "phone_number", "phone_verified", "avatar", "date_of_birth", "gender")}),
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