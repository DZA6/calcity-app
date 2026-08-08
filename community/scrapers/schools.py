"""
Mojave Unified School District scraper — serves California City schools.

The district CMS (Smartsites) renders its content via JavaScript, so pages
are fetched through the r.jina.ai reader proxy, which executes JS and
returns clean markdown (see web-content-retrieval skill, rung 2).

Sources:
  - District home + year-calendar page: school URLs, calendar PDF links
  - /CCHS/, /CCMS/, /HE/ pages: per-school bell schedule documents
  - Year-calendar PDF (pypdf text extraction): dated events
    ("Aug 13 First Day of School", "Nov 24 - Nov 28 Thanksgiving Break")

Deliverables:
  - School rows upserted with website / calendar_url / bell_schedule_url
  - Dated school-year events parsed from the NEWEST calendar PDF, saved to
    Event(category="school"). PDFs for already-finished years parse to zero
    future events (silent no-op), so the scraper is safe to schedule daily.
"""
import io
import logging
import re
from datetime import datetime
from typing import Optional

from .base import BaseScraper
from community.models import School

logger = logging.getLogger("scrapers.schools")

JINA_PREFIX = "https://r.jina.ai/"
DISTRICT_HOME = "https://www.mojave.k12.ca.us/"
YEAR_CALENDAR_PAGE = "https://www.mojave.k12.ca.us/District/2607-2026-2027.html"

# California City schools served by MUSD (name -> info)
CAL_CITY_SCHOOLS = {
    "California City High School": {
        "page": "https://www.mojave.k12.ca.us/CCHS/",
        "type": "high",
    },
    "California City Middle School": {
        "page": "https://www.mojave.k12.ca.us/CCMS",
        "type": "middle",
    },
    "Hacienda Elementary School": {
        "page": "https://www.mojave.k12.ca.us/HE",
        "type": "elementary",
    },
}

MONTHS = {
    "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
    "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
}


class MojaveUSDScraper(BaseScraper):
    CITY_NAME = "Mojave USD (California City schools)"
    BASE_DOMAIN = "mojave.k12.ca.us"

    def scrape(self) -> dict:
        stats = {"agendas": 0, "events": 0, "news": 0, "businesses": 0, "errors": 0}

        try:
            stats["events"] += self._scrape_schools_and_links()
        except Exception as e:
            logger.error("MUSD school links failed: %s", e)
            stats["errors"] += 1

        try:
            stats["events"] += self._scrape_calendar_pdf_events()
        except Exception as e:
            logger.error("MUSD calendar PDF failed: %s", e)
            stats["errors"] += 1

        return stats

    # ------------------------------------------------------------------
    # School rows + links
    # ------------------------------------------------------------------

    def _render(self, url: str):
        """Fetch a JS-rendered page via the jina reader proxy."""
        return self.fetch_page(JINA_PREFIX + url)

    def _fetch_bytes(self, url: str) -> Optional[bytes]:
        """Fetch a binary file (PDF) with the same politeness/retry logic."""
        import urllib.request
        import urllib.error

        for attempt in range(1, self.MAX_RETRIES + 1):
            self._respect_delay()
            try:
                req = urllib.request.Request(url, headers=self.HEADERS)
                with urllib.request.urlopen(req, timeout=self.TIMEOUT) as resp:
                    return resp.read()
            except Exception as e:
                logger.warning("fetch_bytes attempt %d/%d %s: %s",
                               attempt, self.MAX_RETRIES, type(e).__name__, e)
        return None

    @staticmethod
    def _md_links(markdown: str):
        """Yield (text, url) pairs from markdown-style links."""
        for m in re.finditer(r"\[([^\]]+)\]\(([^)]+)\)", markdown):
            text = m.group(1).strip()
            url = m.group(2).strip()
            if url.startswith("http"):
                yield text, url

    def _scrape_schools_and_links(self) -> int:
        """Upsert California City school rows with website/calendar/bell links."""
        updated = 0

        district_md = self._render(DISTRICT_HOME)
        year_md = self._render(YEAR_CALENDAR_PAGE) if district_md else ""
        all_md = f"{district_md or ''}\n{year_md or ''}"

        # District calendar links (page + PDFs) from the district pages
        calendar_links = [u for t, u in self._md_links(all_md)
                          if re.search(r"calendar", t, re.I) and ".pdf" in u.lower()]
        # Prefer the newest school-year calendar PDF by year in the filename
        calendar_links.sort(key=lambda u: re.findall(r"20\d{2}", u))
        calendar_pdf = calendar_links[-1] if calendar_links else ""
        district_cal_page = next(
            (u for t, u in self._md_links(all_md)
             if "musd-calendar" in u), "https://www.mojave.k12.ca.us/District/Portal/musd-calendar")

        for name, info in CAL_CITY_SCHOOLS.items():
            page_md = self._render(info["page"])
            if not page_md:
                continue

            school, _ = School.objects.get_or_create(
                name__iexact=name,
                defaults={
                    "name": name, "type": info["type"], "is_approved": True,
                    "website": "https://www.mojave.k12.ca.us" + info["page"].split(".k12.ca.us")[1],
                },
            )

            def _norm_url(u: str) -> str:
                # Some school pages link absolute URLs with a duplicated domain
                u = u.strip()
                dup = "https://www.mojave.k12.ca.us/https://www.mojave.k12.ca.us"
                if u.startswith(dup):
                    u = "https://www.mojave.k12.ca.us" + u[len(dup):]
                elif u.startswith("https://www.mojave.k12.ca.us/http"):
                    u = u.replace("https://www.mojave.k12.ca.us/", "", 1)
                return u

            links = list(self._md_links(page_md))

            # Bell schedule: prefer a link whose text mentions "bell" first,
            # then any "schedule" link that is NOT a bus schedule.
            bell = next(
                (u for t, u in links
                 if "bell" in t.lower()
                 and re.search(r"\.(pdf|docx?|doc)$|drive\.google\.com", u, re.I)),
                "",
            )
            if not bell:
                bell = next(
                    (u for t, u in links
                     if "schedule" in t.lower() and "bus" not in t.lower()
                     and re.search(r"\.(pdf|docx?|doc)$|drive\.google\.com", u, re.I)),
                    "",
                )
            bell = _norm_url(bell) if bell else ""

            # Calendar: any calendar-ish link, else the district calendar page
            cal = next(
                (u for t, u in links
                 if re.search(r"calendar", t, re.I)),
                district_cal_page,
            )
            cal = _norm_url(cal) if cal else ""

            website = "https://www.mojave.k12.ca.us" + info["page"].split(".k12.ca.us")[1]

            changed = False
            if bell and school.bell_schedule_url != bell:
                school.bell_schedule_url = bell[:200]
                changed = True
            if cal and school.calendar_url != cal:
                school.calendar_url = cal[:200]
                changed = True
            if school.website != website:
                school.website = website
                changed = True
            if changed:
                school.save()
                updated += 1

        logger.info("MUSD schools: %d rows updated with calendar/bell links", updated)
        return 0

    # ------------------------------------------------------------------
    # School-year calendar events from the district PDF
    # ------------------------------------------------------------------

    def _scrape_calendar_pdf_events(self) -> int:
        """Parse dated events from the newest district year-calendar PDF."""
        # Find the newest calendar PDF from the district pages
        all_md = ""
        for url in (DISTRICT_HOME, YEAR_CALENDAR_PAGE):
            md = self._render(url)
            if md:
                all_md += md + "\n"

        pdfs = [u for t, u in self._md_links(all_md)
                if "calendar" in t.lower() and u.lower().endswith(".pdf")]
        if not pdfs:
            logger.info("MUSD: no calendar PDF found")
            return 0
        pdfs.sort(key=lambda u: re.findall(r"20\d{2}", u))
        pdf_url = pdfs[-1]

        body = self._fetch_bytes(pdf_url)
        if not body or b"%PDF" not in body[:1024]:
            logger.info("MUSD: calendar PDF fetch failed (%s)", pdf_url)
            return 0

        try:
            from pypdf import PdfReader
            reader = PdfReader(io.BytesIO(body))
            text = "\n".join((page.extract_text() or "") for page in reader.pages)
        except Exception as e:
            logger.warning("MUSD: pypdf parse failed: %s", e)
            return 0

        # Year context from the PDF header: "CALENDAR 2025-2026"
        yr = re.search(r"(20\d{2})\s*[-–]\s*(20\d{2})", text)
        year1, year2 = (int(yr.group(1)), int(yr.group(2))) if yr else (None, None)

        # Event lines: "Aug 13 First Day of School" / "Nov 24 - Nov 28 Thanksgiving Break"
        event_pat = re.compile(
            r"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.? (\d{1,2})"
            r"(?:\s*[-–]\s*[A-Za-z]{3,9}\.?\s*(\d{1,2}))?\s+([A-Z][A-Za-z0-9 ,'&()\/.-]+)"
        )

        saved = 0
        seen = set()
        today = datetime.now().date()
        for m in event_pat.finditer(text):
            mon = MONTHS[m.group(1)[:3].lower()]
            day = int(m.group(2))
            end_day = int(m.group(3)) if m.group(3) else None
            title = m.group(4).strip().rstrip(".")
            # The PDF's Days-Taught/Holidays columns trail the title as numbers
            title = re.sub(r"\s+(?:\d+\s*)+$", "", title).strip()
            if len(title) < 4:
                continue

            # Assign year: Jul-Dec belong to year1, Jan-Jun to year2
            if year1 and year2:
                year = year1 if mon >= 7 else year2
            else:
                year = today.year if mon >= 7 or (mon < 7 and today.month < 7) else today.year - 1

            try:
                date = datetime(year, mon, day, 12, 0)
            except ValueError:
                continue

            # Only future events (the PDF is usually for a year that has begun)
            if date.date() < today or date.date() > today.replace(year=today.year + 1):
                continue

            full_title = f"{title} ({date:%b %d, %Y})"
            if full_title.lower() in seen:
                continue
            seen.add(full_title.lower())

            end_date = None
            if end_day:
                try:
                    end_date = datetime(year, mon, end_day, 12, 0)
                except ValueError:
                    end_date = None

            if end_date is not None:
                item = self.save_event(
                    title=full_title,
                    description="Mojave Unified School District calendar.",
                    location="Mojave Unified School District",
                    start_date=date,
                    end_date=end_date,
                    category="school",
                )
            else:
                item = self.save_event(
                    title=full_title,
                    description="Mojave Unified School District calendar.",
                    location="Mojave Unified School District",
                    start_date=date,
                    category="school",
                )
            if item:
                saved += 1

        logger.info("MUSD calendar PDF (%s): %d future events saved", pdf_url, saved)
        return saved
