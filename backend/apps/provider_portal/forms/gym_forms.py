"""
Gym-specific forms for the Provider Portal.
Branch management, subscription plans.
"""

import logging
from django import forms
from django.utils.translation import gettext_lazy as _
from apps.gyms.models import GymBranch, GymAmenity, GymSport, GymTier
from apps.core.constants import WEEK_DAYS, SAUDI_CITIES, BRANCH_GENDER_CHOICES

logger = logging.getLogger(__name__)

class BranchForm(forms.Form):
    """
    Add or edit a gym branch.
    Captures location, address, amenities, sports, operating hours via JSON, and roaming settings.
    """
    name = forms.CharField(
        label=_("Branch name"),
        max_length=255,
        widget=forms.TextInput(attrs={"placeholder": _("e.g. Main Branch - Riyadh")}),
    )
    city = forms.ChoiceField(
        label=_("City"),
        choices=[("", _("Select a city"))] + list(SAUDI_CITIES),
    )
    address = forms.CharField(
        label=_("Address"),
        max_length=512,
        widget=forms.TextInput(attrs={
            "readonly": "readonly",
            "placeholder": _("Will be auto-filled from the map"),
            "style": "background-color: var(--color-bg); cursor: not-allowed;"
        }),
    )
    latitude = forms.DecimalField(max_digits=9, decimal_places=6, required=False, widget=forms.HiddenInput())
    longitude = forms.DecimalField(max_digits=9, decimal_places=6, required=False, widget=forms.HiddenInput())
    
    phone_number = forms.CharField(
        label=_("Branch phone number"),
        max_length=20,
        required=False,
        widget=forms.TextInput(attrs={"placeholder": _("05XXXXXXXX")}),
    )
    is_active = forms.BooleanField(label=_("Active"), required=False, initial=True)
    is_temporarily_closed = forms.BooleanField(label=_("Emergency Close"), required=False, initial=False)
    
    description = forms.CharField(
        label=_("Branch Description"),
        required=False,
        widget=forms.Textarea(attrs={
            "rows": 3,
            "placeholder": _("Describe this branch, its atmosphere, and rules..."),
        }),
    )

    gender = forms.ChoiceField(
        label=_("Target Gender"),
        choices=BRANCH_GENDER_CHOICES,
        widget=forms.RadioSelect(attrs={'class': 'gender-radio'}),
        initial="mixed"
    )
    
    max_capacity = forms.IntegerField(
        label=_("Maximum Capacity"), 
        required=False, 
        initial=100
    )
    
    estimated_stay_duration = forms.IntegerField(
        label=_("Estimated Stay Duration"), required=False, initial=120
    )
    
    sports = forms.ModelMultipleChoiceField(
        queryset=GymSport.objects.all(),
        widget=forms.SelectMultiple(attrs={
            'class': 'select2-multi form-control', 
            'data-placeholder': _('Select sports...')
        }),
        required=False,
        label=_("Types of Sports Offered")
    )
    
    amenities = forms.ModelMultipleChoiceField(
        queryset=GymAmenity.objects.all(),
        widget=forms.SelectMultiple(attrs={
            'class': 'select2-multi form-control', 
            'data-placeholder': _('Select amenities...')
        }),
        required=False,
        label=_("Branch Amenities")
    )
    
    branch_logo = forms.ImageField(label=_("Branch Logo (Optional)"), required=False)

    # --- TIER REQUEST FIELD ---
    requested_tier = forms.ModelChoiceField(
        queryset=GymTier.objects.all(),
        required=False,
        label=_("Request Tier Upgrade"),
        empty_label=_("Keep Current Tier"),
        widget=forms.Select(attrs={'class': 'modern-select'})
    )

    # --- ROAMING FIELDS ---
    is_roaming_enabled = forms.BooleanField(
        label=_("Enable Roaming"),
        required=False,
        initial=False,
    )
    roaming_visit_price = forms.DecimalField(
        label=_("Roaming Visit Price (SAR)"),
        max_digits=10,
        decimal_places=2,
        required=False,
        initial=0.00,
        min_value=0.00,
        widget=forms.NumberInput(attrs={"placeholder": "0.00", "step": "0.50"}),
    )

    # --- SMART SCHEDULE DATA ---
    schedule_data = forms.CharField(
        widget=forms.HiddenInput(),
        required=False
    )

    def clean_city(self):
        city = self.cleaned_data["city"]
        if not city:
            raise forms.ValidationError(_("Please select a city."))
        return city

    def clean(self):
        """
        Strict backend validation for Roaming economy rules.
        """
        cleaned_data = super().clean()
        is_roaming_enabled = cleaned_data.get('is_roaming_enabled')
        roaming_visit_price = cleaned_data.get('roaming_visit_price')
        
        if is_roaming_enabled:
            if not roaming_visit_price or roaming_visit_price <= 0:
                self.add_error('roaming_visit_price', _("A valid visit price is required to enable roaming."))
        else:
            cleaned_data['roaming_visit_price'] = 0.00
            
        return cleaned_data


class SubscriptionPlanForm(forms.Form):
    """
    Form for creating and editing subscription plans.
    """
    name = forms.CharField(
        label=_("Plan Name"),
        max_length=255,
        widget=forms.TextInput(attrs={"placeholder": _("e.g. Monthly Premium")}),
    )
    description = forms.CharField(
        label=_("Plan Description"),
        max_length=1000,
        required=False,
        widget=forms.Textarea(attrs={"rows": 3, "placeholder": _("What is included in this plan?")}),
    )
    duration_days = forms.IntegerField(
        label=_("Duration in Days"),
        min_value=1,
        widget=forms.NumberInput(attrs={"placeholder": "30"}),
    )
    price = forms.DecimalField(
        label=_("Price"),
        max_digits=8,
        decimal_places=2,
        min_value=0,
        widget=forms.NumberInput(attrs={"placeholder": "0.00", "step": "0.01"}),
    )
    
    branches = forms.ModelMultipleChoiceField(
        queryset=GymBranch.objects.none(),
        widget=forms.CheckboxSelectMultiple,
        required=True,
        label=_("Available Branches")
    )

    amenities = forms.ModelMultipleChoiceField(
        queryset=GymAmenity.objects.all(),
        widget=forms.SelectMultiple(attrs={
            'class': 'select2-multi form-control', 
            'data-placeholder': _('Select amenities included...')
        }),
        required=False,
        label=_("Included Amenities")
    )
    
    sports = forms.ModelMultipleChoiceField(
        queryset=GymSport.objects.all(),
        widget=forms.SelectMultiple(attrs={
            'class': 'select2-multi form-control', 
            'data-placeholder': _('Select sports included...')
        }),
        required=False,
        label=_("Included Sports")
    )

    custom_features = forms.CharField(
        required=False,
        widget=forms.HiddenInput(attrs={"id": "hidden_features"})
    )
    
    is_active = forms.BooleanField(
        label=_("Is Active"),
        required=False,
        initial=True,
    )

    def __init__(self, *args, **kwargs):
        provider = kwargs.pop('provider', None)
        super().__init__(*args, **kwargs)
        if provider:
            self.fields['branches'].queryset = GymBranch.objects.filter(provider=provider)