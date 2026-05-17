# apps/dashboard/urls.py

from django.urls import path
from .views import (
    DashboardHomeView, GlobalSettingsView, 
    DashboardLoginView, DashboardLogoutView,
    ManageCouponsListView, CreateCouponView, UpdateCouponView, DeleteCouponView,
    PointPackageListView, PointPackageCreateView, PointPackageUpdateView, PointPackageDeleteView,
    RewardListView, RewardCreateView, RewardUpdateView, RewardDeleteView,
    MilestoneListView, MilestoneCreateView, MilestoneUpdateView, MilestoneDeleteView,
    ClaimsLedgerListView  # <-- تمت إضافته هنا
)

app_name = "dashboard"

urlpatterns = [
    path('login/', DashboardLoginView.as_view(), name='login'),
    path('logout/', DashboardLogoutView.as_view(), name='logout'),
    path('', DashboardHomeView.as_view(), name='home'),
    path('settings/', GlobalSettingsView.as_view(), name='settings'),
    
    # Coupons Management
    path('coupons/', ManageCouponsListView.as_view(), name='coupons_list'),
    path('coupons/create/', CreateCouponView.as_view(), name='create_coupon'),
    path('coupons/<int:pk>/edit/', UpdateCouponView.as_view(), name='update_coupon'),
    path('coupons/<int:pk>/delete/', DeleteCouponView.as_view(), name='delete_coupon'),
    
    # Loyalty Management (Point Packages)
    path('loyalty/packages/', PointPackageListView.as_view(), name='packages_list'),
    path('loyalty/packages/create/', PointPackageCreateView.as_view(), name='create_package'),
    path('loyalty/packages/<int:pk>/edit/', PointPackageUpdateView.as_view(), name='update_package'),
    path('loyalty/packages/<int:pk>/delete/', PointPackageDeleteView.as_view(), name='delete_package'),

    # Loyalty Management (Rewards Catalog)
    path('loyalty/rewards/', RewardListView.as_view(), name='rewards_list'),
    path('loyalty/rewards/create/', RewardCreateView.as_view(), name='create_reward'),
    path('loyalty/rewards/<int:pk>/edit/', RewardUpdateView.as_view(), name='update_reward'),
    path('loyalty/rewards/<int:pk>/delete/', RewardDeleteView.as_view(), name='delete_reward'),

    # Loyalty Management (Milestones)
    path('loyalty/milestones/', MilestoneListView.as_view(), name='milestones_list'),
    path('loyalty/milestones/create/', MilestoneCreateView.as_view(), name='create_milestone'),
    path('loyalty/milestones/<int:pk>/edit/', MilestoneUpdateView.as_view(), name='update_milestone'),
    path('loyalty/milestones/<int:pk>/delete/', MilestoneDeleteView.as_view(), name='delete_milestone'),

    # Loyalty Management (Claims Ledger)
    path('loyalty/ledger/', ClaimsLedgerListView.as_view(), name='claims_ledger'), # <-- المسار الجديد
]