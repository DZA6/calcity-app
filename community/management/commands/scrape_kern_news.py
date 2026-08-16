"""
Django management command: scrape Kern County & Antelope Valley news.

Fetches Google News RSS feeds for the region, deduplicates against
existing articles, and creates NewsItem entries. Safe to run repeatedly
— each run only adds new, unique stories.

Articles that mention California City are auto-approved (visible in the
app); all other regional news is saved unapproved so it stays hidden
until a staff member turns it on in the dashboard.

Usage:
    python manage.py scrape_kern_news              # default: 3 feeds, 20 articles each
    python manage.py scrape_kern_news --max 50     # 50 articles per feed
    python manage.py scrape_kern_news --dry-run    # fetch but don't save

Scheduled via Hermes cron job every 2 hours.
"""
import hashlib
import logging
import re
import time
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from difflib import SequenceMatcher
from urllib.parse import urlparse

from django.core.management.base import BaseCommand
from django.utils import timezone

from community.models import NewsItem
from community.scrapers.base import is_california_city

logger = logging.getLogger("scrapers")

# ── Configuration ──────────────────────────────────────────────────────────

FEEDS = [
    {
        "name": "Kern County",
        "url": "https://news.google.com/rss/search?q=kern+county+california&hl=en-US&gl=US&ceid=US:en",
        "category": "general",
    },
    {
        "name": "Antelope Valley",
        "url": "https://news.google.com/rss/search?q=antelope+valley+california&hl=en-US&gl=US&ceid=US:en",
        "category": "general",
    },
    {
        "name": "California City",
        "url": "https://news.google.com/rss/search?q=california+city+ca&hl=en-US&gl=US&ceid=US:en",
        "category": "general",
    },
    {
        "name": "Bakersfield",
        "url": "https://news.google.com/rss/search?q=bakersfield+california+news&hl=en-US&gl=US&ceid=US:en",
        "category": "general",
    },
    {
        "name": "Lancaster-Palmdale",
        "url": "https://news.google.com/rss/search?q=lancaster+palmdale+california+news&hl=en-US&gl=US&ceid=US:en",
        "category": "general",
    },
    {
        "name": "Mojave",
        "url": "https://news.google.com/rss/search?q=mojave+california+news&hl=en-US&gl=US&ceid=US:en",
        "category": "general",
    },
    {
        "name": "Food Giveaways",
        "url": "https://news.google.com/rss/search?q=kern+county+food+giveaway+food+bank&hl=en-US&gl=US&ceid=US:en",
        "category": "community",
    },
    {
        "name": "Kids & Family",
        "url": "https://news.google.com/rss/search?q=bakersfield+kids+events+family&hl=en-US&gl=US&ceid=US:en",
        "category": "community",
    },
    {
        "name": "Church Outreach",
        "url": "https://news.google.com/rss/search?q=lancaster+palmdale+church+food+assistance&hl=en-US&gl=US&ceid=US:en",
        "category": "church",
    },
    {
        "name": "Community Programs",
        "url": "https://news.google.com/rss/search?q=antelope+valley+community+events+programs&hl=en-US&gl=US&ceid=US:en",
        "category": "community",
    },
    {
        "name": "School Giveaways",
        "url": "https://news.google.com/rss/search?q=kern+county+back+to+school+giveaway+event&hl=en-US&gl=US&ceid=US:en",
        "category": "community",
    },
    {
        "name": "CalCity Programs",
        "url": "https://news.google.com/rss/search?q=mojave+california+city+community+programs&hl=en-US&gl=US&ceid=US:en",
        "category": "community",
    },
]

# Category keywords → map articles to the right section
CATEGORY_KEYWORDS = {
    "law_enforcement": [
        "police", "sheriff", "crime", "arrest", "jail", "prison",
        "fire department", "firefighter", "ems", "emergency",
        "chp", "highway patrol", "detective", "deputy",
    ],
    "city_works": [
        "city council", "city hall", "public works", "water",
        "road", "construction", "infrastructure", "zoning",
        "permit", "budget", "tax", "ordinance", "settlement",
    ],
    "education": [
        "school", "student", "teacher", "district", "college",
        "university", "education", "classroom", "principal",
    ],
    "health": [
        "hospital", "health", "clinic", "covid", "virus",
        "medical", "doctor", "nurse", "patient", "wellness",
    ],
    "business": [
        "business", "economy", "job", "employment", "store",
        "restaurant", "shop", "downtown", "commercial",
    ],
    "traffic": [
        "traffic", "freeway", "highway", "i-5", "i5", "sr-14",
        "sr14", "closure", "detour", "crash", "accident",
        "roadwork", "caltrans",
    ],
    "community": [
        "festival", "event", "community", "parade", "fair",
        "concert", "market", "volunteer", "fundraiser",
    ],
    "recreation": [
        "park", "trail", "hike", "recreation", "sports",
        "baseball", "football", "basketball", "soccer",
    ],
    "church": [
        "church", "faith", "pastor", "ministry", "worship",
        "prayer", "religious", "spiritual",
    ],
}

# Title similarity threshold for dedup (0-1)
DUP_THRESHOLD = 0.75


class Command(BaseCommand):
    help = "Scrape Kern County & Antelope Valley news from Google News RSS"

    def add_arguments(self, parser):
        parser.add_argument("--max", type=int, default=20,
                            help="Max articles per feed (default 20)")
        parser.add_argument("--dry-run", action="store_true",
                            help="Fetch but don't save to DB")

    def handle(self, **options):
        max_per_feed = options["max"]
        dry_run = options["dry_run"]

        total_fetched = 0
        total_created = 0
        total_approved = 0
        total_dupes = 0

        for feed in FEEDS:
            self.stdout.write(f"Fetching {feed['name']}...")
            articles = self._fetch_feed(feed["url"], max_per_feed)
            total_fetched += len(articles)
            self.stdout.write(f"  Got {len(articles)} articles")

            for art in articles:
                # Detect category
                cat = self._detect_category(art["title"], art.get("source", ""))

                # Check duplicate
                if self._is_duplicate(art["title"]):
                    total_dupes += 1
                    continue

                # California City articles are auto-approved; all other
                # regional news is saved unapproved (hidden) for review.
                is_approved = is_california_city(
                    f"{art['title']} {art.get('source', '')} {art.get('snippet', '')}"
                )

                if not dry_run:
                    NewsItem.objects.create(
                        title=art["title"][:200],
                        content=art.get("snippet", ""),
                        source_url=art.get("article_url", art.get("google_url", "")),
                        category=cat,
                        is_approved=is_approved,
                    )
                total_created += 1
                if is_approved:
                    total_approved += 1

            time.sleep(1)  # Be polite between feeds

        self.stdout.write(
            self.style.SUCCESS(
                f"Done: {total_fetched} fetched, "
                f"{total_created} new ({total_approved} California City, "
                f"{total_created - total_approved} pending review), "
                f"{total_dupes} duplicates "
                f"{'(dry run)' if dry_run else ''}"
            )
        )

    # ── Feed fetching ──────────────────────────────────────────────────

    def _fetch_feed(self, url, max_items):
        """Fetch and parse a Google News RSS feed."""
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "Mozilla/5.0 (compatible; CalCityBot/1.0)"},
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = resp.read().decode("utf-8")
        except Exception as e:
            self.stderr.write(f"  Error fetching {url}: {e}")
            return []

        try:
            root = ET.fromstring(data)
        except ET.ParseError as e:
            self.stderr.write(f"  XML parse error: {e}")
            return []

        articles = []
        for item in root.findall(".//item")[:max_items]:
            title_el = item.find("title")
            link_el = item.find("link")
            desc_el = item.find("description")
            source_el = item.find("source")

            title = title_el.text.strip() if title_el is not None and title_el.text else ""
            google_url = link_el.text.strip() if link_el is not None and link_el.text else ""
            snippet = desc_el.text.strip() if desc_el is not None and desc_el.text else ""
            source = source_el.text.strip() if source_el is not None and source_el.text else ""

            if not title:
                continue

            # Try to extract real article URL from Google News tracking URL
            article_url = self._extract_real_url(google_url)

            # Clean snippet (remove HTML, truncate)
            snippet = re.sub(r"<[^>]+>", "", snippet)
            snippet = re.sub(r"&amp;", "&", snippet)
            snippet = re.sub(r"&lt;", "<", snippet)
            snippet = re.sub(r"&gt;", ">", snippet)

            # Build display snippet with attribution
            if source:
                display = f"Source: {source}\n\n{snippet}" if snippet else f"Source: {source}"
            else:
                display = snippet

            articles.append({
                "title": title,
                "google_url": google_url,
                "article_url": article_url,
                "snippet": display[:2000],
                "source": source,
            })

        return articles

    def _extract_real_url(self, google_url):
        """Try to extract the real article URL from a Google News tracking URL."""
        # Google News URLs embed the real URL in the path after certain patterns
        match = re.search(r"articles/[A-Za-z0-9_]+[?&]url=([^&]+)", google_url)
        if match:
            from urllib.parse import unquote
            return unquote(match.group(1))
        return google_url  # Keep as-is if we can't extract

    # ── Deduplication ──────────────────────────────────────────────────

    def _is_duplicate(self, title):
        """Check if a title is too similar to any existing article."""
        existing = NewsItem.objects.values_list("title", flat=True)
        for ex_title in existing:
            ratio = SequenceMatcher(None, title.lower(), ex_title.lower()).ratio()
            if ratio >= DUP_THRESHOLD:
                return True
        return False

    # ── Category detection ─────────────────────────────────────────────

    def _detect_category(self, title, source):
        """Map an article title to a category based on keywords."""
        text = (title + " " + source).lower()
        for cat, keywords in CATEGORY_KEYWORDS.items():
            for kw in keywords:
                if kw in text:
                    return cat
        return "general"
