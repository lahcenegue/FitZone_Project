# apps/dashboard/forms/settings_forms.py

import logging
from django import forms
from django.db import transaction
from django.utils.translation import gettext_lazy as _

from apps.core.models import AppConfiguration
from apps.resale.models import ResaleGlobalSetting
from apps.gyms.models import GymGlobalSetting
from apps.loyalty.models import LoyaltyGlobalSetting
from apps.payments.models import PaymentGlobalSetting
from .constants import BASE_INPUT_CLASS, CHECKBOX_CLASS

logger = logging.getLogger(__name__)

class GlobalSettingsForm(forms.Form):
    android_version = forms.CharField(max_length=20, label=_("Android App Version"), widget=forms.TextInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    ios_version = forms.CharField(max_length=20, label=_("iOS App Version"), widget=forms.TextInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    force_update = forms.BooleanField(label=_("Force App Update"), required=False, widget=forms.CheckboxInput(attrs={'class': CHECKBOX_CLASS}))
    update_message = forms.CharField(label=_("Update Message"), required=False, widget=forms.Textarea(attrs={'class': BASE_INPUT_CLASS, 'rows': 5, 'placeholder': ' '}))
    sports_version = forms.FloatField(label=_("Sports Data Version"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.1', 'placeholder': ' '}))
    amenities_version = forms.FloatField(label=_("Amenities Data Version"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.1', 'placeholder': ' '}))
    cities_version = forms.FloatField(label=_("Cities Data Version"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.1', 'placeholder': ' '}))
    service_types_version = forms.FloatField(label=_("Service Types Version"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.1', 'placeholder': ' '}))

    gym_earn_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Gym Earn Rate"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    trainer_earn_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Trainer Earn Rate"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    store_earn_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Store Earn Rate"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    restaurant_earn_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Restaurant Earn Rate"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    point_to_fiat_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Point to Fiat Rate"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    
    max_discount_gym_plan = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Max Points Discount: Gym Plans (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    max_discount_roaming = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Max Points Discount: Roaming (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    max_discount_resale = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Max Points Discount: Resale Market (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    max_discount_packages = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Max Points Discount: Point Packages (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))

    auto_checkout_hours = forms.IntegerField(label=_("Auto Checkout Duration (Hours)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    gym_points_conversion_rate = forms.DecimalField(max_digits=6, decimal_places=2, label=_("Gym Points Conversion Rate"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    roaming_discount_percentage = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Roaming Commission Discount (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))

    app_commission_percentage = forms.DecimalField(max_digits=5, decimal_places=2, label=_("App Commission (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    depreciation_percentage = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Immediate Depreciation (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    minimum_days_buffer = forms.IntegerField(label=_("Minimum Days Buffer"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    escrow_hold_hours = forms.IntegerField(label=_("Escrow Hold Duration (Hours)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))

    vat_percentage = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Global VAT Percentage (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    gym_earnings_hold_days = forms.IntegerField(label=_("Gym Earnings Hold Period (Days)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))
    provider_earnings_hold_days = forms.IntegerField(label=_("Provider Earnings Hold Period (Days)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}))

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if not self.is_bound:
            self._load_initial_data()

    def _load_initial_data(self):
        try:
            core = AppConfiguration.get_solo()
            resale = ResaleGlobalSetting.load()
            gyms = GymGlobalSetting.load()
            loyalty = LoyaltyGlobalSetting.load()
            payments = PaymentGlobalSetting.load()

            self.initial.update({
                'android_version': core.android_version,
                'ios_version': core.ios_version,
                'force_update': core.force_update,
                'update_message': core.update_message,
                'sports_version': core.sports_version,
                'amenities_version': core.amenities_version,
                'cities_version': core.cities_version,
                'service_types_version': core.service_types_version,
                'gym_earn_rate': loyalty.gym_earn_rate,
                'trainer_earn_rate': loyalty.trainer_earn_rate,
                'store_earn_rate': loyalty.store_earn_rate,
                'restaurant_earn_rate': loyalty.restaurant_earn_rate,
                'point_to_fiat_rate': loyalty.point_to_fiat_rate,
                'max_discount_gym_plan': loyalty.max_discount_gym_plan,
                'max_discount_roaming': loyalty.max_discount_roaming,
                'max_discount_resale': loyalty.max_discount_resale,
                'max_discount_packages': loyalty.max_discount_packages,
                'auto_checkout_hours': gyms.auto_checkout_hours,
                'gym_points_conversion_rate': gyms.points_conversion_rate,
                'roaming_discount_percentage': gyms.roaming_discount_percentage,
                'gym_earnings_hold_days': gyms.earnings_hold_days,
                'app_commission_percentage': resale.app_commission_percentage,
                'depreciation_percentage': resale.depreciation_percentage,
                'minimum_days_buffer': resale.minimum_days_buffer,
                'escrow_hold_hours': resale.escrow_hold_hours,
                'vat_percentage': payments.vat_percentage,
                'provider_earnings_hold_days': payments.earnings_hold_days,
            })
        except Exception as e:
            logger.error(f"Failed to load settings: {e}")

    @transaction.atomic
    def save(self):
        try:
            core = AppConfiguration.get_solo()
            resale = ResaleGlobalSetting.load()
            gyms = GymGlobalSetting.load()
            loyalty = LoyaltyGlobalSetting.load()
            payments = PaymentGlobalSetting.load()

            core.android_version = self.cleaned_data['android_version']
            core.ios_version = self.cleaned_data['ios_version']
            core.force_update = self.cleaned_data['force_update']
            core.update_message = self.cleaned_data['update_message']
            core.sports_version = self.cleaned_data['sports_version']
            core.amenities_version = self.cleaned_data['amenities_version']
            core.cities_version = self.cleaned_data['cities_version']
            core.service_types_version = self.cleaned_data['service_types_version']
            core.save()

            loyalty.gym_earn_rate = self.cleaned_data['gym_earn_rate']
            loyalty.trainer_earn_rate = self.cleaned_data['trainer_earn_rate']
            loyalty.store_earn_rate = self.cleaned_data['store_earn_rate']
            loyalty.restaurant_earn_rate = self.cleaned_data['restaurant_earn_rate']
            loyalty.point_to_fiat_rate = self.cleaned_data['point_to_fiat_rate']
            loyalty.max_discount_gym_plan = self.cleaned_data['max_discount_gym_plan']
            loyalty.max_discount_roaming = self.cleaned_data['max_discount_roaming']
            loyalty.max_discount_resale = self.cleaned_data['max_discount_resale']
            loyalty.max_discount_packages = self.cleaned_data['max_discount_packages']
            loyalty.save()

            gyms.auto_checkout_hours = self.cleaned_data['auto_checkout_hours']
            gyms.points_conversion_rate = self.cleaned_data['gym_points_conversion_rate']
            gyms.roaming_discount_percentage = self.cleaned_data['roaming_discount_percentage']
            gyms.earnings_hold_days = self.cleaned_data['gym_earnings_hold_days']
            gyms.save()

            resale.app_commission_percentage = self.cleaned_data['app_commission_percentage']
            resale.depreciation_percentage = self.cleaned_data['depreciation_percentage']
            resale.minimum_days_buffer = self.cleaned_data['minimum_days_buffer']
            resale.escrow_hold_hours = self.cleaned_data['escrow_hold_hours']
            resale.save()

            payments.vat_percentage = self.cleaned_data['vat_percentage']
            payments.earnings_hold_days = self.cleaned_data['provider_earnings_hold_days']
            payments.save()
        except Exception as e:
            logger.error(f"Critical error saving settings: {e}")
            raise forms.ValidationError(_("A critical error occurred while saving the settings."))