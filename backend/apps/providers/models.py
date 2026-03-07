"""
Provider model for FitZone.
Represents a service provider account linked to a User (role=PROVIDER).
One User → One Provider profile.
Provider types: Gym, Trainer, Restaurant, Store.
Financial fields are encrypted at rest using django-encrypted-model-fields.
"""

import logging
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from encrypted_model_fields.fields import EncryptedCharField

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Choices
# ---------------------------------------------------------------------------

class ProviderType(models.TextChoices):
    """The four categories of service providers on FitZone."""
    GYM        = "gym",        _("Gym")
    TRAINER    = "trainer",    _("Trainer")
    RESTAURANT = "restaurant", _("Restaurant")
    STORE      = "store",      _("Store")


class ProviderStatus(models.TextChoices):
    """
    Lifecycle status of a provider account.
    PENDING  → submitted, awaiting admin review
    APPROVED → admin approved, not yet active
    ACTIVE   → fully operational
    SUSPENDED→ blocked by admin
    """
    PENDING   = "pending",   _("Pending")
    APPROVED  = "approved",  _("Approved")
    ACTIVE    = "active",    _("Active")
    SUSPENDED = "suspended", _("Suspended")


# ---------------------------------------------------------------------------
# Model
# ---------------------------------------------------------------------------

class Provider(models.Model):
    """
    FitZone Provider profile.

    Linked one-to-one to a User with role=PROVIDER.
    Contains business identity, location, and encrypted financial details.
    Admin can change provider_type to correct registration errors.
    """

    # --- Link to User ---
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="provider_profile",
        verbose_name=_("User"),
    )

    # --- Type & Status ---
    provider_type = models.CharField(
        _("Provider type"),
        max_length=20,
        choices=ProviderType.choices,
        db_index=True,
    )
    status = models.CharField(
        _("Status"),
        max_length=20,
        choices=ProviderStatus.choices,
        default=ProviderStatus.PENDING,
        db_index=True,
    )

    # --- Business Identity ---
    business_name = models.CharField(
        _("Business name"),
        max_length=255,
        db_index=True,
    )
    description = models.TextField(
        _("Description"),
        blank=True,
        default="",
    )
    logo = models.ImageField(
        _("Logo"),
        upload_to="providers/logos/",
        blank=True,
        null=True,
    )

    # --- Location ---
    city = models.CharField(
        _("City"),
        max_length=100,
        db_index=True,
    )
    address = models.CharField(
        _("Address"),
        max_length=512,
        blank=True,
        default="",
    )

    # --- Legal ---
    commercial_registration = models.CharField(
        _("Commercial registration number"),
        max_length=100,
        blank=True,
        default="",
    )
    tax_id = models.CharField(
        _("Tax ID number"),
        max_length=100,
        blank=True,
        default="",
    )

    # --- Financial (encrypted at rest) ---
    bank_name = EncryptedCharField(
        _("Bank name"),
        max_length=255,
        blank=True,
        default="",
    )
    iban = EncryptedCharField(
        _("IBAN"),
        max_length=34,
        blank=True,
        default="",
    )
    bank_account_number = EncryptedCharField(
        _("Bank account number"),
        max_length=100,
        blank=True,
        default="",
    )

    # --- Timestamps ---
    created_at = models.DateTimeField(
        _("Created at"),
        auto_now_add=True,
    )
    updated_at = models.DateTimeField(
        _("Updated at"),
        auto_now=True,
    )

    class Meta:
        verbose_name = _("Provider")
        verbose_name_plural = _("Providers")
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.business_name} ({self.get_provider_type_display()}) — {self.get_status_display()}"

    # ---------------------------------------------------------------------------
    # Properties
    # ---------------------------------------------------------------------------

    @property
    def is_active(self):
        """Return True if provider is fully operational."""
        return self.status == ProviderStatus.ACTIVE

    @property
    def is_pending(self):
        """Return True if provider is awaiting admin review."""
        return self.status == ProviderStatus.PENDING

    @property
    def is_suspended(self):
        """Return True if provider account is suspended."""
        return self.status == ProviderStatus.SUSPENDED

    @property
    def has_financial_info(self):
        """Return True if provider has submitted bank details."""
        return bool(self.iban and self.bank_name)

    # ---------------------------------------------------------------------------
    # Methods
    # ---------------------------------------------------------------------------

    def activate(self, reason: str = "") -> None:
        """
        Set provider status to ACTIVE.

        Args:
            reason: Human-readable reason for the audit log.
        """
        self.status = ProviderStatus.ACTIVE
        self.save(update_fields=["status", "updated_at"])
        logger.info(
            "Provider activated | provider: %s | user: %s | reason: %s",
            self.business_name, self.user.email, reason,
        )

    def suspend(self, reason: str = "") -> None:
        """
        Set provider status to SUSPENDED.

        Args:
            reason: Human-readable reason for the audit log.
        """
        self.status = ProviderStatus.SUSPENDED
        self.save(update_fields=["status", "updated_at"])
        logger.warning(
            "Provider suspended | provider: %s | user: %s | reason: %s",
            self.business_name, self.user.email, reason,
        )

    def approve(self, reason: str = "") -> None:
        """
        Set provider status to APPROVED.

        Args:
            reason: Human-readable reason for the audit log.
        """
        self.status = ProviderStatus.APPROVED
        self.save(update_fields=["status", "updated_at"])
        logger.info(
            "Provider approved | provider: %s | user: %s | reason: %s",
            self.business_name, self.user.email, reason,
        )