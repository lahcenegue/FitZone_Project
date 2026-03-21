from django.contrib import admin
from .models import AppConfiguration

@admin.register(AppConfiguration)
class AppConfigurationAdmin(admin.ModelAdmin):
    list_display = ('__str__', 'android_version', 'ios_version', 'force_update', 'updated_at')
    
    def has_add_permission(self, request):
        # Prevent adding multiple instances
        if self.model.objects.exists():
            return False
        return super().has_add_permission(request)