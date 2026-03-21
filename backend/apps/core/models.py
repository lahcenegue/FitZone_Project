from django.db import models
from django.utils.translation import gettext_lazy as _

class AppConfiguration(models.Model):
    """
    Singleton model to hold global app configurations and data versions.
    Used by the mobile app's /init/ endpoint to manage caching and force updates.
    """
    # Static Data Versions
    sports_version = models.FloatField(default=1.0, verbose_name=_("Sports Data Version"))
    amenities_version = models.FloatField(default=1.0, verbose_name=_("Amenities Data Version"))
    cities_version = models.FloatField(default=1.0, verbose_name=_("Cities Data Version"))
    
    # App Update Management
    android_version = models.CharField(max_length=20, default="1.0.0", verbose_name=_("Android App Version"))
    ios_version = models.CharField(max_length=20, default="1.0.0", verbose_name=_("iOS App Version"))
    force_update = models.BooleanField(default=False, verbose_name=_("Force App Update"))
    update_message = models.TextField(blank=True, verbose_name=_("Update Message"))

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("App Configuration")
        verbose_name_plural = _("App Configuration")

    def __str__(self):
        return "Global App Configuration"

    def save(self, *args, **kwargs):
        # Ensure only one instance exists (Singleton pattern)
        if not self.pk and AppConfiguration.objects.exists():
            return
        super().save(*args, **kwargs)

    @classmethod
    def get_solo(cls):
        obj, created = cls.objects.get_or_create(id=1)
        return obj