"""
Business logic for Gym operations.
Handles QR scanning, live occupancy, auto-checkout, and subscription validation.
"""

import logging
from datetime import timedelta
from django.utils import timezone
from django.db import transaction

from .models import GymSubscription, GymVisit, GymGlobalSetting, GymBranch

logger = logging.getLogger(__name__)


class GymAccessService:
    """Service handling real-time gym access and occupancy tracking."""

    @staticmethod
    def auto_checkout_visitors(branch_id: int = None):
        """
        Automatically check out visitors who exceeded the allowed duration.
        Called before calculating live occupancy.
        """
        settings = GymGlobalSetting.load()
        expiry_time = timezone.now() - timedelta(hours=settings.auto_checkout_hours)

        query = GymVisit.objects.filter(is_active=True, check_in_time__lt=expiry_time)
        
        if branch_id:
            query = query.filter(branch_id=branch_id)

        checked_out_count = query.update(
            is_active=False, 
            check_out_time=timezone.now()
        )
        
        if checked_out_count > 0:
            logger.info("Auto-checked out %s visitors.", checked_out_count)


    @staticmethod
    def get_live_occupancy(branch_id: int) -> int:
        """
        Returns the current number of active visitors in a specific branch.
        """
        # 1. Clean up old visits first
        GymAccessService.auto_checkout_visitors(branch_id=branch_id)
        
        # 2. Return accurate count
        return GymVisit.objects.filter(branch_id=branch_id, is_active=True).count()


    @staticmethod
    @transaction.atomic
    def process_qr_scan(*, qr_code_id: str, branch_id: int) -> dict:
        """
        Validates QR code, checks subscription rules, and creates a check-in visit.
        Returns user details (including photo) for visual verification by receptionist.
        """
        try:
            subscription = GymSubscription.objects.select_related(
                'user', 'plan'
            ).get(qr_code_id=qr_code_id)
        except GymSubscription.DoesNotExist:
            raise ValueError("Invalid QR Code.")

        # 1. Check if subscription is active
        if subscription.status != "active":
            raise ValueError(f"Subscription is {subscription.status}.")

        # 2. Check date validity
        today = timezone.now().date()
        if today < subscription.start_date:
            raise ValueError("Subscription has not started yet.")
        if today > subscription.end_date:
            raise ValueError("Subscription has expired.")

        # 3. Check branch access privileges
        branch = GymBranch.objects.get(id=branch_id)
        if not subscription.plan.branches.filter(id=branch_id).exists():
            raise ValueError("This subscription does not grant access to this branch.")

        # 4. Prevent double check-in (auto-checkout previous active visit for this user)
        GymVisit.objects.filter(
            subscription__user=subscription.user, 
            is_active=True
        ).update(is_active=False, check_out_time=timezone.now())

        # 5. Create new visit (Check-in)
        visit = GymVisit.objects.create(
            subscription=subscription,
            branch=branch,
            is_active=True
        )

        # 6. Return data for visual verification in the frontend/app
        profile_pic_url = None
        if hasattr(subscription.user, 'profile_picture') and subscription.user.profile_picture:
            profile_pic_url = subscription.user.profile_picture.url

        return {
            "visit_id": visit.id,
            "user_name": subscription.user.full_name,
            "user_image": profile_pic_url,
            "plan_name": subscription.plan.name,
            "end_date": subscription.end_date.strftime("%Y-%m-%d"),
            "days_remaining": (subscription.end_date - today).days
        }