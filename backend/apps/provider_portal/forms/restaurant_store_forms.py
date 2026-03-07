"""
Restaurant and Store forms for the Provider Portal.
Menu items, products, and order status management.
"""

import logging
from django import forms
from django.utils.translation import gettext_lazy as _

logger = logging.getLogger(__name__)


class MenuItemForm(forms.Form):
    """
    Add or edit a restaurant menu item.
    """

    name = forms.CharField(
        label=_("Item name"),
        max_length=255,
        widget=forms.TextInput(attrs={
            "placeholder": _("e.g. Grilled Chicken Salad"),
        }),
    )
    category = forms.CharField(
        label=_("Category"),
        max_length=100,
        widget=forms.TextInput(attrs={
            "placeholder": _("e.g. Salads, Main Course"),
        }),
    )
    description = forms.CharField(
        label=_("Description"),
        max_length=500,
        required=False,
        widget=forms.Textarea(attrs={
            "rows": 3,
            "placeholder": _("Ingredients, preparation notes"),
        }),
    )
    price = forms.DecimalField(
        label=_("Price (SAR)"),
        max_digits=8,
        decimal_places=2,
        min_value=0,
        widget=forms.NumberInput(attrs={
            "placeholder": "0.00",
            "step": "0.01",
        }),
    )
    calories = forms.IntegerField(
        label=_("Calories"),
        min_value=0,
        required=False,
        widget=forms.NumberInput(attrs={"placeholder": "0"}),
    )
    is_available = forms.BooleanField(
        label=_("Available"),
        required=False,
        initial=True,
    )
    photo = forms.ImageField(
        label=_("Photo"),
        required=False,
        widget=forms.FileInput(attrs={"accept": "image/jpeg,image/png,image/webp"}),
    )


class ProductForm(forms.Form):
    """
    Add or edit a store product.
    """

    name = forms.CharField(
        label=_("Product name"),
        max_length=255,
        widget=forms.TextInput(attrs={
            "placeholder": _("e.g. Whey Protein 1kg"),
        }),
    )
    category = forms.CharField(
        label=_("Category"),
        max_length=100,
        widget=forms.TextInput(attrs={
            "placeholder": _("e.g. Supplements, Equipment"),
        }),
    )
    description = forms.CharField(
        label=_("Description"),
        max_length=500,
        required=False,
        widget=forms.Textarea(attrs={
            "rows": 3,
            "placeholder": _("Product details, specifications"),
        }),
    )
    price = forms.DecimalField(
        label=_("Price (SAR)"),
        max_digits=8,
        decimal_places=2,
        min_value=0,
        widget=forms.NumberInput(attrs={
            "placeholder": "0.00",
            "step": "0.01",
        }),
    )
    stock_quantity = forms.IntegerField(
        label=_("Stock quantity"),
        min_value=0,
        initial=0,
        widget=forms.NumberInput(attrs={"placeholder": "0"}),
    )
    sku = forms.CharField(
        label=_("SKU"),
        max_length=100,
        required=False,
        widget=forms.TextInput(attrs={"placeholder": _("Product code")}),
    )
    is_available = forms.BooleanField(
        label=_("Available"),
        required=False,
        initial=True,
    )
    photo = forms.ImageField(
        label=_("Photo"),
        required=False,
        widget=forms.FileInput(attrs={"accept": "image/jpeg,image/png,image/webp"}),
    )


class WithdrawalRequestForm(forms.Form):
    """
    Provider withdrawal request form.
    Validates amount is within allowed range and bank details are confirmed.
    """

    amount = forms.DecimalField(
        label=_("Withdrawal amount (SAR)"),
        max_digits=10,
        decimal_places=2,
        min_value=0,
        widget=forms.NumberInput(attrs={
            "placeholder": "0.00",
            "step": "0.01",
        }),
    )
    notes = forms.CharField(
        label=_("Notes"),
        max_length=500,
        required=False,
        widget=forms.Textarea(attrs={
            "rows": 2,
            "placeholder": _("Optional notes for this withdrawal"),
        }),
    )
    confirm_bank_details = forms.BooleanField(
        label=_("I confirm my bank details are correct"),
        required=True,
    )

    def clean_amount(self):
        """Validate withdrawal amount is within allowed limits."""
        from ..constants import WITHDRAWAL_MIN_AMOUNT, WITHDRAWAL_MAX_AMOUNT
        amount = self.cleaned_data["amount"]
        if amount < WITHDRAWAL_MIN_AMOUNT:
            raise forms.ValidationError(
                _("Minimum withdrawal amount is %(min)s SAR.") % {
                    "min": WITHDRAWAL_MIN_AMOUNT
                }
            )
        if amount > WITHDRAWAL_MAX_AMOUNT:
            raise forms.ValidationError(
                _("Maximum withdrawal amount is %(max)s SAR.") % {
                    "max": WITHDRAWAL_MAX_AMOUNT
                }
            )
        return amount