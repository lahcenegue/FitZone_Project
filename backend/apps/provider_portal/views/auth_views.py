"""
Authentication views for the FitZone Provider Portal.
Handles login, registration (4 steps), logout, pending, and suspended pages.
All business logic delegated to auth_service.
"""

import logging
from django.views import View
from django.shortcuts import render, redirect
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from apps.provider_portal.forms.auth_forms import (
    RegistrationStep1Form,
    RegistrationStep2Form,
    RegistrationStep3Form,
    LoginForm,
)
from apps.provider_portal.services.auth_service import (
    login_provider,
    logout_provider,
    register_provider,
    AuthenticationError,
    RegistrationError,
)
from apps.provider_portal.decorators import anonymous_required, portal_login_required
from apps.provider_portal.constants import (
    SESSION_REGISTRATION_DATA,
    REGISTRATION_STEP_ACCOUNT,
    REGISTRATION_STEP_TYPE,
    REGISTRATION_STEP_BUSINESS,
    REGISTRATION_TOTAL_STEPS,
    SAUDI_CITIES,
)
from apps.providers.models import ProviderType

logger = logging.getLogger(__name__)


class LoginView(View):
    """
    Provider portal login page.
    GET: render login form.
    POST: authenticate and redirect based on provider status.
    """
    template_name = "provider_portal/auth/login.html"

    @staticmethod
    def _redirect_by_status(provider):
        """Return the correct redirect based on provider status."""
        from apps.providers.models import ProviderStatus
        status_map = {
            ProviderStatus.ACTIVE:    "provider_portal:dashboard",
            ProviderStatus.PENDING:   "provider_portal:pending",
            ProviderStatus.APPROVED:  "provider_portal:pending",
            ProviderStatus.SUSPENDED: "provider_portal:suspended",
        }
        return redirect(status_map.get(provider.status, "provider_portal:login"))

    def get(self, request):
        """Render login form. Redirect if already authenticated."""
        if request.user.is_authenticated and hasattr(request.user, "provider_profile"):
            return self._redirect_by_status(request.user.provider_profile)
        return render(request, self.template_name, {"form": LoginForm()})

    def post(self, request):
        """Process login form submission."""
        form = LoginForm(request.POST)
        if not form.is_valid():
            return render(request, self.template_name, {"form": form})

        try:
            provider = login_provider(
                request,
                email=form.cleaned_data["email"],
                password=form.cleaned_data["password"],
            )
            return self._redirect_by_status(provider)

        except AuthenticationError as exc:
            messages.error(request, str(exc))
            return render(request, self.template_name, {"form": form})


class LogoutView(View):
    """
    Logout view — POST only for CSRF protection.
    """

    def post(self, request):
        """Log out the provider and redirect to login."""
        logout_provider(request)
        return redirect("provider_portal:login")

    def get(self, request):
        """GET on logout redirects to login without logging out."""
        return redirect("provider_portal:login")


class RegisterView(View):
    """
    Multi-step provider registration.
    Step data stored in session between steps.
    GET: render current step.
    POST: validate current step, advance or go back.
    """
    template_name = "provider_portal/auth/register.html"

    def _get_step(self, request):
        """Return the current registration step from session, defaulting to 1."""
        return request.session.get("registration_step", 1)

    def _set_step(self, request, step):
        """Persist the current registration step in session."""
        request.session["registration_step"] = step

    def _get_saved_data(self, request):
        """Return all saved registration data from session."""
        return request.session.get(SESSION_REGISTRATION_DATA, {})

    def _save_step_data(self, request, step_key, data):
        """Save validated form data for a step into the session."""
        saved = self._get_saved_data(request)
        saved[step_key] = data
        request.session[SESSION_REGISTRATION_DATA] = saved

    def _build_context(self, request, form, step):
        """Build the template context for the current registration step."""
        context = {
            "form":          form,
            "current_step":  step,
            "steps":         range(1, REGISTRATION_TOTAL_STEPS + 1),
            "city_choices":  SAUDI_CITIES,
        }
        if step == 4:
            saved = self._get_saved_data(request)
            step1 = saved.get("step1", {})
            step2 = saved.get("step2", {})
            step3 = saved.get("step3", {})

            # Resolve display labels
            type_display = dict(ProviderType.choices).get(step2.get("provider_type", ""), "")
            city_display = dict(SAUDI_CITIES).get(step3.get("city", ""), step3.get("city", ""))

            context["review_data"] = {
                "full_name":               step1.get("full_name", ""),
                "email":                   step1.get("email", ""),
                "phone_number":            step1.get("phone_number", ""),
                "provider_type":           step2.get("provider_type", ""),
                "provider_type_display":   type_display,
                "business_name":           step3.get("business_name", ""),
                "city":                    step3.get("city", ""),
                "city_display":            city_display,
                "commercial_registration": step3.get("commercial_registration", ""),
            }
        return context

    def get(self, request):
        """Render the current registration step."""
        if request.user.is_authenticated and hasattr(request.user, 'provider_profile'):
            return redirect("provider_portal:dashboard")

        step = self._get_step(request)
        saved = self._get_saved_data(request)

        # Pre-fill form with saved data if navigating back
        step_key = f"step{step}"
        initial = saved.get(step_key, {})

        form_map = {
            1: RegistrationStep1Form(initial=initial),
            2: RegistrationStep2Form(initial=initial),
            3: RegistrationStep3Form(initial=initial),
            4: None,
        }
        form = form_map.get(step, RegistrationStep1Form())
        return render(request, self.template_name, self._build_context(request, form, step))

    def post(self, request):
        """Process registration step submission."""
        if request.user.is_authenticated and hasattr(request.user, 'provider_profile'):
            return redirect("provider_portal:dashboard")

        step = int(request.POST.get("step", 1))
        direction = request.POST.get("direction", "next")

        # Handle back navigation — no validation needed
        if direction == "back" and step > 1:
            self._set_step(request, step - 1)
            return redirect("provider_portal:register")

        # Validate current step
        if step == 1:
            form = RegistrationStep1Form(request.POST)
            if not form.is_valid():
                return render(request, self.template_name, self._build_context(request, form, step))
            self._save_step_data(request, "step1", {
                "full_name":    form.cleaned_data["full_name"],
                "email":        form.cleaned_data["email"],
                "phone_number": form.cleaned_data["phone_number"],
                "password":     form.cleaned_data["password"],
            })
            self._set_step(request, 2)
            return redirect("provider_portal:register")

        elif step == 2:
            form = RegistrationStep2Form(request.POST)
            if not form.is_valid():
                return render(request, self.template_name, self._build_context(request, form, step))
            self._save_step_data(request, "step2", {
                "provider_type": form.cleaned_data["provider_type"],
            })
            self._set_step(request, 3)
            return redirect("provider_portal:register")

        elif step == 3:
            form = RegistrationStep3Form(request.POST)
            if not form.is_valid():
                return render(request, self.template_name, self._build_context(request, form, step))
            self._save_step_data(request, "step3", {
                "business_name":           form.cleaned_data["business_name"],
                "city":                    form.cleaned_data["city"],
                "commercial_registration": form.cleaned_data.get("commercial_registration", ""),
                "tax_id":                  form.cleaned_data.get("tax_id", ""),
                "description":             form.cleaned_data.get("description", ""),
            })
            self._set_step(request, 4)
            return redirect("provider_portal:register")

        elif step == 4:
            if direction == "back":
                self._set_step(request, 3)
                return redirect("provider_portal:register")

            # Final submission
            saved = self._get_saved_data(request)
            step1 = saved.get("step1")
            step2 = saved.get("step2")
            step3 = saved.get("step3")

            if not all([step1, step2, step3]):
                # Session expired or incomplete — restart
                self._set_step(request, 1)
                messages.error(request, _("Your session expired. Please start over."))
                return redirect("provider_portal:register")

            try:
                register_provider(request, step1, step2, step3)
                # Clear registration session data
                request.session.pop(SESSION_REGISTRATION_DATA, None)
                request.session.pop("registration_step", None)
                return redirect("provider_portal:pending")

            except RegistrationError as exc:
                messages.error(request, str(exc))
                return render(
                    request, self.template_name,
                    self._build_context(request, None, 4),
                )

        # Fallback
        self._set_step(request, 1)
        return redirect("provider_portal:register")


class PendingView(View):
    """
    Shown to providers with PENDING or APPROVED status.
    Requires authentication — unauthenticated users go to login.
    """
    template_name = "provider_portal/auth/pending.html"

    def get(self, request):
        """Render the pending approval page."""
        if not request.user.is_authenticated:
            return redirect("provider_portal:login")
        return render(request, self.template_name)


class SuspendedView(View):
    """
    Shown to providers with SUSPENDED status.
    Requires authentication — unauthenticated users go to login.
    """
    template_name = "provider_portal/auth/suspended.html"

    def get(self, request):
        """Render the suspended account page."""
        if not request.user.is_authenticated:
            return redirect("provider_portal:login")
        return render(request, self.template_name)