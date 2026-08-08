"""
Django management command: scrape nearby cities for CalCity app data.

Usage:
    python manage.py scrape_cities                    # all cities
    python manage.py scrape_cities --city ridgecrest  # one city
    python manage.py scrape_cities --dry-run          # fetch but don't save
"""
import logging
from django.core.management.base import BaseCommand

from community.scrapers.ridgecrest import RidgecrestScraper
from community.scrapers.tehachapi import TehachapiScraper
from community.scrapers.calcity import CalCityScraper
from community.scrapers.kerncounty import KernCountyScraper
from community.scrapers.bakersfield import BakersfieldScraper
from community.scrapers.lancaster import LancasterScraper
from community.scrapers.schools import MojaveUSDScraper

logger = logging.getLogger("scrapers")

SCRAPERS = {
    "ridgecrest": RidgecrestScraper,
    "tehachapi": TehachapiScraper,
    "calcity": CalCityScraper,
    "kerncounty": KernCountyScraper,
    "bakersfield": BakersfieldScraper,
    "lancaster": LancasterScraper,
    "schools": MojaveUSDScraper,
}


class Command(BaseCommand):
    help = "Scrape nearby city websites for agendas, events, and news"

    def add_arguments(self, parser):
        parser.add_argument(
            "--city",
            choices=list(SCRAPERS.keys()) + ["all"],
            default="calcity",
            help="Which city to scrape (default: calcity)",
        )
        parser.add_argument(
            "--quiet",
            action="store_true",
            help="Suppress per-item output",
        )
        parser.add_argument(
            "--verbose",
            action="store_true",
            help="Show detail-level output",
        )

    def handle(self, **options):
        city_arg = options["city"]
        verbose = options.get("verbose", False)
        quiet = options.get("quiet", False)

        if verbose:
            logging.basicConfig(level=logging.DEBUG, format="%(message)s")
        elif not quiet:
            logging.basicConfig(level=logging.INFO, format="%(message)s")

        cities = (
            list(SCRAPERS.keys())
            if city_arg == "all"
            else [city_arg]
        )

        grand_total = {"agendas": 0, "events": 0, "news": 0, "businesses": 0, "errors": 0}

        for city_key in cities:
            scraper_cls = SCRAPERS[city_key]
            self.stdout.write(f"\n--- {scraper_cls.CITY_NAME} ---")

            try:
                scraper = scraper_cls()
                stats = scraper.scrape()

                for k in grand_total:
                    grand_total[k] += stats.get(k, 0)

                self.stdout.write(
                    f"  {scraper_cls.CITY_NAME}: "
                    f"agendas={stats.get('agendas',0)} "
                    f"events={stats.get('events',0)} "
                    f"news={stats.get('news',0)} "
                    f"businesses={stats.get('businesses',0)} "
                    f"errors={stats.get('errors',0)}"
                )
            except Exception as e:
                self.stderr.write(f"  FAILED: {e}")
                grand_total["errors"] += 1

        self.stdout.write(
            f"\n{'='*50}\n"
            f"TOTAL: agendas={grand_total['agendas']} "
            f"events={grand_total['events']} "
            f"news={grand_total['news']} "
            f"businesses={grand_total['businesses']} "
            f"errors={grand_total['errors']}"
        )
