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
            {"code": "riyadh", "name": "Riyadh", "lat": 24.7136, "lng": 46.6753, "translations": {"ar": "الرياض", "en": "Riyadh"}},
            {"code": "jeddah", "name": "Jeddah", "lat": 21.5433, "lng": 39.1728, "translations": {"ar": "جدة", "en": "Jeddah"}},
            {"code": "mecca", "name": "Mecca", "lat": 21.3891, "lng": 39.8579, "translations": {"ar": "مكة المكرمة", "en": "Mecca"}},
            {"code": "medina", "name": "Medina", "lat": 24.5247, "lng": 39.5692, "translations": {"ar": "المدينة المنورة", "en": "Medina"}},
            {"code": "dammam", "name": "Dammam", "lat": 26.4207, "lng": 50.0888, "translations": {"ar": "الدمام", "en": "Dammam"}},
            {"code": "khobar", "name": "Khobar", "lat": 26.2172, "lng": 50.1971, "translations": {"ar": "الخبر", "en": "Khobar"}},
            {"code": "dhahran", "name": "Dhahran", "lat": 26.2361, "lng": 50.0393, "translations": {"ar": "الظهران", "en": "Dhahran"}},
            {"code": "tabuk", "name": "Tabuk", "lat": 28.3835, "lng": 36.5662, "translations": {"ar": "تبوك", "en": "Tabuk"}},
            {"code": "abha", "name": "Abha", "lat": 18.2164, "lng": 42.5053, "translations": {"ar": "أبها", "en": "Abha"}},
            {"code": "khamis_mushait", "name": "Khamis Mushait", "lat": 18.3063, "lng": 42.7392, "translations": {"ar": "خميس مشيط", "en": "Khamis Mushait"}},
            {"code": "hail", "name": "Hail", "lat": 27.5154, "lng": 41.6936, "translations": {"ar": "حائل", "en": "Hail"}},
            {"code": "najran", "name": "Najran", "lat": 17.5021, "lng": 44.1320, "translations": {"ar": "نجران", "en": "Najran"}},
            {"code": "jubail", "name": "Jubail", "lat": 27.0146, "lng": 49.6583, "translations": {"ar": "الجبيل", "en": "Jubail"}},
            {"code": "yanbu", "name": "Yanbu", "lat": 24.0891, "lng": 38.0628, "translations": {"ar": "ينبع", "en": "Yanbu"}},
            {"code": "taif", "name": "Taif", "lat": 21.2854, "lng": 40.4283, "translations": {"ar": "الطائف", "en": "Taif"}},
            {"code": "buraidah", "name": "Buraidah", "lat": 26.3291, "lng": 43.9749, "translations": {"ar": "بريدة", "en": "Buraidah"}},
            {"code": "qatif", "name": "Qatif", "lat": 26.5590, "lng": 50.0104, "translations": {"ar": "القطيف", "en": "Qatif"}},
            {"code": "hofuf", "name": "Hofuf", "lat": 25.3792, "lng": 49.5858, "translations": {"ar": "الهفوف", "en": "Hofuf"}},
            {"code": "jizan", "name": "Jizan", "lat": 16.8892, "lng": 42.5511, "translations": {"ar": "جازان", "en": "Jizan"}},
            {"code": "arar", "name": "Arar", "lat": 30.9833, "lng": 41.0167, "translations": {"ar": "عرعر", "en": "Arar"}},
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
                        'lat': city_data.get('lat'),
                        'lng': city_data.get('lng'),
                        'sort_order': index,
                        'is_active': True
                    }
                )

            self.stdout.write(self.style.SUCCESS(f'Successfully seeded {len(saudi_cities)} cities!'))
            
        except Exception as e:
            logger.error(f"Failed to seed cities: {str(e)}")
            self.stdout.write(self.style.ERROR('An error occurred during seeding. Check logs.'))