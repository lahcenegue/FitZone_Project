from django.urls import path
from .views import GymBranchDetailView

app_name = "gyms_api"

urlpatterns = [
    path("branches/<int:branch_id>/", GymBranchDetailView.as_view(), name="branch-detail"),
]