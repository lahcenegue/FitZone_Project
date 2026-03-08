"""
Email utilities for the providers app.

All outgoing emails for provider registration go through this module.
Each function is pure — it takes explicit arguments, has no side effects
beyond sending the email, and returns True/False.

When a real email service (SendGrid, Mailgun, etc.) is integrated,
only this file changes. Services and views are untouched.
"""

import logging

from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.translation import gettext_lazy as _

logger = logging.getLogger(__name__)


def send_verification_email(
    *,
    recipient_email: str,
    recipient_name: str,
    business_name: str,
    verification_token: str,
    frontend_base_url: str,
) -> bool:
    """
    Send the email verification link to a newly registered provider.

    Returns True on success, False on failure (failure is logged, not raised).
    """
    verification_url = (
        f"{frontend_base_url.rstrip('/')}"
        f"/portal/verify-email/?token={verification_token}"
    )

    context = {
        "recipient_name":   recipient_name,
        "business_name":    business_name,
        "verification_url": verification_url,
        "expiry_hours":     24,
        "support_email":    getattr(settings, "SUPPORT_EMAIL", "support@fitzone.sa"),
    }

    try:
        text_body = render_to_string(
            "provider_portal/emails/verify_email.txt", context
        )
        html_body = render_to_string(
            "provider_portal/emails/verify_email.html", context
        )
        send_mail(
            subject=str(_("Verify your email — FitZone Provider Portal")),
            message=text_body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[recipient_email],
            html_message=html_body,
            fail_silently=False,
        )
        logger.info(
            "Verification email sent | recipient: %s | business: %s",
            recipient_email, business_name,
        )
        return True
    except Exception as exc:
        logger.error(
            "Verification email failed | recipient: %s | error: %s",
            recipient_email, exc,
        )
        return False


def send_approval_email(
    *,
    recipient_email: str,
    recipient_name: str,
    business_name: str,
    frontend_base_url: str,
) -> bool:
    """
    Notify a provider that their application has been approved.

    Returns True on success, False on failure.
    """
    login_url = f"{frontend_base_url.rstrip('/')}/portal/login/"

    context = {
        "recipient_name": recipient_name,
        "business_name":  business_name,
        "login_url":      login_url,
        "support_email":  getattr(settings, "SUPPORT_EMAIL", "support@fitzone.sa"),
    }

    try:
        text_body = render_to_string("provider_portal/emails/approval.txt",  context)
        html_body = render_to_string("provider_portal/emails/approval.html", context)
        send_mail(
            subject=str(_("Your FitZone provider account has been approved")),
            message=text_body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[recipient_email],
            html_message=html_body,
            fail_silently=False,
        )
        logger.info(
            "Approval email sent | recipient: %s | business: %s",
            recipient_email, business_name,
        )
        return True
    except Exception as exc:
        logger.error(
            "Approval email failed | recipient: %s | error: %s",
            recipient_email, exc,
        )
        return False


def send_rejection_email(
    *,
    recipient_email: str,
    recipient_name: str,
    business_name: str,
    rejection_note: str,
    frontend_base_url: str,
) -> bool:
    """
    Notify a provider that their application has been rejected.

    Returns True on success, False on failure.
    """
    context = {
        "recipient_name": recipient_name,
        "business_name":  business_name,
        "rejection_note": rejection_note,
        "support_email":  getattr(settings, "SUPPORT_EMAIL", "support@fitzone.sa"),
    }

    try:
        text_body = render_to_string("provider_portal/emails/rejection.txt",  context)
        html_body = render_to_string("provider_portal/emails/rejection.html", context)
        send_mail(
            subject=str(_("Update on your FitZone provider application")),
            message=text_body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[recipient_email],
            html_message=html_body,
            fail_silently=False,
        )
        logger.info(
            "Rejection email sent | recipient: %s | business: %s",
            recipient_email, business_name,
        )
        return True
    except Exception as exc:
        logger.error(
            "Rejection email failed | recipient: %s | error: %s",
            recipient_email, exc,
        )
        return False