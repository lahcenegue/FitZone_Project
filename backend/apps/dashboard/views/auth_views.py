# apps/dashboard/views/auth_views.py

from django.contrib.auth.views import LoginView, LogoutView
from django.urls import reverse_lazy
from apps.dashboard.forms import DashboardLoginForm

class DashboardLoginView(LoginView):
    template_name = "dashboard/login.html"
    form_class = DashboardLoginForm
    redirect_authenticated_user = True

    def get_success_url(self):
        return reverse_lazy('dashboard:home')

class DashboardLogoutView(LogoutView):
    next_page = reverse_lazy('dashboard:login')