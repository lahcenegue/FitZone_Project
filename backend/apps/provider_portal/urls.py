"""
URL configuration for the FitZone Provider Portal.
"""

from django.urls import path
from django.shortcuts import redirect
from apps.providers.models import ProviderStatus
from apps.provider_portal.views import (
    auth_views, dashboard_views, profile_views, gym_views,
    trainer_views, restaurant_views, store_views, earnings_views, verification_views,
)


def login_redirect_view(request):
    """Redirect portal root based on auth and email verification state."""
    if not request.user.is_authenticated or not hasattr(request.user, "provider_profile"):
        return redirect("provider_portal:login")

    provider = request.user.provider_profile

    if provider.status == ProviderStatus.SUSPENDED:
        return redirect("provider_portal:suspended")
        
    if not provider.email_verified:
        return redirect("provider_portal:pending")
        
    return redirect("provider_portal:dashboard")



app_name = "provider_portal"

urlpatterns = [
    # Auth & Verification
    path("", login_redirect_view, name="index"),
    path("login/", auth_views.LoginView.as_view(), name="login"),
    path("register/", auth_views.RegisterView.as_view(), name="register"),
    path("logout/", auth_views.LogoutView.as_view(), name="logout"),
    path("pending/", auth_views.PendingView.as_view(), name="pending"),
    path("suspended/", auth_views.SuspendedView.as_view(), name="suspended"),
    
    # Email Verification Routes
    path("verify-email/<str:token>/", auth_views.VerifyEmailView.as_view(), name="verify_email"),
    path("resend-verification/", auth_views.ResendVerificationView.as_view(), name="resend_verification"),

    # Dashboard
    path("dashboard/", dashboard_views.DashboardView.as_view(), name="dashboard"),
    # Verification
    path("verification/upload/", verification_views.DocumentUploadView.as_view(), name="document_upload"),

    # Notifications
    path("notifications/", dashboard_views.NotificationsView.as_view(), name="notifications"),
    path("notifications/<int:notification_id>/read/", dashboard_views.MarkNotificationReadView.as_view(), name="notification_mark_read"),

    # Profile
    path("profile/", profile_views.ProfileView.as_view(), name="profile"),
    path("profile/security/", profile_views.SecurityView.as_view(), name="security"),
    path("profile/financial/", profile_views.FinancialView.as_view(), name="financial"),

    # Gym
    path("gym/branches/", gym_views.BranchListView.as_view(), name="gym_branches"),
    path("gym/branches/<int:branch_id>/", gym_views.BranchDetailView.as_view(), name="gym_branch_detail"),
    path("gym/branches/add/", gym_views.BranchAddView.as_view(), name="gym_branch_add"),
    path("gym/branches/<int:branch_id>/edit/", gym_views.BranchEditView.as_view(), name="gym_branch_edit"),
    path("gym/branches/<int:branch_id>/delete/", gym_views.BranchDeleteView.as_view(), name="gym_branch_delete"),
    path("gym/branches/<int:branch_id>/photos/", gym_views.BranchPhotosView.as_view(), name="gym_branch_photos"),
    path('gym/branches/<int:branch_id>/quick-toggle/', gym_views.BranchQuickToggleView.as_view(), name='gym_branch_quick_toggle'),
    path("gym/plans/", gym_views.PlanListView.as_view(), name="gym_plans"),
    path("gym/plans/<int:plan_id>/", gym_views.PlanDetailView.as_view(), name="gym_plan_detail"),
    path("gym/plans/add/", gym_views.PlanAddView.as_view(), name="gym_plan_add"),
    path("gym/plans/<int:plan_id>/edit/", gym_views.PlanEditView.as_view(), name="gym_plan_edit"),
    path("gym/plans/<int:plan_id>/toggle/", gym_views.PlanToggleView.as_view(), name="gym_plan_toggle"),
    path("gym/subscribers/", gym_views.SubscriberListView.as_view(), name="gym_subscribers"),

    # Trainer
    path("trainer/profile/", trainer_views.TrainerProfileView.as_view(), name="trainer_profile"),
    path("trainer/availability/", trainer_views.AvailabilityView.as_view(), name="trainer_availability"),
    path("trainer/bookings/", trainer_views.BookingListView.as_view(), name="trainer_bookings"),
    path("trainer/bookings/<int:booking_id>/accept/", trainer_views.BookingAcceptView.as_view(), name="trainer_booking_accept"),
    path("trainer/bookings/<int:booking_id>/reject/", trainer_views.BookingRejectView.as_view(), name="trainer_booking_reject"),

    # Restaurant
    path("restaurant/menu/", restaurant_views.MenuView.as_view(), name="restaurant_menu"),
    path("restaurant/menu/add/", restaurant_views.MenuItemAddView.as_view(), name="restaurant_menu_add"),
    path("restaurant/menu/<int:item_id>/edit/", restaurant_views.MenuItemEditView.as_view(), name="restaurant_menu_edit"),
    path("restaurant/menu/<int:item_id>/delete/", restaurant_views.MenuItemDeleteView.as_view(), name="restaurant_menu_delete"),
    path("restaurant/orders/", restaurant_views.OrderListView.as_view(), name="restaurant_orders"),

    # Store
    path("store/products/", store_views.ProductListView.as_view(), name="store_products"),
    path("store/products/add/", store_views.ProductAddView.as_view(), name="store_product_add"),
    path("store/products/<int:product_id>/edit/", store_views.ProductEditView.as_view(), name="store_product_edit"),
    path("store/products/<int:product_id>/delete/", store_views.ProductDeleteView.as_view(), name="store_product_delete"),
    path("store/orders/", store_views.OrderListView.as_view(), name="store_orders"),

    # Earnings
    path("earnings/", earnings_views.EarningsView.as_view(), name="earnings"),
    path("earnings/withdraw/", earnings_views.WithdrawView.as_view(), name="withdraw"),

    path('api/scan-qr/', gym_views.QRCodeScannerAPIView.as_view(), name='api_scan_qr'),
]