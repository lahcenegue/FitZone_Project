import uuid
import logging
from datetime import timedelta
from django.db import models, transaction
from django.utils import timezone
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError

logger = logging.getLogger(__name__)

class PaymentGateway(models.TextChoices):
    """Supported payment gateways."""
    MOCK = "mock", _("Mock Gateway (Testing)")
    STRIPE = "stripe", _("Stripe")
    HYPERPAY = "hyperpay", _("HyperPay")

class PaymentStatus(models.TextChoices):
    """Lifecycle of a payment transaction."""
    PENDING = "pending", _("Pending")
    SUCCESS = "success", _("Success")
    FAILED = "failed", _("Failed")
    REFUNDED = "refunded", _("Refunded")

class PaymentTransaction(models.Model):
    """
    Centralized model for tracking all financial transactions.
    Designed to easily switch or integrate multiple payment gateways.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.PROTECT, 
        related_name="transactions",
        verbose_name=_("Customer")
    )
    
    amount = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Amount"))
    currency = models.CharField(max_length=3, default="SAR", verbose_name=_("Currency"))
    
    gateway = models.CharField(
        max_length=20, 
        choices=PaymentGateway.choices, 
        default=PaymentGateway.MOCK,
        verbose_name=_("Payment Gateway")
    )
    status = models.CharField(
        max_length=20, 
        choices=PaymentStatus.choices, 
        default=PaymentStatus.PENDING,
        verbose_name=_("Status")
    )
    
    gateway_transaction_id = models.CharField(
        max_length=255, 
        blank=True, 
        null=True, 
        help_text=_("Unique transaction ID returned by the payment gateway.")
    )
    error_message = models.TextField(blank=True, null=True, verbose_name=_("Error Message"))
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("Payment Transaction")
        verbose_name_plural = _("Payment Transactions")
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.id} - {self.user.email} - {self.amount} {self.currency} ({self.get_status_display()})"

    def mark_as_success(self, gateway_id: str = None):
        """Marks the transaction as successful."""
        self.status = PaymentStatus.SUCCESS
        if gateway_id:
            self.gateway_transaction_id = gateway_id
        self.save(update_fields=['status', 'gateway_transaction_id', 'updated_at'])
        logger.info(f"Transaction {self.id} marked as SUCCESS.")

    def mark_as_failed(self, error_message: str = None):
        """Marks the transaction as failed."""
        self.status = PaymentStatus.FAILED
        if error_message:
            self.error_message = error_message
        self.save(update_fields=['status', 'error_message', 'updated_at'])
        logger.warning(f"Transaction {self.id} marked as FAILED. Reason: {error_message}")


class PaymentGlobalSetting(models.Model):
    """Singleton model for global financial configurations."""
    earnings_hold_days = models.PositiveIntegerField(
        default=3,
        verbose_name=_("Earnings Hold Period (Days)"),
        help_text=_("Number of days before provider earnings become available for withdrawal.")
    )

    class Meta:
        verbose_name = _("Payment Global Setting")
        verbose_name_plural = _("Payment Global Settings")

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return str(_("Global Financial Settings"))


class ProviderWallet(models.Model):
    """
    Financial summary for a provider.
    Strictly updated via WalletTransaction to maintain ledger integrity.
    """
    provider = models.OneToOneField(
        'providers.Provider', 
        on_delete=models.CASCADE, 
        related_name='wallet',
        verbose_name=_("Provider")
    )
    pending_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Pending Balance"))
    available_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Available Balance"))
    total_withdrawn = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Total Withdrawn"))
    
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Wallet: {self.provider.business_name} - Avail: {self.available_balance}"


class WalletTransactionType(models.TextChoices):
    EARNING_PENDING = "earning_pending", _("Earning (Pending Clearance)")
    EARNING_CLEARED = "earning_cleared", _("Earning (Cleared to Available)")
    WITHDRAWAL_REQUEST = "withdrawal_request", _("Withdrawal (Locked Funds)")
    WITHDRAWAL_REFUND = "withdrawal_refund", _("Withdrawal Failed (Refunded)")


class WalletTransaction(models.Model):
    """
    Immutable ledger for every financial movement affecting the ProviderWallet.
    Tracks the exact clearance date and admin overrides.
    """
    wallet = models.ForeignKey(ProviderWallet, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=30, choices=WalletTransactionType.choices)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Clearance Logic
    is_cleared = models.BooleanField(default=False, db_index=True)
    clearance_date = models.DateTimeField(null=True, blank=True, db_index=True)
    
    # Optional links for traceability
    source_payment = models.ForeignKey('PaymentTransaction', on_delete=models.SET_NULL, null=True, blank=True)
    description = models.CharField(max_length=255)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    @transaction.atomic
    def clear_funds(self):
        """
        Moves funds from pending_balance to available_balance.
        Can be triggered automatically by cron or manually by Admin override.
        """
        if self.transaction_type != WalletTransactionType.EARNING_PENDING or self.is_cleared:
            raise ValidationError("This transaction cannot be cleared.")
            
        # Lock wallet for update
        wallet = ProviderWallet.objects.select_for_update().get(pk=self.wallet.pk)
        
        wallet.pending_balance -= self.amount
        wallet.available_balance += self.amount
        wallet.save(update_fields=['pending_balance', 'available_balance', 'updated_at'])
        
        self.is_cleared = True
        self.transaction_type = WalletTransactionType.EARNING_CLEARED
        self.save(update_fields=['is_cleared', 'transaction_type'])
        
        logger.info(f"Funds Cleared: {self.amount} for {wallet.provider.business_name}")


class WithdrawalStatus(models.TextChoices):
    PENDING = "pending", _("Pending Admin Review")
    PROCESSING = "processing", _("Processing Bank Transfer")
    COMPLETED = "completed", _("Completed")
    REJECTED = "rejected", _("Rejected")


class WithdrawalRequest(models.Model):
    """
    Provider request to withdraw available funds.
    Locks the requested amount from the wallet immediately upon creation.
    """
    provider = models.ForeignKey('providers.Provider', on_delete=models.CASCADE, related_name='withdrawals')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=WithdrawalStatus.choices, default=WithdrawalStatus.PENDING)
    
    # Snapshot of bank details at the time of request for safety
    bank_name = models.CharField(max_length=255)
    iban = models.CharField(max_length=34)
    account_name = models.CharField(max_length=255, blank=True)
    
    admin_note = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    @transaction.atomic
    def reject_and_refund(self, note: str):
        """Admin action: Rejects withdrawal and refunds the wallet."""
        if self.status in [WithdrawalStatus.COMPLETED, WithdrawalStatus.REJECTED]:
            raise ValidationError("Cannot reject a completed or already rejected withdrawal.")
            
        wallet = ProviderWallet.objects.select_for_update().get(provider=self.provider)
        wallet.available_balance += self.amount
        wallet.save(update_fields=['available_balance', 'updated_at'])
        
        WalletTransaction.objects.create(
            wallet=wallet,
            transaction_type=WalletTransactionType.WITHDRAWAL_REFUND,
            amount=self.amount,
            is_cleared=True,
            description=f"Refund for rejected withdrawal #{self.pk}"
        )
        
        self.status = WithdrawalStatus.REJECTED
        self.admin_note = note
        self.save(update_fields=['status', 'admin_note', 'updated_at'])