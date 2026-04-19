"""
Dashboard views for the FitZone Provider Portal.
Serves as a Business Intelligence (BI) engine extracting deep analytics.
"""

import logging
from datetime import timedelta
from decimal import Decimal

from django.views import View
from django.shortcuts import render, redirect
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse
from django.utils import timezone
from django.db.models import Count, Sum, Avg, Q, F
from django.db.models.functions import TruncDate, TruncMonth, ExtractHour

from apps.gyms.models import GymSubscription, GymBranch, GymVisit, GymReview, SubscriptionPlan
from apps.payments.models import ProviderWallet, WalletTransaction

logger = logging.getLogger(__name__)

# Constants for Analytics
CHURN_WARNING_DAYS = 7
TREND_DAYS = 7
PEAK_HOURS_DAYS = 30
REVENUE_MONTHS = 6
DEFAULT_STAY_DURATION_MINS = 120


class DashboardView(LoginRequiredMixin, View):
    """
    GET /portal/dashboard/
    Enterprise Command Center Dashboard.
    Fetches real-time operational, financial, and analytical data.
    """
    template_name = "provider_portal/dashboard/dashboard.html"

    def _process_auto_checkouts(self, provider):
        """
        Scans active visits and auto-checkouts users who exceeded the branch's
        estimated_stay_duration. Ensures live occupancy data is highly accurate.
        """
        now = timezone.now()
        active_visits = GymVisit.objects.filter(
            branch__provider=provider,
            is_active=True
        ).select_related('branch')

        stale_visits = []
        for visit in active_visits:
            duration = visit.branch.estimated_stay_duration or DEFAULT_STAY_DURATION_MINS
            expected_checkout_time = visit.check_in_time + timedelta(minutes=duration)
            
            if expected_checkout_time <= now:
                visit.is_active = False
                visit.check_out_time = expected_checkout_time
                stale_visits.append(visit)

        if stale_visits:
            GymVisit.objects.bulk_update(stale_visits, ['is_active', 'check_out_time'])
            logger.info(f"Auto-checked out {len(stale_visits)} stale visits for {provider.business_name}.")

    def _get_financial_kpis(self, provider):
        """Calculates total revenue across all streams."""
        wallet = ProviderWallet.objects.filter(provider=provider).first()
        if wallet:
            return wallet.available_balance + wallet.pending_balance + wallet.total_withdrawn
        return Decimal('0.00')

    def _get_wallet_data(self, provider):
        """Returns the provider's wallet object for financial summary."""
        wallet = ProviderWallet.objects.filter(provider=provider).first()
        if not wallet:
            return {
                'available_balance': Decimal('0.00'),
                'pending_balance': Decimal('0.00'),
                'total_withdrawn': Decimal('0.00'),
            }
        return wallet

    def _get_demographics_data(self, active_subscriptions):
        """Extracts gender distribution for business intelligence."""
        demo_qs = active_subscriptions.values('user__gender').annotate(count=Count('id'))
        demo_dict = {item['user__gender']: item['count'] for item in demo_qs}
        
        return {
            'labels': ['Male', 'Female', 'Unspecified'],
            'data': [
                demo_dict.get('male', 0),
                demo_dict.get('female', 0),
                demo_dict.get('unspecified', 0)
            ]
        }

    def _get_peak_hours_data(self, provider, now):
        """Analyzes the busiest hours over the last 30 days."""
        thirty_days_ago = now - timedelta(days=PEAK_HOURS_DAYS)
        peak_hours_qs = GymVisit.objects.filter(
            branch__provider=provider,
            check_in_time__gte=thirty_days_ago
        ).annotate(
            hour=ExtractHour('check_in_time')
        ).values('hour').annotate(
            count=Count('id')
        ).order_by('hour')

        hours_dict = {item['hour']: item['count'] for item in peak_hours_qs if item['hour'] is not None}
        
        # 0 to 23 hours coverage
        labels = [f"{h:02d}:00" for h in range(24)]
        data = [hours_dict.get(h, 0) for h in range(24)]
        
        return {'labels': labels, 'data': data}

    def _get_revenue_trend(self, provider, now):
        """Monthly revenue trend for the last 6 months from wallet transactions."""
        six_months_ago = now - timedelta(days=REVENUE_MONTHS * 30)
        
        revenue_qs = WalletTransaction.objects.filter(
            wallet__provider=provider,
            transaction_type__in=['earning_pending', 'earning_cleared'],
            created_at__gte=six_months_ago
        ).annotate(
            month=TruncMonth('created_at')
        ).values('month').annotate(
            total=Sum('amount')
        ).order_by('month')

        revenue_dict = {}
        for item in revenue_qs:
            if item['month']:
                key = item['month'].strftime('%Y-%m')
                revenue_dict[key] = float(item['total'] or 0)

        labels = []
        data = []
        for i in range(REVENUE_MONTHS - 1, -1, -1):
            target = (now - timedelta(days=i * 30))
            key = target.strftime('%Y-%m')
            labels.append(target.strftime('%b %Y'))
            data.append(revenue_dict.get(key, 0))

        return {'labels': labels, 'data': data}

    def _get_top_plans(self, provider):
        """Returns the top performing plans ranked by active subscriber count."""
        plans = SubscriptionPlan.objects.filter(
            provider=provider,
            is_archived=False
        ).annotate(
            active_subs=Count('subscribers', filter=Q(subscribers__status='active')),
            total_revenue=Sum(
                'subscribers__payment__amount',
                filter=Q(subscribers__payment__status='success')
            )
        ).order_by('-active_subs')[:5]

        return plans

    def _get_branch_occupancy(self, provider):
        """Returns live occupancy stats for each active branch."""
        branches = GymBranch.objects.filter(
            provider=provider,
            is_active=True
        ).annotate(
            current_occupancy=Count(
                'visits',
                filter=Q(visits__is_active=True)
            )
        ).order_by('-current_occupancy')

        result = []
        for branch in branches:
            capacity = branch.max_capacity or 100
            occupancy = branch.current_occupancy or 0
            percentage = min(round((occupancy / capacity) * 100), 100) if capacity > 0 else 0
            result.append({
                'name': branch.name,
                'occupancy': occupancy,
                'capacity': capacity,
                'percentage': percentage,
                'city': branch.city,
            })
        return result

    def get(self, request):
        if not hasattr(request.user, "provider_profile"):
            logger.warning(f"User {request.user.email} attempted portal access without a provider profile.")
            return redirect("provider_portal:login")

        provider = request.user.provider_profile
        
        context = {
            "provider": provider,
            "is_gym": provider.provider_type == "gym",
            "is_trainer": provider.provider_type == "trainer",
            "is_restaurant": provider.provider_type == "restaurant",
            "is_store": provider.provider_type == "store",
            "has_documents": provider.documents.exists(),
        }

        if provider.provider_type == "gym":
            try:
                # 1. Clean up stale data before calculating metrics
                self._process_auto_checkouts(provider)

                now = timezone.now()
                today = now.date()
                warning_date = today + timedelta(days=CHURN_WARNING_DAYS)
                trend_start_date = now - timedelta(days=TREND_DAYS - 1)

                active_subscriptions = GymSubscription.objects.filter(plan__provider=provider, status='active')
                all_subscriptions = GymSubscription.objects.filter(plan__provider=provider)

                # 2. Core KPIs
                context['total_active_subs'] = active_subscriptions.count()
                context['total_branches'] = GymBranch.objects.filter(provider=provider, is_active=True).count()
                context['total_revenue'] = self._get_financial_kpis(provider)
                context['live_occupancy'] = GymVisit.objects.filter(branch__provider=provider, is_active=True).count()

                # 3. NEW KPIs
                context['todays_visits'] = GymVisit.objects.filter(
                    branch__provider=provider,
                    check_in_time__date=today
                ).count()

                context['new_subs_month'] = GymSubscription.objects.filter(
                    plan__provider=provider,
                    purchased_at__year=now.year,
                    purchased_at__month=now.month
                ).count()

                # 4. Financial Summary (wallet data)
                context['wallet'] = self._get_wallet_data(provider)

                # 5. Expiring Soon (Churn Prevention)
                context['expiring_subs'] = active_subscriptions.filter(
                    end_date__gte=today,
                    end_date__lte=warning_date
                ).select_related('user', 'plan').order_by('end_date')[:8]

                # 6. Live Activity Feed (Includes real checkout times now)
                context['recent_visits'] = GymVisit.objects.select_related(
                    'subscription__user', 
                    'branch',
                    'subscription__plan'
                ).filter(
                    branch__provider=provider
                ).order_by('-check_in_time')[:15]

                # 7. Chart Data: Attendance Trend (Last 7 Days)
                visits_trend = GymVisit.objects.filter(
                    branch__provider=provider,
                    check_in_time__gte=trend_start_date
                ).annotate(
                    date=TruncDate('check_in_time')
                ).values('date').annotate(
                    count=Count('id')
                ).order_by('date')

                trend_dict = {entry['date'].strftime('%Y-%m-%d'): entry['count'] for entry in visits_trend if entry['date']}
                trend_labels, trend_data = [], []
                for i in range(TREND_DAYS - 1, -1, -1):
                    current_date = (today - timedelta(days=i)).strftime('%Y-%m-%d')
                    trend_labels.append(current_date)
                    trend_data.append(trend_dict.get(current_date, 0))
                
                context['chart_trend_labels'] = trend_labels
                context['chart_trend_data'] = trend_data

                # 8. Chart Data: Demographics
                demographics = self._get_demographics_data(active_subscriptions)
                context['chart_demo_labels'] = demographics['labels']
                context['chart_demo_data'] = demographics['data']

                # 9. Chart Data: Peak Hours
                peak_hours = self._get_peak_hours_data(provider, now)
                context['chart_peak_labels'] = peak_hours['labels']
                context['chart_peak_data'] = peak_hours['data']

                # 10. NEW: Revenue Trend (6 Months)
                revenue_trend = self._get_revenue_trend(provider, now)
                context['chart_revenue_labels'] = revenue_trend['labels']
                context['chart_revenue_data'] = revenue_trend['data']

                # 11. NEW: Top Plans Performance
                context['top_plans'] = self._get_top_plans(provider)

                # 12. NEW: Branch Capacity Utilization
                context['branch_occupancy'] = self._get_branch_occupancy(provider)

                # 13. NEW: Total visits count (all time)
                context['total_visits'] = GymVisit.objects.filter(branch__provider=provider).count()

                # 14. NEW: Review stats
                reviews = GymReview.objects.filter(branch__provider=provider)
                context['avg_rating'] = reviews.aggregate(avg=Avg('rating'))['avg']
                context['total_reviews'] = reviews.count()

            except Exception as e:
                logger.error(f"Dashboard data aggregation failed for provider {provider.id}: {str(e)}", exc_info=True)
                # Fail gracefully, UI will show empty states rather than crashing
                context['error_state'] = True

        return render(request, self.template_name, context)


class NotificationsView(View):
    def get(self, request): 
        return HttpResponse('Notifications Page')


class MarkNotificationReadView(View):
    def post(self, request, notification_id): 
        return HttpResponse('Marked as read')