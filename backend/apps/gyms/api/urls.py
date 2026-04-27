from django.urls import path
from .views import (
    GymBranchDetailView, 
    GymSportListAPIView, 
    GymAmenityListAPIView, 
    GymCheckoutAPIView,
    RoamingCheckoutAPIView
)

app_name = "gyms_api"

urlpatterns = [
    path("branches/<int:branch_id>/", GymBranchDetailView.as_view(), name="branch-detail"),
    path("sports/", GymSportListAPIView.as_view(), name="sports-list"),
    path("amenities/", GymAmenityListAPIView.as_view(), name="amenities-list"),

    # Payments & Checkout
    path("checkout/", GymCheckoutAPIView.as_view(), name="gym-checkout"),
    path("roaming/checkout/", RoamingCheckoutAPIView.as_view(), name="roaming-checkout"),
]