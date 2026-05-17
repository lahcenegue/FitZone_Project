# apps/dashboard/views/loyalty_views.py

import logging
from decimal import Decimal
from django.db.models import Count, Q, Prefetch, Max, Sum
from django.views.generic import ListView, CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext as _
from django.contrib.auth import get_user_model

from apps.loyalty.models import PointPackage, MilestoneReward, Milestone, RewardActionType, UserMilestone
from apps.dashboard.mixins import SuperuserRequiredMixin
from apps.dashboard.forms import PointPackageForm, MilestoneRewardForm, MilestoneForm

logger = logging.getLogger(__name__)

User = get_user_model()

# ==========================================
# Point Packages Management
# ==========================================

class PointPackageListView(SuperuserRequiredMixin, ListView):
    model = PointPackage
    template_name = "dashboard/loyalty/packages_list.html"
    context_object_name = "packages"
    paginate_by = 12

    def get_queryset(self):
        return PointPackage.objects.all().order_by('price')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Point Packages")

        # 1. Total Revenue generated from all packages
        total_revenue = PointPackage.objects.aggregate(total=Sum('total_revenue'))['total'] or Decimal('0.00')
        
        # 2. Total Number of packages sold
        total_sold = PointPackage.objects.aggregate(total=Sum('total_purchases'))['total'] or 0
        
        # 3. Active Packages count
        active_packages = PointPackage.objects.filter(is_active=True).count()
        
        # 4. Best Seller logic (Must have at least 1 purchase)
        best_seller = PointPackage.objects.filter(total_purchases__gt=0).order_by('-total_purchases').first()
        
        context['stats'] = {
            'total_revenue': float(total_revenue),
            'total_sold': total_sold,
            'active_packages': active_packages,
            'best_seller_name': best_seller.name if best_seller else str(_("None Yet")),
            'best_seller_id': best_seller.id if best_seller else None
        }

        return context

class PointPackageCreateView(SuperuserRequiredMixin, CreateView):
    model = PointPackage
    form_class = PointPackageForm
    template_name = "dashboard/loyalty/package_form.html"
    success_url = reverse_lazy('dashboard:packages_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Create Point Package")
        context['action_title'] = _("Save & Activate")
        return context

    def form_valid(self, form):
        messages.success(self.request, _("Point package created successfully."))
        return super().form_valid(form)

class PointPackageUpdateView(SuperuserRequiredMixin, UpdateView):
    model = PointPackage
    form_class = PointPackageForm
    template_name = "dashboard/loyalty/package_form.html"
    success_url = reverse_lazy('dashboard:packages_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Update Point Package")
        context['action_title'] = _("Update Changes")
        return context

    def form_valid(self, form):
        messages.success(self.request, _("Point package updated successfully."))
        return super().form_valid(form)

class PointPackageDeleteView(SuperuserRequiredMixin, DeleteView):
    model = PointPackage
    success_url = reverse_lazy('dashboard:packages_list')

    def delete(self, request, *args, **kwargs):
        messages.success(request, _("Point package deleted successfully."))
        return super().delete(request, *args, **kwargs)


# ==========================================
# Rewards Catalog Management
# ==========================================

class RewardListView(SuperuserRequiredMixin, ListView):
    model = MilestoneReward
    template_name = "dashboard/loyalty/rewards_list.html"
    context_object_name = "rewards"
    paginate_by = 12

    def get_queryset(self):
        return MilestoneReward.objects.all().order_by('-created_at')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Rewards Catalog")

        total_rewards = MilestoneReward.objects.count()
        active_rewards = MilestoneReward.objects.filter(is_active=True).count()
        active_rate = int((active_rewards / total_rewards) * 100) if total_rewards > 0 else 0

        user_milestones = UserMilestone.objects.all()
        total_claims = user_milestones.filter(is_claimed=True).count()
        total_consumed = user_milestones.filter(is_consumed=True).count()
        consumption_rate = int((total_consumed / total_claims) * 100) if total_claims > 0 else 0

        manual_gifts_given = user_milestones.filter(
            is_consumed=True,
            milestone__reward__action_type=RewardActionType.MANUAL_FULFILLMENT
        ).count()

        top_reward = MilestoneReward.objects.annotate(
            consumption_count=Count('milestones__unlocked_by_users', filter=Q(milestones__unlocked_by_users__is_consumed=True))
        ).order_by('-consumption_count').first()

        top_reward_count = top_reward.consumption_count if top_reward else 0
        top_reward_name = top_reward.name if top_reward and top_reward_count > 0 else str(_("None Yet"))

        action_distribution = list(MilestoneReward.objects.values('action_type').annotate(count=Count('id')))
        colors = {
            RewardActionType.GENERATE_COUPON: '#D49BEB', 
            RewardActionType.SYSTEM_ROAMING: '#14B8A6',  
            RewardActionType.SYSTEM_EXTENSION: '#3B82F6',
            RewardActionType.MANUAL_FULFILLMENT: '#F59E0B'
        }
        
        dist_data = []
        for d in action_distribution:
            pct = int((d['count'] / total_rewards) * 100) if total_rewards > 0 else 0
            if pct > 0:
                dist_data.append({
                    'label': str(_(dict(RewardActionType.choices).get(d['action_type'], d['action_type']))),
                    'count': d['count'],
                    'pct': pct,
                    'color': colors.get(d['action_type'], '#94A3B8')
                })

        context['stats'] = {
            'total_claims': total_claims,
            'consumption_rate': consumption_rate,
            'manual_gifts_given': manual_gifts_given,
            'top_reward_count': top_reward_count,
            'top_reward_name': top_reward_name,
            'active_rewards': active_rewards,
            'active_rate': active_rate,
            'distribution': dist_data
        }

        return context

class RewardCreateView(SuperuserRequiredMixin, CreateView):
    model = MilestoneReward
    form_class = MilestoneRewardForm
    template_name = "dashboard/loyalty/reward_form.html"
    success_url = reverse_lazy('dashboard:rewards_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Create Reward")
        context['action_title'] = _("Save Reward")
        return context

    def form_valid(self, form):
        messages.success(self.request, _("Reward defined successfully."))
        return super().form_valid(form)

class RewardUpdateView(SuperuserRequiredMixin, UpdateView):
    model = MilestoneReward
    form_class = MilestoneRewardForm
    template_name = "dashboard/loyalty/reward_form.html"
    success_url = reverse_lazy('dashboard:rewards_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Update Reward")
        context['action_title'] = _("Update Changes")
        return context

    def form_valid(self, form):
        messages.success(self.request, _("Reward updated successfully."))
        return super().form_valid(form)

class RewardDeleteView(SuperuserRequiredMixin, DeleteView):
    model = MilestoneReward
    success_url = reverse_lazy('dashboard:rewards_list')

    def delete(self, request, *args, **kwargs):
        messages.success(request, _("Reward deleted successfully."))
        return super().delete(request, *args, **kwargs)


# ==========================================
# Milestones Roadmap Management
# ==========================================

class MilestoneListView(SuperuserRequiredMixin, ListView):
    model = Milestone
    template_name = "dashboard/loyalty/milestones_list.html"
    context_object_name = "milestones"
    paginate_by = 12

    def get_queryset(self):
        return Milestone.objects.all().select_related('reward').order_by('required_lifetime_points')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Milestones Roadmap")

        total_milestones = Milestone.objects.count()
        active_milestones = Milestone.objects.filter(is_active=True).count()
        active_rate = int((active_milestones / total_milestones) * 100) if total_milestones > 0 else 0

        total_achievements = UserMilestone.objects.count()

        highest_points_agg = Milestone.objects.filter(is_active=True).aggregate(max_pts=Max('required_lifetime_points'))
        highest_points_target = highest_points_agg['max_pts'] if highest_points_agg['max_pts'] is not None else 0

        top_milestone = Milestone.objects.annotate(
            reach_count=Count('unlocked_by_users')
        ).order_by('-reach_count').first()

        top_milestone_count = top_milestone.reach_count if top_milestone else 0
        top_milestone_title = top_milestone.title if top_milestone and top_milestone_count > 0 else str(_("None Yet"))

        context['stats'] = {
            'total_milestones': total_milestones,
            'active_milestones': active_milestones,
            'active_rate': active_rate,
            'total_achievements': total_achievements,
            'highest_points_target': highest_points_target,
            'top_milestone_count': top_milestone_count,
            'top_milestone_title': top_milestone_title
        }

        return context

class MilestoneCreateView(SuperuserRequiredMixin, CreateView):
    model = Milestone
    form_class = MilestoneForm
    template_name = "dashboard/loyalty/milestone_form.html"
    success_url = reverse_lazy('dashboard:milestones_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Create Milestone")
        context['action_title'] = _("Save Milestone")
        return context

    def form_valid(self, form):
        messages.success(self.request, _("Milestone created successfully."))
        return super().form_valid(form)

class MilestoneUpdateView(SuperuserRequiredMixin, UpdateView):
    model = Milestone
    form_class = MilestoneForm
    template_name = "dashboard/loyalty/milestone_form.html"
    success_url = reverse_lazy('dashboard:milestones_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Update Milestone")
        context['action_title'] = _("Update Changes")
        return context

    def form_valid(self, form):
        messages.success(self.request, _("Milestone updated successfully."))
        return super().form_valid(form)

class MilestoneDeleteView(SuperuserRequiredMixin, DeleteView):
    model = Milestone
    success_url = reverse_lazy('dashboard:milestones_list')

    def delete(self, request, *args, **kwargs):
        messages.success(request, _("Milestone deleted successfully."))
        return super().delete(request, *args, **kwargs)


# ==========================================
# Claims & Redemptions Ledger Management
# ==========================================

class ClaimsLedgerListView(SuperuserRequiredMixin, ListView):
    model = User
    template_name = "dashboard/loyalty/claims_ledger.html"
    context_object_name = "customers"
    paginate_by = 15

    def get_queryset(self):
        milestones_qs = UserMilestone.objects.all()

        q = self.request.GET.get('q', '').strip()
        status_filter = self.request.GET.get('status', '').strip()
        milestone_filter = self.request.GET.get('milestone', '').strip()
        reward_filter = self.request.GET.get('reward', '').strip()

        if q:
            milestones_qs = milestones_qs.filter(
                Q(user__email__icontains=q) |
                Q(user__full_name__icontains=q) |
                Q(milestone__title__icontains=q)
            )

        if status_filter == 'unlocked':
            milestones_qs = milestones_qs.filter(is_claimed=False, is_consumed=False)
        elif status_filter == 'claimed':
            milestones_qs = milestones_qs.filter(is_claimed=True, is_consumed=False)
        elif status_filter == 'consumed':
            milestones_qs = milestones_qs.filter(is_consumed=True)

        if milestone_filter and milestone_filter.isdigit():
            milestones_qs = milestones_qs.filter(milestone_id=milestone_filter)

        if reward_filter and reward_filter.isdigit():
            milestones_qs = milestones_qs.filter(milestone__reward_id=reward_filter)

        matching_user_ids = milestones_qs.values_list('user_id', flat=True).distinct()
        
        queryset = User.objects.filter(id__in=matching_user_ids).select_related('customer_wallet')
        
        queryset = queryset.annotate(
            active_claims_count=Count(
                'unlocked_milestones',
                filter=Q(unlocked_milestones__is_claimed=True, unlocked_milestones__is_consumed=False)
            )
        )
        
        prefetch_history = milestones_qs.select_related('milestone', 'milestone__reward').order_by('-unlocked_at')
        queryset = queryset.prefetch_related(Prefetch('unlocked_milestones', queryset=prefetch_history))
        
        return queryset.order_by('-customer_wallet__lifetime_points')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['page_title'] = _("Claims & Redemptions Ledger")
        
        milestones_qs = UserMilestone.objects.all()
        q = self.request.GET.get('q', '').strip()
        status_filter = self.request.GET.get('status', '').strip()
        milestone_filter = self.request.GET.get('milestone', '').strip()
        reward_filter = self.request.GET.get('reward', '').strip()

        if q:
            milestones_qs = milestones_qs.filter(
                Q(user__email__icontains=q) | Q(user__full_name__icontains=q) | Q(milestone__title__icontains=q)
            )
        if status_filter == 'unlocked':
            milestones_qs = milestones_qs.filter(is_claimed=False, is_consumed=False)
        elif status_filter == 'claimed':
            milestones_qs = milestones_qs.filter(is_claimed=True, is_consumed=False)
        elif status_filter == 'consumed':
            milestones_qs = milestones_qs.filter(is_consumed=True)

        if milestone_filter and milestone_filter.isdigit():
            milestones_qs = milestones_qs.filter(milestone_id=milestone_filter)
        if reward_filter and reward_filter.isdigit():
            milestones_qs = milestones_qs.filter(milestone__reward_id=reward_filter)

        total_records = milestones_qs.count()
        unlocked_count = milestones_qs.filter(is_claimed=False, is_consumed=False).count()
        claimed_count = milestones_qs.filter(is_claimed=True, is_consumed=False).count()
        consumed_count = milestones_qs.filter(is_consumed=True).count()
        consumption_rate = int((consumed_count / (claimed_count + consumed_count)) * 100) if (claimed_count + consumed_count) > 0 else 0

        context['stats'] = {
            'total_records': total_records,
            'unlocked_count': unlocked_count,
            'claimed_count': claimed_count,
            'consumed_count': consumed_count,
            'consumption_rate': consumption_rate
        }

        context['available_milestones'] = Milestone.objects.filter(is_active=True).values('id', 'title')
        context['available_rewards'] = MilestoneReward.objects.filter(is_active=True).values('id', 'name')

        context['current_filters'] = {
            'q': self.request.GET.get('q', ''),
            'status': self.request.GET.get('status', ''),
            'milestone': self.request.GET.get('milestone', ''),
            'reward': self.request.GET.get('reward', ''),
        }
        return context