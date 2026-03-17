"""
Constants for the FitZone Provider Portal.
All magic numbers and fixed values live here — never inline in views or templates.
"""

from django.utils.translation import gettext_lazy as _

# ---------------------------------------------------------------------------
# Session keys
# ---------------------------------------------------------------------------
SESSION_PROVIDER_ID = "portal_provider_id"
SESSION_REGISTRATION_STEP = "registration_step"
SESSION_REGISTRATION_DATA = "registration_data"

# ---------------------------------------------------------------------------
# Session configuration
# ---------------------------------------------------------------------------
SESSION_EXPIRY_SECONDS = 60 * 60 * 24 * 7  # 7 days

# ---------------------------------------------------------------------------
# Pagination
# ---------------------------------------------------------------------------
PAGE_SIZE_SUBSCRIBERS = 20
PAGE_SIZE_BOOKINGS = 20
PAGE_SIZE_TRANSACTIONS = 20
PAGE_SIZE_NOTIFICATIONS = 30

# ---------------------------------------------------------------------------
# Registration steps
# ---------------------------------------------------------------------------
REGISTRATION_STEP_ACCOUNT = 1
REGISTRATION_STEP_TYPE = 2
REGISTRATION_STEP_BUSINESS = 3
REGISTRATION_STEP_REVIEW = 4
REGISTRATION_TOTAL_STEPS = 4

# ---------------------------------------------------------------------------
# Password validation
# ---------------------------------------------------------------------------
PASSWORD_MIN_LENGTH = 8

# ---------------------------------------------------------------------------
# Phone number
# ---------------------------------------------------------------------------
PHONE_PREFIX = "+966"
PHONE_MAX_LENGTH = 20

# ---------------------------------------------------------------------------
# File upload limits
# ---------------------------------------------------------------------------
MAX_LOGO_SIZE_MB = 2
MAX_PHOTO_SIZE_MB = 5
MAX_PHOTOS_PER_BRANCH = 10
MAX_DOCUMENT_SIZE_MB = 10
ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp"]
ALLOWED_DOCUMENT_TYPES = ["application/pdf", "image/jpeg", "image/png"]

# ---------------------------------------------------------------------------
# Withdrawal
# ---------------------------------------------------------------------------
WITHDRAWAL_MIN_AMOUNT = 100    # SAR
WITHDRAWAL_MAX_AMOUNT = 50000  # SAR

# ---------------------------------------------------------------------------
# Redirect paths — used in decorators and views
# ---------------------------------------------------------------------------
REDIRECT_LOGIN = "provider_portal:login"
REDIRECT_DASHBOARD = "provider_portal:dashboard"
REDIRECT_PENDING = "provider_portal:pending"
REDIRECT_SUSPENDED = "provider_portal:suspended"