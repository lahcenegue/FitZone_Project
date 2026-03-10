"""
Provider models for FitZone.

Provider: the business entity linked 1:1 to a User (role=PROVIDER).
EmailVerificationToken: single-use token sent at registration.

DB state after 0001_initial:
    providers_provider exists with columns:
    id, provider_type, status, business_name, description, logo,
    city, address, commercial_registration, tax_id,
    bank_name, iban, bank_account_number, created_at, updated_at, user_id

Migration 0002 adds:
    business_phone, reviewed_by_id, reviewed_at, rejection_note,
    email_verified, verified_at
    + new table: providers_emailverificationtoken

Registration flow:
    1. User created (is_active=False) + Provider (status=PENDING) + token created + email sent
    2. Provider clicks link → User activated (is_active=True) + email_verified=True
    3. Admin reviews → APPROVED or REJECTED
    4. APPROVED provider can log in, sees inactive-account banner
    5. Admin sets ACTIVE when setup complete
"""

import logging
import secrets
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from encrypted_model_fields.fields import EncryptedCharField

from .constants import (
    EmailVerification,
    FieldLimits,
    ProviderStatus,
    ProviderType,
    PROVIDER_APPROVABLE_STATES,
    PROVIDER_REJECTABLE_STATES,
    PROVIDER_ACTIVATABLE_STATES,
    PROVIDER_SUSPENDABLE_STATES,
    PROVIDER_REINSTATEABLE_STATES,
    PROVIDER_LOGIN_ALLOWED_STATES,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Provider
# ---------------------------------------------------------------------------

class Provider(models.Model):
    """
    FitZone service provider profile.

    Linked one-to-one to a User with role=PROVIDER.
    Contains business identity, location, financial details (encrypted),
    and registration review fields.
    """

    # --- Link to User ---
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="provider_profile",
        verbose_name=_("User"),
    )

    # --- Type ---
    provider_type = models.CharField(
        _("Provider type"),
        max_length=20,
        choices=ProviderType.choices,
        db_index=True,
    )

    # --- Status ---
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
        max_length=FieldLimits.BUSINESS_NAME_MAX,
        db_index=True,
    )
    business_phone = models.CharField(
        _("Business phone"),
        max_length=FieldLimits.BUSINESS_PHONE_MAX,
        blank=True,
        default="",
    )
    description = models.TextField(
        _("Description"),
        max_length=FieldLimits.DESCRIPTION_MAX,
        blank=True,
        default="",
    )

    # --- Location ---
    city = models.CharField(
        _("City"),
        max_length=FieldLimits.CITY_MAX,
        db_index=True,
    )
    address = models.CharField(
        _("Address"),
        max_length=FieldLimits.ADDRESS_MAX,
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

    # --- Email verification ---
    email_verified = models.BooleanField(
        _("Email verified"),
        default=False,
    )
    verified_at = models.DateTimeField(
        _("Verified at"),
        null=True,
        blank=True,
    )

    # --- UI & Branding ---
    logo = models.ImageField(
        upload_to="providers/logos/", 
        null=True, 
        blank=True,
        verbose_name=_("Business Logo")
    )

    # --- Commission System (Admin Only) ---
    COMMISSION_TYPE_CHOICES = [
        ("percentage", _("Percentage")),
        ("fixed", _("Fixed Amount")),
    ]
    commission_type = models.CharField(
        max_length=20, 
        choices=COMMISSION_TYPE_CHOICES, 
        default="percentage",
        verbose_name=_("Commission Type")
    )
    commission_value = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=0.00,
        verbose_name=_("Commission Value")
    )

    # --- Admin review ---
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reviewed_providers",
        verbose_name=_("Reviewed by"),
    )
    reviewed_at = models.DateTimeField(
        _("Reviewed at"),
        null=True,
        blank=True,
    )
    rejection_note = models.TextField(
        _("Rejection note"),
        max_length=FieldLimits.REJECTION_NOTE_MAX,
        blank=True,
        default="",
        help_text=_("Shown to the provider in the rejection email."),
    )

    # --- Timestamps ---
    created_at = models.DateTimeField(_("Created at"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated at"), auto_now=True)

    class Meta:
        verbose_name = _("Provider")
        verbose_name_plural = _("Providers")
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "provider_type"], name="prov_status_type_idx"),
            models.Index(fields=["status", "created_at"],    name="prov_status_created_idx"),
        ]

    def __str__(self):
        return (
            f"{self.business_name} "
            f"({self.get_provider_type_display()}) — "
            f"{self.get_status_display()}"
        )

    # ---------------------------------------------------------------------------
    # Properties
    # ---------------------------------------------------------------------------

    @property
    def is_active(self) -> bool:
        """Return True if provider is fully operational."""
        return self.status == ProviderStatus.ACTIVE

    @property
    def is_pending(self) -> bool:
        """Return True if provider is awaiting admin review."""
        return self.status == ProviderStatus.PENDING

    @property
    def is_approved(self) -> bool:
        """Return True if provider is approved but not yet fully active."""
        return self.status == ProviderStatus.APPROVED

    @property
    def is_suspended(self) -> bool:
        """Return True if provider account has been suspended."""
        return self.status == ProviderStatus.SUSPENDED

    @property
    def is_rejected(self) -> bool:
        """Return True if the application was rejected."""
        return self.status == ProviderStatus.REJECTED

    @property
    def can_access_dashboard(self) -> bool:
        """
        Return True if provider is allowed to log in and see the dashboard.
        APPROVED providers can log in but see a limited dashboard with a
        'waiting for activation' banner.
        """
        return self.status in PROVIDER_LOGIN_ALLOWED_STATES

    @property
    def has_financial_info(self) -> bool:
        """Return True if provider has submitted bank details."""
        return bool(self.iban and self.bank_name)

    # ---------------------------------------------------------------------------
    # State machine methods — called only by ProviderService, never directly
    # ---------------------------------------------------------------------------

    def mark_email_verified(self) -> None:
        """
        Mark email as verified and activate the linked User account.
        Called by ProviderRegistrationService after token validation.
        Provider status stays PENDING — admin still needs to review.
        """
        user = self.user
        user.is_active = True
        user.is_verified = True
        user.save(update_fields=["is_active", "is_verified", "updated_at"])

        self.email_verified = True
        self.verified_at = timezone.now()
        self.save(update_fields=["email_verified", "verified_at", "updated_at"])

        logger.info(
            "Email verified | provider: %s | user: %s",
            self.business_name,
            user.email,
        )

    def approve(self, reviewed_by, note: str = "") -> None:
        """
        Approve a pending provider application.
        Called by admin. Sets status=APPROVED.

        Args:
            reviewed_by: The admin User performing the action.
            note:        Optional internal note (not shown to provider).
        """
        if self.status not in PROVIDER_APPROVABLE_STATES:
            raise ValueError(
                f"Cannot approve provider with status '{self.status}'. "
                f"Only PENDING providers can be approved."
            )
        self.status = ProviderStatus.APPROVED
        self.reviewed_by = reviewed_by
        self.reviewed_at = timezone.now()
        self.save(update_fields=[
            "status", "reviewed_by", "reviewed_at", "updated_at"
        ])
        logger.info(
            "Provider approved | business: %s | by: %s",
            self.business_name,
            reviewed_by.email,
        )

    def reject(self, reviewed_by, note: str = "") -> None:
        """
        Reject a pending provider application.
        Called by admin. Sets status=REJECTED and stores the rejection note.

        Args:
            reviewed_by: The admin User performing the action.
            note:        Reason shown to the provider in the rejection email.
        """
        if self.status not in PROVIDER_REJECTABLE_STATES:
            raise ValueError(
                f"Cannot reject provider with status '{self.status}'. "
                f"Only PENDING providers can be rejected."
            )
        self.status = ProviderStatus.REJECTED
        self.reviewed_by = reviewed_by
        self.reviewed_at = timezone.now()
        self.rejection_note = note
        self.save(update_fields=[
            "status", "reviewed_by", "reviewed_at", "rejection_note", "updated_at"
        ])
        logger.warning(
            "Provider rejected | business: %s | by: %s | note: %s",
            self.business_name,
            reviewed_by.email,
            note,
        )

    def activate(self, reason: str = "") -> None:
        """
        Set provider status to ACTIVE.
        Called by admin when the provider has completed their profile setup.

        Args:
            reason: Human-readable reason for the audit log.
        """
        if self.status not in PROVIDER_ACTIVATABLE_STATES:
            raise ValueError(
                f"Cannot activate provider with status '{self.status}'. "
                f"Only APPROVED providers can be activated."
            )
        self.status = ProviderStatus.ACTIVE
        self.save(update_fields=["status", "updated_at"])
        logger.info(
            "Provider activated | business: %s | user: %s | reason: %s",
            self.business_name,
            self.user.email,
            reason,
        )

    def suspend(self, reason: str = "") -> None:
        """
        Suspend an active provider account.
        Called by admin for policy violations.

        Args:
            reason: Human-readable reason for the audit log.
        """
        if self.status not in PROVIDER_SUSPENDABLE_STATES:
            raise ValueError(
                f"Cannot suspend provider with status '{self.status}'. "
                f"Only ACTIVE providers can be suspended."
            )
        self.status = ProviderStatus.SUSPENDED
        self.save(update_fields=["status", "updated_at"])
        logger.warning(
            "Provider suspended | business: %s | user: %s | reason: %s",
            self.business_name,
            self.user.email,
            reason,
        )

    def reinstate(self, reason: str = "") -> None:
        """
        Reinstate a suspended provider back to ACTIVE.

        Args:
            reason: Human-readable reason for the audit log.
        """
        if self.status not in PROVIDER_REINSTATEABLE_STATES:
            raise ValueError(
                f"Cannot reinstate provider with status '{self.status}'. "
                f"Only SUSPENDED providers can be reinstated."
            )
        self.status = ProviderStatus.ACTIVE
        self.save(update_fields=["status", "updated_at"])
        logger.info(
            "Provider reinstated | business: %s | user: %s | reason: %s",
            self.business_name,
            self.user.email,
            reason,
        )


# ---------------------------------------------------------------------------
# EmailVerificationToken
# ---------------------------------------------------------------------------

class EmailVerificationToken(models.Model):
    """
    Single-use token for verifying a provider's email at registration.

    Lifecycle: created → consumed (is_used=True) or expired (expires_at < now).

    A fresh token is created on every resend request — previous tokens
    for the same provider are deleted first to prevent stale token attacks.

    Future: PhoneVerificationToken will follow the same pattern.
    """

    provider = models.ForeignKey(
        Provider,
        on_delete=models.CASCADE,
        related_name="email_tokens",
        verbose_name=_("Provider"),
    )
    token = models.CharField(
        _("Token"),
        max_length=64,
        unique=True,
        db_index=True,
    )
    expires_at = models.DateTimeField(_("Expires at"))
    is_used = models.BooleanField(_("Used"), default=False)
    created_at = models.DateTimeField(_("Created at"), auto_now_add=True)

    class Meta:
        verbose_name = _("Email verification token")
        verbose_name_plural = _("Email verification tokens")
        indexes = [
            models.Index(fields=["token", "is_used"], name="evt_token_used_idx"),
        ]

    def __str__(self):
        return (
            f"Token for {self.provider.business_name} — "
            f"used={self.is_used} | expires={self.expires_at}"
        )

    @classmethod
    def create_for_provider(cls, provider: "Provider") -> "EmailVerificationToken":
        """
        Invalidate all existing tokens for this provider and create a fresh one.

        Args:
            provider: The Provider instance to create a token for.

        Returns:
            The newly created EmailVerificationToken instance.
        """
        cls.objects.filter(provider=provider).delete()

        raw_token = secrets.token_hex(EmailVerification.TOKEN_BYTES)
        expires_at = timezone.now() + timedelta(
            hours=EmailVerification.TOKEN_EXPIRY_HOURS
        )

        instance = cls.objects.create(
            provider=provider,
            token=raw_token,
            expires_at=expires_at,
        )
        logger.debug(
            "Email verification token created | provider: %s",
            provider.business_name,
        )
        return instance

    @property
    def is_expired(self) -> bool:
        """Return True if the token is past its expiry time."""
        return timezone.now() > self.expires_at

    @property
    def is_valid(self) -> bool:
        """Return True if this token can still be consumed."""
        return not self.is_used and not self.is_expired

    def consume(self) -> None:
        """
        Mark the token as used.

        Raises:
            ValueError: If the token is already used or has expired.
        """
        if self.is_used:
            raise ValueError("This verification link has already been used.")
        if self.is_expired:
            raise ValueError("This verification link has expired.")
        self.is_used = True
        self.save(update_fields=["is_used"])
        logger.debug(
            "Email verification token consumed | provider: %s",
            self.provider.business_name,
        )

class ProviderDocument(models.Model):
    """
    Stores legal and verification documents uploaded by the provider.
    These are reviewed by the administration before activating the account.
    """
    DOCUMENT_STATUS_CHOICES = [
        ("pending", _("Pending Review")),
        ("approved", _("Approved")),
        ("rejected", _("Rejected")),
    ]

    provider = models.ForeignKey(
        Provider, 
        on_delete=models.CASCADE, 
        related_name="documents"
    )
    title = models.CharField(
        max_length=255, 
        help_text=_("e.g., Commercial Register, Owner ID")
    )
    file = models.FileField(upload_to="providers/documents/")
    status = models.CharField(
        max_length=20, 
        choices=DOCUMENT_STATUS_CHOICES, 
        default="pending"
    )
    rejection_reason = models.TextField(blank=True, default="")
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} - {self.provider.business_name}"