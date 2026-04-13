import uuid
import logging
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

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