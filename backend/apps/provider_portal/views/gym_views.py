"""
Views for Gym providers to manage branches, subscription plans, and subscribers.
Includes API view for the Cryptographically Secure QR Code Scanner.
"""

import json
import logging
from datetime import timedelta
from decimal import Decimal
from django.http import JsonResponse
from django.views.generic import ListView, FormView, View, DetailView
from apps.provider_portal.mixins import GymProviderRequiredMixin
from django.urls import reverse_lazy, reverse
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from django.shortcuts import redirect, render, get_object_or_404
from django.contrib.gis.geos import Point
from django.utils import timezone
from django.core.signing import Signer, BadSignature
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.db.models import Count, Prefetch, Q, Max, Sum

from apps.gyms.models import (
    GymBranch, BranchImage, SubscriptionPlan, PlanFeature, 
    GymVisit, GymSubscription, RoamingPass
)
from apps.provider_portal.forms.gym_forms import BranchForm, SubscriptionPlanForm

logger = logging.getLogger(__name__)

# ==========================================
# BRANCH VIEWS
# ==========================================

class BranchListView(GymProviderRequiredMixin, ListView):
    model = GymBranch
    template_name = "provider_portal/gym/branches/list.html"
    context_object_name = "branches"

    def get_queryset(self):
        return GymBranch.objects.filter(
            provider=self.request.user.provider_profile
        ).prefetch_related(
            Prefetch('images', to_attr='prefetched_images'),
            'tier', 'requested_tier'
        ).annotate(
            linked_plans_count=Count('available_plans', distinct=True)
        ).order_by('-created_at')

class BranchAddView(GymProviderRequiredMixin, FormView):
    form_class = BranchForm
    template_name = "provider_portal/gym/branches/form.html"
    success_url = reverse_lazy("provider_portal:gym_branches")

    def form_valid(self, form):
        provider = self.request.user.provider_profile
        data = form.cleaned_data

        location = None
        lat = data.get('latitude')
        lng = data.get('longitude')
        if lat and lng:
            try:
                location = Point(float(lng), float(lat), srid=4326)
            except (ValueError, TypeError):
                logger.error("Invalid coordinates provided.")

        schedule_data_str = data.get('schedule_data')
        operating_hours = {}
        if schedule_data_str:
            try:
                operating_hours = json.loads(schedule_data_str)
            except json.JSONDecodeError:
                logger.error("Failed to parse schedule JSON data.")

        is_active = data.get('is_active', True)
        if provider.status == 'pending':
            is_active = False

        branch = GymBranch.objects.create(
            provider=provider,
            name=data['name'],
            city=data['city'],
            description=data.get('description', ''),
            address=data['address'],
            phone_number=data['phone_number'],
            location=location,
            gender=data.get('gender', 'mixed'),
            is_active=is_active,
            is_temporarily_closed=data.get('is_temporarily_closed', False),
            estimated_stay_duration=data.get('estimated_stay_duration', 120),
            max_capacity=data.get('max_capacity', 100),
            operating_hours=operating_hours,
            is_roaming_enabled=data.get('is_roaming_enabled', False),
            roaming_visit_price=data.get('roaming_visit_price', 0.00),
            requested_tier=data.get('requested_tier')
        )

        if data.get('branch_logo'):
            branch.branch_logo = data['branch_logo']
            branch.save()
        
        if data.get('amenities'):
            branch.amenities.set(data['amenities'])

        if data.get('sports'):
            branch.sports.set(data['sports'])

        if provider.status == 'pending':
            messages.warning(self.request, _("Branch added successfully, but remains inactive until verification."))
        else:
            messages.success(self.request, _("Branch added successfully."))
            
        return super().form_valid(form)

class BranchEditView(GymProviderRequiredMixin, FormView):
    form_class = BranchForm
    template_name = "provider_portal/gym/branches/form.html"
    success_url = reverse_lazy("provider_portal:gym_branches")

    def get_branch(self):
        return get_object_or_404(
            GymBranch, id=self.kwargs['branch_id'], provider=self.request.user.provider_profile
        )

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['is_edit'] = True
        context['branch'] = self.get_branch()
        return context

    def get_initial(self):
        branch = self.get_branch()
        
        schedule_json = '{}'
        if branch.operating_hours:
            try:
                schedule_json = json.dumps(branch.operating_hours)
            except Exception:
                pass

        initial = {
            'name': branch.name,
            'city': branch.city,
            'phone_number': branch.phone_number,
            'address': branch.address,
            'description': branch.description,
            'gender': branch.gender,
            'is_active': branch.is_active,
            'is_temporarily_closed': branch.is_temporarily_closed,
            'estimated_stay_duration': branch.estimated_stay_duration,
            'max_capacity': branch.max_capacity,
            'schedule_data': schedule_json,
            'amenities': branch.amenities.all(),
            'sports': branch.sports.all(),
            'is_roaming_enabled': branch.is_roaming_enabled,
            'roaming_visit_price': branch.roaming_visit_price,
            'requested_tier': branch.requested_tier,
        }
        
        if branch.location:
            initial['latitude'] = branch.location.y
            initial['longitude'] = branch.location.x
            
        return initial

    def form_valid(self, form):
        branch = self.get_branch()
        data = form.cleaned_data

        lat = data.get('latitude')
        lng = data.get('longitude')
        if lat and lng:
            try:
                branch.location = Point(float(lng), float(lat), srid=4326)
            except (ValueError, TypeError):
                pass

        schedule_data_str = data.get('schedule_data')
        if schedule_data_str:
            try:
                branch.operating_hours = json.loads(schedule_data_str)
            except json.JSONDecodeError:
                branch.operating_hours = {}
        else:
            branch.operating_hours = {}

        branch.name = data['name']
        branch.city = data['city']
        branch.address = data['address']
        branch.gender = data.get('gender', 'mixed')
        branch.phone_number = data['phone_number']
        branch.description = data.get('description', '')
        branch.is_temporarily_closed = data.get('is_temporarily_closed', False)
        branch.estimated_stay_duration = data.get('estimated_stay_duration', 120)
        branch.max_capacity = data.get('max_capacity', 100)
        
        branch.is_roaming_enabled = data.get('is_roaming_enabled', False)
        branch.roaming_visit_price = data.get('roaming_visit_price', 0.00)
        branch.requested_tier = data.get('requested_tier')
        
        if self.request.user.provider_profile.status == 'pending':
            branch.is_active = False
        else:
            branch.is_active = data.get('is_active', True)

        if data.get('branch_logo'):
            branch.branch_logo = data['branch_logo']

        branch.save()

        branch.amenities.set(data.get('amenities', []))
        branch.sports.set(data.get('sports', []))

        messages.success(self.request, _("Branch updated successfully."))
        return super().form_valid(form)

class BranchDeleteView(GymProviderRequiredMixin, View):
    def post(self, request, branch_id):
        branch = get_object_or_404(GymBranch, id=branch_id, provider=request.user.provider_profile)
        branch.delete()
        messages.success(request, _("Branch deleted successfully."))
        return redirect("provider_portal:gym_branches")
    
class BranchDetailView(GymProviderRequiredMixin, DetailView):
    model = GymBranch
    template_name = "provider_portal/gym/branches/detail.html"
    context_object_name = "branch"
    pk_url_kwarg = 'branch_id'

    def get_queryset(self):
        return GymBranch.objects.filter(provider=self.request.user.provider_profile)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        branch = self.object
        
        context['plans'] = branch.available_plans.filter(is_active=True)
        
        context['unlinked_plans'] = SubscriptionPlan.objects.filter(
            provider=self.request.user.provider_profile,
            is_active=True,
            is_archived=False
        ).exclude(
            branches=branch
        )
        
        context['photos'] = branch.images.all()
        return context

class BranchLinkPlanAPIView(GymProviderRequiredMixin, View):
    def post(self, request, branch_id):
        try:
            data = json.loads(request.body)
            plan_id = data.get('plan_id')
            
            branch = get_object_or_404(GymBranch, id=branch_id, provider=request.user.provider_profile)
            plan = get_object_or_404(SubscriptionPlan, id=plan_id, provider=request.user.provider_profile)
            
            plan.branches.add(branch)
            
            return JsonResponse({
                'status': 'success',
                'message': str(_(f"Plan '{plan.name}' has been linked to this branch."))
            })
            
        except Exception as e:
            logger.error(f"Error linking plan to branch: {str(e)}")
            return JsonResponse({'status': 'error', 'message': str(e)}, status=400)

class BranchUnlinkPlanAPIView(GymProviderRequiredMixin, View):
    def post(self, request, branch_id):
        try:
            data = json.loads(request.body)
            plan_id = data.get('plan_id')
            
            branch = get_object_or_404(GymBranch, id=branch_id, provider=request.user.provider_profile)
            plan = get_object_or_404(SubscriptionPlan, id=plan_id, provider=request.user.provider_profile)
            
            plan.branches.remove(branch)
            
            return JsonResponse({
                'status': 'success',
                'message': str(_(f"Plan '{plan.name}' has been removed from this branch."))
            })
            
        except Exception as e:
            logger.error(f"Error unlinking plan from branch: {str(e)}")
            return JsonResponse({'status': 'error', 'message': str(e)}, status=400)


class BranchPhotosView(GymProviderRequiredMixin, View):
    template_name = "provider_portal/gym/branches/photos.html"

    def get(self, request, branch_id):
        branch = get_object_or_404(GymBranch, id=branch_id, provider=request.user.provider_profile)
        return render(request, self.template_name, {
            "branch": branch,
            "photos": branch.images.all()
        })

    def post(self, request, branch_id):
        branch = get_object_or_404(GymBranch, id=branch_id, provider=request.user.provider_profile)

        if 'delete_photo_id' in request.POST:
            photo = get_object_or_404(BranchImage, id=request.POST.get('delete_photo_id'), branch=branch)
            photo.image.delete() 
            photo.delete()       
            messages.success(request, _("Photo deleted successfully."))

        if 'photos' in request.FILES:
            for file in request.FILES.getlist('photos'):
                BranchImage.objects.create(branch=branch, image=file)
            messages.success(request, _("Photos uploaded successfully."))

        return redirect("provider_portal:gym_branch_photos", branch_id=branch.id)

class BranchQuickToggleView(GymProviderRequiredMixin, View):
    def post(self, request, branch_id):
        branch = get_object_or_404(GymBranch, id=branch_id, provider=request.user.provider_profile)
        
        try:
            data = json.loads(request.body)
            toggle_field = data.get('field') 
            
            if toggle_field == 'is_active':
                branch.is_active = not branch.is_active
                msg = _("Branch activated successfully.") if branch.is_active else _("Branch hidden from users.")
            elif toggle_field == 'is_temporarily_closed':
                branch.is_temporarily_closed = not branch.is_temporarily_closed
                msg = _("Branch is marked as EMERGENCY CLOSED.") if branch.is_temporarily_closed else _("Branch is now OPEN normally.")
            else:
                return JsonResponse({'status': 'error', 'message': 'Invalid field'}, status=400)
                
            branch.save()
            return JsonResponse({
                'status': 'success', 
                'new_value': getattr(branch, toggle_field),
                'message': str(msg)
            })
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)}, status=400)
        
# ==========================================
# PLAN VIEWS
# ==========================================

class PlanListView(GymProviderRequiredMixin, ListView):
    model = SubscriptionPlan
    template_name = "provider_portal/gym/plans/list.html"
    context_object_name = "plans"

    def get_queryset(self):
        return SubscriptionPlan.objects.filter(
            provider=self.request.user.provider_profile
        ).prefetch_related(
            'features', 'branches'
        ).annotate(
            active_subs_count=Count('subscribers', filter=Q(subscribers__status__in=['active', 'suspended']))
        ).order_by('is_archived', '-created_at')
    
class PlanDetailView(GymProviderRequiredMixin, DetailView):
    model = SubscriptionPlan
    template_name = "provider_portal/gym/plans/detail.html"
    context_object_name = "plan"
    pk_url_kwarg = 'plan_id'

    def get_queryset(self):
        return SubscriptionPlan.objects.filter(provider=self.request.user.provider_profile)

class PlanAddView(GymProviderRequiredMixin, FormView):
    form_class = SubscriptionPlanForm
    template_name = "provider_portal/gym/plans/form.html"
    success_url = reverse_lazy("provider_portal:gym_plans")

    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        kwargs['provider'] = self.request.user.provider_profile
        return kwargs

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        provider = self.request.user.provider_profile
        branches = GymBranch.objects.filter(provider=provider).prefetch_related('amenities', 'sports')
        
        branch_map = {}
        for branch in branches:
            branch_map[str(branch.id)] = {
                'amenities': list(branch.amenities.values_list('id', flat=True)),
                'sports': list(branch.sports.values_list('id', flat=True))
            }
        context['branch_features_map'] = branch_map
        return context

    def form_valid(self, form):
        data = form.cleaned_data
        
        plan = SubscriptionPlan.objects.create(
            provider=self.request.user.provider_profile,
            name=data['name'],
            description=data.get('description', ''),
            duration_days=data['duration_days'],
            price=data['price'],
            is_active=data.get('is_active', True)
        )
        
        plan.branches.set(data['branches'])
        
        if data.get('amenities'):
            plan.amenities.set(data['amenities'])
            
        if data.get('sports'):
            plan.sports.set(data['sports'])
        
        features_str = data.get('custom_features', '')
        if features_str:
            for feature_text in features_str.split(','):
                tag = feature_text.strip()
                if tag:
                    PlanFeature.objects.create(plan=plan, name=tag)
            
        messages.success(self.request, _("Subscription plan added successfully."))
        return super().form_valid(form)


class PlanEditView(GymProviderRequiredMixin, FormView):
    form_class = SubscriptionPlanForm
    template_name = "provider_portal/gym/plans/form.html"
    success_url = reverse_lazy("provider_portal:gym_plans")

    def get_plan(self):
        return get_object_or_404(
            SubscriptionPlan, 
            id=self.kwargs['plan_id'], 
            provider=self.request.user.provider_profile
        )

    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        kwargs['provider'] = self.request.user.provider_profile
        return kwargs

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['is_edit'] = True
        context['plan'] = self.get_plan()
        
        provider = self.request.user.provider_profile
        branches = GymBranch.objects.filter(provider=provider).prefetch_related('amenities', 'sports')
        
        branch_map = {}
        for branch in branches:
            branch_map[str(branch.id)] = {
                'amenities': list(branch.amenities.values_list('id', flat=True)),
                'sports': list(branch.sports.values_list('id', flat=True))
            }
        context['branch_features_map'] = branch_map
        return context

    def get_initial(self):
        plan = self.get_plan()
        features_list = [f.name for f in plan.features.all()] if hasattr(plan, 'features') else []
        features_text = ",".join(features_list)
        
        return {
            'name': plan.name,
            'description': plan.description,
            'duration_days': plan.duration_days,
            'price': plan.price,
            'is_active': plan.is_active,
            'branches': plan.branches.all(),
            'amenities': plan.amenities.all(),
            'sports': plan.sports.all(),
            'custom_features': features_text,
        }

    def form_valid(self, form):
        plan = self.get_plan()
        data = form.cleaned_data

        plan.name = data['name']
        plan.description = data.get('description', '')
        plan.duration_days = data['duration_days']
        plan.price = data['price']
        plan.is_active = data.get('is_active', True)
        plan.save()
        
        plan.branches.set(data['branches'])
        
        plan.amenities.set(data.get('amenities', []))
        plan.sports.set(data.get('sports', []))

        if hasattr(plan, 'features'):
            plan.features.all().delete()
            
        features_str = data.get('custom_features', '')
        if features_str:
            for feature_text in features_str.split(','):
                tag = feature_text.strip()
                if tag:
                    PlanFeature.objects.create(plan=plan, name=tag)

        messages.success(self.request, _("Subscription plan updated successfully."))
        return super().form_valid(form)
    
class PlanDeleteView(GymProviderRequiredMixin, View):
    def post(self, request, plan_id, *args, **kwargs):
        plan = get_object_or_404(
            SubscriptionPlan, 
            id=plan_id, 
            provider=request.user.provider_profile
        )
        
        plan_name = plan.name
        
        if plan.has_active_subscribers():
            plan.is_archived = True
            plan.is_active = False 
            plan.save()
            messages.warning(
                request, 
                _("Plan '{}' was archived because it has active subscribers. It is hidden from new users but will remain active for current subscribers.").format(plan_name)
            )
        else:
            plan.delete()
            messages.success(request, _("Subscription plan '{}' was successfully deleted.").format(plan_name))
            
        return redirect("provider_portal:gym_plans")
    
class PlanRestoreView(GymProviderRequiredMixin, View):
    def post(self, request, plan_id, *args, **kwargs):
        plan = get_object_or_404(
            SubscriptionPlan, 
            id=plan_id, 
            provider=request.user.provider_profile
        )
        
        if plan.is_archived:
            plan.is_archived = False
            plan.is_active = True
            plan.save()
            messages.success(request, _("Subscription plan '{}' has been restored and is active again.").format(plan.name))
            
        return redirect("provider_portal:gym_plans")

class PlanToggleView(GymProviderRequiredMixin, View):
    def post(self, request, plan_id):
        plan = get_object_or_404(
            SubscriptionPlan, 
            id=plan_id, 
            provider=request.user.provider_profile
        )
        plan.is_active = not plan.is_active
        plan.save()
        
        status_text = _("activated") if plan.is_active else _("deactivated")
        messages.success(request, _("Plan %(status)s successfully.") % {'status': status_text})
        return redirect("provider_portal:gym_plans")


# ==========================================
# SECURE QR SCANNER API VIEW (REFACTORED - DRY)
# ==========================================

class QRScanEndpoint(GymProviderRequiredMixin, View):
    """
    Secure Web Endpoint for QR Code CHECK-IN (Logs a visit) via Session Auth.
    Delegates all logic to the central GymAccessService.
    Returns rich JSON data for the interactive scanner UI.
    """
    def post(self, request, *args, **kwargs):
        try:
            data = json.loads(request.body)
            qr_code_data = data.get('qr_code_data') or data.get('qr_code')
            qr_code_data = (qr_code_data or '').strip()
            branch_id = data.get('branch_id')

            if not qr_code_data or not branch_id:
                return JsonResponse({
                    'status_color': 'error',
                    'title': str(_("Invalid Data")),
                    'message': str(_("QR Code or Branch ID missing."))
                }, status=400)

            if qr_code_data.startswith("FZ-SUB-"):
                signer = Signer(salt="fitzone_gym_qr_auth")
                prefix = "FZ-SUB-"
            elif qr_code_data.startswith("FZ-ROAM-"):
                signer = Signer(salt="fitzone_roaming_qr_auth")
                prefix = "FZ-ROAM-"
            else:
                return JsonResponse({
                    'status_color': 'error',
                    'title': str(_("Invalid Format")),
                    'message': str(_("Unrecognized QR Code prefix."))
                }, status=400)

            try:
                raw_data = signer.unsign(qr_code_data)
                qr_uuid = raw_data.replace(prefix, "")
            except BadSignature:
                return JsonResponse({
                    'status_color': 'error',
                    'title': str(_("Security Alert")),
                    'message': str(_("QR code signature is invalid or tampered."))
                }, status=400)

            from apps.gyms.services import GymAccessService
            
            try:
                scan_result = GymAccessService.process_qr_scan(
                    qr_code_id=qr_uuid,
                    branch_id=branch_id
                )
            except ValueError as exc:
                sub_id = None
                user = None
                branch = None
                plan_name = "-"
                is_roaming = False
                days_left = 0
                total_days = 1
                logs_data = []
                plan_price = Decimal('0.00')

                try:
                    if prefix == "FZ-SUB-":
                        subscription = GymSubscription.objects.filter(qr_code_id=qr_uuid).first()
                        if subscription:
                            user = subscription.user
                            sub_id = subscription.id
                            plan_name = subscription.plan.name
                            plan_price = subscription.plan.price
                            
                            agg = GymSubscription.objects.filter(
                                user=user,
                                plan__provider=subscription.plan.provider,
                                status="active"
                            ).aggregate(latest_end=Max('end_date'), total_duration=Sum('plan__duration_days'))
                            
                            latest_end_date = agg['latest_end']
                            if latest_end_date:
                                days_left = max(0, (latest_end_date - timezone.now().date()).days)
                            else:
                                days_left = max(0, (subscription.end_date - timezone.now().date()).days)
                            total_days = agg['total_duration'] or subscription.plan.duration_days

                    elif prefix == "FZ-ROAM-":
                        roaming = RoamingPass.objects.filter(qr_code_id=qr_uuid).first()
                        if roaming:
                            user = roaming.user
                            branch = roaming.branch
                            plan_name = "One-Time Roaming Pass"
                            is_roaming = True
                            plan_price = roaming.fiat_paid
                            days_left = 0 if roaming.is_used else 1
                            total_days = 1
                            
                    if user:
                        recent_visits = GymVisit.objects.filter(
                            Q(subscription__user=user) | Q(roaming_pass__user=user)
                        ).select_related('branch').order_by('-check_in_time')[:5]
                        
                        logs_data = [
                            {
                                "time": timezone.localtime(v.check_in_time).strftime("%I:%M %p"),
                                "date": timezone.localtime(v.check_in_time).strftime("%Y-%m-%d"),
                                "branch_name": v.branch.name
                            } for v in recent_visits
                        ]
                except Exception:
                    pass

                response_error = {
                    'status': 'error',
                    'status_color': 'error',
                    'title': str(_("Access Denied")),
                    'message': str(exc),
                    'redirect_url': reverse('provider_portal:gym_subscriber_detail', args=[sub_id]) if sub_id else "",
                    "member_name": getattr(user, 'full_name', getattr(user, 'email', 'Unknown')) if user else 'Unknown',
                    "member_id": str(user.id) if user else "-",
                    "gender": user.get_gender_display() if hasattr(user, 'get_gender_display') else getattr(user, 'gender', '-') if user else '-',
                    "phone_number": getattr(user, 'phone_number', '-') if user else '-',
                    "city": getattr(user, 'city', '-') if user else '-',
                    "address": getattr(user, 'address', '-') if user else '-',
                    "avatar_url": request.build_absolute_uri(user.real_face_image.url) if user and getattr(user, 'real_face_image', None) else None,
                    "id_card_url": request.build_absolute_uri(user.id_card_image.url) if user and getattr(user, 'id_card_image', None) else None,
                    "allowed_branches": branch.name if branch else "-",
                    "branch_address": branch.address if branch else "-",
                    "branch_logo_url": request.build_absolute_uri(branch.branch_logo.url) if branch and getattr(branch, 'branch_logo', None) else None,
                    "plan_name": plan_name,
                    "plan_price": str(plan_price),
                    "days_left": days_left,
                    "total_days": total_days,
                    "current_capacity": GymAccessService.get_live_occupancy(branch_id) if branch_id else 0,
                    "latest_logs": logs_data,
                    "is_roaming": is_roaming,
                    "visit_type": "Roaming" if is_roaming else "Regular"
                }
                
                return JsonResponse(response_error, status=400)

            visit = GymVisit.objects.select_related(
                'subscription__user', 'subscription__plan',
                'roaming_pass__user', 'branch'
            ).get(id=scan_result["visit_id"])

            user = visit.subscription.user if visit.subscription else visit.roaming_pass.user
            branch = visit.branch

            is_roaming = scan_result.get("is_roaming", False)
            plan_price = visit.subscription.plan.price if visit.subscription else visit.roaming_pass.fiat_paid
            total_days = scan_result.get("total_days", 1)
            days_left = scan_result.get("days_remaining", 0)
            subscription_id = scan_result.get("subscription_id")

            if visit.subscription:
                recent_visits = GymVisit.objects.filter(subscription__user=user).select_related('branch').order_by('-check_in_time')[:5]
            else:
                recent_visits = GymVisit.objects.filter(roaming_pass__user=user).select_related('branch').order_by('-check_in_time')[:5]

            logs_data = [
                {
                    "time": timezone.localtime(v.check_in_time).strftime("%I:%M %p"),
                    "date": timezone.localtime(v.check_in_time).strftime("%Y-%m-%d"),
                    "branch_name": v.branch.name
                } for v in recent_visits
            ]

            response_data = {
                "status": "success",
                "status_color": "success",
                "title": str(_("Access Granted")),
                "message": str(_("Check-in successful")) if not is_roaming else str(_("Roaming Pass Consumed")),
                "member_name": getattr(user, 'full_name', getattr(user, 'email', 'Unknown')),
                "member_id": str(user.id),
                "gender": user.get_gender_display() if hasattr(user, 'get_gender_display') else getattr(user, 'gender', '-'),
                "phone_number": getattr(user, 'phone_number', '-'),
                "city": getattr(user, 'city', '-'),
                "address": getattr(user, 'address', '-'),
                "avatar_url": request.build_absolute_uri(user.real_face_image.url) if getattr(user, 'real_face_image', None) else None,
                "id_card_url": request.build_absolute_uri(user.id_card_image.url) if getattr(user, 'id_card_image', None) else None,
                "allowed_branches": branch.name,
                "branch_address": branch.address,
                "branch_logo_url": request.build_absolute_uri(branch.branch_logo.url) if getattr(branch, 'branch_logo', None) else None,
                "plan_name": scan_result.get("plan_name", "-"),
                "plan_price": str(plan_price),
                "days_left": days_left,
                "total_days": total_days,
                "current_capacity": GymAccessService.get_live_occupancy(branch.id),
                "latest_logs": logs_data,
                "is_roaming": is_roaming,
                "visit_type": scan_result.get("visit_type", "Regular"),
                "redirect_url": reverse('provider_portal:gym_subscriber_detail', args=[subscription_id]) if subscription_id else ""
            }
            return JsonResponse(response_data, status=200)

        except Exception as e:
            logger.error(f"QR Scan Check-in Error: {str(e)}", exc_info=True)
            return JsonResponse({
                'status_color': 'error',
                'title': str(_("System Error")),
                'message': str(_("An internal server error occurred."))
            }, status=500)


class QRCodeScannerAPIView(QRScanEndpoint):
    """Alias for robust routing compatibility."""
    pass


class QRSearchEndpoint(GymProviderRequiredMixin, View):
    """
    Secure API Endpoint for QR Code SEARCH (Redirects to profile without logging visit).
    Updated to handle both regular subscriptions and roaming passes securely.
    """
    def post(self, request, *args, **kwargs):
        try:
            data = json.loads(request.body)
            token = data.get('token') or data.get('qr_code')
            if not token: 
                return JsonResponse({'status': 'error', 'message': _("No QR token provided.")})

            if token.startswith("FZ-SUB-"):
                signer = Signer(salt="fitzone_gym_qr_auth")
                prefix = "FZ-SUB-"
                is_roaming = False
            elif token.startswith("FZ-ROAM-"):
                signer = Signer(salt="fitzone_roaming_qr_auth")
                prefix = "FZ-ROAM-"
                is_roaming = True
            else:
                raise ValueError("Invalid Format")

            raw_data = signer.unsign(token)
            qr_uuid = raw_data.replace(prefix, "")
            
            from django.urls import reverse
            
            if is_roaming:
                detail_url = reverse('provider_portal:gym_branches')
                message = _("Roaming pass verified.")
                return JsonResponse({'status': 'success', 'redirect_url': detail_url, 'message': str(message)})
            else:
                sub = GymSubscription.objects.get(qr_code_id=qr_uuid, plan__provider=request.user.provider_profile)
                detail_url = reverse('provider_portal:gym_subscriber_detail', args=[sub.id])
                return JsonResponse({'status': 'success', 'redirect_url': detail_url})

        except Exception as e:
            logger.error(f"QR Scan Search Error: {str(e)}")
            return JsonResponse({'status': 'error', 'message': _("Subscriber not found or invalid QR.")})

# ==========================================
# SUBSCRIBER MANAGEMENT & CRM VIEWS
# ==========================================

class SubscriberListView(GymProviderRequiredMixin, ListView): 
    model = GymSubscription
    template_name = "provider_portal/gym/subscribers/list.html"
    context_object_name = "subscriptions"

    def get_queryset(self):
        provider = self.request.user.provider_profile
        queryset = GymSubscription.objects.select_related(
            'user', 'plan'
        ).prefetch_related(
            'visits', 'plan__branches'
        ).filter(
            plan__provider=provider
        )

        search_query = self.request.GET.get('search', '').strip()
        branch_id = self.request.GET.get('branch', 'all')
        status_filter = self.request.GET.get('status', 'all')
        plan_id = self.request.GET.get('plan', 'all')
        expiration_filter = self.request.GET.get('expiration', 'all')

        if search_query:
            queryset = queryset.filter(
                Q(user__full_name__icontains=search_query) | 
                Q(user__phone_number__icontains=search_query)
            )
        
        if branch_id != 'all':
            queryset = queryset.filter(plan__branches__id=branch_id)
        
        if status_filter != 'all':
            queryset = queryset.filter(status=status_filter)
            
        if plan_id != 'all':
            queryset = queryset.filter(plan__id=plan_id)

        now_date = timezone.now().date()
        if expiration_filter == '7days':
            queryset = queryset.filter(end_date__gte=now_date, end_date__lte=now_date + timedelta(days=7))
        elif expiration_filter == '30days':
            queryset = queryset.filter(end_date__gte=now_date, end_date__lte=now_date + timedelta(days=30))

        return queryset.distinct().order_by('-start_date')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        qs = self.get_queryset()
        provider = self.request.user.provider_profile
        
        all_provider_subs = GymSubscription.objects.filter(plan__provider=provider)
        context['total_active'] = all_provider_subs.filter(status='active').count()
        context['total_expired'] = all_provider_subs.filter(status='expired').count()
        context['total_suspended'] = all_provider_subs.filter(status='suspended').count()
        
        context['branches'] = GymBranch.objects.filter(provider=provider)
        context['all_plans'] = SubscriptionPlan.objects.filter(provider=provider, is_archived=False)
        
        grouped_data = {}
        for sub in qs:
            user_id = sub.user.id
            if user_id not in grouped_data:
                grouped_data[user_id] = {
                    'user': sub.user,
                    'current': [], 
                    'history': [], 
                    'active_count': 0,
                    'has_suspended': False,
                    'latest_date': sub.start_date
                }

            if sub.status == 'expired':
                grouped_data[user_id]['history'].append(sub)
            else:
                grouped_data[user_id]['current'].append(sub)
                if sub.status == 'active':
                    grouped_data[user_id]['active_count'] += 1
                elif sub.status == 'suspended':
                    grouped_data[user_id]['has_suspended'] = True

        sorted_users = sorted(grouped_data.values(), key=lambda x: x['latest_date'], reverse=True)
        context['grouped_users'] = sorted_users

        return context
    
class SubscriberDetailView(GymProviderRequiredMixin, DetailView):
    model = GymSubscription
    template_name = "provider_portal/gym/subscribers/detail.html"
    context_object_name = "subscription"
    pk_url_kwarg = "sub_id"

    def get_queryset(self):
        return GymSubscription.objects.select_related(
            'user', 'plan'
        ).prefetch_related(
            'visits__branch', 'disputes', 'plan__branches'
        ).filter(plan__provider=self.request.user.provider_profile)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['recent_visits'] = self.object.visits.all().order_by('-check_in_time')[:50]
        context['disputes'] = self.object.disputes.all().order_by('-created_at')
        return context

class SubscriberSuspendView(GymProviderRequiredMixin, View):
    def post(self, request, sub_id, *args, **kwargs):
        sub = get_object_or_404(GymSubscription, id=sub_id, plan__provider=request.user.provider_profile)
        reason = request.POST.get('suspend_reason', '').strip()
        
        if not reason:
            messages.error(request, _("A reason is required to block a subscriber."))
            return redirect(request.META.get('HTTP_REFERER', 'provider_portal:gym_subscribers'))

        sub.status = 'suspended'
        sub.save(update_fields=['status'])
        
        from apps.gyms.models import GymSubscriptionDispute
        GymSubscriptionDispute.objects.create(
            subscription=sub,
            opened_by=request.user,
            reason=reason,
            status='open'
        )
        messages.success(request, _("Subscriber has been blocked successfully."))
        return redirect(request.META.get('HTTP_REFERER', 'provider_portal:gym_subscribers'))

class SubscriberUnsuspendView(GymProviderRequiredMixin, View):
    def post(self, request, sub_id, *args, **kwargs):
        sub = get_object_or_404(GymSubscription, id=sub_id, plan__provider=request.user.provider_profile)
        resolution = request.POST.get('resolution_note', '').strip()
        
        if not resolution:
            messages.error(request, _("A resolution note is required to unblock a subscriber."))
            return redirect(request.META.get('HTTP_REFERER', 'provider_portal:gym_subscribers'))
            
        sub.status = 'active'
        sub.save(update_fields=['status'])
        
        sub.disputes.filter(status='open').update(
            status='resolved', 
            resolution_note=resolution
        )
        messages.success(request, _("Subscriber access has been restored successfully."))
        return redirect(request.META.get('HTTP_REFERER', 'provider_portal:gym_subscribers'))