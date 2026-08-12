"""Deactivate stale alerts so the Alerts feed stays current.

Usage:
    python manage.py expire_stale_alerts            # deactivate alerts older than 14 days
    python manage.py expire_stale_alerts --days 7   # custom window

Schedule daily on PythonAnywhere (Tasks tab).
"""
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from community.models import Alert


class Command(BaseCommand):
    help = "Deactivate stale alerts (default: older than 14 days)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--days", type=int, default=14,
            help="Deactivate alerts older than this many days",
        )

    def handle(self, *args, **options):
        cutoff = timezone.now() - timedelta(days=options["days"])
        updated = Alert.objects.filter(is_active=True, created_at__lt=cutoff).update(is_active=False)
        self.stdout.write(self.style.SUCCESS(
            f"Deactivated {updated} stale alert(s) older than {options['days']} days"
        ))
