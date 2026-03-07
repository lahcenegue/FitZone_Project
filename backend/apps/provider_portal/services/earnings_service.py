"""
Earnings service for the Provider Portal.
Handles earnings overview, transaction history, and withdrawal requests.
"""

import logging
from decimal import Decimal
from django.core.paginator import Paginator
from django.utils.translation import gettext_lazy as _
from apps.providers.models import Provider
from apps.payments.models import Transaction, WithdrawalRequest
from ..constants import PAGE_SIZE_TRANSACTIONS, WITHDRAWAL_MIN_AMOUNT, WITHDRAWAL_MAX_AMOUNT

logger = logging.getLogger(__name__)


class EarningsServiceError(Exception):
    """Raised when an earnings operation fails for a known, user-facing reason."""
    pass


def get_earnings_summary(provider: Provider) -> dict:
    """
    Return a summary of the provider's earnings.
    Calculates total earned, pending, and withdrawn amounts.

    Args:
        provider: The authenticated Provider instance.

    Returns:
        Dict with keys: total_earned, pending, withdrawn, available.
    """
    from django.db.models import Sum

    transactions = Transaction.objects.filter(provider=provider)

    total_earned = transactions.filter(
        status="completed"
    ).aggregate(total=Sum("amount"))["total"] or Decimal("0.00")

    withdrawn = transactions.filter(
        transaction_type="withdrawal",
        status="completed",
    ).aggregate(total=Sum("amount"))["total"] or Decimal("0.00")

    pending = transactions.filter(
        status="pending"
    ).aggregate(total=Sum("amount"))["total"] or Decimal("0.00")

    available = total_earned - withdrawn

    return {
        "total_earned": total_earned,
        "pending":      pending,
        "withdrawn":    withdrawn,
        "available":    available,
    }


def get_transaction_history(provider: Provider, page: int = 1):
    """
    Return paginated transaction history for the given provider.

    Args:
        provider: The authenticated Provider instance.
        page: Page number for pagination.

    Returns:
        Django Page object containing Transaction instances.
    """
    transactions = Transaction.objects.filter(
        provider=provider
    ).order_by("-created_at")

    paginator = Paginator(transactions, PAGE_SIZE_TRANSACTIONS)
    return paginator.get_page(page)


def create_withdrawal_request(provider: Provider, amount: Decimal, notes: str = "") -> WithdrawalRequest:
    """
    Submit a withdrawal request for the given provider.
    Validates amount against available balance before creating the request.

    Args:
        provider: The authenticated Provider instance.
        amount: Requested withdrawal amount in SAR.
        notes: Optional notes from the provider.

    Returns:
        Newly created WithdrawalRequest instance.

    Raises:
        EarningsServiceError: If amount exceeds available balance or limits.
    """
    if not provider.has_financial_info:
        raise EarningsServiceError(
            _("Please add your bank details before requesting a withdrawal.")
        )

    summary = get_earnings_summary(provider)
    available = summary["available"]

    if amount > available:
        raise EarningsServiceError(
            _("Withdrawal amount exceeds your available balance of %(balance)s SAR.") % {
                "balance": available,
            }
        )

    if amount < WITHDRAWAL_MIN_AMOUNT:
        raise EarningsServiceError(
            _("Minimum withdrawal amount is %(min)s SAR.") % {
                "min": WITHDRAWAL_MIN_AMOUNT,
            }
        )

    if amount > WITHDRAWAL_MAX_AMOUNT:
        raise EarningsServiceError(
            _("Maximum withdrawal amount is %(max)s SAR.") % {
                "max": WITHDRAWAL_MAX_AMOUNT,
            }
        )

    try:
        withdrawal = WithdrawalRequest.objects.create(
            provider=provider,
            amount=amount,
            notes=notes,
            status="pending",
        )

        logger.info(
            "Withdrawal requested | provider: %s | amount: %s",
            provider.business_name, amount,
        )
        return withdrawal

    except Exception as exc:
        logger.error(
            "Withdrawal request failed | provider: %s | error: %s",
            provider.business_name, str(exc),
        )
        raise EarningsServiceError(
            _("Failed to submit withdrawal request. Please try again.")
        ) from exc


def get_withdrawal_history(provider: Provider, page: int = 1):
    """
    Return paginated withdrawal request history for the given provider.

    Args:
        provider: The authenticated Provider instance.
        page: Page number for pagination.

    Returns:
        Django Page object containing WithdrawalRequest instances.
    """
    withdrawals = WithdrawalRequest.objects.filter(
        provider=provider
    ).order_by("-created_at")

    paginator = Paginator(withdrawals, PAGE_SIZE_TRANSACTIONS)
    return paginator.get_page(page)