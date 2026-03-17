"""
Authentication forms for the Provider Portal.
Handles registration (4 steps) and login.
All validation logic lives here — never in views.
"""

import logging
import re
from django import forms
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from apps.providers.models import ProviderType
from ..constants import (
    PASSWORD_MIN_LENGTH,
    PHONE_PREFIX,
    PHONE_MAX_LENGTH,
)
from apps.core.constants import SAUDI_CITIES

logger = logging.getLogger(__name__)
User = get_user_model()


class RegistrationStep1Form(forms.Form):
    """
    Step 1 of provider registration — personal account details.
    Validates email uniqueness, phone format, and password strength.
    """

    full_name = forms.CharField(
        label=_("Full name"),
        max_length=255,
        widget=forms.TextInput(attrs={
            "placeholder": _("Enter your full name"),
            "autocomplete": "name",
        }),
    )
    email = forms.EmailField(
        label=_("Email address"),
        widget=forms.EmailInput(attrs={
            "placeholder": _("example@domain.com"),
            "autocomplete": "email",
        }),
    )
    phone_number = forms.CharField(
        label=_("Phone number"),
        max_length=PHONE_MAX_LENGTH,
        widget=forms.TextInput(attrs={
            "placeholder": _("05XXXXXXXX"),
            "autocomplete": "tel",
        }),
    )
    password = forms.CharField(
        label=_("Password"),
        widget=forms.PasswordInput(attrs={
            "placeholder": _("Minimum 8 characters"),
            "autocomplete": "new-password",
        }),
    )
    password_confirm = forms.CharField(
        label=_("Confirm password"),
        widget=forms.PasswordInput(attrs={
            "placeholder": _("Repeat your password"),
            "autocomplete": "new-password",
        }),
    )

    def clean_email(self):
        """Validate email is not already registered."""
        email = self.cleaned_data["email"].lower().strip()
        if User.objects.filter(email=email).exists():
            raise forms.ValidationError(
                _("This email address is already registered.")
            )
        return email

    def clean_phone_number(self):
        """
        Validate Saudi phone number format.
        Accepts: 05XXXXXXXX or +9665XXXXXXXX
        Normalizes to +966XXXXXXXXX format.
        """
        phone = self.cleaned_data["phone_number"].strip()

        # Normalize local format to international
        if phone.startswith("05") and len(phone) == 10:
            phone = PHONE_PREFIX + phone[1:]
        elif phone.startswith("5") and len(phone) == 9:
            phone = PHONE_PREFIX + phone

        pattern = r"^\+9665\d{8}$"
        if not re.match(pattern, phone):
            raise forms.ValidationError(
                _("Enter a valid Saudi phone number (e.g. 0512345678).")
            )
        return phone

    def clean_password(self):
        """Validate password meets minimum length requirement."""
        password = self.cleaned_data["password"]
        if len(password) < PASSWORD_MIN_LENGTH:
            raise forms.ValidationError(
                _("Password must be at least %(min)d characters long.") % {
                    "min": PASSWORD_MIN_LENGTH
                }
            )
        return password

    def clean(self):
        """Validate passwords match."""
        cleaned = super().clean()
        password = cleaned.get("password")
        password_confirm = cleaned.get("password_confirm")
        if password and password_confirm and password != password_confirm:
            self.add_error("password_confirm", _("Passwords do not match."))
        return cleaned


class RegistrationStep2Form(forms.Form):
    """
    Step 2 of provider registration — provider type selection.
    Single field: which type of service provider are they.
    """

    provider_type = forms.ChoiceField(
        label=_("Provider type"),
        choices=ProviderType.choices,
        widget=forms.RadioSelect(),
    )

    def clean_provider_type(self):
        """Validate the selected provider type is a valid choice."""
        value = self.cleaned_data["provider_type"]
        valid_types = [choice[0] for choice in ProviderType.choices]
        if value not in valid_types:
            raise forms.ValidationError(_("Please select a valid provider type."))
        return value


class RegistrationStep3Form(forms.Form):
    """
    Step 3 of provider registration — business information.
    Captures business identity and legal registration details.
    """

    business_name = forms.CharField(
        label=_("Business name"),
        max_length=255,
        widget=forms.TextInput(attrs={
            "placeholder": _("Your gym, studio, or brand name"),
        }),
    )
    city = forms.ChoiceField(
        label=_("City"),
        choices=[("", _("Select a city"))] + list(SAUDI_CITIES),
    )
    commercial_registration = forms.CharField(
        label=_("Commercial registration number"),
        max_length=100,
        required=False,
        widget=forms.TextInput(attrs={
            "placeholder": _("CR number (optional)"),
        }),
    )
    tax_id = forms.CharField(
        label=_("Tax ID number"),
        max_length=100,
        required=False,
        widget=forms.TextInput(attrs={
            "placeholder": _("VAT registration number (optional)"),
        }),
    )
    description = forms.CharField(
        label=_("Brief description"),
        max_length=1000,
        required=False,
        widget=forms.Textarea(attrs={
            "rows": 4,
            "placeholder": _("Tell clients what makes your service unique"),
        }),
    )

    def clean_city(self):
        """Validate a city was selected."""
        city = self.cleaned_data["city"]
        if not city:
            raise forms.ValidationError(_("Please select your city."))
        return city


class LoginForm(forms.Form):
    """
    Provider portal login form.
    Email + password authentication.
    """

    email = forms.EmailField(
        label=_("Email address"),
        widget=forms.EmailInput(attrs={
            "placeholder": _("example@domain.com"),
            "autocomplete": "email",
        }),
    )
    password = forms.CharField(
        label=_("Password"),
        widget=forms.PasswordInput(attrs={
            "placeholder": _("Your password"),
            "autocomplete": "current-password",
        }),
    )

    def clean_email(self):
        """Normalize email to lowercase."""
        return self.cleaned_data["email"].lower().strip()