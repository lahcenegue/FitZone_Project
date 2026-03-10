"""
Views for Gym providers to manage branches, subscription plans, and subscribers.
"""

import logging
from django.views.generic import ListView, FormView, View, DetailView
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from django.shortcuts import redirect, render, get_object_or_404
from django.contrib.gis.geos import Point

from apps.gyms.models import GymBranch, BranchImage, GymAmenity, SubscriptionPlan, PlanFeature
from apps.provider_portal.forms.gym_forms import BranchForm, SubscriptionPlanForm

logger = logging.getLogger(__name__)


class GymProviderRequiredMixin(UserPassesTestMixin):
    """Ensure the logged-in user is a Gym Provider."""
    def test_func(self):
        user = self.request.user
        if not hasattr(user, 'provider_profile'):
            return False
        return user.provider_profile.provider_type == 'gym'


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

        # 1. Location Parsing
        location = None
        lat = data.get('latitude')
        lng = data.get('longitude')
        if lat and lng:
            try:
                location = Point(float(lng), float(lat), srid=4326)
            except (ValueError, TypeError):
                logger.error("Invalid coordinates.")

        opening_time = data.get('sunday_open') or data.get('monday_open')
        closing_time = data.get('sunday_close') or data.get('monday_close')

        # 2. Activation Status
        is_active = data.get('is_active', True)
        if provider.status == 'pending':
            is_active = False

        # 3. Create Branch (Now includes 'city')
        branch = GymBranch.objects.create(
            provider=provider,
            name=data['name'],
            city=data['city'],  # <-- City is now saved to DB
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

        # 4. Amenities (Fixed boolean shadowing bug by using 'created' instead of '_')
        amenities_str = data.get('custom_amenities', '')
        if amenities_str:
            amenity_objs = []
            for tag in amenities_str.split(','):
                tag = tag.strip()
                if tag:
                    obj, created = GymAmenity.objects.get_or_create(name=tag)
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
            'city': branch.city, # <-- Pre-fill city
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
        branch.city = data['city'] # <-- Update city
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

        # Fixed Bug here as well
        amenities_str = data.get('custom_amenities', '')
        if amenities_str:
            amenity_objs = []
            for tag in amenities_str.split(','):
                tag = tag.strip()
                if tag:
                    obj, created = GymAmenity.objects.get_or_create(name=tag)
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
    """
    GET /portal/gym/branches/<id>/
    Displays the full details of a specific branch, including its photos and associated plans.
    """
    model = GymBranch
    template_name = "provider_portal/gym/branches/detail.html"
    context_object_name = "branch"
    pk_url_kwarg = 'branch_id'

    def get_queryset(self):
        # Security: Ensure the provider can only view their own branches
        return GymBranch.objects.filter(provider=self.request.user.provider_profile)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # Fetch associated photos
        context['photos'] = self.object.images.all()
        # Fetch active subscription plans linked specifically to this branch
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
    
class PlanListView(LoginRequiredMixin, GymProviderRequiredMixin, ListView):
    """Displays all subscription plans created by the provider."""
    model = SubscriptionPlan
    template_name = "provider_portal/gym/plans/list.html"
    context_object_name = "plans"

    def get_queryset(self):
        return SubscriptionPlan.objects.filter(
            provider=self.request.user.provider_profile
        ).order_by('price')
    
class PlanDetailView(LoginRequiredMixin, GymProviderRequiredMixin, DetailView):
    """
    GET /portal/gym/plans/<id>/
    Displays the full details of a specific subscription plan, including features and linked branches.
    """
    model = SubscriptionPlan
    template_name = "provider_portal/gym/plans/detail.html"
    context_object_name = "plan"
    pk_url_kwarg = 'plan_id'

    def get_queryset(self):
        # Security: Ensure the provider can only view their own plans
        return SubscriptionPlan.objects.filter(provider=self.request.user.provider_profile)


class PlanAddView(LoginRequiredMixin, GymProviderRequiredMixin, FormView):
    """Handles creation of a new subscription plan."""
    form_class = SubscriptionPlanForm
    template_name = "provider_portal/gym/plans/form.html"
    success_url = reverse_lazy("provider_portal:gym_plans")

    def get_form_kwargs(self):
        """Inject the provider into the form to filter branches."""
        kwargs = super().get_form_kwargs()
        kwargs['provider'] = self.request.user.provider_profile
        return kwargs

    def form_valid(self, form):
        data = form.cleaned_data
        
        # 1. Create the base Plan (Removed is_transferable as it's not in models.py)
        plan = SubscriptionPlan.objects.create(
            provider=self.request.user.provider_profile,
            name=data['name'],
            description=data.get('description', ''),
            duration_days=data['duration_days'],
            price=data['price'],
            is_active=data.get('is_active', True)
        )
        
        # 2. Assign selected branches
        plan.branches.set(data['branches'])
        
        # 3. Save Features (Tags) into PlanFeature model
        features_str = data.get('custom_features', '')
        if features_str:
            for feature_text in features_str.split(','):
                tag = feature_text.strip()
                if tag:
                    # Using 'name' as per your models.py
                    PlanFeature.objects.create(plan=plan, name=tag)
            
        messages.success(self.request, _("Subscription plan added successfully."))
        return super().form_valid(form)


class PlanEditView(LoginRequiredMixin, GymProviderRequiredMixin, FormView):
    """Handles editing an existing subscription plan."""
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
        """Pre-fill the form with existing data."""
        plan = self.get_plan()
        
        # Extract features as comma-separated string for the tags input
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

        # 1. Update the base Plan (Removed is_transferable)
        plan.name = data['name']
        plan.description = data.get('description', '')
        plan.duration_days = data['duration_days']
        plan.price = data['price']
        plan.is_active = data.get('is_active', True)
        plan.save()
        
        # 2. Update branches
        plan.branches.set(data['branches'])

        # 3. Update Features (Delete old, create new)
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
    """Quickly toggles the active status of a plan."""
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

# Placeholder classes
class SubscriberListView(LoginRequiredMixin, View): pass