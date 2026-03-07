"""
Gym-specific forms for the Provider Portal.
Branch management, subscription plans.
"""

import logging
from django import forms
from django.utils.translation import gettext_lazy as _
from ..constants import SAUDI_CITIES, WEEK_DAYS

logger = logging.getLogger(__name__)


class BranchForm(forms.Form):
    """
    Add or edit a gym branch.
    Captures location, address, and operating hours.
    """

    name = forms.CharField(
        label=_("Branch name"),
        max_length=255,
        widget=forms.TextInput(attrs={
            "placeholder": _("e.g. Main Branch - Riyadh"),
        }),
    )
    city = forms.ChoiceField(
        label=_("City"),
        choices=[("", _("Select a city"))] + list(SAUDI_CITIES),
    )
    address = forms.CharField(
        label=_("Address"),
        max_length=512,
        widget=forms.TextInput(attrs={
            "placeholder": _("Street, district, building number"),
        }),
    )
    latitude = forms.DecimalField(
        label=_("Latitude"),
        max_digits=9,
        decimal_places=6,
        required=False,
        widget=forms.HiddenInput(),
    )
    longitude = forms.DecimalField(
        label=_("Longitude"),
        max_digits=9,
        decimal_places=6,
        required=False,
        widget=forms.HiddenInput(),
    )
    phone_number = forms.CharField(
        label=_("Branch phone number"),
        max_length=20,
        required=False,
        widget=forms.TextInput(attrs={"placeholder": _("05XXXXXXXX")}),
    )
    is_active = forms.BooleanField(
        label=_("Active"),
        required=False,
        initial=True,
    )

    # Opening hours — one open/close pair per day
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
        """Validate a city was selected."""
        city = self.cleaned_data["city"]
        if not city:
            raise forms.ValidationError(_("Please select a city."))
        return city

    def clean(self):
        """Validate open time is before close time for each day."""
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
    Add or edit a gym subscription plan.
    Defines pricing, duration, and transferability.
    """

    name = forms.CharField(
        label=_("Plan name"),
        max_length=255,
        widget=forms.TextInput(attrs={
            "placeholder": _("e.g. Monthly Premium"),
        }),
    )
    description = forms.CharField(
        label=_("Description"),
        max_length=1000,
        required=False,
        widget=forms.Textarea(attrs={
            "rows": 3,
            "placeholder": _("What is included in this plan?"),
        }),
    )
    duration_days = forms.IntegerField(
        label=_("Duration (days)"),
        min_value=1,
        max_value=3650,
        widget=forms.NumberInput(attrs={"placeholder": _("e.g. 30")}),
    )
    price = forms.DecimalField(
        label=_("Price (SAR)"),
        max_digits=8,
        decimal_places=2,
        min_value=0,
        widget=forms.NumberInput(attrs={
            "placeholder": _("0.00"),
            "step": "0.01",
        }),
    )
    is_transferable = forms.BooleanField(
        label=_("Transferable (can be resold)"),
        required=False,
        initial=False,
    )
    is_active = forms.BooleanField(
        label=_("Active"),
        required=False,
        initial=True,
    )
    features = forms.CharField(
        label=_("Features"),
        required=False,
        widget=forms.Textarea(attrs={
            "rows": 3,
            "placeholder": _("One feature per line"),
        }),
        help_text=_("Enter each feature on a new line."),
    )

    def clean_features(self):
        """Parse features text into a clean list, removing empty lines."""
        raw = self.cleaned_data.get("features", "")
        lines = [line.strip() for line in raw.splitlines() if line.strip()]
        return lines