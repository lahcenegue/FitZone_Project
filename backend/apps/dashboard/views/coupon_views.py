# apps/dashboard/views/coupon_views.py

import logging
from decimal import Decimal
from django.views.generic import ListView, CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext as _
from django.db.models import Count, Q, Sum
from django.utils import timezone
from django.http import HttpResponseRedirect

from apps.coupons.models import CouponDefinition, UserCoupon, CouponSource
from apps.dashboard.mixins import SuperuserRequiredMixin
from apps.dashboard.forms import CreateCouponDefinitionForm

logger = logging.getLogger(__name__)

class ManageCouponsListView(SuperuserRequiredMixin, ListView):
    """
    Displays strictly Marketing Campaigns with real-time usage statistics.
    Template Path: dashboard/coupons/coupons_list.html
    """
    model = CouponDefinition
    template_name = "dashboard/coupons/coupons_list.html"
    context_object_name = "coupons"
    paginate_by = 12

    def _calculate_percentage(self, part, total):
        if not total or total <= 0:
            return 0
        percentage = (Decimal(part) / Decimal(total)) * Decimal('100')
        return min(int(percentage), 100)

    def get_queryset(self):
        queryset = CouponDefinition.objects.filter(source=CouponSource.MARKETING).annotate(
            total_usage=Count('generated_coupons', filter=Q(generated_coupons__is_used=True)),
            fiat_saved=Sum('generated_coupons__fiat_discount_applied', filter=Q(generated_coupons__is_used=True))
        )

        search_query = self.request.GET.get('q', '').strip()
        status_filter = self.request.GET.get('status', '')
        type_filter = self.request.GET.get('type', '').strip()
        sort_by = self.request.GET.get('sort', '-created_at')

        # Apply Search Query Filter
        if search_query:
            queryset = queryset.filter(
                Q(title__icontains=search_query) | 
                Q(code__icontains=search_query)
            ).distinct()
            
        # Apply Status Filter
        if status_filter == 'active':
            queryset = queryset.filter(is_active=True)
        elif status_filter == 'paused':
            queryset = queryset.filter(is_active=False)

        # Apply Coupon Type Filter
        if type_filter:
            queryset = queryset.filter(coupon_type=type_filter)

        # Apply Smart Sorting & Complex Filtering logic
        if sort_by == '-total_usage':
            queryset = queryset.order_by('-total_usage', '-created_at')
        elif sort_by == 'unused':
            queryset = queryset.filter(total_usage=0).order_by('-created_at')
        elif sort_by == 'expiring_soon':
            current_time = timezone.now()
            queryset = queryset.filter(expiration_date__gt=current_time).order_by('expiration_date')
        else:
            queryset = queryset.order_by('-created_at')

        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Coupons Management")
        
        marketing_coupons = CouponDefinition.objects.filter(source=CouponSource.MARKETING)
        marketing_user_coupons = UserCoupon.objects.filter(definition__source=CouponSource.MARKETING)
        
        total_campaigns = marketing_coupons.count()
        total_active_rules = marketing_coupons.filter(is_active=True).count()
        active_percentage = self._calculate_percentage(total_active_rules, total_campaigns)
        
        total_generated = marketing_user_coupons.count()
        total_redeemed = marketing_user_coupons.filter(is_used=True).count()
        redemption_percentage = self._calculate_percentage(total_redeemed, total_generated)
        
        thirty_days_ago = timezone.now() - timezone.timedelta(days=30)
        fiat_aggregates = marketing_user_coupons.filter(is_used=True).aggregate(
            total_fiat=Sum('fiat_discount_applied'),
            recent_fiat=Sum('fiat_discount_applied', filter=Q(used_at__gte=thirty_days_ago))
        )
        
        total_fiat_saved = fiat_aggregates['total_fiat'] or Decimal('0.00')
        recent_fiat_saved = fiat_aggregates['recent_fiat'] or Decimal('0.00')
        fiat_percentage = self._calculate_percentage(recent_fiat_saved, total_fiat_saved)
        
        context['stats'] = {
            'total_active_rules': total_active_rules,
            'active_percentage': active_percentage,
            'total_redeemed': total_redeemed,
            'redemption_percentage': redemption_percentage,
            'total_fiat_saved': total_fiat_saved,
            'fiat_percentage': fiat_percentage,
        }
        
        context['current_filters'] = {
            'q': self.request.GET.get('q', ''),
            'status': self.request.GET.get('status', ''),
            'sort': self.request.GET.get('sort', '-created_at'),
            'type': self.request.GET.get('type', ''),
        }
        return context


class CreateCouponView(SuperuserRequiredMixin, CreateView):
    model = CouponDefinition
    form_class = CreateCouponDefinitionForm
    template_name = "dashboard/coupons/coupon_form.html"
    success_url = reverse_lazy('dashboard:coupons_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Create Marketing Campaign")
        context['action_title'] = _("Save & Activate")
        return context

    def form_valid(self, form):
        messages.success(self.request, _("Marketing campaign has been established successfully."))
        return super().form_valid(form)

    def form_invalid(self, form):
        messages.error(self.request, _("Failed to create campaign. Please correct the errors below."))
        return super().form_invalid(form)


class UpdateCouponView(SuperuserRequiredMixin, UpdateView):
    model = CouponDefinition
    form_class = CreateCouponDefinitionForm
    template_name = "dashboard/coupons/coupon_form.html"
    success_url = reverse_lazy('dashboard:coupons_list')

    def get_queryset(self):
        return CouponDefinition.objects.filter(source=CouponSource.MARKETING)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Update Marketing Campaign")
        context['action_title'] = _("Update Changes")
        return context

    def form_valid(self, form):
        messages.success(self.request, _("Marketing campaign has been updated successfully."))
        return super().form_valid(form)

    def form_invalid(self, form):
        messages.error(self.request, _("Failed to update campaign. Please correct the errors below."))
        return super().form_invalid(form)


class DeleteCouponView(SuperuserRequiredMixin, DeleteView):
    model = CouponDefinition
    success_url = reverse_lazy('dashboard:coupons_list')

    def get_queryset(self):
        return CouponDefinition.objects.filter(source=CouponSource.MARKETING)

    def delete(self, request, *args, **kwargs):
        coupon = self.get_object()
        
        if coupon.generated_coupons.filter(is_used=True).exists():
            messages.error(request, _("Cannot delete this campaign because it has already been used by customers. Please pause it instead."))
            return HttpResponseRedirect(self.success_url)
            
        messages.success(request, _("Marketing campaign deleted successfully."))
        return super().delete(request, *args, **kwargs)