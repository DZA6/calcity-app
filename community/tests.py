"""
CalCity canonical test suite — cover the backend logic without network.

Categories:
  - Scraper parse logic (fixtures, no HTTP)
  - API views & response shapes
  - Security (axes lockout, rate limits, auth, staff-only endpoints)
  - FCM no-op safety
  - Model field / category-map integrity
"""
import os
import re
from datetime import datetime

from django.contrib.auth.models import User
from django.test import TestCase, Client, override_settings

from community.models import Alert, Business, Event, NewsItem, School
from axes.models import AccessAttempt, AccessLog


# ── Security — axes lockout + rate limits ───────────────────────────

class SecurityTests(TestCase):
    """Login brute-force lockout + rate-limited registration/tips."""

    def setUp(self):
        self.c = Client(HTTP_HOST="localhost")
        AccessAttempt.objects.all().delete()
        AccessLog.objects.all().delete()
        self.user = User.objects.create_user("securtest", password="CorrectHorse1!")

    # -- login --
    def test_bad_login_returns_401(self):
        r = self.c.post(
            "/api/auth/login/",
            {"username": "securtest", "password": "WrongPass1!"},
            content_type="application/json",
        )
        self.assertEqual(r.status_code, 401)
        self.assertIn("error", r.json())

    def test_good_login_returns_token(self):
        r = self.c.post(
            "/api/auth/login/",
            {"username": "securtest", "password": "CorrectHorse1!"},
            content_type="application/json",
        )
        self.assertEqual(r.status_code, 200)
        self.assertIn("token", r.json())

    def test_axes_locks_account_after_five_failures(self):
        for _ in range(5):
            self.c.post(
                "/api/auth/login/",
                {"username": "securtest", "password": "WrongPass1!"},
                content_type="application/json",
            )
        # 6th attempt with the CORRECT password — must still fail
        # because the IP is locked out (authenticate() rejects it).
        r = self.c.post(
            "/api/auth/login/",
            {"username": "securtest", "password": "CorrectHorse1!"},
            content_type="application/json",
        )
        self.assertNotEqual(r.status_code, 200)
        self.assertEqual(r.status_code, 401)
        self.assertIn("Invalid username/email or password", r.json()["error"])

    # -- registration rate limit (3/h per IP) --
    def test_register_rate_limit_triggers(self):
        """4th POST from the same IP should hit the 3/h rate limit."""
        bodies = []
        for i in range(4):
            r = self.c.post(
                "/api/auth/register/",
                {
                    "username": f"rtest_{i}",
                    "email": f"rtest_{i}@example.com",
                    "password": "CorrectHorse1!",
                },
                content_type="application/json",
            )
            bodies.append((r.status_code, r.json()))
            if r.status_code == 429:
                break
        # The 4th request must be a 429 (first 3 OK or 409 for dup, 4th blocked)
        self.assertTrue(any(s == 429 for s, _ in bodies),
                        f"no 429 among {[s for s,_ in bodies]}")

    # -- tip submission rate limit (10/h per IP) --
    def test_tip_rate_limit_triggers(self):
        for i in range(11):
            r = self.c.post(
                "/api/tips/",
                {"content": f"tip {i}", "category": "general"},
                content_type="application/json",
            )
            if r.status_code == 429:
                # Hit the limit — pass
                return
        self.fail("Expected 429 after 11 tips from same IP")

    # -- staff-only endpoint --
    def test_alert_push_unauthenticated_redirects(self):
        alert = Alert.objects.create(
            title="Test", message="body", severity="info", is_active=True,
        )
        r = self.c.post(f"/manage/alerts/{alert.pk}/push/")
        self.assertEqual(r.status_code, 302)

    def test_alert_push_staff_returns_json(self):
        staff = User.objects.create_user("staffer", is_staff=True, password="x")
        alert = Alert.objects.create(
            title="Test", message="body", severity="info", is_active=True,
        )
        self.c.force_login(staff)
        r = self.c.post(f"/manage/alerts/{alert.pk}/push/")
        self.assertEqual(r.status_code, 200)
        self.assertFalse(r.json()["ok"])  # FCM not configured


# ── FCM no-op safety ────────────────────────────────────────────────

class FcmNoOpTests(TestCase):
    """Firebase messaging module must never crash — safe no-op."""

    def test_no_config_returns_false(self):
        from community.firebase_messaging import send_topic_message
        ok, detail = send_topic_message("t", "b")
        self.assertFalse(ok)
        self.assertIn("not configured", detail)

    def test_missing_key_file_returns_false(self):
        from community.firebase_messaging import send_topic_message
        os.environ["FIREBASE_SERVICE_ACCOUNT_PATH"] = "/nonexistent/key.json"
        ok, detail = send_topic_message("t", "b")
        os.environ.pop("FIREBASE_SERVICE_ACCOUNT_PATH")
        self.assertFalse(ok)

    def test_broken_inline_json_returns_false(self):
        from community.firebase_messaging import send_topic_message
        os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"] = "{not valid json"
        ok, detail = send_topic_message("t", "b")
        os.environ.pop("FIREBASE_SERVICE_ACCOUNT_JSON")
        self.assertFalse(ok)


# ── Scraper parse logic (no network) ────────────────────────────────

class ScraperParseTests(TestCase):
    """Regression tests for the regex-based parsers in the scrapers."""

    def test_city_calendar_us_date_format(self):
        """08.11.2026 = Aug 11, 2026 (US MM.DD.YYYY)."""
        pattern = re.compile(
            r"## \[([^\]]+)\]\(([^)]+)\)\s*\n\s*(\d{2})\.(\d{2})\.(\d{4})"
        )
        fixture = (
            "## [City Council Meeting](https://www.californiacity-ca.gov/CC/index.php/cityconnection2/city-calendar/city-council-meeting-20150904180000-1786424400)\n"
            "08.11.2026  Monthly on the 2nd Tuesday and 4th Tuesday for 300 times  City Calendar   630 Hits\n"
        )
        m = pattern.search(fixture)
        self.assertIsNotNone(m)
        mm, dd, yyyy = int(m.group(3)), int(m.group(4)), int(m.group(5))
        self.assertEqual((mm, dd, yyyy), (8, 11, 2026))
        self.assertEqual(m.group(1), "City Council Meeting")

    def test_school_pdf_parser_single_day(self):
        from community.scrapers.schools import MONTHS
        pat = re.compile(
            r"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.? (\d{1,2})"
            r"(?:\s*[-–]\s*[A-Za-z]{3,9}\.?\s*(\d{1,2}))?\s+([A-Z][A-Za-z0-9 ,'&()\/.-]+)"
        )
        fixture = "August    11 12 13 14 15    Aug 13 First Day of School\n"
        m = pat.search(fixture)
        self.assertIsNotNone(m)
        title = re.sub(r"\s+(?:\d+\s*)+$", "", m.group(4).strip().rstrip(".")).strip()
        self.assertEqual(MONTHS[m.group(1)[:3].lower()], 8)
        self.assertEqual(int(m.group(2)), 13)
        self.assertEqual(title, "First Day of School")

    def test_school_pdf_parser_multi_day(self):
        from community.scrapers.schools import MONTHS
        pat = re.compile(
            r"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.? (\d{1,2})"
            r"(?:\s*[-–]\s*[A-Za-z]{3,9}\.?\s*(\d{1,2}))?\s+([A-Z][A-Za-z0-9 ,'&()\/.-]+)"
        )
        fixture = "November    24 25 26 27 28    Nov 24 - Nov 28 Thanksgiving Break\n"
        m = pat.search(fixture)
        self.assertIsNotNone(m)
        title = re.sub(r"\s+(?:\d+\s*)+$", "", m.group(4).strip().rstrip(".")).strip()
        self.assertEqual(MONTHS[m.group(1)[:3].lower()], 11)
        self.assertEqual(int(m.group(2)), 24)
        self.assertEqual(int(m.group(3)), 28)  # end-day
        self.assertEqual(title, "Thanksgiving Break")

    def test_school_pdf_parser_trailing_digits_stripped(self):
        """The PDF's Days-Taught/Holiday columns trail as numbers."""
        pat = re.compile(
            r"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.? (\d{1,2})"
            r"(?:\s*[-–]\s*[A-Za-z]{3,9}\.?\s*(\d{1,2}))?\s+([A-Z][A-Za-z0-9 ,'&()\/.-]+)"
        )
        # Sept 19 entry with trailing "19 1 1" from the Days/Holiday table
        fixture = "September   15 16 17 18 19   Sept 19 Inclement Weather Day 19 1 1\n"
        m = pat.search(fixture)
        self.assertIsNotNone(m)
        title = re.sub(r"\s+(?:\d+\s*)+$", "", m.group(4).strip().rstrip(".")).strip()
        self.assertEqual(title, "Inclement Weather Day")

    def test_business_directory_regex(self):
        """Server-rendered Joomla business-table row parsing."""
        fixture = (
            '<tr>'
            '<td style="vertical-align: top; text-align: justify;">'
            '<p><span style="color: #000000; font-family: Helvetica Neue; font-size: small;">'
            '<b>680095</b></span></p>'
            '</td>'
            '<td style="vertical-align: top;">&nbsp; &nbsp;&nbsp;</td>'
            '<td style="vertical-align: top;">'
            '<p><span style="color: #000000; font-family: Helvetica Neue; font-size: small;">'
            '2nd Hand Shack</span></p>'
            '</td>'
            '<td style="vertical-align: top;">'
            '<p><span style="color: #000000; font-family: Helvetica Neue; font-size: small;">'
            '760-373-5988</span></p>'
            '</td>'
            '<td style="vertical-align: top;">'
            '<p><span style="color: #000000; font-family: Helvetica Neue; font-size: small;">'
            'Retail</span></p>'
            '</td>'
            '</tr>'
        )
        import html as html_mod

        def clean(cell):
            txt = re.sub(r"<[^>]+>", "", cell)
            txt = html_mod.unescape(txt).replace("&nbsp;", " ")
            return " ".join(txt.split())

        cells = re.findall(r"<td[^>]*>(.*?)</td>", fixture, re.S)
        self.assertEqual(len(cells), 5)
        acct, _, name, phone, desc = [clean(c) for c in cells[:5]]
        self.assertEqual(name, "2nd Hand Shack")
        self.assertEqual(phone, "760-373-5988")
        self.assertEqual(desc, "Retail")

    def test_city_category_map_all_valid(self):
        from community.scrapers.calcity import CITY_CATEGORY_MAP

        valid = {c for c, _ in Business.CATEGORY_CHOICES}
        for raw_cat, app_cat in CITY_CATEGORY_MAP.items():
            self.assertIn(app_cat, valid,
                          f"{raw_cat!r} maps to {app_cat!r}, not in {valid}")

    def test_schools_imports_without_errors(self):
        """Smoke test — the scraper module must load cleanly."""
        from community.scrapers.schools import MojaveUSDScraper, MONTHS  # noqa: F811
        self.assertTrue(hasattr(MojaveUSDScraper, "scrape"))


# ── API views & model integrity ─────────────────────────────────────

class ApiViewTests(TestCase):
    """Public API endpoints return the right shape and filtering."""

    @classmethod
    def setUpTestData(cls):
        Business.objects.create(
            name="TestBiz", category="local_shop", is_approved=True,
            contact_phone="555-0100",
        )
        Business.objects.create(
            name="UnapprovedBiz", category="service", is_approved=False,
        )
        Event.objects.create(
            title="TestEvent", location="Test", category="community",
            start_date=datetime(2026, 8, 15, 12, 0), is_approved=True,
        )
        School.objects.create(
            name="TestSchool", type="high", is_approved=True,
            calendar_url="http://cal.example.com",
            bell_schedule_url="http://bell.example.com",
        )
        Alert.objects.create(
            title="Alert", message="msg", severity="info", is_active=True,
        )

    def setUp(self):
        self.c = Client(HTTP_HOST="localhost")

    def test_health(self):
        r = self.c.get("/api/health/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json(), {"status": "ok"})

    def test_businesses_excludes_unapproved(self):
        r = self.c.get("/api/businesses/")
        self.assertEqual(r.status_code, 200)
        data = r.json()
        names = [b["name"] for b in data]
        self.assertIn("TestBiz", names)
        self.assertNotIn("UnapprovedBiz", names)

    def test_events_approved_only(self):
        r = self.c.get("/api/events/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(len(r.json()), 1)

    def test_schools_includes_calendar_bell_urls(self):
        r = self.c.get("/api/schools/")
        self.assertEqual(r.status_code, 200)
        s = r.json()[0]
        self.assertEqual(s["calendar_url"], "http://cal.example.com")
        self.assertEqual(s["bell_schedule_url"], "http://bell.example.com")

    def test_alerts_active_only(self):
        r = self.c.get("/api/alerts/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(len(r.json()), 1)


# ── Axes / DRF config integrity ─────────────────────────────────────

class ConfigTests(TestCase):
    """Verify that security-mandatory settings are present at import time."""

    def test_axes_in_installed_apps(self):
        from django.conf import settings
        self.assertIn("axes", settings.INSTALLED_APPS)

    def test_axes_middleware_present(self):
        from django.conf import settings
        self.assertIn("axes.middleware.AxesMiddleware", settings.MIDDLEWARE)

    def test_axes_standalone_backend_first(self):
        from django.conf import settings
        self.assertTrue(
            settings.AUTHENTICATION_BACKENDS[0].endswith("AxesStandaloneBackend"),
        )

    def test_sentry_noop_without_dsn(self):
        from django.conf import settings
        self.assertEqual(settings.SENTRY_DSN, "")
