"""
Initial migration for the custom User model.
Generated manually to ensure correctness before first migrate run.
"""

import django.contrib.gis.db.models.fields
import django.contrib.auth.models
import django.utils.timezone
from django.db import migrations, models


class Migration(migrations.Migration):
    """Create the custom User table."""

    initial = True

    dependencies = [
        ("auth", "0012_alter_user_first_name_max_length"),
    ]

    operations = [
        migrations.CreateModel(
            name="User",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("password", models.CharField(max_length=128, verbose_name="password")),
                ("last_login", models.DateTimeField(blank=True, null=True, verbose_name="last login")),
                ("is_superuser", models.BooleanField(default=False, verbose_name="superuser status")),
                ("email", models.EmailField(db_index=True, max_length=254, unique=True, verbose_name="Email address")),
                ("full_name", models.CharField(max_length=255, verbose_name="Full name")),
                ("phone_number", models.CharField(blank=True, db_index=True, default="", max_length=20, verbose_name="Phone number")),
                ("phone_verified", models.BooleanField(default=False, verbose_name="Phone verified")),
                ("avatar", models.ImageField(blank=True, null=True, upload_to="avatars/", verbose_name="Avatar")),
                ("date_of_birth", models.DateField(blank=True, null=True, verbose_name="Date of birth")),
                ("gender", models.CharField(choices=[("male", "Male"), ("female", "Female"), ("unspecified", "Unspecified")], default="unspecified", max_length=20, verbose_name="Gender")),
                ("location", django.contrib.gis.db.models.fields.PointField(blank=True, geography=True, null=True, srid=4326, verbose_name="Location")),
                ("address", models.CharField(blank=True, default="", max_length=512, verbose_name="Address")),
                ("city", models.CharField(blank=True, db_index=True, default="", max_length=100, verbose_name="City")),
                ("role", models.CharField(choices=[("customer", "Customer"), ("provider", "Provider"), ("admin", "Admin")], db_index=True, default="customer", max_length=20, verbose_name="Role")),
                ("is_active", models.BooleanField(default=True, verbose_name="Active")),
                ("is_staff", models.BooleanField(default=False, verbose_name="Staff")),
                ("is_verified", models.BooleanField(default=False, verbose_name="Verified")),
                ("is_premium", models.BooleanField(default=False, verbose_name="Premium")),
                ("premium_since", models.DateTimeField(blank=True, null=True, verbose_name="Premium since")),
                ("points_balance", models.PositiveIntegerField(default=0, verbose_name="Points balance")),
                ("points_total", models.PositiveIntegerField(default=0, verbose_name="Total points earned")),
                ("date_joined", models.DateTimeField(auto_now_add=True, verbose_name="Date joined")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Updated at")),
                ("groups", models.ManyToManyField(blank=True, related_name="user_set", related_query_name="user", to="auth.group", verbose_name="groups")),
                ("user_permissions", models.ManyToManyField(blank=True, related_name="user_set", related_query_name="user", to="auth.permission", verbose_name="user permissions")),
            ],
            options={
                "verbose_name": "User",
                "verbose_name_plural": "Users",
                "ordering": ["-date_joined"],
            },
            managers=[
                ("objects", django.contrib.auth.models.BaseUserManager()),
            ],
        ),
    ]