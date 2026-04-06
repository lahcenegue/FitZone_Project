from django.urls import path
from .views import (
    CustomerRegisterView, CustomerLoginView, CustomerProfileCompletionView,
    CustomerVerifyEmailView, CustomerResendVerificationView,
    CustomerPasswordResetRequestView, CustomerPasswordResetConfirmView
)

app_name = "users_api"

urlpatterns = [
    path("register/", CustomerRegisterView.as_view(), name="customer-register"),
    path("login/", CustomerLoginView.as_view(), name="customer-login"),
    path("verify-email/", CustomerVerifyEmailView.as_view(), name="customer-verify-email"),
    path("resend-verification/", CustomerResendVerificationView.as_view(), name="customer-resend-verification"),
    path("profile/complete/", CustomerProfileCompletionView.as_view(), name="profile-complete"),
    path("password-reset/request/", CustomerPasswordResetRequestView.as_view(), name="password-reset-request"),
    path("password-reset/confirm/", CustomerPasswordResetConfirmView.as_view(), name="password-reset-confirm"),
]