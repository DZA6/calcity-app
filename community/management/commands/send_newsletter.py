"""\
Email the CalCity daily digest to newsletter subscribers.

Builds a plain-text digest of the latest approved news + upcoming events and
emails it to every active NewsletterSubscriber. Safe no-op when there are no
subscribers or SMTP is not configured (fail_silently=True).

Email is sent via Django's SMTP backend, configured through these env vars:
    DJANGO_EMAIL_HOST / PORT / USE_TLS / HOST_USER / HOST_PASSWORD
    DJANGO_FROM_EMAIL
Set them in the PythonAnywhere Web app's environment to enable real delivery.

Usage:
    python manage.py send_newsletter
"""
from django.conf import settings
from django.core.mail import send_mail
from django.core.management.base import BaseCommand
from django.utils import timezone

from community.models import Event, NewsletterSubscriber, NewsItem


class Command(BaseCommand):
    help = "Email the daily digest to newsletter subscribers"

    def handle(self, **options):
        subscribers = NewsletterSubscriber.objects.filter(is_active=True)
        if not subscribers.exists():
            self.stdout.write("No active subscribers.")
            return

        news = NewsItem.objects.filter(is_approved=True).order_by("-created_at")[:10]
        events = (
            Event.objects.filter(is_approved=True, start_date__gte=timezone.now())
            .order_by("start_date")[:10]
        )

        if not news and not events:
            self.stdout.write("No content to send.")
            return

        lines = ["Here's the latest from California City:\n"]
        if news:
            lines.append("NEWS")
            for n in news:
                lines.append(f"\u2022 {n.title}")
            lines.append("")
        if events:
            lines.append("UPCOMING EVENTS")
            for e in events:
                lines.append(f"\u2022 {e.start_date:%a %b %d} \u2014 {e.title}")
            lines.append("")
        lines.append("\u2014 CalCity")
        body = "\n".join(lines)

        sent = 0
        for sub in subscribers:
            try:
                count = send_mail(
                    "CalCity Daily Digest",
                    body,
                    settings.DEFAULT_FROM_EMAIL,
                    [sub.email],
                    fail_silently=True,
                )
                if count:
                    sent += 1
            except Exception as e:  # pragma: no cover - SMTP misconfig edge case
                self.stderr.write(f"Failed for {sub.email}: {e}")

        self.stdout.write(self.style.SUCCESS(f"Sent digest to {sent} subscriber(s)."))
