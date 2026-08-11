"""User authentication models — email verification + password reset tokens."""
import secrets
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone


class EmailVerificationToken(models.Model):
    """One-time token for email verification during registration."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="email_verification"
    )
    token = models.CharField(max_length=64, unique=True, default=secrets.token_urlsafe)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)

    def is_expired(self):
        """Tokens expire after 24 hours."""
        return timezone.now() > self.created_at + timedelta(hours=24)

    def __str__(self):
        return f"Verify {self.user.email}"

    class Meta:
        ordering = ["-created_at"]


class PasswordResetToken(models.Model):
    """One-time 6-digit code for password reset, valid 30 minutes.

    Created by POST /api/auth/password-reset/ and consumed by
    POST /api/auth/password-reset/confirm/. Codes are numeric so users
    can type them straight into the mobile app.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="password_reset_tokens",
    )
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)

    def is_expired(self):
        """Reset codes expire after 30 minutes."""
        return timezone.now() > self.created_at + timedelta(minutes=30)

    def __str__(self):
        return f"Reset {self.user.email}"

    class Meta:
        ordering = ["-created_at"]
