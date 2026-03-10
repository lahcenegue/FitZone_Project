"""
URL configuration for the Gyms app API.
"""

from django.urls import path
from .views import QRScanView, LiveOccupancyView

app_name = "gyms_api"

urlpatterns = [
    # Requires Authentication (JWT Bearer Token)
    path("scan-qr/", QRScanView.as_view(), name="scan-qr"),
    path("branches/<int:branch_id>/occupancy/", LiveOccupancyView.as_view(), name="live-occupancy"),
]