"""
Trainer service for the Provider Portal.
Handles trainer profile, availability, and booking management.
"""

import logging
from django.core.paginator import Paginator
from django.utils.translation import gettext_lazy as _
from apps.providers.models import Provider
from apps.trainers.models import TrainerProfile, TrainerAvailability, Booking
from ..constants import PAGE_SIZE_BOOKINGS
from apps.core.constants import WEEK_DAYS

logger = logging.getLogger(__name__)


class TrainerServiceError(Exception):
    """Raised when a trainer operation fails for a known, user-facing reason."""
    pass


def get_or_create_trainer_profile(provider: Provider) -> TrainerProfile:
    """
    Return the trainer profile for the given provider, creating it if needed.

    Args:
        provider: The authenticated Provider instance.

    Returns:
        TrainerProfile instance.
    """
    profile, created = TrainerProfile.objects.get_or_create(provider=provider)
    if created:
        logger.info("Trainer profile created | provider: %s", provider.business_name)
    return profile


def update_trainer_profile(provider: Provider, form_data: dict) -> TrainerProfile:
    """
    Update the trainer's professional profile.

    Args:
        provider: The authenticated Provider instance.
        form_data: Cleaned data from TrainerProfileForm.

    Returns:
        Updated TrainerProfile instance.

    Raises:
        TrainerServiceError: If update fails.
    """
    try:
        profile = get_or_create_trainer_profile(provider)
        profile.bio                  = form_data.get("bio", "")
        profile.years_of_experience  = form_data["years_of_experience"]
        profile.session_price        = form_data["session_price"]
        profile.specializations      = form_data.get("specializations", [])
        profile.save()

        logger.info("Trainer profile updated | provider: %s", provider.business_name)
        return profile

    except Exception as exc:
        logger.error(
            "Trainer profile update failed | provider: %s | error: %s",
            provider.business_name, str(exc),
        )
        raise TrainerServiceError(_("Failed to update profile. Please try again.")) from exc


def save_trainer_availability(provider: Provider, form_data: dict) -> None:
    """
    Replace the trainer's weekly availability schedule.
    Deletes existing schedule and creates fresh entries from form data.
    Wrapped in a transaction.

    Args:
        provider: The authenticated Provider instance.
        form_data: Cleaned data from AvailabilityForm.

    Raises:
        TrainerServiceError: If save fails.
    """
    from django.db import transaction

    try:
        with transaction.atomic():
            TrainerAvailability.objects.filter(provider=provider).delete()

            for day_key, _ in WEEK_DAYS:
                enabled = form_data.get(f"{day_key}_enabled")
                start   = form_data.get(f"{day_key}_start")
                end     = form_data.get(f"{day_key}_end")

                if enabled and start and end:
                    TrainerAvailability.objects.create(
                        provider=provider,
                        day=day_key,
                        start_time=start,
                        end_time=end,
                    )

        logger.info("Availability saved | provider: %s", provider.business_name)

    except Exception as exc:
        logger.error(
            "Availability save failed | provider: %s | error: %s",
            provider.business_name, str(exc),
        )
        raise TrainerServiceError(_("Failed to save availability. Please try again.")) from exc


def get_trainer_availability(provider: Provider) -> dict:
    """
    Return the trainer's current availability as a dict keyed by day.

    Args:
        provider: The authenticated Provider instance.

    Returns:
        Dict mapping day_key to {start_time, end_time}.
    """
    availability = TrainerAvailability.objects.filter(provider=provider)
    return {
        entry.day: {
            "start": entry.start_time.strftime("%H:%M"),
            "end":   entry.end_time.strftime("%H:%M"),
        }
        for entry in availability
    }


def get_provider_bookings(provider: Provider, upcoming_only: bool = False, page: int = 1):
    """
    Return paginated bookings for the given trainer provider.

    Args:
        provider: The authenticated Provider instance.
        upcoming_only: If True, return only future bookings.
        page: Page number for pagination.

    Returns:
        Django Page object containing Booking instances.
    """
    from django.utils import timezone

    qs = Booking.objects.filter(provider=provider).order_by("-booking_date")
    if upcoming_only:
        qs = qs.filter(booking_date__gte=timezone.now())

    paginator = Paginator(qs, PAGE_SIZE_BOOKINGS)
    return paginator.get_page(page)


def get_booking(provider: Provider, booking_id: int) -> Booking:
    """
    Return a single booking that belongs to the given provider.

    Args:
        provider: The authenticated Provider instance.
        booking_id: Primary key of the booking.

    Returns:
        Booking instance.

    Raises:
        TrainerServiceError: If booking not found or belongs to another provider.
    """
    try:
        return Booking.objects.get(id=booking_id, provider=provider)
    except Booking.DoesNotExist:
        raise TrainerServiceError(_("Booking not found."))


def accept_booking(provider: Provider, booking_id: int) -> Booking:
    """
    Accept a pending booking request.

    Args:
        provider: The authenticated Provider instance.
        booking_id: Primary key of the booking.

    Returns:
        Updated Booking instance.

    Raises:
        TrainerServiceError: If booking not found or not in pending state.
    """
    booking = get_booking(provider, booking_id)

    if booking.status != "pending":
        raise TrainerServiceError(_("Only pending bookings can be accepted."))

    booking.status = "accepted"
    booking.save(update_fields=["status", "updated_at"])

    logger.info(
        "Booking accepted | provider: %s | booking: %s",
        provider.business_name, booking_id,
    )
    return booking


def reject_booking(provider: Provider, booking_id: int) -> Booking:
    """
    Reject a pending booking request.

    Args:
        provider: The authenticated Provider instance.
        booking_id: Primary key of the booking.

    Returns:
        Updated Booking instance.

    Raises:
        TrainerServiceError: If booking not found or not in pending state.
    """
    booking = get_booking(provider, booking_id)

    if booking.status != "pending":
        raise TrainerServiceError(_("Only pending bookings can be rejected."))

    booking.status = "rejected"
    booking.save(update_fields=["status", "updated_at"])

    logger.info(
        "Booking rejected | provider: %s | booking: %s",
        provider.business_name, booking_id,
    )
    return booking