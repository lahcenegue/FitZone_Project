from django.shortcuts import redirect
from django.contrib.auth import logout
from django.contrib import messages
from django.utils.translation import gettext_lazy as _

class ProviderRequiredMixin:
    """
    Base security layer for all portal views.
    Handles Authentication and strictly blocks Admin accounts.
    """
    def dispatch(self, request, *args, **kwargs):
        # 1. فحص تسجيل الدخول
        if not request.user.is_authenticated:
            return redirect('provider_portal:login')

        # 2. فحص الإدمن (طرد فوري)
        if request.user.is_superuser or getattr(request.user, 'is_staff', False):
            logout(request)
            messages.error(request, _("Admin accounts cannot access the Provider Portal. You have been logged out."))
            return redirect('provider_portal:login')
            
        # 3. فحص وجود ملف المورد
        if not hasattr(request.user, 'provider_profile'):
            logout(request)
            messages.error(request, _("Your account is not registered as a Provider."))
            return redirect('provider_portal:login')

        # السماح بالمرور إذا اجتاز كل الفحوصات
        return super().dispatch(request, *args, **kwargs)


class GymProviderRequiredMixin:
    """
    Specific security layer for Gym-only routes.
    Includes all base checks + Gym type verification.
    """
    def dispatch(self, request, *args, **kwargs):
        # 1. فحص تسجيل الدخول
        if not request.user.is_authenticated:
            return redirect('provider_portal:login')

        # 2. فحص الإدمن (طرد فوري)
        if request.user.is_superuser or getattr(request.user, 'is_staff', False):
            logout(request)
            messages.error(request, _("Admin accounts cannot access the Provider Portal. You have been logged out."))
            return redirect('provider_portal:login')

        # 3. فحص وجود ملف المورد
        if not hasattr(request.user, 'provider_profile'):
            logout(request)
            messages.error(request, _("Your account is not registered as a Provider."))
            return redirect('provider_portal:login')

        # 4. فحص نوع المورد (يجب أن يكون صالة رياضية)
        if request.user.provider_profile.provider_type != 'gym':
            messages.error(request, _("Access denied. This section is for Gym providers only."))
            return redirect('provider_portal:dashboard')

        # السماح بالمرور
        return super().dispatch(request, *args, **kwargs)