import json
import logging
from datetime import timedelta
from decimal import Decimal, InvalidOperation

from django.views import View
from django.shortcuts import render, redirect
from django.contrib import messages
from django.db import transaction
from django.db.models import Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from apps.provider_portal.mixins import ProviderRequiredMixin
from apps.payments.models import (
    ProviderWallet,
    WalletTransaction,
    WithdrawalRequest,
    PaymentGlobalSetting,
    WalletTransactionType
)
from apps.gyms.models import GymSubscription

logger = logging.getLogger(__name__)

def calculate_net_revenue(gross_amount: Decimal, provider) -> Decimal:
    if not gross_amount:
        return Decimal('0.00')
    
    if provider.commission_type == 'percentage':
        commission = gross_amount * (provider.commission_value / Decimal('100.00'))
    else:
        commission = provider.commission_value
        
    net = gross_amount - commission
    return max(Decimal('0.00'), net)


class EarningsView(ProviderRequiredMixin, View):
    def get(self, request):
        provider = request.user.provider_profile
        wallet, _ = ProviderWallet.objects.get_or_create(provider=provider)
        
        transactions = WalletTransaction.objects.filter(wallet=wallet).order_by('-created_at')
        
        total_earnings = transactions.filter(
            transaction_type__in=[
                WalletTransactionType.EARNING_CLEARED,
                WalletTransactionType.EARNING_PENDING
            ]
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

        withdrawals = WithdrawalRequest.objects.filter(provider=provider).order_by('-created_at')

        try:
            hold_setting = PaymentGlobalSetting.load()
            hold_days = hold_setting.earnings_hold_days
        except Exception:
            hold_days = 3

        pending_txns = transactions.filter(
            is_cleared=False, 
            transaction_type=WalletTransactionType.EARNING_PENDING
        )
        
        pending_breakdown = []
        for txn in pending_txns:
            release_date = txn.created_at + timedelta(days=hold_days)
            diff = release_date - timezone.now()
            days_left = max(0, diff.days + (1 if diff.seconds > 0 else 0))
            
            pending_breakdown.append({
                'amount': txn.amount,
                'description': txn.description,
                'created_at': txn.created_at,
                'release_date': release_date,
                'days_left': days_left
            })

        six_months_ago = timezone.now() - timedelta(days=180)
        revenue_data = transactions.filter(
            transaction_type__in=[
                WalletTransactionType.EARNING_CLEARED,
                WalletTransactionType.EARNING_PENDING
            ],
            created_at__gte=six_months_ago
        ).annotate(
            month=TruncMonth('created_at')
        ).values('month').annotate(total=Sum('amount')).order_by('month')

        chart_labels = [data['month'].strftime('%b %Y') for data in revenue_data]
        chart_data = [float(data['total']) for data in revenue_data]

        branch_data = GymSubscription.objects.filter(
            plan__provider=provider,
            status__in=['active', 'expired']
        ).values('plan__branches__name').annotate(
            total_revenue=Sum('plan__price')
        ).order_by('-total_revenue')[:5]

        bar_labels = [data['plan__branches__name'] or str(_("General")) for data in branch_data]
        bar_data = [float(data['total_revenue']) for data in branch_data]

        context = {
            'wallet': wallet,
            'total_earnings': total_earnings,
            'transactions': transactions[:50], 
            'withdrawals': withdrawals,
            'pending_breakdown': pending_breakdown,
            'chart_labels': json.dumps(chart_labels),
            'chart_data': json.dumps(chart_data),
            'bar_labels': json.dumps(bar_labels),
            'bar_data': json.dumps(bar_data),
            'hold_days': hold_days,
        }
        return render(request, 'provider_portal/finance/earnings.html', context)


class WithdrawView(ProviderRequiredMixin, View):
    @transaction.atomic
    def post(self, request):
        provider = request.user.provider_profile
        wallet = ProviderWallet.objects.select_for_update().get(provider=provider)
        
        try:
            amount_str = request.POST.get('amount', '0')
            requested_amount = Decimal(amount_str)
            
            if not provider.bank_name or not provider.iban:
                messages.error(request, _("You must link a bank account before withdrawing funds."))
                return redirect('provider_portal:earnings')

            MIN_WITHDRAWAL = Decimal('100.00')
            if requested_amount < MIN_WITHDRAWAL:
                messages.error(request, _("Minimum withdrawal amount is 100."))
            elif requested_amount > wallet.available_balance:
                messages.error(request, _("Insufficient available balance."))
            else:
                wallet.available_balance -= requested_amount
                wallet.save(update_fields=['available_balance', 'updated_at'])
                
                withdrawal = WithdrawalRequest.objects.create(
                    provider=provider,
                    amount=requested_amount,
                    status='pending',
                    bank_name=provider.bank_name,
                    iban=provider.iban,
                    account_name=provider.business_name
                )
                
                WalletTransaction.objects.create(
                    wallet=wallet,
                    transaction_type=WalletTransactionType.WITHDRAWAL_REQUEST,
                    amount=-requested_amount,
                    is_cleared=True,
                    description=str(_("Withdrawal request #")) + str(withdrawal.pk)
                )
                
                logger.info(f"Withdrawal {withdrawal.pk} created for {provider.business_name}. Amount: {requested_amount}")
                messages.success(request, _("Withdrawal request submitted successfully. It is now pending review."))
                
        except InvalidOperation:
            messages.error(request, _("Invalid amount format."))
        except Exception as e:
            logger.error(f"Withdrawal failed: {str(e)}", exc_info=True)
            messages.error(request, _("An internal error occurred while processing your request."))

        return redirect('provider_portal:earnings')


class BankUpdateView(ProviderRequiredMixin, View):
    def post(self, request):
        provider = request.user.provider_profile
        bank_name = request.POST.get('bank_name', '').strip()
        iban = request.POST.get('iban', '').strip()
        
        if bank_name and iban:
            provider.bank_name = bank_name
            provider.iban = iban
            provider.save(update_fields=['bank_name', 'iban', 'updated_at'])
            messages.success(request, _("Bank account details updated successfully."))
        else:
            messages.error(request, _("Please provide both Bank Name and IBAN."))
            
        return redirect('provider_portal:earnings')