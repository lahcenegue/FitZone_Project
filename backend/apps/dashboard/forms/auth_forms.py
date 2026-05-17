# apps/dashboard/forms/auth_forms.py

from django.contrib.auth.forms import AuthenticationForm
from .constants import BASE_INPUT_CLASS

class DashboardLoginForm(AuthenticationForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'].widget.attrs.update({'class': BASE_INPUT_CLASS, 'placeholder': ' '})
        self.fields['password'].widget.attrs.update({'class': BASE_INPUT_CLASS, 'placeholder': ' '})