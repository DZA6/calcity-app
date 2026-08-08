"""
Bakersfield news scraper — RSS feed from bakersfield.com.
Pulls local news from The Bakersfield Californian.
"""
import logging
import xml.etree.ElementTree as ET
from datetime import datetime

from .base import BaseScraper

logger = logging.getLogger("scrapers.bakersfield")

RSS_URL = "https://www.bakersfield.com/rss"


class BakersfieldScraper(BaseScraper):
    CITY_NAME = "Bakersfield"
    BASE_DOMAIN = "bakersfield.com"

    def scrape(self) -> dict:
        stats = {"agendas": 0, "events": 0, "news": 0, "errors": 0}

        try:
            stats["news"] = self._scrape_rss()
        except Exception as e:
            logger.error("Bakersfield RSS failed: %s", e)
            stats["errors"] += 1

        return stats

    def _scrape_rss(self) -> int:
        body = self.fetch_page(RSS_URL)
        if not body:
            return 0

        saved = 0
        try:
            root = ET.fromstring(body)
        except ET.ParseError as e:
            logger.error("Bakersfield RSS parse failed: %s", e)
            return 0

        for item in root.iter("item"):
            title = ""
            description = ""
            link = ""

            title_el = item.find("title")
            desc_el = item.find("description")
            link_el = item.find("link")

            if title_el is not None and title_el.text:
                title = title_el.text.strip()
            if desc_el is not None and desc_el.text:
                description = desc_el.text.strip()[:2000]
            if link_el is not None and link_el.text:
                link = link_el.text.strip()

            if not title or len(title) < 10:
                continue

            content = description or f"Bakersfield news. Read more at {link}"

            item_obj = self.save_news(
                title=f"[Bakersfield] {title}",
                content=content,
                category="general",
                source_url=link,
            )
            if item_obj:
                saved += 1

        logger.info("Bakersfield RSS news: %d saved", saved)
        return saved
