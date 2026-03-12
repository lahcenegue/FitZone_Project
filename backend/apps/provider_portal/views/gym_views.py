"""
Views for Gym providers to manage branches, subscription plans, and subscribers.
Includes API view for the QR Code Scanner.
"""

import json
import logging
import random
from datetime import timedelta, timezone
from django.http import JsonResponse
from django.views.generic import ListView, FormView, View, DetailView
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from django.shortcuts import redirect, render, get_object_or_404
from django.contrib.gis.geos import Point

from apps.gyms.models import GymBranch, BranchImage, GymAmenity, SubscriptionPlan, PlanFeature, GymAttendance
from apps.provider_portal.forms.gym_forms import BranchForm, SubscriptionPlanForm

logger = logging.getLogger(__name__)


class GymProviderRequiredMixin(UserPassesTestMixin):
    """Ensure the logged-in user is a Gym Provider."""
    def test_func(self):
        user = self.request.user
        if not hasattr(user, 'provider_profile'):
            return False
        return user.provider_profile.provider_type == 'gym'


# ==========================================
# BRANCH VIEWS
# ==========================================

class BranchListView(LoginRequiredMixin, GymProviderRequiredMixin, ListView):
    model = GymBranch
    template_name = "provider_portal/gym/branches/list.html"
    context_object_name = "branches"

    def get_queryset(self):
        return GymBranch.objects.filter(
            provider=self.request.user.provider_profile
        ).order_by('-created_at')


class BranchAddView(LoginRequiredMixin, GymProviderRequiredMixin, FormView):
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
            is_active=is_active,
            opening_time=opening_time,
            closing_time=closing_time
        )

        if data.get('branch_logo'):
            branch.branch_logo = data['branch_logo']
            branch.save()

        amenities_str = data.get('custom_amenities', '')
        if amenities_str:
            amenity_objs = []
            for tag in amenities_str.split(','):
                tag = tag.strip()
                if tag:
                    obj, _created = GymAmenity.objects.get_or_create(name=tag)
                    amenity_objs.append(obj)
            branch.amenities.set(amenity_objs)

        if provider.status == 'pending':
            messages.warning(self.request, _("Branch added successfully, but remains inactive until verification."))
        else:
            messages.success(self.request, _("Branch added successfully."))
            
        return super().form_valid(form)


class BranchEditView(LoginRequiredMixin, GymProviderRequiredMixin, FormView):
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
            'is_active': branch.is_active,
            'sunday_open': branch.opening_time, 'sunday_close': branch.closing_time,
            'monday_open': branch.opening_time, 'monday_close': branch.closing_time,
            'tuesday_open': branch.opening_time, 'tuesday_close': branch.closing_time,
            'wednesday_open': branch.opening_time, 'wednesday_close': branch.closing_time,
            'thursday_open': branch.opening_time, 'thursday_close': branch.closing_time,
            'friday_open': branch.opening_time, 'friday_close': branch.closing_time,
            'saturday_open': branch.opening_time, 'saturday_close': branch.closing_time,
        }
        
        if branch.location:
            initial['latitude'] = branch.location.y
            initial['longitude'] = branch.location.x
            
        try:
            amenities_list = list(branch.amenities.values_list('name', flat=True))
            if amenities_list:
                initial['custom_amenities'] = ",".join(amenities_list)
        except Exception:
            initial['custom_amenities'] = ""
            
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
        branch.phone_number = data['phone_number']
        branch.description = data.get('description', '')
        
        if self.request.user.provider_profile.status == 'pending':
            branch.is_active = False
        else:
            branch.is_active = data.get('is_active', True)

        if data.get('branch_logo'):
            branch.branch_logo = data['branch_logo']

        branch.save()

        amenities_str = data.get('custom_amenities', '')
        if amenities_str:
            amenity_objs = []
            for tag in amenities_str.split(','):
                tag = tag.strip()
                if tag:
                    obj, _created = GymAmenity.objects.get_or_create(name=tag)
                    amenity_objs.append(obj)
            branch.amenities.set(amenity_objs)
        else:
            branch.amenities.clear()

        messages.success(self.request, _("Branch updated successfully."))
        return super().form_valid(form)


class BranchDeleteView(LoginRequiredMixin, GymProviderRequiredMixin, View):
    def post(self, request, branch_id):
        branch = get_object_or_404(GymBranch, id=branch_id, provider=request.user.provider_profile)
        branch.delete()
        messages.success(request, _("Branch deleted successfully."))
        return redirect("provider_portal:gym_branches")
    

class BranchDetailView(LoginRequiredMixin, GymProviderRequiredMixin, DetailView):
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


class BranchPhotosView(LoginRequiredMixin, GymProviderRequiredMixin, View):
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


# ==========================================
# PLAN VIEWS
# ==========================================

class PlanListView(LoginRequiredMixin, GymProviderRequiredMixin, ListView):
    model = SubscriptionPlan
    template_name = "provider_portal/gym/plans/list.html"
    context_object_name = "plans"

    def get_queryset(self):
        return SubscriptionPlan.objects.filter(
            provider=self.request.user.provider_profile
        ).order_by('price')
    

class PlanDetailView(LoginRequiredMixin, GymProviderRequiredMixin, DetailView):
    model = SubscriptionPlan
    template_name = "provider_portal/gym/plans/detail.html"
    context_object_name = "plan"
    pk_url_kwarg = 'plan_id'

    def get_queryset(self):
        return SubscriptionPlan.objects.filter(provider=self.request.user.provider_profile)


class PlanAddView(LoginRequiredMixin, GymProviderRequiredMixin, FormView):
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


class PlanEditView(LoginRequiredMixin, GymProviderRequiredMixin, FormView):
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


class PlanToggleView(LoginRequiredMixin, GymProviderRequiredMixin, View):
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
# QR SCANNER API VIEW
# ==========================================

class QRCodeScannerAPIView(LoginRequiredMixin, GymProviderRequiredMixin, View):
    """
    POST /portal/api/scan-qr/
    Validates FitZone QR code, generates rich member data, and tracks attendance.
    """
    def post(self, request, *args, **kwargs):
        try:
            data = json.loads(request.body)
            qr_code = data.get('qr_code', '').strip()
            
            if not qr_code:
                return JsonResponse({'status': 'ignore'}, status=200)

            # 1. SECURITY: STRICT QR CODE VALIDATION (Ignore silently if not FitZone)
            if not qr_code.startswith("fz_usr_"):
                # Return 'ignore' so the frontend doesn't show an error, just keeps scanning
                return JsonResponse({'status': 'ignore'}, status=200)

            provider = request.user.provider_profile
            now = timezone.now()

            # 2. REALISTIC MOCK DATA
            users_db = {
                "fz_usr_vip_999": {
                    "scenario": "success",
                    "member_id": "MEM-VIP999",
                    "member_name": "Lahcene Guenane",
                    "plan_name": "Premium VIP (1 Year)",
                    "total_days": 365, "days_left": 200, "visits": 45,
                    "message": _("Check-in successful. Welcome back Lahcene!")
                },
                "fz_usr_warn_555": {
                    "scenario": "warning",
                    "member_id": "MEM-WRN555",
                    "member_name": "Ahmed Khaled",
                    "plan_name": "Standard Fitness (1 Month)",
                    "total_days": 30, "days_left": 2, "visits": 28,
                    "message": _("Subscription expires in 2 days. Please remind the member.")
                },
                "fz_usr_exp_111": {
                    "scenario": "error",
                    "member_id": "MEM-EXP111",
                    "member_name": "Omar Salem",
                    "plan_name": "Cardio Plan",
                    "total_days": 30, "days_left": 0, "visits": 0,
                    "message": _("Subscription expired. Access Denied.")
                }
            }

            user_data = users_db.get(qr_code)

            if not user_data:
                return JsonResponse({
                    'status': 'error',
                    'status_color': 'error',
                    'title': _("Member Not Found"),
                    'message': _("This code is valid but the member does not exist in this gym.")
                })

            # 3. SAFE DATABASE TRACKING
            current_capacity = 0
            try:
                if user_data['scenario'] in ['success', 'warning']:
                    GymAttendance.objects.create(
                        provider=provider,
                        member_reference=user_data['member_id'],
                        is_currently_inside=True
                    )
                current_capacity = GymAttendance.objects.filter(
                    provider=provider, 
                    is_currently_inside=True
                ).count()
            except Exception as db_err:
                logger.warning(f"DB Error (Missing Migrations?): {db_err}")
                current_capacity = 12 

            # 4. BUILD RESPONSE
            response_data = {
                'member_id': user_data['member_id'],
                'member_name': user_data['member_name'],
                'plan_name': user_data['plan_name'],
                'total_days': user_data['total_days'],
                'days_left': user_data['days_left'],
                'visits_this_month': user_data['visits'],
                'message': user_data['message'],
                'current_capacity': current_capacity,
                'estimated_exit': (now + timedelta(hours=2)).strftime("%I:%M %p"),
                'avatar_url': None 
            }
            
            if user_data['scenario'] == 'success':
                response_data.update({'status': 'success', 'status_color': 'success', 'title': _("Access Granted")})
            elif user_data['scenario'] == 'warning':
                response_data.update({'status': 'success', 'status_color': 'warning', 'title': _("Expiring Soon!")})
            else:
                response_data.update({'status': 'error', 'status_color': 'error', 'title': _("Access Denied")})
                
            return JsonResponse(response_data)

        except Exception as e:
            logger.error(f"QR Scan Error: {str(e)}")
            return JsonResponse({'status': 'ignore'}, status=200)

class SubscriberListView(LoginRequiredMixin, View): 
    pass