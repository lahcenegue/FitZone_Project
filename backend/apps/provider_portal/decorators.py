"""
Access control decorators for the FitZone Provider Portal.
Applied to every portal view to enforce authentication and status checks.
All business logic for redirect decisions lives here — never in views.
"""

import logging
from functools import wraps
from django.shortcuts import redirect
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from apps.providers.models import ProviderStatus
from .constants import REDIRECT_LOGIN, REDIRECT_DASHBOARD, REDIRECT_PENDING, REDIRECT_SUSPENDED

logger = logging.getLogger(__name__)


def portal_login_required(view_func):
    """
    Require the user to be authenticated in the provider portal session.
    Redirects unauthenticated users to the portal login page.
    Does not use Django's login_required — portal has its own session logic.
    """
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            logger.debug("Unauthenticated access attempt to %s", request.path)
            return redirect(REDIRECT_LOGIN)
        if not hasattr(request.user, "provider_profile"):
            logger.warning(
                "Non-provider user %s attempted portal access at %s",
                request.user.email, request.path,
            )
            return redirect(REDIRECT_LOGIN)
        return view_func(request, *args, **kwargs)
    return wrapper


def active_provider_required(view_func):
    """
    Require the provider to have ACTIVE status.
    PENDING providers → redirect to pending page.
    SUSPENDED providers → redirect to suspended page.
    Must be applied after @portal_login_required.
    """
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return redirect(REDIRECT_LOGIN)

        try:
            provider = request.user.provider_profile
        except Exception:
            return redirect(REDIRECT_LOGIN)

        if provider.status == ProviderStatus.PENDING:
            return redirect(REDIRECT_PENDING)

        if provider.status == ProviderStatus.APPROVED:
            # Approved but not yet active — treat same as pending for now
            return redirect(REDIRECT_PENDING)

        if provider.status == ProviderStatus.SUSPENDED:
            logger.warning(
                "Suspended provider %s attempted to access %s",
                request.user.email, request.path,
            )
            return redirect(REDIRECT_SUSPENDED)

        return view_func(request, *args, **kwargs)
    return wrapper


def provider_type_required(*allowed_types):
    """
    Restrict a view to specific provider types.
    Used to protect gym-only, trainer-only, etc. pages.

    Usage:
        @portal_login_required
        @active_provider_required
        @provider_type_required('gym')
        def my_gym_view(request): ...

    Args:
        *allowed_types: One or more provider type strings (e.g. 'gym', 'trainer').
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            try:
                provider = request.user.provider_profile
            except Exception:
                return redirect(REDIRECT_LOGIN)

            if provider.provider_type not in allowed_types:
                logger.warning(
                    "Provider %s (type=%s) attempted to access restricted page %s",
                    request.user.email, provider.provider_type, request.path,
                )
                messages.error(
                    request,
                    _("You do not have permission to access this page."),
                )
                return redirect(REDIRECT_DASHBOARD)

            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator


def anonymous_required(view_func):
    """
    Redirect authenticated active providers away from public pages (login, register).
    Prevents logged-in providers from seeing the login form.
    """
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if request.user.is_authenticated and hasattr(request.user, "provider_profile"):
            provider = request.user.provider_profile
            if provider.status == ProviderStatus.ACTIVE:
                return redirect(REDIRECT_DASHBOARD)
            if provider.status in (ProviderStatus.PENDING, ProviderStatus.APPROVED):
                return redirect(REDIRECT_PENDING)
            if provider.status == ProviderStatus.SUSPENDED:
                return redirect(REDIRECT_SUSPENDED)
        return view_func(request, *args, **kwargs)
    return wrapper