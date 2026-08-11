"""Post a discussion topic to Seddit, optionally as the daily featured one.

Used by the daily "community topics" automation (Hermes cron) to give the
Seddit section fresh things to talk about each morning.

Usage:
  manage.py post_topic "Title" "Body text" [--category general] [--pin]
  manage.py post_topic --recent 10          # list recent topics (for dedupe)
"""
import datetime

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from community.models import DiscussionTopic

BOT_USERNAME = "CalCityDaily"


class Command(BaseCommand):
    help = "Create a Seddit discussion topic (bot author), with optional pin rotation."

    def add_arguments(self, parser):
        parser.add_argument("title", nargs="?", help="Topic title")
        parser.add_argument("body", nargs="?", help="Topic body text")
        parser.add_argument("--category", default="general",
                            choices=["general", "news", "events", "business", "help"])
        parser.add_argument("--pin", action="store_true",
                            help="Pin as the daily featured topic (unpins the previous one)")
        parser.add_argument("--recent", type=int, default=0,
                            help="Print the last N topic titles instead of posting")

    def handle(self, *args, **options):
        if options["recent"]:
            for t in DiscussionTopic.objects.order_by("-created_at")[: options["recent"]]:
                self.stdout.write(f"{t.created_at:%Y-%m-%d} | {t.category:9s} | {t.title}")
            return

        title = (options["title"] or "").strip()
        body = (options["body"] or "").strip()
        if not title or not body:
            self.stderr.write("ERROR: title and body are required")
            raise SystemExit(2)

        dup = DiscussionTopic.objects.filter(title__iexact=title).first()
        if dup:
            self.stdout.write(f"SKIP duplicate (id {dup.id}): {title}")
            return

        author, _ = User.objects.get_or_create(
            username=BOT_USERNAME,
            defaults={"email": "daily@calcity.app"},
        )

        if options["pin"]:
            DiscussionTopic.objects.filter(
                author=author, is_pinned=True
            ).update(is_pinned=False)
            self.stdout.write(f"rotated pin: unpinned previous {BOT_USERNAME} topics")

        t = DiscussionTopic.objects.create(
            title=title, body=body, author=author,
            category=options["category"], is_pinned=options["pin"],
        )
        self.stdout.write(
            f"POSTED id={t.id} [{'PINNED' if t.is_pinned else '      '}] "
            f"[{t.category}] {title}"
        )
        self.stdout.write(f"posted_at={datetime.datetime.now():%Y-%m-%d %H:%M}")
