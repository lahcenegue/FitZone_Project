from django.contrib.auth.mixins import UserPassesTestMixin
from django.shortcuts import redirect
from django.contrib import messages
from django.utils.translation import gettext_lazy as _

class SuperuserRequiredMixin(UserPassesTestMixin):
    """
    Security Mixin: Restricts access exclusively to system superusers.
    Redirects unauthorized users to the secure dashboard login page.
    """
    def test_func(self):
        return self.request.user.is_authenticated and self.request.user.is_superuser

    def handle_no_permission(self):
        if not self.request.user.is_authenticated:
            messages.error(self.request, _("Please login to access the Mastermind Dashboard."))
        else:
            messages.error(self.request, _("Access Denied. Mastermind privileges required."))
        return redirect('dashboard:login')