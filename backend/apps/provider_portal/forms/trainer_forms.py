"""
Trainer-specific forms for the Provider Portal.
Professional profile and availability management.
"""

import logging
from django import forms
from django.utils.translation import gettext_lazy as _
from ..constants import WEEK_DAYS

logger = logging.getLogger(__name__)

SPECIALIZATION_CHOICES = [
    ("weight_loss",     _("Weight Loss")),
    ("muscle_gain",     _("Muscle Gain")),
    ("rehabilitation",  _("Rehabilitation")),
    ("yoga",            _("Yoga")),
    ("crossfit",        _("CrossFit")),
    ("boxing",          _("Boxing")),
    ("swimming",        _("Swimming")),
    ("nutrition",       _("Nutrition Coaching")),
    ("kids_fitness",    _("Kids Fitness")),
    ("senior_fitness",  _("Senior Fitness")),
]


class TrainerProfileForm(forms.Form):
    """
    Trainer professional profile form.
    Captures certifications, specializations, experience, and pricing.
    """

    bio = forms.CharField(
        label=_("Bio"),
        max_length=2000,
        required=False,
        widget=forms.Textarea(attrs={
            "rows": 5,
            "placeholder": _("Tell clients about your background and approach"),
        }),
    )
    years_of_experience = forms.IntegerField(
        label=_("Years of experience"),
        min_value=0,
        max_value=50,
        widget=forms.NumberInput(attrs={"placeholder": "0"}),
    )
    session_price = forms.DecimalField(
        label=_("Session price (SAR)"),
        max_digits=8,
        decimal_places=2,
        min_value=0,
        widget=forms.NumberInput(attrs={
            "placeholder": "0.00",
            "step": "0.01",
        }),
    )
    specializations = forms.MultipleChoiceField(
        label=_("Specializations"),
        choices=SPECIALIZATION_CHOICES,
        widget=forms.CheckboxSelectMultiple(),
        required=False,
    )
    certification_document = forms.FileField(
        label=_("Certification document"),
        required=False,
        widget=forms.FileInput(attrs={
            "accept": "application/pdf,image/jpeg,image/png",
        }),
        help_text=_("PDF or image. Maximum 10MB."),
    )


class AvailabilityForm(forms.Form):
    """
    Weekly availability schedule for a trainer.
    Each day has an enabled toggle and open/close time.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for day_key, day_label in WEEK_DAYS:
            self.fields[f"{day_key}_enabled"] = forms.BooleanField(
                label=day_label,
                required=False,
            )
            self.fields[f"{day_key}_start"] = forms.TimeField(
                label=_("Start"),
                required=False,
                widget=forms.TimeInput(attrs={"type": "time"}),
            )
            self.fields[f"{day_key}_end"] = forms.TimeField(
                label=_("End"),
                required=False,
                widget=forms.TimeInput(attrs={"type": "time"}),
            )

    def clean(self):
        """Validate that enabled days have valid start and end times."""
        cleaned = super().clean()
        for day_key, day_label in WEEK_DAYS:
            enabled = cleaned.get(f"{day_key}_enabled")
            start   = cleaned.get(f"{day_key}_start")
            end     = cleaned.get(f"{day_key}_end")
            if enabled:
                if not start:
                    self.add_error(
                        f"{day_key}_start",
                        _("Start time is required for %(day)s.") % {"day": day_label},
                    )
                if not end:
                    self.add_error(
                        f"{day_key}_end",
                        _("End time is required for %(day)s.") % {"day": day_label},
                    )
                if start and end and start >= end:
                    self.add_error(
                        f"{day_key}_end",
                        _("End time must be after start time for %(day)s.") % {"day": day_label},
                    )
        return cleaned