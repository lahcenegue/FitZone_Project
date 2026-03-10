"""
Forms for provider verification process.
Handles file validation, size limits, and security checks.
"""

from django import forms
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError

def validate_file_size(file):
    """Validator to ensure uploaded files do not exceed 5MB."""
    max_size_kb = 5120  # 5 Megabytes
    if file.size > max_size_kb * 1024:
        raise ValidationError(_("File size cannot exceed 5MB."))

class DocumentUploadForm(forms.Form):
    """
    Form to collect mandatory verification documents from the provider.
    These files will be mapped to the ProviderDocument model.
    """
    commercial_register = forms.FileField(
        label=_("Commercial Register"),
        help_text=_("Accepted formats: PDF, JPG, PNG. Max size: 5MB."),
        validators=[validate_file_size]
    )
    owner_id = forms.FileField(
        label=_("Owner ID / Passport"),
        help_text=_("Accepted formats: PDF, JPG, PNG. Max size: 5MB."),
        validators=[validate_file_size]
    )