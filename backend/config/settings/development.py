"""
Development settings for FitZone.
Extends base settings with debug-friendly configuration.
"""

from .base import *  # noqa: F401, F403

# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------

DEBUG = True

# ---------------------------------------------------------------------------
# Email — use console backend in development
# ---------------------------------------------------------------------------

EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# ---------------------------------------------------------------------------
# CORS — allow all origins in development
# ---------------------------------------------------------------------------

CORS_ALLOW_ALL_ORIGINS = True