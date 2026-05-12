import logging
from django.views.generic import TemplateView, FormView
from django.contrib.auth.views import LoginView, LogoutView
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext as _
from .mixins import SuperuserRequiredMixin
from .forms import GlobalSettingsForm, DashboardLoginForm

logger = logging.getLogger(__name__)

class DashboardLoginView(LoginView):
    """
    Secure login portal strictly for Mastermind Admins.
    """
    template_name = "dashboard/login.html"
    form_class = DashboardLoginForm
    redirect_authenticated_user = True

    def get_success_url(self):
        return reverse_lazy('dashboard:home')


class DashboardLogoutView(LogoutView):
    """
    Secure logout handling for the dashboard.
    """
    next_page = reverse_lazy('dashboard:login')


class DashboardHomeView(SuperuserRequiredMixin, TemplateView):
    template_name = "dashboard/home.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = "Overview & KPIs"
        return context


class GlobalSettingsView(SuperuserRequiredMixin, FormView):
    template_name = "dashboard/settings.html"
    form_class = GlobalSettingsForm
    success_url = reverse_lazy('dashboard:settings')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = "Global System Settings"
        return context

    def form_valid(self, form):
        form.save()
        messages.success(self.request, _("System configurations have been updated successfully."))
        logger.info(f"Global settings updated by superuser: {self.request.user.email}")
        return super().form_valid(form)