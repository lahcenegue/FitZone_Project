"""App configuration for the gyms app."""

from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class GymsConfig(AppConfig):
    """Configuration for the gyms application."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.gyms"
    verbose_name = _("Gyms")