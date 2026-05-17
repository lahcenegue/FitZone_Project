# apps/dashboard/views/home_views.py

from django.views.generic import TemplateView
from apps.dashboard.mixins import SuperuserRequiredMixin

class DashboardHomeView(SuperuserRequiredMixin, TemplateView):
    template_name = "dashboard/home.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = "Overview & KPIs"
        return context