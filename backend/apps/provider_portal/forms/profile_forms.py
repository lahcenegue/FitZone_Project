"""
Profile management forms for the Provider Portal.
Personal info, business info, financial info, and password change.
"""

import logging
from django import forms
from django.utils.translation import gettext_lazy as _
from ..constants import SAUDI_CITIES, PHONE_PREFIX, PHONE_MAX_LENGTH
import re

logger = logging.getLogger(__name__)


class PersonalInfoForm(forms.Form):
    """
    Update provider's personal information.
    Linked to the User model fields.
    """

    full_name = forms.CharField(
        label=_("Full name"),
        max_length=255,
        widget=forms.TextInput(attrs={"autocomplete": "name"}),
    )
    phone_number = forms.CharField(
        label=_("Phone number"),
        max_length=PHONE_MAX_LENGTH,
        widget=forms.TextInput(attrs={
            "placeholder": _("05XXXXXXXX"),
            "autocomplete": "tel",
        }),
    )
    avatar = forms.ImageField(
        label=_("Profile photo"),
        required=False,
        widget=forms.FileInput(attrs={"accept": "image/jpeg,image/png,image/webp"}),
    )

    def clean_phone_number(self):
        """Normalize and validate Saudi phone number."""
        phone = self.cleaned_data["phone_number"].strip()
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


class BusinessInfoForm(forms.Form):
    """
    Update provider's business information.
    Linked to the Provider model fields.
    """

    business_name = forms.CharField(
        label=_("Business name"),
        max_length=255,
    )
    description = forms.CharField(
        label=_("Description"),
        max_length=1000,
        required=False,
        widget=forms.Textarea(attrs={"rows": 4}),
    )
    city = forms.ChoiceField(
        label=_("City"),
        choices=[("", _("Select a city"))] + list(SAUDI_CITIES),
    )
    address = forms.CharField(
        label=_("Address"),
        max_length=512,
        required=False,
        widget=forms.TextInput(attrs={
            "placeholder": _("Street, district, building"),
        }),
    )
    commercial_registration = forms.CharField(
        label=_("Commercial registration number"),
        max_length=100,
        required=False,
    )
    tax_id = forms.CharField(
        label=_("Tax ID number"),
        max_length=100,
        required=False,
    )
    logo = forms.ImageField(
        label=_("Business logo"),
        required=False,
        widget=forms.FileInput(attrs={"accept": "image/jpeg,image/png,image/webp"}),
    )

    def clean_city(self):
        """Validate a city was selected."""
        city = self.cleaned_data["city"]
        if not city:
            raise forms.ValidationError(_("Please select your city."))
        return city


class FinancialInfoForm(forms.Form):
    """
    Update provider's bank and payment details.
    Data is encrypted before being saved to the database.
    """

    bank_name = forms.CharField(
        label=_("Bank name"),
        max_length=255,
        widget=forms.TextInput(attrs={
            "placeholder": _("e.g. Al Rajhi Bank"),
        }),
    )
    iban = forms.CharField(
        label=_("IBAN"),
        max_length=34,
        widget=forms.TextInput(attrs={
            "placeholder": _("SA followed by 22 digits"),
            "autocomplete": "off",
        }),
    )
    bank_account_number = forms.CharField(
        label=_("Bank account number"),
        max_length=100,
        required=False,
        widget=forms.TextInput(attrs={"autocomplete": "off"}),
    )

    def clean_iban(self):
        """Validate Saudi IBAN format: SA followed by 22 digits."""
        iban = self.cleaned_data["iban"].strip().upper().replace(" ", "")
        if not re.match(r"^SA\d{22}$", iban):
            raise forms.ValidationError(
                _("Enter a valid Saudi IBAN (SA followed by 22 digits).")
            )
        return iban


class PasswordChangeForm(forms.Form):
    """
    Change provider account password.
    Requires current password for verification.
    """

    current_password = forms.CharField(
        label=_("Current password"),
        widget=forms.PasswordInput(attrs={"autocomplete": "current-password"}),
    )
    new_password = forms.CharField(
        label=_("New password"),
        widget=forms.PasswordInput(attrs={"autocomplete": "new-password"}),
    )
    new_password_confirm = forms.CharField(
        label=_("Confirm new password"),
        widget=forms.PasswordInput(attrs={"autocomplete": "new-password"}),
    )

    def clean_new_password(self):
        """Validate new password meets minimum length."""
        from ..constants import PASSWORD_MIN_LENGTH
        password = self.cleaned_data["new_password"]
        if len(password) < PASSWORD_MIN_LENGTH:
            raise forms.ValidationError(
                _("Password must be at least %(min)d characters long.") % {
                    "min": PASSWORD_MIN_LENGTH
                }
            )
        return password

    def clean(self):
        """Validate new passwords match."""
        cleaned = super().clean()
        new_password = cleaned.get("new_password")
        new_password_confirm = cleaned.get("new_password_confirm")
        if new_password and new_password_confirm and new_password != new_password_confirm:
            self.add_error("new_password_confirm", _("Passwords do not match."))
        return cleaned