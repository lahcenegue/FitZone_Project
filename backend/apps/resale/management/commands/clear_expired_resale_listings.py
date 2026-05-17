# apps/resale/management/commands/clear_expired_resale_listings.py

import logging
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.resale.services import ResaleMarketService

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    """
    Django management command to scan and clear resale listings that fell below 
    the dynamic minimum days buffer threshold established in the dashboard settings.
    Usage: python manage.py clear_expired_resale_listings
    """
    help = "Automatically processes active listings and marks them expired if remaining days violate business criteria rules."

    def handle(self, *args, **options):
        self.stdout.write(self.style.WARNING("Starting automated marketplace cleanup protocol..."))
        logger.info("Executing management cron script: clear_expired_resale_listings initiated.")

        try:
            processed_count = ResaleMarketService.expire_invalid_listings()
            
            if processed_count > 0:
                success_msg = f"Successfully updated and deactivated {processed_count} expired listings from the secondary market."
                self.stdout.write(self.style.SUCCESS(success_msg))
            else:
                self.stdout.write(self.style.SUCCESS("Cleanup completed. No active listings violated buffer thresholds today."))

        except Exception as e:
            error_msg = f"Critical failure in marketplace cleanup execution command: {str(e)}"
            logger.error(error_msg)
            self.stdout.write(self.style.ERROR(error_msg))