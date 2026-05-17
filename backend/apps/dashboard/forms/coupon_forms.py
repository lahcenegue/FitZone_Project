# apps/dashboard/forms/coupon_forms.py

from django import forms
from django.utils.translation import gettext_lazy as _
from apps.coupons.models import CouponDefinition, CouponSource
from .constants import BASE_INPUT_CLASS, CHECKBOX_CLASS

class CreateCouponDefinitionForm(forms.ModelForm):
    class Meta:
        model = CouponDefinition
        fields = ['title', 'code', 'coupon_type', 'discount_value', 'max_usage', 'expiration_date', 'is_active']
        widgets = {
            'title': forms.TextInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}),
            'code': forms.TextInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' ', 'style': 'text-transform: uppercase;'}),
            'coupon_type': forms.Select(attrs={'class': BASE_INPUT_CLASS}),
            'discount_value': forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.01', 'min': '0', 'placeholder': ' '}),
            'max_usage': forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'min': '0', 'placeholder': ' '}),
            'expiration_date': forms.DateTimeInput(attrs={'class': BASE_INPUT_CLASS, 'type': 'datetime-local', 'placeholder': ' '}),
            'is_active': forms.CheckboxInput(attrs={'class': CHECKBOX_CLASS}),
        }

    def clean_code(self):
        code = self.cleaned_data.get('code')
        if not code:
            raise forms.ValidationError(_("A public coupon code is strictly required for marketing campaigns."))
        return code.strip().upper()

    def save(self, commit=True):
        instance = super().save(commit=False)
        instance.source = CouponSource.MARKETING
        if commit:
            instance.save()
        return instance