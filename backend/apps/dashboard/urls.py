"""URL configuration for the dashboard app."""

from django.urls import path
from .views import (
    DashboardHomeView, 
    GlobalSettingsView, 
    DashboardLoginView, 
    DashboardLogoutView
)

app_name = "dashboard"

urlpatterns = [
    path('login/', DashboardLoginView.as_view(), name='login'),
    path('logout/', DashboardLogoutView.as_view(), name='logout'),
    path('', DashboardHomeView.as_view(), name='home'),
    path('settings/', GlobalSettingsView.as_view(), name='settings'),
]