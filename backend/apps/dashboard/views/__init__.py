# apps/dashboard/views/__init__.py

from .auth_views import DashboardLoginView, DashboardLogoutView
from .home_views import DashboardHomeView
from .settings_views import GlobalSettingsView
from .coupon_views import (
    ManageCouponsListView, CreateCouponView, 
    UpdateCouponView, DeleteCouponView
)
from .loyalty_views import (  
    PointPackageListView, PointPackageCreateView, 
    PointPackageUpdateView, PointPackageDeleteView,
    RewardListView, RewardCreateView, RewardUpdateView, RewardDeleteView,
    MilestoneListView, MilestoneCreateView, MilestoneUpdateView, MilestoneDeleteView,
    ClaimsLedgerListView 
)

__all__ = [
    'DashboardLoginView', 'DashboardLogoutView',
    'DashboardHomeView', 'GlobalSettingsView',
    'ManageCouponsListView', 'CreateCouponView', 
    'UpdateCouponView', 'DeleteCouponView',
    'PointPackageListView', 'PointPackageCreateView',
    'PointPackageUpdateView', 'PointPackageDeleteView',
    'RewardListView', 'RewardCreateView', 'RewardUpdateView', 'RewardDeleteView',
    'MilestoneListView', 'MilestoneCreateView', 'MilestoneUpdateView', 'MilestoneDeleteView',
    'ClaimsLedgerListView' 
]