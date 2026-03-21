import logging
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from apps.gyms.models import GymSport, GymAmenity
from apps.core.models import AppConfiguration, City

logger = logging.getLogger(__name__)

def increment_version(field_name):
    """Helper function to increment a specific version field by 0.1"""
    try:
        config = AppConfiguration.get_solo()
        current_version = getattr(config, field_name)
        # Increment by 0.1 and round to 1 decimal place
        setattr(config, field_name, round(current_version + 0.1, 1))
        config.save()
    except Exception as e:
        logger.error(f"Failed to increment {field_name}: {e}")

@receiver([post_save, post_delete], sender=GymSport)
def update_sports_version(sender, instance, **kwargs):
    increment_version('sports_version')

@receiver([post_save, post_delete], sender=GymAmenity)
def update_amenities_version(sender, instance, **kwargs):
    increment_version('amenities_version')

@receiver([post_save, post_delete], sender=City)
def update_cities_version(sender, instance, **kwargs):
    increment_version('cities_version')