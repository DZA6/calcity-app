"""
California City scraper — Joomla-based site + Granicus meeting platform.
Sources:
  - Granicus RSS feed: structured meeting data with dates, descriptions, videos
  - OpenStreetMap Overpass API: businesses and amenities in California City
  - News: desertnews.com (East Kern County news)
"""
import re
import json
import logging
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
from datetime import datetime

from .base import BaseScraper
from community.models import Business, NewsItem
from typing import Optional

logger = logging.getLogger("scrapers.calcity")

GRANICUS_RSS = (
    "https://californiacity.granicus.com/ViewPublisherRSS.php?view_id=1"
)
HOME_URL = "https://www.californiacity-ca.gov/CC/"
OVERPASS_URL = "https://overpass-api.de/api/interpreter"
BUSINESS_DIRECTORY_URL = (
    "https://www.californiacity-ca.gov/CC/index.php/business/business-directory"
)
CITY_CALENDAR_LIST_URL = (
    "https://www.californiacity-ca.gov/CC/index.php/cityconnection2/city-calendar?view=list"
)

# City business-directory category text -> CalCity app category.
# The directory table's 4th column is a free-text description of the
# business license type (e.g. "Retail", "Professional Service").
CITY_CATEGORY_MAP = {
    "professional service": "service",
    "retail": "local_shop",
    "restaurant/supply": "restaurant",
    "home based business": "home_business",
    "handyman services": "service",
    "real estate": "service",
    "service organization": "other",
    "internet sales/service": "home_business",
    "landlord": "service",
    "cultivation cannabis": "other",
    "cannabis distribution": "other",
    "general contractor": "service",
    "cleaning services": "service",
    "medical services": "service",
    "hair & nail salon": "service",
    "ministry": "other",
    "vending": "home_business",
    "novelty gifts": "local_shop",
    "aircraft/aviation": "other",
    "cannabis delivery": "other",
    "gardener": "service",
    "landscape contractor": "service",
    "transportation": "service",
    "auto repair": "service",
    "cannabis mfg": "other",
    "mobile vending/food/catering": "restaurant",
    "gym/fitness center": "service",
    "concrete sales & del": "local_shop",
    "storage facility": "service",
    "bank": "service",
    "auto parts store": "local_shop",
    "convenient store/gas": "local_shop",
    "laundromat": "service",
    "youth/sports activity": "other",
    "cannabis storefront": "other",
    "purified water sales": "local_shop",
    "grocery store": "local_shop",
    "donut/bakery": "restaurant",
    "home improvement services": "service",
    "towing": "service",
    "massage services": "service",
    "hardware store": "local_shop",
    "auto sales": "local_shop",
    "auto supply store": "local_shop",
    "recreation services": "other",
    "hotel": "service",
    "locksmith": "service",
    "garden supply": "local_shop",
    "solar": "service",
    "newspaper/media": "other",
    "electrical services": "service",
    "carpet care/cleaning": "service",
    "educational services": "service",
    "dental services": "service",
    "recycling services": "service",
    "property management": "service",
    "barber services": "service",
    "pet breeder": "other",
    "recycling/trash service": "service",
    "metal fabrication": "other",
    "day care services": "service",
    "party and supply rentals": "service",
    "plumbing contractor": "service",
    "heating & air conditioning": "service",
    "photography services": "freelancer",
    "rv park": "service",
    "painting": "service",
    "food pantry": "other",
    "flooring": "service",
    "tire store/garage": "local_shop",
    "construction": "other",
    "wireless communication": "service",
    "firearms sales": "local_shop",
    "pest control": "service",
    "veterinarian/animal care": "service",
}

# OSM → CalCity category mapping
OSM_CATEGORY_MAP = {
    "restaurant": "restaurant",
    "fast_food": "restaurant",
    "cafe": "restaurant",
    "pub": "restaurant",
    "bar": "restaurant",
    "supermarket": "local_shop",
    "convenience": "local_shop",
    "bakery": "local_shop",
    "butcher": "local_shop",
    "alcohol": "local_shop",
    "clothes": "local_shop",
    "hairdresser": "service",
    "beauty": "service",
    "car_repair": "service",
    "car_parts": "service",
    "laundry": "service",
    "travel_agency": "service",
    "tax_advisor": "service",
    "bank": "service",
    "mobile_phone": "local_shop",
    "doityourself": "local_shop",
    "pharmacy": "local_shop",
    "fuel": "local_shop",
    "car_rental": "service",
    "estate_agent": "service",
    "post_office": "service",
    "clinic": "service",
    "dentist": "service",
    "veterinary": "service",
    "library": "service",
    "police": "service",
    "place_of_worship": "other",
    "office": "other",
    "craft": "other",
}


class CalCityScraper(BaseScraper):
    CITY_NAME = "California City"
    BASE_DOMAIN = "californiacity-ca.gov"

    def scrape(self) -> dict:
        stats = {"agendas": 0, "events": 0, "news": 0, "businesses": 0, "errors": 0}

        try:
            stats["agendas"] = self._scrape_granicus_rss()
        except Exception as e:
            logger.error("CalCity Granicus agendas failed: %s", e)
            stats["errors"] += 1

        try:
            stats["events"] = self._scrape_city_calendar()
        except Exception as e:
            logger.error("CalCity city calendar failed: %s", e)
            stats["errors"] += 1

        try:
            stats["news"] = self._scrape_desert_news()
        except Exception as e:
            logger.error("CalCity news failed: %s", e)
            stats["errors"] += 1

        try:
            stats["businesses"] = self._scrape_business_directory()
        except Exception as e:
            logger.error("CalCity business directory failed: %s", e)
            stats["errors"] += 1

        try:
            stats["businesses"] += self._scrape_businesses_osm()
        except Exception as e:
            logger.error("CalCity OSM businesses failed: %s", e)
            stats["errors"] += 1

        try:
            self._enrich_businesses_osm()
        except Exception as e:
            logger.error("CalCity OSM enrichment failed: %s", e)
            stats["errors"] += 1

        return stats

    # ------------------------------------------------------------------
    # Businesses from the City's official business directory
    # ------------------------------------------------------------------

    def _scrape_business_directory(self) -> int:
        """
        Parse the City of California City business-directory page. It is a
        server-rendered Joomla article containing a table of every licensed
        business: Account# | (blank) | Business | Business Phone # | Description.

        The Description column is the license category text (e.g. "Retail",
        "Professional Service") — mapped to app categories via CITY_CATEGORY_MAP.
        Upserts: if a business with the same name already exists (e.g. from the
        OSM source), its missing phone/description are filled in instead of
        creating a duplicate.
        """
        import html as html_mod

        body = self.fetch_page(BUSINESS_DIRECTORY_URL)
        if not body:
            return 0

        def clean(cell: str) -> str:
            txt = re.sub(r"<[^>]+>", "", cell)
            txt = html_mod.unescape(txt).replace("&nbsp;", " ")
            return " ".join(txt.split())

        saved = 0
        updated = 0
        seen = set()

        for row in re.findall(r"<tr>(.*?)</tr>", body, re.S):
            cells = re.findall(r"<td[^>]*>(.*?)</td>", row, re.S)
            if len(cells) < 5:
                continue
            acct, _, name, phone, desc = [clean(c) for c in cells[:5]]
            if not name or name == "Business":
                continue
            key = name.lower()
            if key in seen:
                continue
            seen.add(key)

            category = CITY_CATEGORY_MAP.get(desc.lower().strip(), "other")
            description = (
                f"Licensed business in California City, CA "
                f"(license type: {desc or 'General'})."
            )

            existing = Business.objects.filter(name__iexact=name).first()
            if existing:
                changed = False
                if phone and not existing.contact_phone:
                    existing.contact_phone = phone[:20]
                    changed = True
                if not existing.description:
                    existing.description = description
                    changed = True
                if changed:
                    existing.save()
                    updated += 1
                continue

            item = self.save_business(
                name=name,
                description=description,
                category=category,
                phone=phone,
            )
            if item:
                saved += 1

        logger.info(
            "CalCity business directory: %d saved, %d updated",
            saved, updated,
        )
        return saved

    # ------------------------------------------------------------------
    # Events from the City's DPCalendar (via jina reader proxy)
    # ------------------------------------------------------------------

    def _scrape_city_calendar(self) -> int:
        """
        Parse the City of California City calendar (Joomla DPCalendar).

        The calendar view is JS-rendered, so it is fetched through the
        r.jina.ai reader proxy, which returns markdown. The list view has a
        regular shape:

            ## [City Council Meeting](https://.../city-council-meeting-...)
            08.11.2026  Monthly on the 2nd Tuesday ... [Agenda](...)[Zoom](...)

        Title -> Event.category: "city" for council meetings (6 PM, City
        Hall), "community" for everything else (ceremonies, celebrations).
        Titles carry the date so recurring meetings deduplicate correctly.
        """
        body = self.fetch_page(f"https://r.jina.ai/{CITY_CALENDAR_LIST_URL}")
        if not body:
            return 0

        saved = 0
        pattern = re.compile(
            r"## \[([^\]]+)\]\(([^)]+)\)\s*\n\s*(\d{2})\.(\d{2})\.(\d{4})",
        )
        for m in pattern.finditer(body):
            title = m.group(1).strip()
            url = m.group(2).strip()
            # US date format: MM.DD.YYYY (08.11.2026 = Aug 11, 2026)
            mm, dd, yyyy = m.group(3), m.group(4), m.group(5)

            if not title or title.lower() == "city calendar":
                continue

            try:
                meeting_date = datetime(int(yyyy), int(mm), int(dd))
            except ValueError:
                continue

            is_council = "council" in title.lower()
            category = "city" if is_council else "community"
            location = "City Hall, California City, CA" if is_council else ""
            hour = 18 if is_council else 12
            meeting_date = meeting_date.replace(hour=hour)

            full_title = f"{title} — {meeting_date:%b %d, %Y}"
            description = (
                f"Posted on the City of California City calendar. "
                f"Details: {url}"
            )

            item = self.save_event(
                title=full_title,
                description=description,
                location=location,
                start_date=meeting_date,
                category=category,
            )
            if item:
                saved += 1

        logger.info("CalCity city calendar: %d events saved", saved)
        return saved

    # ------------------------------------------------------------------
    # Shared Overpass helper (retry + mirror fallback)
    # ------------------------------------------------------------------

    OVERPASS_ENDPOINTS = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
    ]

    def _overpass_query(self, query: str) -> Optional[list]:
        """
        POST an Overpass QL query via curl --data-urlencode (urllib gets 406).
        Tries each endpoint twice (transient error pages happen under load)
        and returns the JSON 'elements' list, or None if all fail.
        """
        import subprocess

        query_clean = " ".join(query.split())
        for endpoint in self.OVERPASS_ENDPOINTS:
            for attempt in range(2):
                self._respect_delay()
                try:
                    result = subprocess.run(
                        [
                            "curl", "-s", "--max-time", str(self.TIMEOUT),
                            endpoint,
                            "-H", "Accept: application/json",
                            "--data-urlencode", f"data={query_clean}",
                        ],
                        capture_output=True, text=True, timeout=self.TIMEOUT + 5,
                    )
                    if result.returncode != 0:
                        logger.warning("curl %s failed: %s", endpoint, result.stderr[:150])
                        continue
                    data = json.loads(result.stdout)
                    return data.get("elements", [])
                except (json.JSONDecodeError, ValueError) as e:
                    logger.warning(
                        "Overpass %s attempt %d returned non-JSON: %s",
                        endpoint, attempt + 1, e,
                    )
                except Exception as e:
                    logger.warning("Overpass %s attempt %d error: %s", endpoint, attempt + 1, e)
        logger.error("Overpass query failed on all endpoints")
        return None

    # ------------------------------------------------------------------
    # Businesses from OpenStreetMap
    # ------------------------------------------------------------------

    def _scrape_businesses_osm(self) -> int:
        """
        Query OpenStreetMap Overpass API for businesses in California City.
        Returns structured data: name, type, phone, website, address, hours.
        No API key required — free and open data.
        """
        query = """
[out:json][timeout:25];
(
  node["shop"](35.10,-118.05,35.20,-117.90);
  node["amenity"](35.10,-118.05,35.20,-117.90);
  node["office"](35.10,-118.05,35.20,-117.90);
  node["craft"](35.10,-118.05,35.20,-117.90);
);
out body;
"""

        elements = self._overpass_query(query)
        if elements is None:
            return 0

        saved = 0

        for el in elements:
            tags = el.get("tags", {})
            name = tags.get("name", "").strip()
            if not name:
                continue

            # Determine OSM type
            osm_type = (
                tags.get("shop", "")
                or tags.get("amenity", "")
                or tags.get("office", "")
                or tags.get("craft", "")
            )

            # Skip non-commercial entities
            skip_types = {
                "police", "fire_station", "place_of_worship", "library",
                "townhall", "courthouse", "school", "kindergarten",
                "toilets", "bench", "waste_basket", "drinking_water",
                "fountain", "post_box", "recycling", "telephone",
                "parking", "bicycle_parking", "atm", "clock",
            }
            if osm_type in skip_types:
                continue

            # Map to CalCity category
            category = OSM_CATEGORY_MAP.get(osm_type, "local_shop")

            # Extract contact info
            phone = tags.get("phone", "") or tags.get("contact:phone", "")
            website = tags.get("website", "") or tags.get("contact:website", "")
            if website and not website.startswith("http"):
                website = ""

            # Build address
            addr_parts = []
            for key in ["addr:housenumber", "addr:street", "addr:city", "addr:postcode"]:
                val = tags.get(key, "")
                if val:
                    addr_parts.append(val)
            address = ", ".join(addr_parts) if addr_parts else "California City, CA 93505"

            # Build description
            description_parts = [f"{name} is a {osm_type.replace('_', ' ')} in California City, CA."]
            cuisine = tags.get("cuisine", "")
            if cuisine:
                description_parts.append(f"Cuisine: {cuisine}.")
            hours = tags.get("opening_hours", "")
            if hours:
                description_parts.append(f"Hours: {hours}.")
            description = " ".join(description_parts)

            item = self.save_business(
                name=name,
                description=description,
                category=category,
                website=website[:200] if website else "",
                address=address[:300],
                phone=phone[:20] if phone else "",
            )
            if item:
                saved += 1

        logger.info("CalCity OSM businesses: %d saved (%d total POIs)", saved, len(elements))
        return saved

    # ------------------------------------------------------------------
    # OSM enrichment — fill blank address/website/phone on existing rows
    # ------------------------------------------------------------------

    def _enrich_businesses_osm(self) -> int:
        """
        Fill missing address/website/phone on existing Business rows using
        OpenStreetMap data (nodes AND ways) in the city bbox. Matches by
        normalized name (exact, or one-name-contains-the-other for >=6 char
        names, catching "ACE Hardware Store" vs "Ace Hardware").

        ADDITIVE ONLY: never overwrites a populated field. Idempotent by
        design — once a field is filled it is left alone.
        """
        query = """
[out:json][timeout:25];
(
  node["shop"](35.10,-118.05,35.20,-117.90);
  node["amenity"](35.10,-118.05,35.20,-117.90);
  node["office"](35.10,-118.05,35.20,-117.90);
  node["craft"](35.10,-118.05,35.20,-117.90);
  way["shop"](35.10,-118.05,35.20,-117.90);
  way["amenity"](35.10,-118.05,35.20,-117.90);
  way["office"](35.10,-118.05,35.20,-117.90);
  way["craft"](35.10,-118.05,35.20,-117.90);
);
out tags;
"""

        def _norm(name: str) -> str:
            return re.sub(r"[^a-z0-9]+", " ", name.lower()).strip()

        elements = self._overpass_query(query)
        if elements is None:
            return 0

        # Index OSM entries by normalized name
        osm_index = {}
        for el in elements:
            tags = el.get("tags", {})
            name = tags.get("name", "").strip()
            if not name:
                continue
            osm_index.setdefault(_norm(name), []).append(tags)

        # Businesses that could use enrichment (blank-string fields, not NULL)
        candidates = Business.objects.filter(is_approved=True)
        enriched = 0
        for biz in candidates:
            need = bool(biz.address) + bool(biz.website) + bool(biz.contact_phone)
            if need == 3:
                continue
            key = _norm(biz.name)
            match = osm_index.get(key)
            if not match:
                # containment fallback
                for k, v in osm_index.items():
                    if len(key) >= 6 and len(k) >= 6 and (key in k or k in key):
                        match = v
                        break
            if not match:
                continue
            tags = match[0]

            changed = False
            if not biz.address:
                parts = []
                for k in ["addr:housenumber", "addr:street", "addr:city", "addr:postcode"]:
                    if tags.get(k):
                        parts.append(tags[k])
                if parts:
                    biz.address = ", ".join(parts)[:300]
                    changed = True
            if not biz.website:
                ws = tags.get("website", "") or tags.get("contact:website", "")
                if ws and ws.startswith("http"):
                    biz.website = ws[:200]
                    changed = True
            if not biz.contact_phone:
                ph = tags.get("phone", "") or tags.get("contact:phone", "")
                if ph:
                    biz.contact_phone = ph[:20]
                    changed = True
            if changed:
                biz.save()
                enriched += 1

        logger.info("CalCity OSM enrichment: %d businesses updated", enriched)
        return enriched

    # ------------------------------------------------------------------
    # Agendas from Granicus RSS
    # ------------------------------------------------------------------

    def _scrape_granicus_rss(self) -> int:
        """
        Parse the Granicus RSS feed. Each <item> is a meeting:
          <title>City Council Meeting - Aug 11, 2026</title>
          <description>...</description>
          <link>https://...</link>
          <pubDate>Mon, 11 Aug 2026 ...</pubDate>
          <enclosure ... /> (video MP4)
        """
        body = self.fetch_page(GRANICUS_RSS)
        if not body:
            return 0

        saved = 0
        try:
            root = ET.fromstring(body)
        except ET.ParseError as e:
            logger.error("Granicus RSS parse failed: %s", e)
            return 0

        for item in root.iter("item"):
            title = ""
            description = ""
            link = ""
            pub_date = None

            title_el = item.find("title")
            desc_el = item.find("description")
            link_el = item.find("link")
            date_el = item.find("pubDate")

            if title_el is not None and title_el.text:
                title = title_el.text.strip()
            if desc_el is not None and desc_el.text:
                description = re.sub(r"<[^>]+>", "", desc_el.text).strip()[:2000]
            if link_el is not None and link_el.text:
                link = link_el.text.strip()
            if date_el is not None and date_el.text:
                try:
                    pub_date = datetime.strptime(
                        date_el.text.strip()[:25],
                        "%a, %d %b %Y %H:%M:%S",
                    )
                except ValueError:
                    pass

            if not title:
                continue
            if "California City" not in title:
                title = f"California City {title}"

            # Filter junk
            if len(title) < 8:
                continue

            item = self.save_agenda(
                title=title,
                description=description or f"Meeting details at {link}",
                meeting_date=pub_date or datetime.now(),
                pdf_url=link,
            )
            if item:
                saved += 1

        logger.info("CalCity Granicus agendas: %d saved", saved)
        return saved

    # ------------------------------------------------------------------
    # News from Desert News (East Kern)
    # ------------------------------------------------------------------

    def _scrape_desert_news(self) -> int:
        """Scrape East Kern / California City news from desertnews.com.

        For each NEW article (dedup checked BEFORE fetching), downloads the
        article page and extracts the real body text with trafilatura.
        Falls back to a stub when extraction fails or trafilatura is not
        installed (e.g. fresh clone before pip install -r requirements.txt).
        """
        body = self.fetch_page("https://www.desertnews.com/news/")
        if not body:
            return 0

        saved = 0

        # Find article links and titles. DesertNews runs TownNews — article
        # URLs are /news/article_<uuid>.html with the title as anchor text.
        article_pattern = re.compile(
            r'<a[^>]*?href=["\']([^"\']*/news/article_[a-f0-9-]+\.html)["\']'
            r'[^>]*>(.*?)</a>',
            re.IGNORECASE,
        )

        seen_urls = set()
        for m in article_pattern.finditer(body):
            url = m.group(1)
            title_raw = m.group(2).strip()

            if not url.startswith("http"):
                url = f"https://www.desertnews.com{url}"

            if url in seen_urls or len(title_raw) < 10:
                continue
            seen_urls.add(url)

            # Skip known articles BEFORE fetching them (saves a request each)
            if self.is_duplicate(NewsItem, title_raw, url):
                continue

            content = self._extract_article_content(url)
            if not content:
                content = f"East Kern County news. Read more at {url}"

            item = self.save_news(
                title=title_raw,
                content=content,
                category="general",
                source_url=url,
            )
            if item:
                saved += 1

        logger.info("CalCity news: %d saved", saved)
        return saved

    def _extract_article_content(self, url: str) -> str:
        """Extract the main article text with trafilatura. '' on any failure."""
        try:
            import trafilatura
        except ImportError:
            return ""

        body = self.fetch_page(url)
        if not body:
            return ""

        try:
            text = trafilatura.extract(body)
        except Exception:
            text = None
        if not text:
            return ""
        return text.strip()[:5000]
