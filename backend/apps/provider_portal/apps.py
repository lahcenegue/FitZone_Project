"""App configuration for the provider_portal app."""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class ProviderPortalConfig(AppConfig):
    """Configuration for the provider portal application."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.provider_portal"
    verbose_name = _("Provider Portal")