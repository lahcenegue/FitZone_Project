import logging
from django.core.management.base import BaseCommand
from apps.core.models import City

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    """
    Management command to automatically populate the City table 
    with Saudi cities and their proper JSON translations.
    Usage: python manage.py seed_cities
    """
    help = 'Seeds the database with standard Saudi cities and translations'

    def handle(self, *args, **kwargs):
        # Comprehensive dictionary of Saudi cities with pre-defined translations
        saudi_cities = [
            {"code": "riyadh", "name": "Riyadh", "translations": {"ar": "الرياض", "en": "Riyadh"}},
            {"code": "jeddah", "name": "Jeddah", "translations": {"ar": "جدة", "en": "Jeddah"}},
            {"code": "mecca", "name": "Mecca", "translations": {"ar": "مكة المكرمة", "en": "Mecca"}},
            {"code": "medina", "name": "Medina", "translations": {"ar": "المدينة المنورة", "en": "Medina"}},
            {"code": "dammam", "name": "Dammam", "translations": {"ar": "الدمام", "en": "Dammam"}},
            {"code": "khobar", "name": "Khobar", "translations": {"ar": "الخبر", "en": "Khobar"}},
            {"code": "dhahran", "name": "Dhahran", "translations": {"ar": "الظهران", "en": "Dhahran"}},
            {"code": "tabuk", "name": "Tabuk", "translations": {"ar": "تبوك", "en": "Tabuk"}},
            {"code": "abha", "name": "Abha", "translations": {"ar": "أبها", "en": "Abha"}},
            {"code": "khamis_mushait", "name": "Khamis Mushait", "translations": {"ar": "خميس مشيط", "en": "Khamis Mushait"}},
            {"code": "hail", "name": "Hail", "translations": {"ar": "حائل", "en": "Hail"}},
            {"code": "najran", "name": "Najran", "translations": {"ar": "نجران", "en": "Najran"}},
            {"code": "jubail", "name": "Jubail", "translations": {"ar": "الجبيل", "en": "Jubail"}},
            {"code": "yanbu", "name": "Yanbu", "translations": {"ar": "ينبع", "en": "Yanbu"}},
            {"code": "taif", "name": "Taif", "translations": {"ar": "الطائف", "en": "Taif"}},
            {"code": "buraidah", "name": "Buraidah", "translations": {"ar": "بريدة", "en": "Buraidah"}},
            {"code": "qatif", "name": "Qatif", "translations": {"ar": "القطيف", "en": "Qatif"}},
            {"code": "hofuf", "name": "Hofuf", "translations": {"ar": "الهفوف", "en": "Hofuf"}},
            {"code": "jizan", "name": "Jizan", "translations": {"ar": "جازان", "en": "Jizan"}},
            {"code": "arar", "name": "Arar", "translations": {"ar": "عرعر", "en": "Arar"}},
        ]

        try:
            self.stdout.write("Starting city seeding process...")
            
            # Use update_or_create to prevent duplicates if script is run multiple times
            for index, city_data in enumerate(saudi_cities):
                City.objects.update_or_create(
                    code=city_data['code'],
                    defaults={
                        'name': city_data['name'],
                        'translations': city_data['translations'],
                        'sort_order': index,
                        'is_active': True
                    }
                )

            self.stdout.write(self.style.SUCCESS(f'Successfully seeded {len(saudi_cities)} cities!'))
            
        except Exception as e:
            logger.error(f"Failed to seed cities: {str(e)}")
            self.stdout.write(self.style.ERROR('An error occurred during seeding. Check logs.'))