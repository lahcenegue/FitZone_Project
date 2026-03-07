"""
Context processors for the FitZone Provider Portal.
Injects portal-wide variables into every template automatically.
Registered in settings TEMPLATES context_processors list.
"""

import logging
from apps.providers.models import ProviderStatus

logger = logging.getLogger(__name__)


def portal_context(request):
    """
    Inject provider portal context into every portal template.

    Provides:
        provider        — Provider instance or None
        provider_type   — string ('gym', 'trainer', etc.) or None
        provider_status — string status or None
        is_gym          — bool
        is_trainer      — bool
        is_restaurant   — bool
        is_store        — bool
        unread_count    — integer count of unread notifications

    Returns:
        Dict of context variables available in all portal templates.
    """
    context = {
        "provider":          None,
        "provider_type":     None,
        "provider_status":   None,
        "is_gym":            False,
        "is_trainer":        False,
        "is_restaurant":     False,
        "is_store":          False,
        "unread_count":      0,
    }

    if not request.user.is_authenticated:
        return context

    if not hasattr(request.user, "provider_profile"):
        return context

    try:
        provider = request.user.provider_profile

        context["provider"]        = provider
        context["provider_type"]   = provider.provider_type
        context["provider_status"] = provider.status
        context["is_gym"]          = provider.provider_type == "gym"
        context["is_trainer"]      = provider.provider_type == "trainer"
        context["is_restaurant"]   = provider.provider_type == "restaurant"
        context["is_store"]        = provider.provider_type == "store"

        # Only query notifications for active providers — skip for pending/suspended
        if provider.status == ProviderStatus.ACTIVE:
            context["unread_count"] = _get_unread_notification_count(provider)

    except Exception as exc:
        logger.error(
            "portal_context processor error | user: %s | error: %s",
            request.user.email, str(exc),
        )

    return context


def _get_unread_notification_count(provider) -> int:
    """
    Return the count of unread notifications for the given provider.
    Returns 0 on any error to never break page rendering.

    Args:
        provider: The authenticated Provider instance.

    Returns:
        Integer count of unread notifications.
    """
    try:
        from apps.notifications.models import Notification
        return Notification.objects.filter(
            recipient=provider.user,
            is_read=False,
        ).count()
    except Exception as exc:
        logger.warning(
            "Failed to fetch notification count | provider: %s | error: %s",
            provider.business_name, str(exc),
        )
        return 0