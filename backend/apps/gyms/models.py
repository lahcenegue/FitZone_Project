"""
Database models for the Gyms application.
Handles branches, amenities, subscription plans, and user subscriptions.
Utilizes PostGIS for geographical location data.
"""

import uuid
from django.contrib.gis.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.validators import MinValueValidator, MaxValueValidator

from apps.providers.models import Provider
from apps.core.constants import BRANCH_GENDER_CHOICES


class GymAmenity(models.Model):
    """
    Lookup table for gym amenities (e.g., Swimming Pool, Sauna).
    """
    name = models.CharField(max_length=100, unique=True, verbose_name=_("Default Name"))
    translations = models.JSONField(
        default=dict, 
        blank=True, 
        help_text='Format: {"ar": "مسبح", "en": "Swimming Pool"}'
    )
    icon_image = models.ImageField(upload_to="gyms/amenities/icons/", null=True, blank=True)

    def __str__(self):
        return self.name

class GymSport(models.Model):
    """
    Lookup table for types of sports offered.
    """
    name = models.CharField(max_length=100, unique=True, verbose_name=_("Default Name"))
    translations = models.JSONField(
        default=dict, 
        blank=True, 
        help_text='Format: {"ar": "ملاكمة", "en": "Boxing"}'
    )
    image = models.ImageField(upload_to="gyms/sports/images/", null=True, blank=True)

    def __str__(self):
        return self.name


class GymBranch(models.Model):
    """
    Represents a physical branch of a gym provider.
    Includes geographical data for map integration and dynamic crowd thresholds.
    """
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name="gym_branches")
    name = models.CharField(max_length=255, verbose_name=_("Branch Name"))
    description = models.TextField(blank=True, verbose_name=_("Branch Description"))
    
    # Contact & Time
    phone_number = models.CharField(max_length=20, verbose_name=_("Branch Phone Number"))
    opening_time = models.TimeField(null=True, blank=True, verbose_name=_("Opening Time"))
    closing_time = models.TimeField(null=True, blank=True, verbose_name=_("Closing Time"))
    
    # Location data
    city = models.CharField(max_length=100, verbose_name=_("City"))
    address = models.CharField(max_length=512, verbose_name=_("Full Address"))
    location = models.PointField(geography=True, null=True, blank=True, verbose_name=_("Map Coordinates"))

    # Branch Logo
    branch_logo = models.ImageField(
        upload_to="gyms/branches/logos/", 
        null=True, 
        blank=True, 
        verbose_name=_("Branch Specific Logo")
    )
    
    # Relationships
    amenities = models.ManyToManyField(GymAmenity, blank=True, related_name="branches")
    sports = models.ManyToManyField(GymSport, blank=True, related_name="branches")

    gender = models.CharField(
        max_length=10,
        choices=BRANCH_GENDER_CHOICES,
        default="mixed",
        verbose_name=_("Target Gender")
    )
    
    # Live Crowd Management Settings
    max_capacity = models.PositiveIntegerField(default=100, verbose_name=_("Maximum Capacity"))
    estimated_stay_duration = models.PositiveIntegerField(
        default=120, 
        verbose_name=_("Estimated Stay Duration (Minutes)"),
        help_text=_("Average time a member spends in this branch.")
    )
    crowd_level_low = models.PositiveIntegerField(default=30, help_text=_("Percentage threshold for Low crowd (e.g., 30)"))
    crowd_level_medium = models.PositiveIntegerField(default=70, help_text=_("Percentage threshold for Medium crowd (e.g., 70)"))
    crowd_level_high = models.PositiveIntegerField(default=95, help_text=_("Percentage threshold for High crowd (e.g., 95)"))

    # Status
    is_active = models.BooleanField(default=True, verbose_name=_("Is Active"))
    is_temporarily_closed = models.BooleanField(
        default=False, 
        verbose_name=_("Temporarily Closed"),
        help_text=_("Check this to override the schedule and show the gym as closed immediately.")
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.provider.business_name})"


class BranchImage(models.Model):
    """
    Model to store multiple images for a single gym branch gallery.
    """
    branch = models.ForeignKey(
        'GymBranch', 
        on_delete=models.CASCADE, 
        related_name='images',
        verbose_name=_("Branch")
    )
    image = models.ImageField(
        upload_to="gyms/branches/gallery/",
        verbose_name=_("Image")
    )
    is_primary = models.BooleanField(
        default=False, 
        help_text=_("Will be used as the cover image on the app.")
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("Branch Image")
        verbose_name_plural = _("Branch Images")
        ordering = ['-created_at']

    def __str__(self):
        return f"Image for {self.branch.name}"


class GymBranchSchedule(models.Model):
    """
    Model to store specific working hours for each day of the week.
    """
    class Days(models.IntegerChoices):
        MONDAY = 0, _("Monday")
        TUESDAY = 1, _("Tuesday")
        WEDNESDAY = 2, _("Wednesday")
        THURSDAY = 3, _("Thursday")
        FRIDAY = 4, _("Friday")
        SATURDAY = 5, _("Saturday")
        SUNDAY = 6, _("Sunday")

    branch = models.ForeignKey(
        'GymBranch', 
        on_delete=models.CASCADE, 
        related_name='schedules',
        verbose_name=_("Branch")
    )
    day = models.IntegerField(choices=Days.choices, verbose_name=_("Day of Week"))
    opening_time = models.TimeField(null=True, blank=True, verbose_name=_("Opening Time"))
    closing_time = models.TimeField(null=True, blank=True, verbose_name=_("Closing Time"))
    is_closed = models.BooleanField(default=False, verbose_name=_("Is Closed?"))

    class Meta:
        verbose_name = _("Branch Schedule")
        verbose_name_plural = _("Branch Schedules")
        unique_together = ('branch', 'day')
        ordering = ['day']

    def __str__(self):
        return f"{self.branch.name} - {self.get_day_display()}"


class GymReview(models.Model):
    """
    Model to store customer reviews and ratings for a branch.
    """
    branch = models.ForeignKey(
        'GymBranch', 
        on_delete=models.CASCADE, 
        related_name='reviews',
        verbose_name=_("Branch")
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='gym_reviews',
        verbose_name=_("Customer")
    )
    rating = models.FloatField(
        validators=[MinValueValidator(1.0), MaxValueValidator(5.0)],
        verbose_name=_("Rating")
    )
    comment = models.TextField(verbose_name=_("Comment"))
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    class Meta:
        verbose_name = _("Gym Review")
        verbose_name_plural = _("Gym Reviews")
        ordering = ['-created_at']

    def __str__(self):
        return f"Review by {self.user.email} for {self.branch.name}"


class SubscriptionPlan(models.Model):
    """
    Subscription packages offered by the gym (e.g., 1 Month Gold, 1 Year VIP).
    Providers can assign a plan to specific branches or all branches.
    """
    provider = models.ForeignKey(Provider, on_delete=models.CASCADE, related_name="gym_plans")
    branches = models.ManyToManyField(GymBranch, related_name="available_plans")
    
    name = models.CharField(max_length=255, verbose_name=_("Plan Name"))
    description = models.TextField(blank=True, verbose_name=_("Plan Description"))
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Price"))
    duration_days = models.PositiveIntegerField(verbose_name=_("Duration in Days"))
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.provider.business_name}"


class PlanFeature(models.Model):
    """Specific features included in a subscription plan (e.g., Personal Trainer, Free Towels)."""
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.CASCADE, related_name="features")
    name = models.CharField(max_length=255, verbose_name=_("Feature Name"))

    def __str__(self):
        return self.name


class GymSubscription(models.Model):
    """
    Tracks which user purchased which plan, and their current validity.
    Includes a unique QR code for access and flags for the Resale system.
    """
    SUBSCRIPTION_STATUS = [
        ("active", _("Active")),
        ("expired", _("Expired")),
        ("cancelled", _("Cancelled")),
        ("transferred", _("Transferred/Resold")),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="gym_subscriptions")
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.PROTECT, related_name="subscribers")
    
    start_date = models.DateField(verbose_name=_("Start Date"))
    end_date = models.DateField(verbose_name=_("End Date"))
    
    status = models.CharField(max_length=20, choices=SUBSCRIPTION_STATUS, default="active")
    purchased_at = models.DateTimeField(auto_now_add=True)

    # --- QR Code System ---
    qr_code_id = models.UUIDField(
        default=uuid.uuid4, 
        editable=False, 
        unique=True, 
        verbose_name=_("QR Code Identifier")
    )

    # --- Resale System ---
    is_resold = models.BooleanField(
        default=False, 
        help_text=_("Indicates if this subscription was sold to another user.")
    )

    def __str__(self):
        return f"{self.user.email} - {self.plan.name} ({self.status})"


class GymVisit(models.Model):
    """
    Tracks real-time gym check-ins and check-outs.
    Used for live crowd management and occupancy tracking.
    """
    subscription = models.ForeignKey(GymSubscription, on_delete=models.CASCADE, related_name="visits")
    branch = models.ForeignKey(GymBranch, on_delete=models.CASCADE, related_name="visits")
    
    check_in_time = models.DateTimeField(auto_now_add=True, verbose_name=_("Check-in Time"))
    check_out_time = models.DateTimeField(null=True, blank=True, verbose_name=_("Check-out Time"))
    
    # is_active=True means the user is currently inside the gym
    is_active = models.BooleanField(default=True, db_index=True)

    def __str__(self):
        return f"Visit by {self.subscription.user.email} at {self.branch.name}"
    

class GymGlobalSetting(models.Model):
    """
    Singleton model for global gym settings controlled by Super Admin.
    Handles the auto-checkout duration for live occupancy tracking.
    """
    auto_checkout_hours = models.PositiveIntegerField(
        default=2,
        verbose_name=_("Auto Checkout Duration (Hours)"),
        help_text=_("How many hours before a visitor is automatically checked out.")
    )

    points_conversion_rate = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        default=10.00,
        verbose_name=_("Points Conversion Rate (SAR)"),
        help_text=_("How many Riyals equal 1 reward point for Gyms. (e.g., 10 means 1 point for every 10 SAR).")
    )

    class Meta:
        verbose_name = _("Gym Global Setting")
        verbose_name_plural = _("Gym Global Settings")

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def load(cls):
        obj, created = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return str(_("Gym Global Settings"))
    

class GymAttendance(models.Model):
    """
    Tracks daily check-ins for gym members.
    Used to calculate current gym capacity and estimated checkout times.
    """
    branch = models.ForeignKey(
        'GymBranch', 
        on_delete=models.CASCADE, 
        related_name="attendances"
    )
    member_reference = models.CharField(max_length=100) 
    
    check_in_time = models.DateTimeField(auto_now_add=True)
    estimated_checkout_time = models.DateTimeField()
    is_currently_inside = models.BooleanField(default=True)

    def save(self, *args, **kwargs):
        if not self.estimated_checkout_time:
            from datetime import timedelta
            from django.utils import timezone
            self.estimated_checkout_time = timezone.now() + timedelta(hours=2)
        super().save(*args, **kwargs)

    class Meta:
        ordering = ['-check_in_time']