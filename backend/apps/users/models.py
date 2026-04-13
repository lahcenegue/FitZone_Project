"""
Custom User model for FitZone.
Email is the primary login identifier — no username field.
Must be set as AUTH_USER_MODEL before the first migration.
"""

import logging
import random
from datetime import timedelta
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.contrib.gis.db import models as gis_models
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

from apps.core.constants import OTP_EXPIRATION_MINUTES

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

class UserRole(models.TextChoices):
    """Defines all possible roles a user can hold in the system."""
    CUSTOMER = "customer", _("Customer")
    PROVIDER = "provider", _("Provider")
    ADMIN = "admin", _("Admin")


class UserGender(models.TextChoices):
    """Gender options for user profile."""
    MALE = "male", _("Male")
    FEMALE = "female", _("Female")
    UNSPECIFIED = "unspecified", _("Unspecified")


# ---------------------------------------------------------------------------
# Manager
# ---------------------------------------------------------------------------

class UserManager(BaseUserManager):
    """
    Custom manager for the User model.
    Handles creation of regular users and superusers using email as identifier.
    """

    def create_user(self, email, password=None, **extra_fields):
        """
        Create and return a regular user with the given email and password.
        """
        if not email:
            raise ValueError(_("Email address is required."))

        email = self.normalize_email(email)
        extra_fields.setdefault("role", UserRole.CUSTOMER)
        extra_fields.setdefault("is_active", True)

        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)

        logger.info("New user created: %s | role: %s", email, extra_fields.get("role"))
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """
        Create and return a superuser with admin privileges.
        """
        extra_fields.setdefault("role", UserRole.ADMIN)
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)
        extra_fields.setdefault("is_verified", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError(_("Superuser must have is_staff=True."))
        if extra_fields.get("is_superuser") is not True:
            raise ValueError(_("Superuser must have is_superuser=True."))

        return self.create_user(email, password, **extra_fields)


# ---------------------------------------------------------------------------
# Model
# ---------------------------------------------------------------------------

class User(AbstractBaseUser, PermissionsMixin):
    """
    FitZone custom user model.

    Authentication: email + password
    Roles: customer, provider, admin
    Location: PostGIS PointField for map-based features
    Points: loyalty points system with balance tracking
    """

    # --- Identity ---
    email = models.EmailField(
        _("Email address"),
        unique=True,
        db_index=True,
    )
    full_name = models.CharField(
        _("Full name"),
        max_length=255,
    )
    phone_number = models.CharField(
        _("Phone number"),
        max_length=20,
        blank=True,
        default="",
        db_index=True,
    )
    phone_verified = models.BooleanField(
        _("Phone verified"),
        default=False,
    )

    # --- Profile ---
    avatar = models.ImageField(
        _("Avatar"),
        upload_to="avatars/",
        blank=True,
        null=True,
    )

    gender = models.CharField(
        _("Gender"),
        max_length=20,
        choices=UserGender.choices,
        default=UserGender.UNSPECIFIED,
    )

    # --- Verification (Step 2) ---
    real_face_image = models.ImageField(
        _("Real Face Image"),
        upload_to="users/verification/faces/",
        blank=True,
        null=True,
        help_text=_("Required for gym subscription check-ins.")
    )
    id_card_image = models.ImageField(
        _("ID Card Image"),
        upload_to="users/verification/id_cards/",
        blank=True,
        null=True,
        help_text=_("Required for identity verification.")
    )

    # --- Location ---
    location = gis_models.PointField(
        _("Location"),
        geography=True,
        blank=True,
        null=True,
        srid=4326,
    )
    address = models.CharField(
        _("Address"),
        max_length=512,
        blank=True,
        default="",
    )
    city = models.CharField(
        _("City"),
        max_length=100,
        blank=True,
        default="",
        db_index=True,
    )

    # --- Role & Status ---
    role = models.CharField(
        _("Role"),
        max_length=20,
        choices=UserRole.choices,
        default=UserRole.CUSTOMER,
        db_index=True,
    )
    is_active = models.BooleanField(
        _("Active"),
        default=True,
    )
    is_staff = models.BooleanField(
        _("Staff"),
        default=False,
    )
    is_verified = models.BooleanField(
        _("Verified"),
        default=False,
    )

    # --- Premium ---
    is_premium = models.BooleanField(
        _("Premium"),
        default=False,
    )
    premium_since = models.DateTimeField(
        _("Premium since"),
        blank=True,
        null=True,
    )

    # --- Loyalty Points ---
    points_balance = models.PositiveIntegerField(
        _("Points balance"),
        default=0,
    )
    points_total = models.PositiveIntegerField(
        _("Total points earned"),
        default=0,
    )

    # --- Timestamps ---
    date_joined = models.DateTimeField(
        _("Date joined"),
        auto_now_add=True,
    )
    updated_at = models.DateTimeField(
        _("Updated at"),
        auto_now=True,
    )

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]

    class Meta:
        verbose_name = _("User")
        verbose_name_plural = _("Users")
        ordering = ["-date_joined"]

    def __str__(self):
        return f"{self.full_name} <{self.email}>"

    # ---------------------------------------------------------------------------
    # Properties
    # ---------------------------------------------------------------------------

    @property
    def display_name(self):
        """Return full name if set, otherwise the email prefix."""
        return self.full_name if self.full_name else self.email.split("@")[0]

    @property
    def has_location(self):
        """Return True if the user has set a geographic location."""
        return self.location is not None

    @property
    def profile_complete(self):
        """
        Return True if the user has filled in all essential profile fields
        and uploaded the required identity documents.
        """
        return bool(
            self.full_name and 
            self.phone_number and 
            self.city and 
            self.real_face_image and 
            self.id_card_image
        )

    # ---------------------------------------------------------------------------
    # Methods
    # ---------------------------------------------------------------------------

    def add_points(self, amount: int, reason: str = "") -> None:
        """
        Add loyalty points to the user's balance and total.

        Args:
            amount: Number of points to add. Must be a positive integer.
            reason: Human-readable reason for the audit log.
        """
        if amount <= 0:
            raise ValueError("Points amount must be a positive integer.")

        self.points_balance += amount
        self.points_total += amount
        self.save(update_fields=["points_balance", "points_total", "updated_at"])

        logger.info(
            "Points added | user: %s | amount: %d | reason: %s | balance: %d",
            self.email, amount, reason, self.points_balance,
        )

    def deduct_points(self, amount: int, reason: str = "") -> None:
        """
        Deduct loyalty points from the user's balance.

        Args:
            amount: Number of points to deduct. Must not exceed current balance.
            reason: Human-readable reason for the audit log.
        """
        if amount <= 0:
            raise ValueError("Points amount must be a positive integer.")
        if amount > self.points_balance:
            raise ValueError("Insufficient points balance.")

        self.points_balance -= amount
        self.save(update_fields=["points_balance", "updated_at"])

        logger.info(
            "Points deducted | user: %s | amount: %d | reason: %s | balance: %d",
            self.email, amount, reason, self.points_balance,
        )

    def suspend(self, reason: str = "") -> None:
        """
        Deactivate the user account.

        Args:
            reason: Human-readable reason for the audit log.
        """
        self.is_active = False
        self.save(update_fields=["is_active", "updated_at"])

        logger.warning(
            "User suspended | user: %s | reason: %s",
            self.email, reason,
        )

    def activate(self) -> None:
        """Reactivate a previously suspended user account."""
        self.is_active = True
        self.save(update_fields=["is_active", "updated_at"])

        logger.info("User activated | user: %s", self.email)

    def update_location(self, longitude: float, latitude: float) -> None:
        """
        Update the user's geographic location.

        Args:
            longitude: Longitude coordinate (x).
            latitude: Latitude coordinate (y).
        """
        from django.contrib.gis.geos import Point

        self.location = Point(longitude, latitude, srid=4326)
        self.save(update_fields=["location", "updated_at"])

        logger.info(
            "Location updated | user: %s | lng: %f | lat: %f",
            self.email, longitude, latitude,
        )

def generate_otp():
    """Generates a secure, random 6-digit OTP."""
    return str(random.randint(100000, 999999))

def get_otp_expiration():
    """Returns the expiration timestamp for the OTP."""
    return timezone.now() + timedelta(minutes=OTP_EXPIRATION_MINUTES)

class UserVerificationToken(models.Model):
    """
    Stores the 6-digit OTP for user email verification.
    """
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='verification_token'
    )
    otp = models.CharField(
        max_length=6, 
        default=generate_otp, 
        unique=True,
        verbose_name="One Time Password"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(default=get_otp_expiration)

    class Meta:
        verbose_name = "Verification Token"
        verbose_name_plural = "Verification Tokens"

    def __str__(self):
        return f"OTP for {self.user.email}"

    def is_valid(self):
        """
        Checks if the OTP is still valid (not expired).
        """
        return timezone.now() <= self.expires_at
    

class PasswordResetToken(models.Model):
    """
    Stores the 6-digit OTP specifically for password reset requests.
    """
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='password_reset_token'
    )
    otp = models.CharField(
        max_length=6, 
        default=generate_otp, 
        unique=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(default=get_otp_expiration)

    class Meta:
        verbose_name = "Password Reset Token"
        verbose_name_plural = "Password Reset Tokens"

    def __str__(self):
        return f"Password Reset OTP for {self.user.email}"

    def is_valid(self):
        """
        Checks if the password reset OTP is still valid (not expired).
        """
        return timezone.now() <= self.expires_at