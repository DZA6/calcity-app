"""
Base scraper class for city data ingestion.
Provides HTTP fetching, deduplication, and model-saving primitives.
"""
import hashlib
import logging
import re
import time
import urllib.request
import urllib.error
from datetime import datetime, timedelta
from abc import ABC, abstractmethod
from typing import Optional

from django.utils import timezone
from django.core.files.base import ContentFile
from django.db import IntegrityError

from community.models import NewsItem, Event, Business, CouncilAgenda, Alert

logger = logging.getLogger("scrapers")


# ── California City detection ────────────────────────────────────────────
# Articles specifically about California City, CA are auto-approved; all other
# scraped news is stored unapproved (hidden) until a staff member flips it on.
CALCITY_PATTERNS = [
    re.compile(r"\bcalifornia city\b", re.IGNORECASE),
    re.compile(r"\bcal city\b", re.IGNORECASE),
    re.compile(r"\bcalcity\b", re.IGNORECASE),
    re.compile(r"\b93505\b"),
]


def is_california_city(text: str) -> bool:
    """Return True if `text` is specifically about California City, CA."""
    t = text or ""
    return any(p.search(t) for p in CALCITY_PATTERNS)


class BaseScraper(ABC):
    """Common HTTP + dedup infrastructure. Subclass per city."""

    # Override in subclasses
    CITY_NAME: str = ""
    BASE_DOMAIN: str = ""

    # Default headers (polite scraping)
    HEADERS = {
        "User-Agent": (
            "Mozilla/5.0 (compatible; CalCityBot/1.0; "
            "+https://calcityapp.com)"
        ),
        "Accept": "text/html,application/xhtml+xml",
    }
    REQUEST_DELAY = 2.0  # seconds between requests
    MAX_RETRIES = 3
    TIMEOUT = 20
    MAX_AGE_DAYS = 90  # only import items newer than this

    _last_request_time: float = 0.0

    # ------------------------------------------------------------------
    # HTTP helpers
    # ------------------------------------------------------------------

    def _respect_delay(self):
        elapsed = time.monotonic() - self._last_request_time
        if elapsed < self.REQUEST_DELAY:
            time.sleep(self.REQUEST_DELAY - elapsed)
        self._last_request_time = time.monotonic()

    def fetch_page(self, url: str) -> Optional[str]:
        """Fetch a URL as text. Returns None on failure after retries."""
        for attempt in range(1, self.MAX_RETRIES + 1):
            self._respect_delay()
            try:
                req = urllib.request.Request(url, headers=self.HEADERS)
                with urllib.request.urlopen(req, timeout=self.TIMEOUT) as resp:
                    body = resp.read().decode("utf-8", errors="replace")
                    logger.debug("Fetched %s (%d chars)", url, len(body))
                    return body
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    logger.warning("404: %s", url)
                    return None
                logger.warning("Attempt %d/%d HTTP %d: %s", attempt, self.MAX_RETRIES, e.code, url)
            except Exception as e:
                logger.warning("Attempt %d/%d %s: %s", attempt, self.MAX_RETRIES, type(e).__name__, e)
        logger.error("Failed after %d retries: %s", self.MAX_RETRIES, url)
        return None

    def fetch_json(self, url: str) -> Optional[dict]:
        """Fetch JSON from a URL."""
        body = self.fetch_page(url)
        if body is None:
            return None
        import json
        try:
            return json.loads(body)
        except json.JSONDecodeError:
            return None

    # ------------------------------------------------------------------
    # Deduplication
    # ------------------------------------------------------------------

    @staticmethod
    def content_hash(text: str) -> str:
        """SHA-256 of normalized text, used for dedup."""
        normalized = " ".join(text.lower().split())
        return hashlib.sha256(normalized.encode()).hexdigest()[:16]

    # Titles that should never be saved (HTML artifacts, generic labels)
    JUNK_TITLES = {
        "more details", "previous versions", "minutes", "agenda",
        "download", "view file", "click here", "read more", "details",
        "video", "recording", "archive",
    }

    def _is_junk_title(self, title: str) -> bool:
        """Filter out generic HTML artifact titles."""
        t = title.strip().lower()
        return t in self.JUNK_TITLES or len(t) < 5

    def is_duplicate(self, model_class, title: str, source_url: str = "") -> bool:
        """
        Check if an item with the same title/name already exists.
        Uses source_url as a tiebreaker for events/agendas.
        """
        title = title.strip()
        # Business model uses 'name' field, others use 'title'
        field = "name" if model_class.__name__ == "Business" else "title"
        qs = model_class.objects.filter(**{f"{field}__iexact": title})
        if source_url and hasattr(model_class, "source_url"):
            qs = qs.filter(source_url__iexact=source_url.strip())
        return qs.exists()

    # ------------------------------------------------------------------
    # Save helpers
    # ------------------------------------------------------------------

    def save_news(self, title: str, content: str, category: str = "general",
                   source_url: str = "", is_approved: Optional[bool] = None) -> Optional[NewsItem]:
        title = title.strip()
        if self._is_junk_title(title) or self.is_duplicate(NewsItem, title, source_url):
            logger.debug("Duplicate news: %s", title[:80])
            return None
        # Default: auto-approve only California City articles; everything else
        # is saved unapproved (hidden from the app) for staff review.
        if is_approved is None:
            is_approved = is_california_city(f"{title} {content}")
        try:
            item = NewsItem.objects.create(
                title=title[:200],
                content=content,
                category=category,
                source_url=source_url[:500],
                is_approved=is_approved,
            )
            logger.info("News saved: %s [%s]", title[:80], self.CITY_NAME)
            return item
        except IntegrityError:
            return None

    def save_event(self, title: str, description: str, location: str,
                    start_date: datetime, end_date: datetime = None,
                    category: str = "community", is_approved: bool = True) -> Optional[Event]:
        title = title.strip()
        if self._is_junk_title(title) or self.is_duplicate(Event, title):
            return None
        try:
            tz_aware = timezone.make_aware(start_date) if timezone.is_naive(start_date) else start_date
            end_tz = None
            if end_date:
                end_tz = timezone.make_aware(end_date) if timezone.is_naive(end_date) else end_date
            item = Event.objects.create(
                title=title[:200],
                description=description,
                location=location[:300],
                start_date=tz_aware,
                end_date=end_tz,
                category=category,
                is_approved=is_approved,
            )
            logger.info("Event saved: %s [%s]", title[:80], self.CITY_NAME)
            return item
        except IntegrityError:
            return None

    def save_agenda(self, title: str, description: str, meeting_date: datetime,
                     pdf_url: str = "", is_approved: bool = True) -> Optional[CouncilAgenda]:
        title = title.strip()
        if self._is_junk_title(title) or self.is_duplicate(CouncilAgenda, title, pdf_url):
            return None
        try:
            tz_aware = timezone.make_aware(meeting_date) if timezone.is_naive(meeting_date) else meeting_date
            item = CouncilAgenda.objects.create(
                title=title[:200],
                description=description,
                meeting_date=tz_aware,
                pdf_url=pdf_url[:500] if pdf_url else "",
                is_approved=is_approved,
            )
            logger.info("Agenda saved: %s [%s]", title[:80], self.CITY_NAME)
            return item
        except IntegrityError:
            return None

    def save_business(self, name: str, description: str, category: str = "local_shop",
                       website: str = "", address: str = "", phone: str = "",
                       is_approved: bool = True) -> Optional[Business]:
        name = name.strip()
        if self._is_junk_title(name) or self.is_duplicate(Business, name):
            return None
        try:
            item = Business.objects.create(
                name=name[:200],
                description=description,
                category=category,
                website=website[:200] if website else "",
                address=address[:300],
                contact_phone=phone[:20],
                is_approved=is_approved,
            )
            logger.info("Business saved: %s [%s]", name[:80], self.CITY_NAME)
            return item
        except IntegrityError:
            return None

    # ------------------------------------------------------------------
    # Entry point
    # ------------------------------------------------------------------

    @abstractmethod
    def scrape(self) -> dict:
        """
        Run the scraper. Returns a dict like:
            {"agendas": 5, "events": 3, "news": 2, "errors": 0}
        """
        ...
