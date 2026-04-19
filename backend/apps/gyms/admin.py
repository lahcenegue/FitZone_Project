from django.contrib.gis import admin
from django.utils.translation import gettext_lazy as _
from .models import (
    GymAmenity, GymBranch, BranchImage, SubscriptionPlan, 
    PlanFeature, GymSubscription, GymSubscriptionDispute, 
    GymVisit, GymGlobalSetting, GymAttendance, GymSport, 
    GymBranchSchedule, GymReview
)

# 1. Branch Maps, Images, and Schedules
class BranchImageInline(admin.TabularInline):
    model = BranchImage
    extra = 1

class GymBranchScheduleInline(admin.TabularInline):
    model = GymBranchSchedule
    extra = 7

@admin.register(GymBranch)
class GymBranchAdmin(admin.GISModelAdmin):
    list_display = ('name', 'provider', 'city', 'is_active', 'is_temporarily_closed', 'created_at')
    list_editable = ('is_active', 'is_temporarily_closed')
    list_filter = ('is_active', 'is_temporarily_closed', 'city', 'provider')
    search_fields = ('name', 'provider__business_name', 'city')
    inlines = [BranchImageInline, GymBranchScheduleInline]
    default_lat = 24.7136
    default_lon = 46.6753
    default_zoom = 10

# 2. Subscription Plans
class PlanFeatureInline(admin.TabularInline):
    model = PlanFeature
    extra = 1

@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'provider', 'price', 'duration_days', 'is_active', 'is_archived')
    list_filter = ('is_active', 'is_archived', 'provider')
    search_fields = ('name', 'provider__business_name')
    inlines = [PlanFeatureInline]

# 3. User Subscriptions & Disputes
@admin.register(GymSubscription)
class GymSubscriptionAdmin(admin.ModelAdmin):
    list_display = ('user', 'plan', 'status', 'start_date', 'end_date', 'is_resold')
    list_filter = ('status', 'is_resold', 'plan')
    search_fields = ('user__email', 'qr_code_id')
    readonly_fields = ('qr_code_id', 'purchased_at')

@admin.register(GymSubscriptionDispute)
class GymSubscriptionDisputeAdmin(admin.ModelAdmin):
    list_display = ('subscription', 'status', 'opened_by', 'created_at')
    list_filter = ('status',)
    search_fields = ('subscription__user__email',)

# 4. Visits and Attendance
@admin.register(GymAttendance)
class GymAttendanceAdmin(admin.ModelAdmin):
    list_display = ('member_reference', 'branch', 'check_in_time', 'estimated_checkout_time', 'is_currently_inside')
    list_filter = ('is_currently_inside', 'branch', 'check_in_time')
    search_fields = ('member_reference', 'branch__name')

@admin.register(GymVisit)
class GymVisitAdmin(admin.ModelAdmin):
    list_display = ('subscription', 'branch', 'check_in_time', 'check_out_time', 'is_active')
    list_filter = ('is_active', 'branch')

# 5. Simple Tables & Reviews
@admin.register(GymAmenity)
class GymAmenityAdmin(admin.ModelAdmin):
    list_display = ('name', 'icon_image')
    search_fields = ('name',)

@admin.register(GymSport)
class GymSportAdmin(admin.ModelAdmin):
    list_display = ('id', 'name')
    search_fields = ('name',)
    ordering = ('name',)

@admin.register(GymReview)
class GymReviewAdmin(admin.ModelAdmin):
    list_display = ('user', 'branch', 'rating', 'created_at')
    list_filter = ('rating',)
    search_fields = ('user__email', 'branch__name')

# 6. Global Settings (Singleton)
@admin.register(GymGlobalSetting)
class GymGlobalSettingAdmin(admin.ModelAdmin):
    list_display = ('__str__', 'earnings_hold_days', 'points_conversion_rate', 'auto_checkout_hours')
    
    def has_add_permission(self, request):
        """Prevent adding multiple settings since it's a Singleton model."""
        if self.model.objects.exists():
            return False
        return super().has_add_permission(request)
    
    def has_delete_permission(self, request, obj=None):
        """Prevent deleting the global settings."""
        return False