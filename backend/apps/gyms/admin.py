from django.contrib.gis import admin
from django.utils.translation import gettext_lazy as _
from .models import (
    GymAmenity, GymBranch, BranchImage, SubscriptionPlan, 
    PlanFeature, GymSubscription, GymVisit, GymGlobalSetting, GymAttendance
)

# 1. إعداد الخرائط والصور الفرعية للصالات
class BranchImageInline(admin.TabularInline):
    model = BranchImage
    extra = 1

@admin.register(GymBranch)
class GymBranchAdmin(admin.GISModelAdmin):
    """
    استخدام GISModelAdmin يظهر خريطة تفاعلية (OpenStreetMap) 
    في لوحة التحكم لتحديد موقع الصالة بسهولة.
    """
    list_display = ('name', 'provider', 'city', 'is_active', 'is_temporarily_closed', 'created_at')
    list_editable = ('is_active', 'is_temporarily_closed')
    list_filter = ('is_active', 'is_temporarily_closed', 'city', 'provider')
    search_fields = ('name', 'provider__business_name', 'city')
    inlines = [BranchImageInline]
    
    # إعدادات الخريطة الافتراضية (توسيط الخريطة على الرياض كمثال)
    default_lat = 24.7136
    default_lon = 46.6753
    default_zoom = 10

# 2. إعدادات باقات الاشتراك ومميزاتها
class PlanFeatureInline(admin.TabularInline):
    model = PlanFeature
    extra = 2

@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'provider', 'price', 'duration_days', 'is_active')
    list_filter = ('is_active', 'provider')
    search_fields = ('name', 'provider__business_name')
    inlines = [PlanFeatureInline]

# 3. إعدادات الاشتراكات الخاصة بالمستخدمين
@admin.register(GymSubscription)
class GymSubscriptionAdmin(admin.ModelAdmin):
    list_display = ('user', 'plan', 'status', 'start_date', 'end_date', 'is_resold')
    list_filter = ('status', 'is_resold', 'plan')
    search_fields = ('user__email', 'qr_code_id')
    readonly_fields = ('qr_code_id', 'purchased_at')

# 4. إعدادات الزيارات والحضور (لتتبع الكثافة)
@admin.register(GymAttendance)
class GymAttendanceAdmin(admin.ModelAdmin):
    list_display = ('member_reference', 'provider', 'check_in_time', 'is_currently_inside')
    list_filter = ('is_currently_inside', 'provider')
    search_fields = ('member_reference',)

@admin.register(GymVisit)
class GymVisitAdmin(admin.ModelAdmin):
    list_display = ('subscription', 'branch', 'check_in_time', 'check_out_time', 'is_active')
    list_filter = ('is_active', 'branch')

# 5. الجداول البسيطة
@admin.register(GymAmenity)
class GymAmenityAdmin(admin.ModelAdmin):
    list_display = ('name', 'icon_name')
    search_fields = ('name',)

@admin.register(GymGlobalSetting)
class GymGlobalSettingAdmin(admin.ModelAdmin):
    list_display = ('__str__', 'auto_checkout_hours')