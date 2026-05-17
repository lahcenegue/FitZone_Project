# apps/dashboard/views/settings_views.py

from django.views.generic import FormView
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext as _

from apps.dashboard.mixins import SuperuserRequiredMixin
from apps.dashboard.forms import GlobalSettingsForm

class GlobalSettingsView(SuperuserRequiredMixin, FormView):
    template_name = "dashboard/settings.html"
    form_class = GlobalSettingsForm
    success_url = reverse_lazy('dashboard:settings')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Global System Settings")
        return context

    def form_valid(self, form):
        form.save()
        messages.success(self.request, _("System configurations have been updated successfully."))
        return super().form_valid(form)