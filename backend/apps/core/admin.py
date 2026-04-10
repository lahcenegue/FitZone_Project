from django.contrib import admin
from .models import AppConfiguration, City

@admin.register(AppConfiguration)
class AppConfigurationAdmin(admin.ModelAdmin):
    list_display = (
        '__str__', 
        'premium_points_required', 
        'points_config_version', 
        'android_version', 
        'ios_version', 
        'force_update', 
        'updated_at'
    )

    # جعل رقم الإصدار للقراءة فقط
    readonly_fields = (
        'sports_version', 
        'amenities_version', 
        'cities_version', 
        'service_types_version',
        'points_config_version' 
    )
    
    fieldsets = (
        ('App Versions & Updates', {
            'fields': ('android_version', 'ios_version', 'force_update', 'update_message')
        }),
        ('Loyalty & Subscriptions', {
            # تمت إزالة points_config_version من هنا لأنه أصبح في readonly_fields بالأسفل
            'fields': ('premium_points_required',) 
        }),
        ('Static Data Versions (Read Only)', {
            'fields': ('sports_version', 'amenities_version', 'cities_version', 'service_types_version', 'points_config_version')
        }),
    )
    
    def has_add_permission(self, request):
        if self.model.objects.exists():
            return False
        return super().has_add_permission(request)

@admin.register(City)
class CityAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'is_active', 'sort_order')
    list_editable = ('is_active', 'sort_order')
    search_fields = ('name', 'code')