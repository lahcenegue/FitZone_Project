"""
Gym service for the Provider Portal.
Handles branch and subscription plan management.
All database operations for gym providers live here.
"""

import logging
from django.db import transaction
from django.utils.translation import gettext_lazy as _
from django.core.paginator import Paginator
from apps.providers.models import Provider
from apps.gyms.models import Branch, SubscriptionPlan
from apps.core.constants import PAGE_SIZE_DEFAULT

logger = logging.getLogger(__name__)


class GymServiceError(Exception):
    """Raised when a gym operation fails for a known, user-facing reason."""
    pass


# ---------------------------------------------------------------------------
# Branch operations
# ---------------------------------------------------------------------------

def get_provider_branches(provider: Provider, page: int = 1):
    """
    Return a paginated list of branches for the given provider.

    Args:
        provider: The authenticated Provider instance.
        page: Page number for pagination.

    Returns:
        Django Page object containing Branch instances.
    """
    branches = Branch.objects.filter(
        provider=provider
    ).order_by("-created_at")

    paginator = Paginator(branches, PAGE_SIZE_DEFAULT)
    return paginator.get_page(page)


def get_branch(provider: Provider, branch_id: int) -> Branch:
    """
    Return a single branch that belongs to the given provider.

    Args:
        provider: The authenticated Provider instance.
        branch_id: Primary key of the branch.

    Returns:
        Branch instance.

    Raises:
        GymServiceError: If branch does not exist or belongs to another provider.
    """
    try:
        return Branch.objects.get(id=branch_id, provider=provider)
    except Branch.DoesNotExist:
        raise GymServiceError(_("Branch not found."))


def create_branch(provider: Provider, form_data: dict) -> Branch:
    """
    Create a new branch for the given provider.

    Args:
        provider: The authenticated Provider instance.
        form_data: Cleaned data from BranchForm.

    Returns:
        Newly created Branch instance.

    Raises:
        GymServiceError: If creation fails.
    """
    try:
        opening_hours = _extract_opening_hours(form_data)

        location = None
        latitude  = form_data.get("latitude")
        longitude = form_data.get("longitude")
        if latitude and longitude:
            from django.contrib.gis.geos import Point
            location = Point(float(longitude), float(latitude), srid=4326)

        branch = Branch.objects.create(
            provider=provider,
            name=form_data["name"],
            city=form_data["city"],
            address=form_data["address"],
            phone_number=form_data.get("phone_number", ""),
            location=location,
            opening_hours=opening_hours,
            is_active=form_data.get("is_active", True),
        )

        logger.info(
            "Branch created | provider: %s | branch: %s | city: %s",
            provider.business_name, branch.name, branch.city,
        )
        return branch

    except GymServiceError:
        raise
    except Exception as exc:
        logger.error("Branch creation failed | provider: %s | error: %s", provider.business_name, str(exc))
        raise GymServiceError(_("Failed to create branch. Please try again.")) from exc


def update_branch(provider: Provider, branch_id: int, form_data: dict) -> Branch:
    """
    Update an existing branch.

    Args:
        provider: The authenticated Provider instance.
        branch_id: Primary key of the branch to update.
        form_data: Cleaned data from BranchForm.

    Returns:
        Updated Branch instance.

    Raises:
        GymServiceError: If branch not found or update fails.
    """
    branch = get_branch(provider, branch_id)

    try:
        opening_hours = _extract_opening_hours(form_data)

        latitude  = form_data.get("latitude")
        longitude = form_data.get("longitude")
        if latitude and longitude:
            from django.contrib.gis.geos import Point
            branch.location = Point(float(longitude), float(latitude), srid=4326)

        branch.name          = form_data["name"]
        branch.city          = form_data["city"]
        branch.address       = form_data["address"]
        branch.phone_number  = form_data.get("phone_number", "")
        branch.opening_hours = opening_hours
        branch.is_active     = form_data.get("is_active", True)
        branch.save()

        logger.info(
            "Branch updated | provider: %s | branch: %s",
            provider.business_name, branch.name,
        )
        return branch

    except GymServiceError:
        raise
    except Exception as exc:
        logger.error("Branch update failed | branch_id: %s | error: %s", branch_id, str(exc))
        raise GymServiceError(_("Failed to update branch. Please try again.")) from exc


def delete_branch(provider: Provider, branch_id: int) -> None:
    """
    Delete a branch that belongs to the given provider.

    Args:
        provider: The authenticated Provider instance.
        branch_id: Primary key of the branch to delete.

    Raises:
        GymServiceError: If branch not found or deletion fails.
    """
    branch = get_branch(provider, branch_id)

    try:
        branch_name = branch.name
        branch.delete()
        logger.info(
            "Branch deleted | provider: %s | branch: %s",
            provider.business_name, branch_name,
        )
    except GymServiceError:
        raise
    except Exception as exc:
        logger.error("Branch deletion failed | branch_id: %s | error: %s", branch_id, str(exc))
        raise GymServiceError(_("Failed to delete branch. Please try again.")) from exc


def _extract_opening_hours(form_data: dict) -> dict:
    """
    Extract opening hours from flat form data into a structured dict.

    Args:
        form_data: Cleaned form data containing {day}_open and {day}_close fields.

    Returns:
        Dict mapping day names to {open, close} time strings.
    """
    from apps.core.constants import WEEK_DAYS
    hours = {}
    for day_key, _ in WEEK_DAYS:
        open_time  = form_data.get(f"{day_key}_open")
        close_time = form_data.get(f"{day_key}_close")
        if open_time and close_time:
            hours[day_key] = {
                "open":  open_time.strftime("%H:%M"),
                "close": close_time.strftime("%H:%M"),
            }
    return hours


# ---------------------------------------------------------------------------
# Subscription plan operations
# ---------------------------------------------------------------------------

def get_provider_plans(provider: Provider, page: int = 1):
    """
    Return a paginated list of subscription plans for the given provider.

    Args:
        provider: The authenticated Provider instance.
        page: Page number for pagination.

    Returns:
        Django Page object containing SubscriptionPlan instances.
    """
    plans = SubscriptionPlan.objects.filter(
        provider=provider
    ).order_by("-created_at")

    paginator = Paginator(plans, PAGE_SIZE_DEFAULT)
    return paginator.get_page(page)


def get_plan(provider: Provider, plan_id: int) -> SubscriptionPlan:
    """
    Return a single subscription plan that belongs to the given provider.

    Args:
        provider: The authenticated Provider instance.
        plan_id: Primary key of the plan.

    Returns:
        SubscriptionPlan instance.

    Raises:
        GymServiceError: If plan not found or belongs to another provider.
    """
    try:
        return SubscriptionPlan.objects.get(id=plan_id, provider=provider)
    except SubscriptionPlan.DoesNotExist:
        raise GymServiceError(_("Subscription plan not found."))


def create_plan(provider: Provider, form_data: dict) -> SubscriptionPlan:
    """
    Create a new subscription plan for the given provider.

    Args:
        provider: The authenticated Provider instance.
        form_data: Cleaned data from SubscriptionPlanForm.

    Returns:
        Newly created SubscriptionPlan instance.

    Raises:
        GymServiceError: If creation fails.
    """
    try:
        plan = SubscriptionPlan.objects.create(
            provider=provider,
            name=form_data["name"],
            description=form_data.get("description", ""),
            duration_days=form_data["duration_days"],
            price=form_data["price"],
            is_transferable=form_data.get("is_transferable", False),
            is_active=form_data.get("is_active", True),
            features=form_data.get("features", []),
        )

        logger.info(
            "Plan created | provider: %s | plan: %s | price: %s",
            provider.business_name, plan.name, plan.price,
        )
        return plan

    except Exception as exc:
        logger.error("Plan creation failed | provider: %s | error: %s", provider.business_name, str(exc))
        raise GymServiceError(_("Failed to create plan. Please try again.")) from exc


def update_plan(provider: Provider, plan_id: int, form_data: dict) -> SubscriptionPlan:
    """
    Update an existing subscription plan.

    Args:
        provider: The authenticated Provider instance.
        plan_id: Primary key of the plan to update.
        form_data: Cleaned data from SubscriptionPlanForm.

    Returns:
        Updated SubscriptionPlan instance.

    Raises:
        GymServiceError: If plan not found or update fails.
    """
    plan = get_plan(provider, plan_id)

    try:
        plan.name            = form_data["name"]
        plan.description     = form_data.get("description", "")
        plan.duration_days   = form_data["duration_days"]
        plan.price           = form_data["price"]
        plan.is_transferable = form_data.get("is_transferable", False)
        plan.is_active       = form_data.get("is_active", True)
        plan.features        = form_data.get("features", [])
        plan.save()

        logger.info(
            "Plan updated | provider: %s | plan: %s",
            provider.business_name, plan.name,
        )
        return plan

    except GymServiceError:
        raise
    except Exception as exc:
        logger.error("Plan update failed | plan_id: %s | error: %s", plan_id, str(exc))
        raise GymServiceError(_("Failed to update plan. Please try again.")) from exc


def toggle_plan_status(provider: Provider, plan_id: int) -> SubscriptionPlan:
    """
    Toggle a subscription plan between active and inactive.

    Args:
        provider: The authenticated Provider instance.
        plan_id: Primary key of the plan.

    Returns:
        Updated SubscriptionPlan instance.

    Raises:
        GymServiceError: If plan not found.
    """
    plan = get_plan(provider, plan_id)
    plan.is_active = not plan.is_active
    plan.save(update_fields=["is_active", "updated_at"])

    logger.info(
        "Plan status toggled | provider: %s | plan: %s | active: %s",
        provider.business_name, plan.name, plan.is_active,
    )
    return plan