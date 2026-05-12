import logging
from django import forms
from django.db import transaction
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.forms import AuthenticationForm

from apps.core.models import AppConfiguration
from apps.resale.models import ResaleGlobalSetting
from apps.gyms.models import GymGlobalSetting
from apps.loyalty.models import LoyaltyGlobalSetting
from apps.payments.models import PaymentGlobalSetting

logger = logging.getLogger(__name__)

# Ultra-Premium Input Classes
BASE_INPUT_CLASS = 'relative w-full px-5 py-3.5 bg-surface border border-border rounded-xl text-[14px] font-bold text-text-primary focus:border-transparent focus:ring-0 outline-none transition-all shadow-sm z-10'
CURRENCY_INPUT_CLASS = f"{BASE_INPUT_CLASS} pe-14 rtl:ps-14 rtl:pe-5"
CHECKBOX_CLASS = 'w-6 h-6 text-primary bg-surface rounded-md border-border focus:ring-primary cursor-pointer transition-all shadow-sm'

class DashboardLoginForm(AuthenticationForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'].widget.attrs.update({'class': BASE_INPUT_CLASS, 'placeholder': ' '})
        self.fields['password'].widget.attrs.update({'class': BASE_INPUT_CLASS, 'placeholder': ' '})


class GlobalSettingsForm(forms.Form):
    # --- Core App Configuration (No currency needed here) ---
    android_version = forms.CharField(max_length=20, label=_("Android App Version"), help_text=_("Latest version on Play Store."), widget=forms.TextInput(attrs={'class': BASE_INPUT_CLASS}))
    ios_version = forms.CharField(max_length=20, label=_("iOS App Version"), help_text=_("Latest version on App Store."), widget=forms.TextInput(attrs={'class': BASE_INPUT_CLASS}))
    force_update = forms.BooleanField(label=_("Force App Update"), required=False, help_text=_("Force screen update."), widget=forms.CheckboxInput(attrs={'class': CHECKBOX_CLASS}))
    update_message = forms.CharField(label=_("Update Message"), required=False, widget=forms.Textarea(attrs={'class': BASE_INPUT_CLASS, 'rows': 5}))
    
    sports_version = forms.FloatField(label=_("Sports Data Version"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.1'}))
    amenities_version = forms.FloatField(label=_("Amenities Data Version"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.1'}))
    cities_version = forms.FloatField(label=_("Cities Data Version"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.1'}))
    service_types_version = forms.FloatField(label=_("Service Types Version"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.1'}))

    # --- Loyalty & Economy (Use CURRENCY_INPUT_CLASS) ---
    gym_earn_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Gym Earn Rate"), widget=forms.NumberInput(attrs={'class': CURRENCY_INPUT_CLASS}))
    trainer_earn_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Trainer Earn Rate"), widget=forms.NumberInput(attrs={'class': CURRENCY_INPUT_CLASS}))
    store_earn_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Store Earn Rate"), widget=forms.NumberInput(attrs={'class': CURRENCY_INPUT_CLASS}))
    restaurant_earn_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Restaurant Earn Rate"), widget=forms.NumberInput(attrs={'class': CURRENCY_INPUT_CLASS}))
    
    point_to_fiat_rate = forms.DecimalField(max_digits=10, decimal_places=2, label=_("Point to Fiat Rate"), widget=forms.NumberInput(attrs={'class': CURRENCY_INPUT_CLASS}))
    max_global_discount_percent = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Max Global Discount (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))

    # --- Gyms & Roaming ---
    auto_checkout_hours = forms.IntegerField(label=_("Auto Checkout Duration (Hours)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))
    gym_points_conversion_rate = forms.DecimalField(max_digits=6, decimal_places=2, label=_("Gym Points Conversion Rate"), widget=forms.NumberInput(attrs={'class': CURRENCY_INPUT_CLASS}))
    roaming_discount_percentage = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Roaming Commission Discount (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))

    # --- Resale Market ---
    app_commission_percentage = forms.DecimalField(max_digits=5, decimal_places=2, label=_("App Commission (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))
    depreciation_percentage = forms.DecimalField(max_digits=5, decimal_places=2, label=_("Immediate Depreciation (%)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))
    minimum_days_buffer = forms.IntegerField(label=_("Minimum Days Buffer"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))
    escrow_hold_hours = forms.IntegerField(label=_("Escrow Hold Duration (Hours)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))

    # --- Payment & Financial ---
    gym_earnings_hold_days = forms.IntegerField(label=_("Gym Earnings Hold Period (Days)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))
    provider_earnings_hold_days = forms.IntegerField(label=_("Provider Earnings Hold Period (Days)"), widget=forms.NumberInput(attrs={'class': BASE_INPUT_CLASS}))

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
                'max_global_discount_percent': loyalty.max_global_discount_percent,
                'auto_checkout_hours': gyms.auto_checkout_hours,
                'gym_points_conversion_rate': gyms.points_conversion_rate,
                'roaming_discount_percentage': gyms.roaming_discount_percentage,
                'gym_earnings_hold_days': gyms.earnings_hold_days,
                'app_commission_percentage': resale.app_commission_percentage,
                'depreciation_percentage': resale.depreciation_percentage,
                'minimum_days_buffer': resale.minimum_days_buffer,
                'escrow_hold_hours': resale.escrow_hold_hours,
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
            loyalty.max_global_discount_percent = self.cleaned_data['max_global_discount_percent']
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

            payments.earnings_hold_days = self.cleaned_data['provider_earnings_hold_days']
            payments.save()
        except Exception as e:
            logger.error(f"Critical error saving settings: {e}")
            raise forms.ValidationError(_("A critical error occurred while saving the settings."))