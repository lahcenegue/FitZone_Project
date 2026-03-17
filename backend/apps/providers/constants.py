from django.db import models
from django.utils.translation import gettext_lazy as _

class ProviderType(models.TextChoices):
    GYM        = "gym",        _("Gym")
    TRAINER    = "trainer",    _("Trainer")
    RESTAURANT = "restaurant", _("Restaurant")
    STORE      = "store",      _("Store")

class ProviderStatus(models.TextChoices):
    PENDING   = "pending",   _("Pending Review")
    APPROVED  = "approved",  _("Approved")
    ACTIVE    = "active",    _("Active")
    SUSPENDED = "suspended", _("Suspended")
    REJECTED  = "rejected",  _("Rejected")

    @classmethod
    def _missing_(cls, value):
        return None

PROVIDER_LOGIN_ALLOWED_STATES  = {ProviderStatus.APPROVED, ProviderStatus.ACTIVE}
PROVIDER_APPROVABLE_STATES     = {ProviderStatus.PENDING}
PROVIDER_REJECTABLE_STATES     = {ProviderStatus.PENDING}
PROVIDER_ACTIVATABLE_STATES    = {ProviderStatus.APPROVED}
PROVIDER_SUSPENDABLE_STATES    = {ProviderStatus.ACTIVE}
PROVIDER_REINSTATEABLE_STATES  = {ProviderStatus.SUSPENDED}

class EmailVerification:
    TOKEN_EXPIRY_HOURS: int = 24
    TOKEN_BYTES: int = 32

class FieldLimits:
    BUSINESS_NAME_MAX  = 255
    BUSINESS_PHONE_MAX = 20
    CITY_MAX           = 100
    ADDRESS_MAX        = 512
    DESCRIPTION_MAX    = 2000
    REJECTION_NOTE_MAX = 1000