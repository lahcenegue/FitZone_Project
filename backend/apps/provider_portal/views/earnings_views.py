import logging
from datetime import timedelta
from decimal import Decimal, InvalidOperation
from django.views import View
from django.shortcuts import render, redirect
from django.contrib import messages
from django.db import transaction
from django.db.models import Sum, Count, Q
from django.db.models.functions import TruncMonth
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from apps.provider_portal.mixins import ProviderRequiredMixin
from apps.payments.models import ProviderWallet, WalletTransaction, WithdrawalRequest, PaymentGlobalSetting
from apps.gyms.models import GymSubscription

logger = logging.getLogger(__name__)

# --- Helper Methods ---
def calculate_net_revenue(gross_amount: Decimal, provider) -> Decimal:
    """Calculates net revenue by deducting the platform commission."""
    if not gross_amount:
        return Decimal('0.00')
    
    if provider.commission_type == 'percentage':
        commission = gross_amount * (provider.commission_value / Decimal('100.00'))
    else:
        commission = provider.commission_value
        
    net = gross_amount - commission
    return max(Decimal('0.00'), net)


class EarningsView(ProviderRequiredMixin, View):
    """
    GET /portal/earnings/
    Enterprise Data Engine feeding multiple charts and deep financial analytics.
    """
    def get(self, request):
        provider = request.user.provider_profile
        wallet, _ = ProviderWallet.objects.get_or_create(provider=provider)
        
        # 1. CORE KPIs (Gross vs Net)
        valid_subscriptions = GymSubscription.objects.filter(
            plan__provider=provider,
            status__in=['active', 'expired']
        )
        gross_volume = valid_subscriptions.aggregate(total=Sum('plan__price'))['total'] or Decimal('0.00')
        net_revenue = calculate_net_revenue(gross_volume, provider)

        # Temporary sync for existing dummy data (Ensures wallet matches net revenue initially)
        if wallet.available_balance == Decimal('0.00') and net_revenue > Decimal('0.00') and wallet.total_withdrawn == Decimal('0.00'):
            wallet.available_balance = net_revenue
            wallet.save(update_fields=['available_balance'])

        # 2. HOLD PERIOD TRANSPARENCY (Next Clearance)
        next_clearance_txn = WalletTransaction.objects.filter(
            wallet=wallet, 
            is_cleared=False, 
            transaction_type='earning_pending'
        ).order_by('clearance_date').first()
        
        next_clearance_date = next_clearance_txn.clearance_date if next_clearance_txn else None
        next_clearance_amount = next_clearance_txn.amount if next_clearance_txn else Decimal('0.00')

        # 3. GRANULAR LEDGER & WITHDRAWALS
        # Fetching 100 transactions for frontend JS DataTables (Filtering/CSV Export)
        transactions_ledger = WalletTransaction.objects.filter(wallet=wallet).order_by('-created_at')[:100]
        recent_withdrawals = WithdrawalRequest.objects.filter(provider=provider).order_by('-created_at')[:10]

        # 4. CHART 1: REVENUE TIMELINE (Area/Line Chart)
        six_months_ago = timezone.now() - timedelta(days=30 * 6)
        monthly_revenue_qs = valid_subscriptions.filter(
            start_date__gte=six_months_ago.date()
        ).annotate(
            month=TruncMonth('start_date')
        ).values('month').annotate(
            revenue=Sum('plan__price')
        ).order_by('month')

        timeline_labels = []
        timeline_data = []
        for entry in monthly_revenue_qs:
            if entry['month']:
                timeline_labels.append(entry['month'].strftime('%b %Y'))
                net_val = calculate_net_revenue(entry['revenue'], provider)
                timeline_data.append(float(net_val))

        # 5. CHART 2: TOP PLANS DISTRIBUTION (Doughnut/Pie Chart)
        plans_distribution = valid_subscriptions.values('plan__name').annotate(
            total=Count('id')
        ).order_by('-total')[:5]
        
        pie_labels = [p['plan__name'] for p in plans_distribution]
        pie_data = [p['total'] for p in plans_distribution]

        # 6. CHART 3: BRANCH PERFORMANCE (Bar Chart)
        branch_performance = valid_subscriptions.filter(
            plan__branches__isnull=False
        ).values('plan__branches__name').annotate(
            revenue=Sum('plan__price')
        ).order_by('-revenue')[:5]

        bar_labels = [b['plan__branches__name'] for b in branch_performance]
        bar_data = [float(b['revenue'] or 0) for b in branch_performance]

        context = {
            'provider': provider,
            'wallet': wallet,
            'gross_volume': gross_volume,
            'net_revenue': net_revenue,
            'next_clearance_date': next_clearance_date,
            'next_clearance_amount': next_clearance_amount,
            'transactions_ledger': transactions_ledger,
            'recent_withdrawals': recent_withdrawals,
            'has_bank_info': provider.has_financial_info,
            
            # JSON Serialized Chart Data
            'chart_timeline_labels': timeline_labels,
            'chart_timeline_data': timeline_data,
            'chart_pie_labels': pie_labels,
            'chart_pie_data': pie_data,
            'chart_bar_labels': bar_labels,
            'chart_bar_data': bar_data,
        }
        
        return render(request, 'provider_portal/finance/earnings.html', context)


class WithdrawView(ProviderRequiredMixin, View):
    """
    POST /portal/earnings/withdraw/
    Handles secure payout requests.
    """
    def post(self, request):
        provider = request.user.provider_profile
        
        if not provider.has_financial_info:
            messages.error(request, _("You must configure your bank details first."))
            return redirect('provider_portal:earnings')

        try:
            amount_str = request.POST.get('amount', '0')
            requested_amount = Decimal(amount_str)
        except InvalidOperation:
            messages.error(request, _("Invalid amount format."))
            return redirect('provider_portal:earnings')

        if requested_amount <= 0:
            messages.error(request, _("Withdrawal amount must be greater than zero."))
            return redirect('provider_portal:earnings')

        try:
            with transaction.atomic():
                wallet = ProviderWallet.objects.select_for_update().get(provider=provider)
                
                if requested_amount > wallet.available_balance:
                    messages.error(request, _("Insufficient available balance."))
                    return redirect('provider_portal:earnings')
                
                wallet.available_balance -= requested_amount
                wallet.save(update_fields=['available_balance', 'updated_at'])
                
                withdrawal = WithdrawalRequest.objects.create(
                    provider=provider,
                    amount=requested_amount,
                    bank_name=provider.bank_name,
                    iban=provider.iban,
                    account_name=provider.business_name
                )
                
                WalletTransaction.objects.create(
                    wallet=wallet,
                    transaction_type='withdrawal_request',
                    amount=-requested_amount,
                    is_cleared=True,
                    description=str(_("Withdrawal request #")) + str(withdrawal.pk)
                )
                
                logger.info(f"Withdrawal {withdrawal.pk} created for {provider.business_name}. Amount: {requested_amount}")
                messages.success(request, _("Withdrawal request submitted successfully."))
                
        except Exception as e:
            logger.error(f"Withdrawal failed: {str(e)}", exc_info=True)
            messages.error(request, _("An internal error occurred."))

        return redirect('provider_portal:earnings')


class BankUpdateView(ProviderRequiredMixin, View):
    """
    POST /portal/earnings/bank-update/
    Allows the provider to update bank details directly from the earnings dashboard.
    """
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