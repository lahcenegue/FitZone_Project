"""
Migration 0002 — Add registration review fields to Provider.

Adds to providers_provider:
    - business_phone     VARCHAR(20) NOT NULL DEFAULT ''
    - email_verified     BOOLEAN NOT NULL DEFAULT False
    - verified_at        TIMESTAMP NULL
    - reviewed_by_id     FK → AUTH_USER_MODEL NULL
    - reviewed_at        TIMESTAMP NULL
    - rejection_note     TEXT NOT NULL DEFAULT ''

Adds new table: providers_emailverificationtoken

Updates status choices to include 'rejected'.
NOTE: Django choices are Python-level validation only — no ALTER TABLE needed
for the new 'rejected' value. The existing VARCHAR(20) column already accepts it.

Adds two composite indexes on Provider for efficient admin queries.
"""

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("providers", "0001_initial"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [

        # ── New fields on Provider ──────────────────────────────────────────

        migrations.AddField(
            model_name="provider",
            name="business_phone",
            field=models.CharField(
                blank=True,
                default="",
                max_length=20,
                verbose_name="Business phone",
            ),
        ),
        migrations.AddField(
            model_name="provider",
            name="email_verified",
            field=models.BooleanField(
                default=False,
                verbose_name="Email verified",
            ),
        ),
        migrations.AddField(
            model_name="provider",
            name="verified_at",
            field=models.DateTimeField(
                blank=True,
                null=True,
                verbose_name="Verified at",
            ),
        ),
        migrations.AddField(
            model_name="provider",
            name="reviewed_by",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="reviewed_providers",
                to=settings.AUTH_USER_MODEL,
                verbose_name="Reviewed by",
            ),
        ),
        migrations.AddField(
            model_name="provider",
            name="reviewed_at",
            field=models.DateTimeField(
                blank=True,
                null=True,
                verbose_name="Reviewed at",
            ),
        ),
        migrations.AddField(
            model_name="provider",
            name="rejection_note",
            field=models.TextField(
                blank=True,
                default="",
                help_text="Shown to the provider in the rejection email.",
                max_length=1000,
                verbose_name="Rejection note",
            ),
        ),

        # ── Update status choices (Python-level only — no ALTER TABLE) ──────
        migrations.AlterField(
            model_name="provider",
            name="status",
            field=models.CharField(
                choices=[
                    ("pending",   "Pending Review"),
                    ("approved",  "Approved"),
                    ("active",    "Active"),
                    ("suspended", "Suspended"),
                    ("rejected",  "Rejected"),
                ],
                db_index=True,
                default="pending",
                max_length=20,
                verbose_name="Status",
            ),
        ),

        # ── Composite indexes on Provider ────────────────────────────────────
        migrations.AddIndex(
            model_name="provider",
            index=models.Index(
                fields=["status", "provider_type"],
                name="prov_status_type_idx",
            ),
        ),
        migrations.AddIndex(
            model_name="provider",
            index=models.Index(
                fields=["status", "created_at"],
                name="prov_status_created_idx",
            ),
        ),

        # ── New table: EmailVerificationToken ────────────────────────────────
        migrations.CreateModel(
            name="EmailVerificationToken",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                (
                    "token",
                    models.CharField(
                        db_index=True,
                        max_length=64,
                        unique=True,
                        verbose_name="Token",
                    ),
                ),
                (
                    "expires_at",
                    models.DateTimeField(verbose_name="Expires at"),
                ),
                (
                    "is_used",
                    models.BooleanField(default=False, verbose_name="Used"),
                ),
                (
                    "created_at",
                    models.DateTimeField(
                        auto_now_add=True,
                        verbose_name="Created at",
                    ),
                ),
                (
                    "provider",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="email_tokens",
                        to="providers.provider",
                        verbose_name="Provider",
                    ),
                ),
            ],
            options={
                "verbose_name": "Email verification token",
                "verbose_name_plural": "Email verification tokens",
            },
        ),
        migrations.AddIndex(
            model_name="emailverificationtoken",
            index=models.Index(
                fields=["token", "is_used"],
                name="evt_token_used_idx",
            ),
        ),
    ]