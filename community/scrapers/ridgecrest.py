"""
Ridgecrest, CA scraper — CivicPlus platform.
Sources:
  - Council agendas: /AgendaCenter/City-Council-2
  - Events: /Calendar.aspx
  - News/alerts: /CivicAlerts.aspx
"""
import re
import logging
from datetime import datetime

from .base import BaseScraper

logger = logging.getLogger("scrapers.ridgecrest")

AGENDA_URL = "https://www.ridgecrest-ca.gov/AgendaCenter/City-Council-2"
CALENDAR_URL = "https://www.ridgecrest-ca.gov/Calendar.aspx"
ALERTS_URL = "https://www.ridgecrest-ca.gov/CivicAlerts.aspx"
BASE = "https://www.ridgecrest-ca.gov"


class RidgecrestScraper(BaseScraper):
    CITY_NAME = "Ridgecrest"
    BASE_DOMAIN = "ridgecrest-ca.gov"

    def scrape(self) -> dict:
        stats = {"agendas": 0, "events": 0, "news": 0, "errors": 0}
        try:
            stats["agendas"] = self._scrape_agendas()
        except Exception as e:
            logger.error("Agendas failed: %s", e)
            stats["errors"] += 1

        try:
            stats["events"] = self._scrape_events()
        except Exception as e:
            logger.error("Events failed: %s", e)
            stats["errors"] += 1

        try:
            stats["news"] = self._scrape_news()
        except Exception as e:
            logger.error("News failed: %s", e)
            stats["errors"] += 1

        return stats

    # ------------------------------------------------------------------
    # Council Agendas
    # ------------------------------------------------------------------

    def _scrape_agendas(self) -> int:
        body = self.fetch_page(AGENDA_URL)
        if not body:
            return 0

        # Find agenda items — CivicPlus renders each as a block with
        # a date heading followed by ViewFile links.
        # The ViewFile ID encodes the date: _MMDDYYYY-NNNN
        saved = 0

        # Pattern: date headers like "August 5, 2026"
        date_pattern = re.compile(
            r'(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|'
            r'Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|'
            r'Nov(?:ember)?|Dec(?:ember)?)\s+(\d{1,2}),?\s*(\d{4})',
            re.IGNORECASE,
        )

        # Pattern: ViewFile links
        viewfile_pattern = re.compile(
            r'/AgendaCenter/ViewFile/Agenda/([^"\']+)'
        )

        # Simple approach: parse all ViewFile IDs, extract dates from filenames
        seen = set()
        for m in viewfile_pattern.finditer(body):
            file_id = m.group(1)
            if file_id in seen:
                continue
            seen.add(file_id)

            # Extract date from filename: _MMDDYYYY-NNNN
            date_match = re.search(r'_(\d{2})(\d{2})(\d{4})', file_id)
            if not date_match:
                continue

            month, day, year = date_match.groups()
            try:
                meeting_date = datetime(int(year), int(month), int(day))
            except ValueError:
                continue

            # Build title
            title = f"Ridgecrest City Council Agenda — {meeting_date:%B %d, %Y}"
            pdf_url = f"{BASE}/AgendaCenter/ViewFile/Agenda/{file_id}"

            # Also try to find the link text near the ViewFile
            # Look at surrounding context
            pos = body.find(file_id)
            if pos > 0:
                snippet = body[max(0, pos - 200):pos]
                link_match = re.search(r'>\s*([^<]{10,100})\s*<', snippet)
                if link_match and len(link_match.group(1).strip()) > 5:
                    title = link_match.group(1).strip()

            item = self.save_agenda(
                title=title,
                description=f"City Council meeting agenda for {meeting_date:%B %d, %Y}. "
                            f"Source: Ridgecrest City Hall.",
                meeting_date=meeting_date,
                pdf_url=pdf_url,
            )
            if item:
                saved += 1

        logger.info("Ridgecrest agendas: %d saved (%d unique found)", saved, len(seen))
        return saved

    # ------------------------------------------------------------------
    # Events
    # ------------------------------------------------------------------

    def _scrape_events(self) -> int:
        body = self.fetch_page(CALENDAR_URL)
        if not body:
            return 0

        saved = 0
        seen_eids = set()

        # CivicPlus calendar: each event entry has a heading/id with the title,
        # followed by a "More Details" link with the EID.
        # Pattern: find the heading near each EID link
        eid_pattern = re.compile(
            r'href=["\'](/Calendar\.aspx\?EID=(\d+)[^"\']*)["\']',
            re.IGNORECASE,
        )

        dates_found = re.findall(
            r'(\w+ \d{1,2},?\s*\d{4})', body
        )

        for m in eid_pattern.finditer(body):
            eid = m.group(2)
            event_url = f"{BASE}{m.group(1)}"
            if eid in seen_eids:
                continue
            seen_eids.add(eid)

            # Extract the real title: look at the HTML before this link
            pos = m.start()
            preceding = body[max(0, pos - 600):pos]

            # Try to find a heading or descriptive text before the link
            title = None
            # Look for an <a> with a heading class or id containing event name
            for pattern in [
                r'(?:class|id)=["\'].*?(?:title|event|summary|name).*?["\']\s*>\s*([^<]+)',
                r'<h\d[^>]*>\s*([^<]+)\s*</h\d>',
                r'(?:class|id)=["\'].*?(?:desc|detail|info).*?["\']\s*>\s*([^<]+)',
            ]:
                tm = re.search(pattern, preceding[-500:], re.IGNORECASE)
                if tm:
                    candidate = tm.group(1).strip()
                    if len(candidate) > 3 and "more" not in candidate.lower():
                        title = candidate
                        break

            if not title:
                # Fallback: grab the last non-trivial text node before the link
                stripped = re.sub(r'<[^>]+>', '\n', preceding[-600:])
                lines = [l.strip() for l in stripped.split('\n') if len(l.strip()) > 3]
                # Skip known junk lines
                bad = {'more details', 'details', 'previous', 'next', 'today', 'calendar', 'view all'}
                lines = [l for l in lines if l.lower() not in bad]
                if lines:
                    title = lines[-1]  # last meaningful text before the link

            if not title:
                continue

            description = f"Community event in Ridgecrest, CA. Details at {event_url}"

            # Try to find date
            start_date = datetime.now()
            dm = re.search(r'(\w+ \d{1,2},?\s*\d{4})', preceding[-800:])
            if dm:
                try:
                    start_date = datetime.strptime(dm.group(1), "%B %d, %Y")
                except ValueError:
                    try:
                        start_date = datetime.strptime(dm.group(1), "%b %d, %Y")
                    except ValueError:
                        pass

            item = self.save_event(
                title=f"[Ridgecrest] {title}",
                description=description,
                location="Ridgecrest, CA",
                start_date=start_date,
                category="community",
            )
            if item:
                saved += 1

        logger.info("Ridgecrest events: %d saved", saved)
        return saved

    # ------------------------------------------------------------------
    # News / Alerts
    # ------------------------------------------------------------------

    def _scrape_news(self) -> int:
        body = self.fetch_page(ALERTS_URL)
        if not body:
            return 0

        saved = 0
        # CivicAlerts has article links
        alert_pattern = re.compile(
            r'<a[^>]*?href=["\'](/CivicAlerts\.aspx\?AID=\d+[^"\']*)["\']',
            re.IGNORECASE,
        )

        seen_urls = set()
        for m in alert_pattern.finditer(body):
            alert_url = f"{BASE}{m.group(1)}"
            if alert_url in seen_urls:
                continue
            seen_urls.add(alert_url)

            # Fetch the alert detail page
            detail = self.fetch_page(alert_url)
            if not detail:
                continue

            # Extract title
            title_match = re.search(r'<title>([^<]+)</title>', detail)
            if not title_match:
                continue
            title = title_match.group(1).strip()
            # Strip site name suffix
            title = re.sub(r'\s*[|•-]\s*Ridgecrest.*$', '', title).strip()

            # Extract content (first substantial paragraph)
            content_match = re.search(
                r'<div[^>]*?(?:articleContent|content|description)[^>]*>(.*?)</div>',
                detail, re.IGNORECASE | re.DOTALL
            )
            if not content_match:
                content_match = re.search(r'<p>(.{50,500})</p>', detail, re.DOTALL)
            content = ""
            if content_match:
                content = re.sub(r'<[^>]+>', '', content_match.group(1)).strip()[:2000]

            item = self.save_news(
                title=f"[Ridgecrest] {title}",
                content=self.full_article_text(alert_url, content or title),
                category="general",
                source_url=alert_url,
            )
            if item:
                saved += 1

        logger.info("Ridgecrest news: %d saved", saved)
        return saved
