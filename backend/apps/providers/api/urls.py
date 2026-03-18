from django.urls import path
from .views import (
    ProviderRegisterView, ProviderRegistrationStatusView, ResendVerificationView,
    VerifyEmailView, ProviderLoginView, ProviderLogoutView
)
from .search_views import UnifiedSearchAPIView

app_name = "providers_api"

urlpatterns = [
    path("register/", ProviderRegisterView.as_view(), name="register"),
    path("verify-email/", VerifyEmailView.as_view(), name="verify-email"),
    path("resend-verification/", ResendVerificationView.as_view(), name="resend-verification"),
    path("login/", ProviderLoginView.as_view(), name="login"),
    path("logout/", ProviderLogoutView.as_view(), name="logout"),
    path("registration-status/", ProviderRegistrationStatusView.as_view(), name="registration-status"),
    
    # The Ultimate Single Endpoint for Map, List, Search, and Filters
    path("discover/", UnifiedSearchAPIView.as_view(), name="discover"),
]