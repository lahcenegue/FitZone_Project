# apps/dashboard/forms/__init__.py

from .auth_forms import DashboardLoginForm
from .settings_forms import GlobalSettingsForm
from .coupon_forms import CreateCouponDefinitionForm
from .loyalty_forms import PointPackageForm, MilestoneRewardForm, MilestoneForm

__all__ = [
    'DashboardLoginForm',
    'GlobalSettingsForm',
    'CreateCouponDefinitionForm',
    'PointPackageForm',
    'MilestoneRewardForm',
    'MilestoneForm',
]