"""App configuration for the stores app."""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class StoresConfig(AppConfig):
    """Configuration for the stores application."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.stores"
    verbose_name = _("Stores")