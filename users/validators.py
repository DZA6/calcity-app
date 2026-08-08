"""Password strength validators for user registration."""
import re

from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _


class MinimumLengthValidator:
    """Require at least 10 characters."""

    def __init__(self, min_length=10):
        self.min_length = min_length

    def validate(self, password, user=None):
        if len(password) < self.min_length:
            raise ValidationError(
                _(f"Password must be at least {self.min_length} characters long."),
                code="password_too_short",
            )

    def get_help_text(self):
        return _(f"Your password must contain at least {self.min_length} characters.")


class ComplexityValidator:
    """Require mix of uppercase, lowercase, digit, and special character."""

    def validate(self, password, user=None):
        checks = [
            (r"[A-Z]", "one uppercase letter"),
            (r"[a-z]", "one lowercase letter"),
            (r"[0-9]", "one digit"),
            (r"[!@#$%^&*()_+\-=\[\]{};':\"\\|,.<>/?`~]", "one special character"),
        ]
        missing = []
        for pattern, name in checks:
            if not re.search(pattern, password):
                missing.append(name)

        if missing:
            raise ValidationError(
                _(f"Password must include at least {', '.join(missing)}."),
                code="password_not_complex",
            )

    def get_help_text(self):
        return _(
            "Your password must include at least one uppercase letter, "
            "one lowercase letter, one digit, and one special character."
        )


class CommonPasswordValidator:
    """Reject commonly used passwords."""

    COMMON = {
        "password", "password123", "12345678", "123456789", "qwerty123",
        "abc123456", "password1", "admin123", "letmein123", "welcome1",
        "monkey123", "dragon123", "master123", "football1", "baseball1",
        "iloveyou1", "trustno1", "sunshine1", "princess1", "qwertyuiop",
        "calcity123", "california1", "antelope1", "kerncounty1",
    }

    def validate(self, password, user=None):
        if password.lower() in self.COMMON:
            raise ValidationError(
                _("This password is too common. Please choose a stronger one."),
                code="password_too_common",
            )

    def get_help_text(self):
        return _("Your password must not be a commonly used password.")
