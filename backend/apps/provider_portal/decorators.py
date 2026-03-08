"""
Access control decorators for the Provider Portal.
Enforces authentication, email verification, and active status.
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
    """Require authenticated user with a provider profile."""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated or not hasattr(request.user, "provider_profile"):
            return redirect(REDIRECT_LOGIN)
        return view_func(request, *args, **kwargs)
    return wrapper


def email_verified_required(view_func):
    """Require verified email. Redirect to pending if not verified."""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        provider = request.user.provider_profile
        
        if provider.status == ProviderStatus.SUSPENDED:
            return redirect(REDIRECT_SUSPENDED)
            
        if not provider.email_verified:
            return redirect(REDIRECT_PENDING)
            
        return view_func(request, *args, **kwargs)
    return wrapper


def active_provider_required(view_func):
    """Require ACTIVE status for managing services/products."""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        provider = request.user.provider_profile
        
        if provider.status != ProviderStatus.ACTIVE:
            messages.warning(
                request,
                _("Your account is under review. You cannot access this feature yet.")
            )
            return redirect(REDIRECT_DASHBOARD)
            
        return view_func(request, *args, **kwargs)
    return wrapper


def provider_type_required(*allowed_types):
    """Restrict view to specific provider types (e.g., 'gym')."""
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            provider = request.user.provider_profile
            if provider.provider_type not in allowed_types:
                messages.error(request, _("You do not have permission to access this page."))
                return redirect(REDIRECT_DASHBOARD)
            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator


def anonymous_required(view_func):
    """Redirect logged-in providers away from auth pages."""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if request.user.is_authenticated and hasattr(request.user, "provider_profile"):
            provider = request.user.provider_profile
            
            if provider.status == ProviderStatus.SUSPENDED:
                return redirect(REDIRECT_SUSPENDED)
                
            if not provider.email_verified:
                return redirect(REDIRECT_PENDING)
                
            return redirect(REDIRECT_DASHBOARD)
        return view_func(request, *args, **kwargs)
    return wrapper