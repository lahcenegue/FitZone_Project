"""
Central API router for FitZone.
All app-level API endpoints are registered here.
Adding a new app requires only adding one line to this file.
"""

from rest_framework.routers import DefaultRouter
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

router = DefaultRouter()

# ---------------------------------------------------------------------------
# Health check endpoint — public, no authentication required
# GET /api/v1/health/
# ---------------------------------------------------------------------------

@api_view(["GET"])
@permission_classes([AllowAny])
def health_check(request):
    """
    Returns service health status.
    Used by Docker and load balancers to verify the backend is running.
    """
    return Response({"status": "healthy"})


# ---------------------------------------------------------------------------
# Attach health check directly to router URLs
# ---------------------------------------------------------------------------

from django.urls import path  # noqa: E402

class FitZoneAPIRouter(DefaultRouter):
    """
    Extended DefaultRouter that includes the health check endpoint.
    """

    def get_urls(self):
        """Return router URLs with health check appended."""
        urls = super().get_urls()
        custom_urls = [
            path("health/", health_check, name="health-check"),
        ]
        return custom_urls + urls


api_router = FitZoneAPIRouter()

# ---------------------------------------------------------------------------
# App viewsets are registered here as they are built
# Example: api_router.register(r"users", UserViewSet, basename="user")
# ---------------------------------------------------------------------------