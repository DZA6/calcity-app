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

logger = logging.getLogger("scrapers.calcity")

GRANICUS_RSS = (
    "https://californiacity.granicus.com/ViewPublisherRSS.php?view_id=1"
)
HOME_URL = "https://www.californiacity-ca.gov/CC/"
OVERPASS_URL = "https://overpass-api.de/api/interpreter"

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
            stats["news"] = self._scrape_desert_news()
        except Exception as e:
            logger.error("CalCity news failed: %s", e)
            stats["errors"] += 1

        try:
            stats["businesses"] = self._scrape_businesses_osm()
        except Exception as e:
            logger.error("CalCity OSM businesses failed: %s", e)
            stats["errors"] += 1

        return stats

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

        try:
            import subprocess
            query_clean = " ".join(query.split())
            self._respect_delay()
            result = subprocess.run(
                [
                    "curl", "-s", "--max-time", str(self.TIMEOUT),
                    "https://overpass-api.de/api/interpreter",
                    "-H", "Accept: application/json",
                    "--data-urlencode", f"data={query_clean}",
                ],
                capture_output=True, text=True, timeout=self.TIMEOUT + 5,
            )
            if result.returncode != 0:
                logger.error("curl Overpass failed: %s", result.stderr[:200])
                return 0
            data = json.loads(result.stdout)
        except Exception as e:
            logger.error("Overpass API failed: %s", e)
            return 0

        elements = data.get("elements", [])
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
        """Scrape East Kern / California City news from desertnews.com."""
        body = self.fetch_page("https://www.desertnews.com/news/")
        if not body:
            return 0

        saved = 0

        # Find article links and titles
        article_pattern = re.compile(
            r'<a[^>]*?href=["\']([^"\']*california[^"\']*city[^"\']*|\d{4}/[^"\']+)["\']'
            r'[^>]*>([^<]+)</a>',
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

            item = self.save_news(
                title=title_raw,
                content=f"East Kern County news. Read more at {url}",
                category="general",
                source_url=url,
            )
            if item:
                saved += 1

        logger.info("CalCity news: %d saved", saved)
        return saved
