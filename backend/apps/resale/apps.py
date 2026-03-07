"""App configuration for the resale app."""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class ResaleConfig(AppConfig):
    """Configuration for the resale application."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.resale"
    verbose_name = _("Resale")