"""
URL configuration for the providers app API.

Mounted in config/urls.py as:
    path("api/v1/providers/", include("apps.providers.urls")),
"""

from django.urls import path

from .views import (
    ProviderRegisterView,
    ProviderRegistrationStatusView,
    ResendVerificationView,
    VerifyEmailView,
    ProviderLoginView,
    ProviderLogoutView,
)

app_name = "providers_api"

urlpatterns = [
    # Public — no authentication required
    path("register/",             ProviderRegisterView.as_view(),        name="register"),
    path("verify-email/",         VerifyEmailView.as_view(),             name="verify-email"),
    path("resend-verification/",  ResendVerificationView.as_view(),      name="resend-verification"),
    path("login/",                ProviderLoginView.as_view(),           name="login"),

    # Authenticated — requires JWT Bearer token
    path("logout/",               ProviderLogoutView.as_view(),          name="logout"),
    path("registration-status/",  ProviderRegistrationStatusView.as_view(), name="registration-status"),
]