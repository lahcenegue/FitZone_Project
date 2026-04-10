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

    # Version tracking for service types
    service_types_version = models.FloatField(default=1.0, verbose_name=_("Service Types Version"))
    
    # NEW: Premium Membership configuration
    premium_points_required = models.PositiveIntegerField(default=1000, verbose_name=_("Premium Points Required"))
    points_config_version = models.FloatField(default=1.0, verbose_name=_("Points Config Version"))

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
            
        # Auto-increment points_config_version if premium_points_required changes
        if self.pk:
            try:
                old_instance = AppConfiguration.objects.get(pk=self.pk)
                if self.premium_points_required != old_instance.premium_points_required:
                    # Increase version by 0.1 and round it to avoid floating point issues (e.g. 1.10000001)
                    self.points_config_version = round(self.points_config_version + 0.1, 1)
            except AppConfiguration.DoesNotExist:
                pass

        super().save(*args, **kwargs)

    @classmethod
    def get_solo(cls):
        obj, created = cls.objects.get_or_create(id=1)
        return obj
    
class City(models.Model):
    """
    Lookup table for supported cities with dynamic JSON-based translations.
    """
    code = models.CharField(max_length=50, unique=True, help_text="Internal code (e.g., riyadh)")
    name = models.CharField(max_length=100, help_text="Default/Fallback name (e.g., Riyadh)")
    translations = models.JSONField(
        default=dict, 
        blank=True, 
        help_text='Format: {"ar": "الرياض", "en": "Riyadh", "fr": "Riyad"}'
    )
    lat = models.FloatField(null=True, blank=True, verbose_name="Latitude")
    lng = models.FloatField(null=True, blank=True, verbose_name="Longitude")
    
    is_active = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0)

    class Meta:
        verbose_name = _("City")
        verbose_name_plural = _("Cities")
        ordering = ['sort_order', 'name']

    def __str__(self):
        return self.name