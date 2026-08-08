"""
Kern County scraper — county-wide calendar, board agendas, and business listings.

NOTE: kerncounty.com returns 403 for automated requests (Cloudflare/WAF).
This scraper will need manual configuration or an alternative data source.
For now, it degrades gracefully — logging the blockage instead of crashing.

Sources:
  - Events: kerncounty.com/Home/Components/Calendar/ (currently blocked)
  - Board agendas: kerncounty.com/government/board-of-supervisors (currently blocked)
"""
import re
import logging
from datetime import datetime, timedelta

from .base import BaseScraper

logger = logging.getLogger("scrapers.kerncounty")

CALENDAR_URL = "https://www.kerncounty.com/Home/Components/Calendar/"
BOS_URL = "https://www.kerncounty.com/government/board-of-supervisors"
BASE = "https://www.kerncounty.com"


class KernCountyScraper(BaseScraper):
    CITY_NAME = "Kern County"
    BASE_DOMAIN = "kerncounty.com"

    # Override: kerncounty.com blocks generic bot UAs
    MAX_RETRIES = 1

    def scrape(self) -> dict:
        stats = {"agendas": 0, "events": 0, "news": 0, "errors": 0}

        # Kern County blocks automated access (403). Try once and report.
        try:
            stats["events"] = self._scrape_events()
        except Exception as e:
            logger.warning("Kern County events blocked or unavailable: %s", e)

        try:
            stats["agendas"] = self._scrape_bos_agendas()
        except Exception as e:
            logger.warning("Kern County BOS blocked or unavailable: %s", e)

        if stats["events"] == 0 and stats["agendas"] == 0:
            logger.info(
                "Kern County skipped: site blocks automated requests (403). "
                "To enable: add kerncounty.com RSS feed URL or manually "
                "configure a session cookie."
            )

        return stats

    # ------------------------------------------------------------------
    # County Events Calendar
    # ------------------------------------------------------------------

    def _scrape_events(self) -> int:
        body = self.fetch_page(CALENDAR_URL)
        if not body:
            return 0

        saved = 0

        # Look for event entries with dates and descriptions
        # County sites often have structured event listings
        event_pattern = re.compile(
            r'<a[^>]*?href=["\']([^"\']*Event/\d+[^"\']*)["\']'
            r'[^>]*>([^<]+)</a>',
            re.IGNORECASE,
        )
        date_pattern = re.compile(
            r'(\w{3,9} \d{1,2},?\s*\d{4})',
        )

        for m in event_pattern.finditer(body):
            url = m.group(1)
            title = m.group(2).strip()

            if not url.startswith("http"):
                url = f"{BASE}{url}"

            if len(title) < 5:
                continue

            # Try to find associated date
            pos = body.find(url.split("/")[-1][:20])
            date_str = "TBD"
            if pos > 0:
                dm = date_pattern.search(body[max(0, pos - 500):pos + 500])
                if dm:
                    date_str = dm.group(1)

            try:
                start_date = datetime.strptime(date_str, "%B %d, %Y")
            except ValueError:
                start_date = datetime.now()

            item = self.save_event(
                title=f"[Kern County] {title}",
                description=f"Kern County event. Details: {url}",
                location="Kern County, CA",
                start_date=start_date,
                category="community",
            )
            if item:
                saved += 1

        logger.info("Kern County events: %d saved", saved)
        return saved

    # ------------------------------------------------------------------
    # Board of Supervisors Agendas
    # ------------------------------------------------------------------

    def _scrape_bos_agendas(self) -> int:
        body = self.fetch_page(BOS_URL)
        if not body:
            return 0

        saved = 0

        # Look for agenda PDF links
        pdf_pattern = re.compile(
            r'href=["\']([^"\']*\.pdf[^"\']*)["\']'
            r'[^>]*>([^<]*(?:agenda|meeting|board)[^<]*)</a>',
            re.IGNORECASE,
        )

        for m in pdf_pattern.finditer(body):
            pdf_url = m.group(1)
            link_text = m.group(2).strip()

            if not pdf_url.startswith("http"):
                pdf_url = f"{BASE}{pdf_url}"

            # Try to extract date from filename or nearby context
            date_match = re.search(r'(\d{4})[-_]?(\d{2})[-_]?(\d{2})', pdf_url)
            if date_match:
                year, month, day = date_match.groups()
                try:
                    meeting_date = datetime(int(year), int(month), int(day))
                except ValueError:
                    continue
            else:
                meeting_date = datetime.now()

            title = f"Kern County Board of Supervisors — {meeting_date:%B %d, %Y}"
            if link_text and len(link_text) > 5:
                title = link_text

            item = self.save_agenda(
                title=title,
                description="Kern County Board of Supervisors agenda. "
                            f"Source: kerncounty.com",
                meeting_date=meeting_date,
                pdf_url=pdf_url,
            )
            if item:
                saved += 1

        logger.info("Kern County BOS agendas: %d saved", saved)
        return saved
