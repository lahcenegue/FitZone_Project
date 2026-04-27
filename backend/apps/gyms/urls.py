"""
URL configuration for the Gyms app API.
"""

from django.urls import path
from .views import (
    GymBranchDetailView, 
    GymSportListAPIView, 
    GymAmenityListAPIView, 
    GymCheckoutAPIView,
    RoamingCheckoutAPIView,
    QRScanView,
    LiveOccupancyView
)

app_name = "gyms_api"

urlpatterns = [
    # Public / Discovery
    path("branches/<int:branch_id>/", GymBranchDetailView.as_view(), name="branch-detail"),
    path("branches/<int:branch_id>/occupancy/", LiveOccupancyView.as_view(), name="live-occupancy"),
    path("sports/", GymSportListAPIView.as_view(), name="sports-list"),
    path("amenities/", GymAmenityListAPIView.as_view(), name="amenities-list"),

    # Payments & Checkout (Requires Auth)
    path("checkout/", GymCheckoutAPIView.as_view(), name="gym-checkout"),
    path("roaming/checkout/", RoamingCheckoutAPIView.as_view(), name="roaming-checkout"),
    
    # Provider / Receptionist Operations (Requires Auth)
    path("scan-qr/", QRScanView.as_view(), name="scan-qr"),
]