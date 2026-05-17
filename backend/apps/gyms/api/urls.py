"""
API Routing mapping configuration for the Gyms application.
Secures direct entry points for branches, amenities, checkouts and metric analytics reviews.
"""

from django.urls import path
from .views import (
    GymBranchDetailView, 
    GymSportListAPIView, 
    GymAmenityListAPIView, 
    GymCheckoutAPIView,
    RoamingCheckoutAPIView,
    QRScanView,
    LiveOccupancyView,
    GymReviewSubmissionAPIView,
    GymReviewTagListView
)

app_name = "gyms_api"

urlpatterns = [
    path("branches/<int:branch_id>/", GymBranchDetailView.as_view(), name="branch-detail"),
    path("sports/", GymSportListAPIView.as_view(), name="sports-list"),
    path("amenities/", GymAmenityListAPIView.as_view(), name="amenities-list"),

    # Global lookup taxonomy endpoint for mobile form builders
    path("reviews/tags/", GymReviewTagListView.as_view(), name="review-tags-list"),

    # New Dynamic Vibe Score & Review Actions Endpoints System
    path("providers/gyms/<int:gym_id>/reviews/", GymReviewSubmissionAPIView.as_view(), name="gym-review-submission"),

    # Payments & Checkout
    path("checkout/", GymCheckoutAPIView.as_view(), name="gym-checkout"),
    path("roaming/checkout/", RoamingCheckoutAPIView.as_view(), name="roaming-checkout"),
    path("scan-qr/", QRScanView.as_view(), name="scan-qr"),
    path("branches/<int:branch_id>/occupancy/", LiveOccupancyView.as_view(), name="live-occupancy"),
]