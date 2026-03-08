"""
Constants for the providers app.

ProviderType and ProviderStatus are Django TextChoices subclasses.
This gives them both .choices (lowercase) and individual value attributes,
matching the pattern used throughout the project — forms, models, and views
all rely on this interface.

State transition sets (APPROVABLE_STATES etc.) are defined as plain class
attributes on ProviderStatus — TextChoices allows this cleanly.
"""

from django.db import models
from django.utils.translation import gettext_lazy as _


# ---------------------------------------------------------------------------
# Provider type choices
# ---------------------------------------------------------------------------

class ProviderType(models.TextChoices):
    """
    Supported service provider types.

    Adding a new type: add one line here.
    No migration required — the DB column is VARCHAR(20) with no DB-level constraint.

    Usage:
        ProviderType.choices          → [('gym', 'Gym'), ...]  (for model/form fields)
        ProviderType.GYM              → 'gym'
        ProviderType.GYM.label        → 'Gym'
    """
    GYM        = "gym",        _("Gym")
    TRAINER    = "trainer",    _("Trainer")
    RESTAURANT = "restaurant", _("Restaurant")
    STORE      = "store",      _("Store")


# ---------------------------------------------------------------------------
# Provider registration status
# ---------------------------------------------------------------------------

class ProviderStatus(models.TextChoices):
    """
    Lifecycle status for provider accounts.

    State machine:
        PENDING   →  APPROVED   (admin approves after email verification)
        PENDING   →  REJECTED   (admin rejects the application)
        APPROVED  →  ACTIVE     (admin activates after profile is complete)
        ACTIVE    →  SUSPENDED  (admin suspends for policy violation)
        SUSPENDED →  ACTIVE     (admin reinstates)

    APPROVED providers can log in and see the dashboard with an
    'account not yet active' banner. They cannot perform revenue-generating
    actions until status is ACTIVE.

    Usage:
        ProviderStatus.choices        → [('pending', 'Pending Review'), ...]
        ProviderStatus.PENDING        → 'pending'
        ProviderStatus.ACTIVE         → 'active'
        ProviderStatus.LOGIN_ALLOWED_STATES  → {'approved', 'active'}
    """
    PENDING   = "pending",   _("Pending Review")
    APPROVED  = "approved",  _("Approved")
    ACTIVE    = "active",    _("Active")
    SUSPENDED = "suspended", _("Suspended")
    REJECTED  = "rejected",  _("Rejected")

    # ── State transition sets ──────────────────────────────────────────────
    # Defined outside the enum values so TextChoices does not treat them
    # as choice entries. Access as ProviderStatus.LOGIN_ALLOWED_STATES etc.

    @classmethod
    def _missing_(cls, value):
        return None


# State sets — defined at module level to avoid TextChoices member conflicts
# Import these directly: from .constants import PROVIDER_LOGIN_ALLOWED_STATES

PROVIDER_LOGIN_ALLOWED_STATES  = {ProviderStatus.APPROVED, ProviderStatus.ACTIVE}
PROVIDER_APPROVABLE_STATES     = {ProviderStatus.PENDING}
PROVIDER_REJECTABLE_STATES     = {ProviderStatus.PENDING}
PROVIDER_ACTIVATABLE_STATES    = {ProviderStatus.APPROVED}
PROVIDER_SUSPENDABLE_STATES    = {ProviderStatus.ACTIVE}
PROVIDER_REINSTATEABLE_STATES  = {ProviderStatus.SUSPENDED}


# ---------------------------------------------------------------------------
# Email verification token configuration
# ---------------------------------------------------------------------------

class EmailVerification:
    """Configuration for the email verification token."""

    # Token validity in hours
    TOKEN_EXPIRY_HOURS: int = 24

    # Random bytes for the token — produces a 64-character hex string
    TOKEN_BYTES: int = 32


# ---------------------------------------------------------------------------
# Field length limits — no magic numbers anywhere else
# ---------------------------------------------------------------------------

class FieldLimits:
    """Maximum field lengths for Provider model fields."""

    BUSINESS_NAME_MAX  = 255
    BUSINESS_PHONE_MAX = 20
    CITY_MAX           = 100
    ADDRESS_MAX        = 512
    DESCRIPTION_MAX    = 2000
    REJECTION_NOTE_MAX = 1000