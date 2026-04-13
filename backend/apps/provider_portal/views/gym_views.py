"""
Views for Gym providers to manage branches, subscription plans, and subscribers.
Includes API view for the Cryptographically Secure QR Code Scanner.
"""

import json
import logging
from datetime import timedelta
from django.http import JsonResponse
from django.views.generic import ListView, FormView, View, DetailView
from apps.provider_portal.mixins import GymProviderRequiredMixin
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from django.shortcuts import redirect, render, get_object_or_404
from django.contrib.gis.geos import Point
from django.utils import timezone
from django.core.signing import Signer, BadSignature

from apps.gyms.models import (
    GymBranch, BranchImage, SubscriptionPlan, PlanFeature, 
    GymVisit, GymSubscription
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

        opening_time = data.get('sunday_open') or data.get('monday_open')
        closing_time = data.get('sunday_close') or data.get('monday_close')

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
            opening_time=opening_time,
            closing_time=closing_time
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
            'sunday_open': branch.opening_time, 'sunday_close': branch.closing_time,
            'monday_open': branch.opening_time, 'monday_close': branch.closing_time,
            'tuesday_open': branch.opening_time, 'tuesday_close': branch.closing_time,
            'wednesday_open': branch.opening_time, 'wednesday_close': branch.closing_time,
            'thursday_open': branch.opening_time, 'thursday_close': branch.closing_time,
            'friday_open': branch.opening_time, 'friday_close': branch.closing_time,
            'saturday_open': branch.opening_time, 'saturday_close': branch.closing_time,
            'amenities': branch.amenities.all(),
            'sports': branch.sports.all(),
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

        branch.opening_time = data.get('sunday_open') or data.get('monday_open')
        branch.closing_time = data.get('sunday_close') or data.get('monday_close')

        branch.name = data['name']
        branch.city = data['city']
        branch.address = data['address']
        branch.gender = data.get('gender', 'mixed')
        branch.phone_number = data['phone_number']
        branch.description = data.get('description', '')
        branch.is_temporarily_closed = data.get('is_temporarily_closed', False)
        branch.estimated_stay_duration = data.get('estimated_stay_duration', 120)
        
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
        context['photos'] = self.object.images.all()
        context['plans'] = self.object.available_plans.filter(is_active=True)
        return context

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
        ).order_by('price')
    
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
# SECURE QR SCANNER API VIEW
# ==========================================

class QRCodeScannerAPIView(GymProviderRequiredMixin, View):
    """
    POST /portal/api/scan-qr/
    Decodes the cryptographically signed QR code.
    Verifies subscription validity, extracts allowed branches, and creates a GymVisit.
    """
    def post(self, request, *args, **kwargs):
        try:
            data = json.loads(request.body)
            qr_code = data.get('qr_code', '').strip()
            
            if not qr_code:
                return JsonResponse({'status': 'ignore'}, status=200)

            # 1. DECRYPT AND VERIFY SIGNATURE
            # Using the exact same salt defined in GymSubscription.get_signed_qr_code()
            signer = Signer(salt="fitzone_gym_qr_auth")
            try:
                raw_data = signer.unsign(qr_code)
                if not raw_data.startswith("FZ-SUB-"):
                    raise ValueError("Invalid FitZone Prefix")
                qr_uuid = raw_data.replace("FZ-SUB-", "")
            except (BadSignature, ValueError):
                # Fake or forged QR code -> Ignore silently to prevent brute force
                return JsonResponse({'status': 'ignore'}, status=200)

            provider = request.user.provider_profile
            now = timezone.now().date()

            # 2. FETCH REAL SUBSCRIPTION DATA
            subscription = GymSubscription.objects.select_related('user', 'plan').prefetch_related('plan__branches').filter(
                qr_code_id=qr_uuid,
                plan__provider=provider
            ).first()

            if not subscription:
                return JsonResponse({
                    'status': 'error',
                    'status_color': 'error',
                    'title': str(_("Subscription Not Found")),
                    'message': str(_("This QR code belongs to another gym or is invalid."))
                })

            user = subscription.user
            plan = subscription.plan
            allowed_branches = list(plan.branches.values_list('name', flat=True))

            # 3. VERIFY STATUS & EXPIRATION
            days_left = (subscription.end_date - now).days

            if subscription.status != 'active' or days_left < 0:
                return JsonResponse({
                    'status': 'error',
                    'status_color': 'error',
                    'title': str(_("Access Denied")),
                    'message': str(_("Subscription is expired or suspended.")),
                    'member_name': user.full_name,
                    'avatar_url': request.build_absolute_uri(user.real_face_image.url) if user.real_face_image else None,
                })

            # Determine Warning vs Success
            scenario = 'warning' if days_left <= 3 else 'success'
            message = _("Subscription expires soon. Please remind the member.") if scenario == 'warning' else _("Check-in successful.")
            
            # 4. LOG VISIT (Smart Logging)
            first_branch = plan.branches.first()
            if first_branch:
                GymVisit.objects.create(
                    subscription=subscription,
                    branch=first_branch,
                    is_active=True
                )
                
            current_capacity = GymVisit.objects.filter(
                branch__in=plan.branches.all(),
                is_active=True
            ).count()

# Fetch up to 10 recent visits to fill the bottom timeline area perfectly
            recent_visits = GymVisit.objects.filter(subscription=subscription).order_by('-check_in_time')[:10]
            logs_data = [{"time": v.check_in_time.strftime("%I:%M %p"), "date": v.check_in_time.strftime("%Y-%m-%d")} for v in recent_visits]

            # BUILD RESPONSE
            response_data = {
                'member_id': str(user.id),
                'member_name': user.full_name,
                'gender': user.get_gender_display() if hasattr(user, 'get_gender_display') else user.gender,
                'phone_number': user.phone_number,
                'city': user.city,
                'address': user.address,
                'plan_name': plan.name,
                'plan_price': str(plan.price), 
                'allowed_branches': ", ".join(allowed_branches),
                'branch_address': first_branch.address if first_branch else "متعدد الفروع",
                'branch_logo_url': request.build_absolute_uri(first_branch.branch_logo.url) if first_branch and first_branch.branch_logo else None, # <-- ADDED BRANCH LOGO
                'total_days': plan.duration_days,
                'days_left': max(0, days_left),
                'visits_this_month': subscription.visits.count(),
                'message': str(message),
                'current_capacity': current_capacity,
                'estimated_exit': (timezone.now() + timedelta(hours=2)).strftime("%I:%M %p"),
                'avatar_url': request.build_absolute_uri(user.real_face_image.url) if user.real_face_image else None,
                'id_card_url': request.build_absolute_uri(user.id_card_image.url) if user.id_card_image else None,
                'latest_logs': logs_data
            }
            
            if scenario == 'success':
                response_data.update({'status': 'success', 'status_color': 'success', 'title': str(_("Access Granted"))})
            else:
                response_data.update({'status': 'success', 'status_color': 'warning', 'title': str(_("Expiring Soon!"))})
                
            return JsonResponse(response_data)

        except Exception as e:
            logger.error(f"QR Scan Error: {str(e)}", exc_info=True)
            return JsonResponse({'status': 'ignore'}, status=200)
        
        
class SubscriberListView(GymProviderRequiredMixin, ListView): 
    """
    GET /portal/gym/subscribers/
    Enterprise Grade CRM Dashboard for Subscribers.
    """
    model = GymSubscription
    template_name = "provider_portal/gym/subscribers/list.html"
    context_object_name = "subscriptions"

    def get_queryset(self):
        provider = self.request.user.provider_profile
        # Using prefetch_related for branches to avoid N+1 inside the template/JSON
        return GymSubscription.objects.select_related(
            'user', 'plan'
        ).prefetch_related(
            'visits', 'plan__branches'
        ).filter(
            plan__provider=provider
        ).order_by('-start_date')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        qs = self.get_queryset()
        
        # KPIs
        context['total_active'] = qs.filter(status='active').count()
        context['total_expired'] = qs.filter(status='expired').count()
        context['total_suspended'] = qs.filter(status='suspended').count()
        
        # Pass branches for the filter dropdown
        from apps.gyms.models import GymBranch
        context['branches'] = GymBranch.objects.filter(provider=self.request.user.provider_profile)
        
        return context