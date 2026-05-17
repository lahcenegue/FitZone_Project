# apps/dashboard/forms/loyalty_forms.py

from django import forms
from django.utils.translation import gettext_lazy as _
from apps.loyalty.models import PointPackage, MilestoneReward, Milestone, RewardActionType, DiscountType
from .constants import BASE_INPUT_CLASS, CHECKBOX_CLASS

class PointPackageForm(forms.ModelForm):
    class Meta:
        model = PointPackage
        fields = ['name', 'points', 'price', 'is_active']
        widgets = {
            'name': forms.TextInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}),
            'points': forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'min': '1', 'placeholder': ' '}),
            'price': forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.01', 'min': '0', 'placeholder': ' '}),
            'is_active': forms.CheckboxInput(attrs={'class': CHECKBOX_CLASS}),
        }


class MilestoneRewardForm(forms.ModelForm):
    class Meta:
        model = MilestoneReward
        fields = ['name', 'action_type', 'action_value', 'discount_type', 'is_active']
        widgets = {
            'name': forms.TextInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}),
            'action_type': forms.Select(attrs={'class': BASE_INPUT_CLASS}),
            'action_value': forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'step': '0.01', 'min': '0', 'placeholder': ' '}),
            'discount_type': forms.Select(attrs={'class': BASE_INPUT_CLASS}),
            'is_active': forms.CheckboxInput(attrs={'class': CHECKBOX_CLASS}),
        }

    def clean(self):
        cleaned_data = super().clean()
        action_type = cleaned_data.get('action_type')
        discount_type = cleaned_data.get('discount_type')

        # Business Logic Validation: Ensure discount_type is selected if action type is coupon
        if action_type == RewardActionType.GENERATE_COUPON and not discount_type:
            self.add_error('discount_type', _("You must select a Discount Type (Percentage or Fixed) when the action type is 'Discount Coupon'."))
        
        return cleaned_data


class MilestoneForm(forms.ModelForm):
    class Meta:
        model = Milestone
        fields = ['title', 'required_lifetime_points', 'reward', 'description', 'is_active']
        widgets = {
            'title': forms.TextInput(attrs={'class': BASE_INPUT_CLASS, 'placeholder': ' '}),
            'required_lifetime_points': forms.NumberInput(attrs={'class': BASE_INPUT_CLASS, 'min': '0', 'placeholder': ' '}),
            'reward': forms.Select(attrs={'class': BASE_INPUT_CLASS}),
            'description': forms.Textarea(attrs={'class': BASE_INPUT_CLASS, 'rows': 3, 'placeholder': ' '}),
            'is_active': forms.CheckboxInput(attrs={'class': CHECKBOX_CLASS}),
        }
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Only show active rewards to be linked with milestones
        self.fields['reward'].queryset = MilestoneReward.objects.filter(is_active=True)