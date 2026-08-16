"""\
Push a digest of new California City news + upcoming events to FCM topics.

The Flutter app subscribes to the "news" and "events" topics; this command
publishes a single summary notification to each (only when there is something
new). Safe no-op when Firebase is not configured.

Schedule: daily (see OPS_RUNBOOK / PythonAnywhere Tasks).

Usage:
    python manage.py push_digest
"""
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from community.firebase_messaging import send_topic_message
from community.models import Event, NewsItem


class Command(BaseCommand):
    help = "Push a digest of new CalCity news and upcoming events to FCM topics"

    def handle(self, **options):
        since = timezone.now() - timedelta(hours=24)
        news = NewsItem.objects.filter(
            is_approved=True, created_at__gte=since
        ).count()
        upcoming = Event.objects.filter(
            is_approved=True, start_date__gte=timezone.now()
        ).count()

        results = []

        if news:
            ok, msg = send_topic_message(
                title=f"{news} new CalCity update{'s' if news != 1 else ''}",
                body="Tap to see the latest California City news.",
                topic="news",
                data={"type": "news"},
            )
            results.append(("news", ok, msg))

        if upcoming:
            ok, msg = send_topic_message(
                title=f"{upcoming} upcoming event{'s' if upcoming != 1 else ''}",
                body="Tap to see what's happening in California City.",
                topic="events",
                data={"type": "events"},
            )
            results.append(("events", ok, msg))

        if not results:
            self.stdout.write("Nothing to push (no new news or upcoming events).")
            return

        for topic, ok, msg in results:
            self.stdout.write(self.style.SUCCESS(f"[{topic}] {'OK' if ok else 'FAIL'} — {msg}"))
