"""
Tehachapi, CA scraper — CivicPlus platform (same pattern as Ridgecrest).
Sources:
  - Council agendas: /agendacenter
  - Events: /Calendar.aspx
"""
import re
import logging
from datetime import datetime

from .base import BaseScraper

logger = logging.getLogger("scrapers.tehachapi")

AGENDA_URL = "https://www.liveuptehachapi.com/agendacenter"
CALENDAR_URL = "https://www.liveuptehachapi.com/Calendar.aspx"
BASE = "https://www.liveuptehachapi.com"


class TehachapiScraper(BaseScraper):
    CITY_NAME = "Tehachapi"
    BASE_DOMAIN = "liveuptehachapi.com"

    def scrape(self) -> dict:
        stats = {"agendas": 0, "events": 0, "news": 0, "errors": 0}

        try:
            stats["agendas"] = self._scrape_agendas()
        except Exception as e:
            logger.error("Tehachapi agendas failed: %s", e)
            stats["errors"] += 1

        try:
            stats["events"] = self._scrape_events()
        except Exception as e:
            logger.error("Tehachapi events failed: %s", e)
            stats["errors"] += 1

        return stats

    # ------------------------------------------------------------------
    # Council Agendas
    # ------------------------------------------------------------------

    def _scrape_agendas(self) -> int:
        body = self.fetch_page(AGENDA_URL)
        if not body:
            return 0

        saved = 0
        seen = set()

        # CivicPlus ViewFile pattern
        viewfile_pattern = re.compile(r'/AgendaCenter/ViewFile/Agenda/([^"\']+)')

        for m in viewfile_pattern.finditer(body):
            file_id = m.group(1)
            if file_id in seen:
                continue
            seen.add(file_id)

            # Extract date: _MMDDYYYY-NNN
            date_match = re.search(r'_(\d{2})(\d{2})(\d{4})', file_id)
            if not date_match:
                continue

            month, day, year = date_match.groups()
            try:
                meeting_date = datetime(int(year), int(month), int(day))
            except ValueError:
                continue

            title = f"Tehachapi City Council Agenda — {meeting_date:%B %d, %Y}"
            pdf_url = f"{BASE}/AgendaCenter/ViewFile/Agenda/{file_id}"

            # Try to extract actual title from page context
            pos = body.find(file_id)
            if pos > 0:
                snippet = body[max(0, pos - 300):pos]
                link_match = re.search(r'>\s*([^<]{10,120})\s*<', snippet)
                if link_match:
                    candidate = link_match.group(1).strip()
                    if len(candidate) > 5 and not candidate.startswith("<"):
                        title = candidate

            item = self.save_agenda(
                title=title,
                description=f"City Council meeting agenda for {meeting_date:%B %d, %Y}. "
                            f"Source: City of Tehachapi.",
                meeting_date=meeting_date,
                pdf_url=pdf_url,
            )
            if item:
                saved += 1

        logger.info("Tehachapi agendas: %d saved (%d found)", saved, len(seen))
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

        eid_pattern = re.compile(
            r'href=["\'](/Calendar\.aspx\?EID=(\d+)[^"\']*)["\']',
            re.IGNORECASE,
        )

        for m in eid_pattern.finditer(body):
            eid = m.group(2)
            event_url = f"{BASE}{m.group(1)}"
            if eid in seen_eids:
                continue
            seen_eids.add(eid)

            pos = m.start()
            preceding = body[max(0, pos - 600):pos]

            title = None
            for pattern in [
                r'(?:class|id)=["\'].*?(?:title|event|summary|name).*?["\']\s*>\s*([^<]+)',
                r'<h\d[^>]*>\s*([^<]+)\s*</h\d>',
            ]:
                tm = re.search(pattern, preceding[-500:], re.IGNORECASE)
                if tm:
                    candidate = tm.group(1).strip()
                    if len(candidate) > 3 and "more" not in candidate.lower():
                        title = candidate
                        break

            if not title:
                stripped = re.sub(r'<[^>]+>', '\n', preceding[-600:])
                lines = [l.strip() for l in stripped.split('\n') if len(l.strip()) > 3]
                bad = {'more details', 'details', 'previous', 'next', 'today', 'calendar', 'view all'}
                lines = [l for l in lines if l.lower() not in bad]
                if lines:
                    title = lines[-1]

            if not title:
                continue

            start_date = datetime.now()
            dm = re.search(r'(\w+ \d{1,2},?\s*\d{4})', preceding[-800:])
            if dm:
                try:
                    start_date = datetime.strptime(dm.group(1), "%B %d, %Y")
                except ValueError:
                    pass

            item = self.save_event(
                title=f"[Tehachapi] {title}",
                description=f"Community event in Tehachapi, CA. Details at {event_url}",
                location="Tehachapi, CA",
                start_date=start_date,
                category="community",
            )
            if item:
                saved += 1

        logger.info("Tehachapi events: %d saved", saved)
        return saved
