"""
Gym-specific forms for the Provider Portal.
Branch management, subscription plans.
"""

import logging
from django import forms
from django.utils.translation import gettext_lazy as _
from apps.gyms.models import GymBranch, GymAmenity, GymSport

logger = logging.getLogger(__name__)


from django import forms
from django.utils.translation import gettext_lazy as _
from apps.gyms.models import GymAmenity, GymSport
from apps.core.constants import WEEK_DAYS, SAUDI_CITIES, BRANCH_GENDER_CHOICES

class BranchForm(forms.Form):
    """
    Add or edit a gym branch.
    Captures location, address, amenities, sports, and operating hours.
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

    # Opening hours
    sunday_open    = forms.TimeField(label=_("Sunday open"),    required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    sunday_close   = forms.TimeField(label=_("Sunday close"),   required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    monday_open    = forms.TimeField(label=_("Monday open"),    required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    monday_close   = forms.TimeField(label=_("Monday close"),   required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    tuesday_open   = forms.TimeField(label=_("Tuesday open"),   required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    tuesday_close  = forms.TimeField(label=_("Tuesday close"),  required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    wednesday_open = forms.TimeField(label=_("Wednesday open"), required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    wednesday_close= forms.TimeField(label=_("Wednesday close"),required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    thursday_open  = forms.TimeField(label=_("Thursday open"),  required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    thursday_close = forms.TimeField(label=_("Thursday close"), required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    friday_open    = forms.TimeField(label=_("Friday open"),    required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    friday_close   = forms.TimeField(label=_("Friday close"),   required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    saturday_open  = forms.TimeField(label=_("Saturday open"),  required=False, widget=forms.TimeInput(attrs={"type": "time"}))
    saturday_close = forms.TimeField(label=_("Saturday close"), required=False, widget=forms.TimeInput(attrs={"type": "time"}))

    def clean_city(self):
        city = self.cleaned_data["city"]
        if not city:
            raise forms.ValidationError(_("Please select a city."))
        return city

    def clean(self):
        cleaned = super().clean()
        for day, _ in WEEK_DAYS:
            open_time  = cleaned.get(f"{day}_open")
            close_time = cleaned.get(f"{day}_close")
            if open_time and close_time and open_time >= close_time:
                self.add_error(
                    f"{day}_close",
                    _("Closing time must be after opening time."),
                )
        return cleaned


class SubscriptionPlanForm(forms.Form):
    """
    Form for creating and editing subscription plans.
    Injects the provider instance to filter available branches dynamically.
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
    
    # Branch assignment (ModelMultipleChoiceField)
    branches = forms.ModelMultipleChoiceField(
        queryset=GymBranch.objects.none(), # Populated dynamically in __init__
        widget=forms.CheckboxSelectMultiple,
        required=True,
        label=_("Available Branches")
    )

    # Hidden field to capture dynamic tags for features
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
        # Extract provider from kwargs before initializing the superclass
        provider = kwargs.pop('provider', None)
        super().__init__(*args, **kwargs)
        
        if provider:
            # FIX: Removed is_active=True so pending providers can see their branches
            self.fields['branches'].queryset = GymBranch.objects.filter(provider=provider)