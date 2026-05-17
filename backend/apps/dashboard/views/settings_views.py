# apps/dashboard/views/settings_views.py

import logging
from django.views.generic import FormView
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext as _

from apps.dashboard.mixins import SuperuserRequiredMixin
from apps.dashboard.forms import GlobalSettingsForm

logger = logging.getLogger(__name__)

class GlobalSettingsView(SuperuserRequiredMixin, FormView):
    """
    Unified command center FormView to securely manage and update 
    all core platform configurations, economic modules, and cache parameters.
    """
    template_name = "dashboard/settings/settings.html"
    form_class = GlobalSettingsForm
    success_url = reverse_lazy('dashboard:settings')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Global System Settings")
        logger.info(f"User {self.request.user.email} accessed global system configuration panel.")
        return context

    def form_valid(self, form):
        form.save()
        logger.info(f"System configurations successfully updated by superuser {self.request.user.email}.")
        messages.success(self.request, _("System configurations have been updated successfully."))
        return super().form_valid(form)