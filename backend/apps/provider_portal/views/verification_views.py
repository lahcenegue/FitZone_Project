"""
Views for handling provider document uploads and verification status.
"""

import logging
from django.views.generic import FormView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.contrib import messages
from django.shortcuts import redirect
from django.utils.translation import gettext_lazy as _
from django.db import transaction

from apps.providers.models import ProviderDocument
from apps.provider_portal.forms.verification_forms import DocumentUploadForm

logger = logging.getLogger(__name__)

class DocumentUploadView(LoginRequiredMixin, FormView):
    """
    GET: Displays the document upload form.
    POST: Validates files, saves them to the database, and updates provider status.
    """
    template_name = "provider_portal/verification/upload.html"
    form_class = DocumentUploadForm
    success_url = reverse_lazy("provider_portal:dashboard")

    def dispatch(self, request, *args, **kwargs):
        """Prevent access if documents are already uploaded or account is active."""
        if not hasattr(request.user, "provider_profile"):
            return redirect("provider_portal:login")
            
        provider = request.user.provider_profile
        
        # If already uploaded or not pending, redirect back to dashboard
        if provider.documents.exists() or provider.status != 'pending':
            messages.info(request, _("Your documents are already under review or your account is active."))
            return redirect("provider_portal:dashboard")
            
        return super().dispatch(request, *args, **kwargs)

    @transaction.atomic
    def form_valid(self, form):
        """Process valid form data and create database records."""
        provider = self.request.user.provider_profile
        
        # 1. Save Commercial Register
        ProviderDocument.objects.create(
            provider=provider,
            title="Commercial Register",
            file=form.cleaned_data['commercial_register']
        )
        
        # 2. Save Owner ID
        ProviderDocument.objects.create(
            provider=provider,
            title="Owner ID",
            file=form.cleaned_data['owner_id']
        )

        logger.info("Verification documents uploaded | provider: %s", provider.user.email)
        messages.success(self.request, _("Documents uploaded successfully. Our team will review them shortly."))
        
        return super().form_valid(form)