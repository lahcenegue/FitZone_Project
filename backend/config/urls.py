"""
Root URL configuration for FitZone.
- API routes are handled via api_router.py
- Web portal routes are handled per app
- i18n_patterns wraps web routes for automatic language prefix
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.conf.urls.i18n import i18n_patterns

from config.api_router import api_router

# ---------------------------------------------------------------------------
# API routes — no language prefix, consumed by mobile app and frontend
# ---------------------------------------------------------------------------

urlpatterns = [
    path("api/v1/", include(api_router.urls)),
    path("i18n/", include("django.conf.urls.i18n")),
    path("api/v1/providers/", include("apps.providers.api.urls")),
    path("api/v1/gyms/", include("apps.gyms.api.urls")),
    path("api/v1/users/", include("apps.users.api.urls")),

    # Core Endpoints (/api/v1/init/ and /api/v1/cities/)
    path("api/v1/", include("apps.core.api.urls")),
]

# ---------------------------------------------------------------------------
# Web routes — wrapped in i18n_patterns for language prefix
# Arabic: /admin/  |  English: /en/admin/
# ---------------------------------------------------------------------------

urlpatterns += i18n_patterns(
    path("admin/", admin.site.urls),
    path("portal/", include("apps.provider_portal.urls", namespace="provider_portal")),
    path("dashboard/", include("apps.dashboard.urls", namespace="dashboard")),
    prefix_default_language=False,  # Arabic URLs have no prefix
)

# ---------------------------------------------------------------------------
# Serve media files in development
# ---------------------------------------------------------------------------

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)