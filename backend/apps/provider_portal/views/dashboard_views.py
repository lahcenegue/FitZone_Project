"""
Dashboard views for the FitZone Provider Portal.
Handles the main overview page and notifications.
"""

from django.views import View
from django.shortcuts import render, redirect
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse

class DashboardView(LoginRequiredMixin, View):
    """
    GET /portal/dashboard/
    Renders the main dashboard overview page.
    Requires standard session login.
    """
    template_name = "provider_portal/dashboard/dashboard.html"

    def get(self, request):
        # Ensure the logged-in user has a provider profile
        if not hasattr(request.user, "provider_profile"):
            return redirect("provider_portal:login")

        provider = request.user.provider_profile
        
        # Check if the provider has uploaded any verification documents
        has_documents = provider.documents.exists()

        context = {
            "provider": provider,
            # Flags for sidebar rendering (to show/hide specific links)
            "is_gym": provider.provider_type == "gym",
            "is_trainer": provider.provider_type == "trainer",
            "is_restaurant": provider.provider_type == "restaurant",
            "is_store": provider.provider_type == "store",
            # Flag for the document verification banner
            "has_documents": has_documents,
        }
        
        return render(request, self.template_name, context)


class NotificationsView(View):
    def get(self, request): 
        # Placeholder for notifications page
        return HttpResponse('Notifications Page')


class MarkNotificationReadView(View):
    def post(self, request, notification_id): 
        # Placeholder for marking notification as read
        return HttpResponse('Marked as read')