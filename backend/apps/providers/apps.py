"""
App configuration for the providers app.
"""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class ProvidersConfig(AppConfig):
    """Configuration for the providers application."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.providers"
    verbose_name = _("Providers")