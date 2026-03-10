from django.views.generic import FormView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from django.contrib.auth import update_session_auth_hash
from django.contrib.auth import get_user_model

from apps.provider_portal.forms.profile_forms import BusinessInfoForm, FinancialInfoForm, PasswordChangeForm
from apps.providers.models import ProviderDocument

User = get_user_model()

class ProfileView(LoginRequiredMixin, FormView):
    template_name = "provider_portal/profile/edit.html"
    form_class = BusinessInfoForm
    success_url = reverse_lazy("provider_portal:profile")

    def get_initial(self):
        provider = self.request.user.provider_profile
        return {
            'email': self.request.user.email,
            'business_name': provider.business_name,
            'business_phone': provider.business_phone,
            'description': provider.description,
            'city': provider.city,
            'address': provider.address,
            'commercial_registration': provider.commercial_registration,
            'tax_id': provider.tax_id,
        }

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        provider = self.request.user.provider_profile
        context['provider'] = provider
        context['current_documents'] = provider.documents.all() 
        return context

    def form_valid(self, form):
        user = self.request.user
        provider = user.provider_profile
        data = form.cleaned_data

        new_email = data['email']
        if User.objects.filter(email=new_email).exclude(pk=user.pk).exists():
            form.add_error('email', _("This email is already in use by another account."))
            return self.form_invalid(form)
            
        user.email = new_email
        user.save(update_fields=['email'])

        provider.business_name = data['business_name']
        provider.business_phone = data['business_phone']
        provider.description = data.get('description', '')
        provider.city = data['city']
        provider.address = data.get('address', '')
        provider.commercial_registration = data.get('commercial_registration', '')
        provider.tax_id = data.get('tax_id', '')

        if data.get('logo'):
            provider.logo = data['logo']

        provider.save()

        documents = self.request.FILES.getlist('commercial_register_document')
        for doc in documents:
            ProviderDocument.objects.create(
                provider=provider,
                title=doc.name,
                file=doc,
                status="pending"
            )

        messages.success(self.request, _("Business profile updated successfully."))
        return super().form_valid(form)


class FinancialView(LoginRequiredMixin, FormView):
    template_name = "provider_portal/profile/financial.html"
    form_class = FinancialInfoForm
    success_url = reverse_lazy("provider_portal:financial")

    def get_initial(self):
        provider = self.request.user.provider_profile
        return {
            'bank_name': provider.bank_name,
            'iban': provider.iban,
            'bank_account_number': provider.bank_account_number,
        }

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['provider'] = self.request.user.provider_profile
        return context

    def form_valid(self, form):
        provider = self.request.user.provider_profile
        provider.bank_name = form.cleaned_data['bank_name']
        provider.iban = form.cleaned_data['iban']
        provider.bank_account_number = form.cleaned_data.get('bank_account_number', '')
        provider.save()
        messages.success(self.request, _("Financial information updated successfully."))
        return super().form_valid(form)


class SecurityView(LoginRequiredMixin, FormView):
    template_name = "provider_portal/profile/security.html"
    form_class = PasswordChangeForm
    success_url = reverse_lazy("provider_portal:security")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['provider'] = self.request.user.provider_profile
        return context

    def form_valid(self, form):
        user = self.request.user
        current_password = form.cleaned_data['current_password']
        
        if not user.check_password(current_password):
            form.add_error('current_password', _("Incorrect current password."))
            return self.form_invalid(form)
            
        user.set_password(form.cleaned_data['new_password'])
        user.save()
        update_session_auth_hash(self.request, user)
        messages.success(self.request, _("Password updated successfully."))
        return super().form_valid(form)