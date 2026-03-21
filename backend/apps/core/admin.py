from django.contrib import admin
from .models import AppConfiguration, City

@admin.register(AppConfiguration)
class AppConfigurationAdmin(admin.ModelAdmin):
    list_display = ('__str__', 'android_version', 'ios_version', 'force_update', 'updated_at')
    
    readonly_fields = ('sports_version', 'amenities_version', 'cities_version')
    
    def has_add_permission(self, request):
        if self.model.objects.exists():
            return False
        return super().has_add_permission(request)

@admin.register(City)
class CityAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'is_active', 'sort_order')
    list_editable = ('is_active', 'sort_order')
    search_fields = ('name', 'code')