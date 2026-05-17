# apps/resale/tasks.py

import logging
from celery import shared_task
from apps.resale.services import ResaleMarketService

logger = logging.getLogger(__name__)

@shared_task(name="apps.resale.tasks.run_marketplace_cleanup_cron")
def run_marketplace_cleanup_cron():
    """
    Automated background Celery task executed daily via Celery Beat schedules.
    Clears out decayed resale items below the dashboard's dynamic minimum day thresholds.
    """
    logger.info("Celery beat scheduler triggered run_marketplace_cleanup_cron task.")
    try:
        expired_count = ResaleMarketService.expire_invalid_listings()
        logger.info(f"Automated marketplace cleanup completed. {expired_count} records marked expired.")
        return f"Success: {expired_count} listings cleared."
    except Exception as e:
        logger.critical(f"Celery marketplace cleanup cron crashed: {str(e)}")
        return f"Failed: {str(e)}"