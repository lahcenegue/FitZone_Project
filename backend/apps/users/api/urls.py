from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    CustomerRegisterView, 
    CustomerLoginView, 
    CustomerProfileCompletionView,
    CustomerVerifyEmailView, 
    CustomerResendVerificationView,
    CustomerPasswordResetRequestView, 
    CustomerPasswordResetConfirmView,
    CustomerProfileUpdateView, 
    CustomerAvatarUpdateView,
    CustomerChangePasswordView,
    CustomerAccountDeleteView,
    CustomerLogoutView,
    UserSubscriptionsAPIView
)

app_name = "users_api"

urlpatterns = [
    # Auth & Tokens
    path("register/", CustomerRegisterView.as_view(), name="customer-register"),
    path("login/", CustomerLoginView.as_view(), name="customer-login"),
    path("logout/", CustomerLogoutView.as_view(), name="customer-logout"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    
    # Verification & Password Reset
    path("verify-email/", CustomerVerifyEmailView.as_view(), name="customer-verify-email"),
    path("resend-verification/", CustomerResendVerificationView.as_view(), name="customer-resend-verification"),
    path("password-reset/request/", CustomerPasswordResetRequestView.as_view(), name="password-reset-request"),
    path("password-reset/confirm/", CustomerPasswordResetConfirmView.as_view(), name="password-reset-confirm"),  
    
    # Profile Management
    path("profile/complete/", CustomerProfileCompletionView.as_view(), name="profile-complete"),
    path("profile/change-password/", CustomerChangePasswordView.as_view(), name="profile-change-password"),
    path("profile/avatar/", CustomerAvatarUpdateView.as_view(), name="profile-avatar-update"),
    path("profile/update/", CustomerProfileUpdateView.as_view(), name="profile-update"),
    path("profile/delete/", CustomerAccountDeleteView.as_view(), name="profile-delete"),
    
    # Unified User Dashboard Endpoints
    path("my-subscriptions/", UserSubscriptionsAPIView.as_view(), name="my-subscriptions"),
]