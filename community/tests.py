"""
CalCity canonical test suite — cover the backend logic without network.

Categories:
  - Scraper parse logic (fixtures, no HTTP)
  - API views & response shapes
  - Security (axes lockout, rate limits, auth, staff-only endpoints)
  - FCM no-op safety
  - Model field / category-map integrity
"""
import json
import os
import re
from datetime import datetime

from django.contrib.auth.models import User
from django.contrib.contenttypes.models import ContentType
from django.test import TestCase, Client, override_settings
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from community.models import (
    Alert,
    Business,
    BusinessReview,
    Comment,
    DiscussionTopic,
    Event,
    NewsletterSubscriber,
    NewsItem,
    Reaction,
    School,
)
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

    def test_is_california_city_detection(self):
        from community.scrapers.base import is_california_city
        self.assertTrue(is_california_city("California City council approves budget"))
        self.assertTrue(is_california_city("Cal City road closure this weekend"))
        self.assertTrue(is_california_city("Community event in 93505"))
        self.assertFalse(is_california_city("Kern County opens new park"))
        self.assertFalse(is_california_city("Bakersfield local city news roundup"))
        self.assertFalse(is_california_city("Antelope Valley housing market update"))

    def test_save_news_auto_approves_only_calcity(self):
        from community.scrapers.calcity import CalCityScraper
        s = CalCityScraper()
        cal = s.save_news("California City park grand opening", "details",
                          source_url="http://example.com/1")
        other = s.save_news("Bakersfield mall expansion", "details",
                            source_url="http://example.com/2")
        self.assertIsNotNone(cal)
        self.assertTrue(cal.is_approved)
        self.assertIsNotNone(other)
        self.assertFalse(other.is_approved)

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


class ManagementNewsBulkTests(TestCase):
    """Staff dashboard bulk-delete endpoints (mass delete + delete-older-than)."""

    def setUp(self):
        from datetime import timedelta
        from django.utils import timezone
        from django.contrib.auth import get_user_model
        self.timedelta = timedelta
        self.timezone = timezone
        User = get_user_model()
        self.user = User.objects.create_user("staff", is_staff=True)
        self.c = Client(HTTP_HOST="localhost")
        self.c.force_login(self.user)

    def _make_article(self, days_old, title):
        n = NewsItem.objects.create(title=title, content="body", is_approved=True)
        NewsItem.objects.filter(pk=n.pk).update(
            created_at=self.timezone.now() - self.timedelta(days=days_old)
        )
        return n

    def test_bulk_delete_older(self):
        from django.urls import reverse
        self._make_article(200, "Very old article")
        self._make_article(5, "Recent article")
        cutoff = (self.timezone.localdate() - self.timedelta(days=90)).isoformat()
        r = self.c.post(reverse("manage:news_bulk_delete_older"), {"cutoff": cutoff})
        self.assertEqual(r.status_code, 302)
        self.assertFalse(NewsItem.objects.filter(title="Very old article").exists())
        self.assertTrue(NewsItem.objects.filter(title="Recent article").exists())

    def test_bulk_delete_older_requires_post(self):
        from django.urls import reverse
        r = self.c.get(reverse("manage:news_bulk_delete_older"))
        self.assertEqual(r.status_code, 405)


class EngagementEndpointTests(TestCase):
    """Classified submissions + newsletter subscription endpoints."""

    def setUp(self):
        self.c = Client(HTTP_HOST="localhost")

    def test_classified_creates_pending(self):
        r = self.c.post(
            "/api/classifieds/",
            data=json.dumps({
                "title": "Couch for sale",
                "content": "Good condition",
                "category": "for_sale",
            }),
            content_type="application/json",
        )
        self.assertEqual(r.status_code, 201)
        body = r.json()
        self.assertFalse(body["is_approved"])
        self.assertEqual(body["category"], "for_sale")

    def test_classified_rejects_other_category(self):
        r = self.c.post(
            "/api/classifieds/",
            data=json.dumps({"title": "x", "content": "y", "category": "general"}),
            content_type="application/json",
        )
        self.assertEqual(r.status_code, 400)

    def test_newsletter_subscribe_and_unsubscribe(self):
        r = self.c.post(
            "/api/newsletter/subscribe/",
            data=json.dumps({"email": "person@example.com"}),
            content_type="application/json",
        )
        self.assertEqual(r.status_code, 201)
        self.assertTrue(
            NewsletterSubscriber.objects.filter(
                email="person@example.com", is_active=True
            ).exists()
        )
        r2 = self.c.post(
            "/api/newsletter/unsubscribe/",
            data=json.dumps({"email": "person@example.com"}),
            content_type="application/json",
        )
        self.assertEqual(r2.status_code, 200)
        self.assertFalse(
            NewsletterSubscriber.objects.filter(
                email="person@example.com", is_active=True
            ).exists()
        )

    def test_news_full_endpoint(self):
        n = NewsItem.objects.create(
            title="Full test", content="short snippet", is_approved=True
        )
        r = self.c.get(f"/api/news/{n.pk}/full/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()["content"], "short snippet")

        hidden = NewsItem.objects.create(
            title="Hidden", content="x", is_approved=False
        )
        r2 = self.c.get(f"/api/news/{hidden.pk}/full/")
        self.assertEqual(r2.status_code, 404)

    def test_category_choices_include_classifieds(self):
        slugs = {c for c, _ in NewsItem.CATEGORY_CHOICES}
        self.assertIn("for_sale", slugs)
        self.assertIn("announcements", slugs)


class BusinessReviewTests(TestCase):
    """Business reviews: write (auth), list, rating aggregation."""

    def setUp(self):
        self.c = Client(HTTP_HOST="localhost")
        self.biz = Business.objects.create(
            name="ReviewBiz", category="local_shop", is_approved=True
        )
        self.user = User.objects.create_user("reviewer", password="pass")

    def test_review_requires_auth(self):
        r = self.c.post(
            f"/api/businesses/{self.biz.pk}/reviews/",
            data=json.dumps({"rating": 5, "body": "great"}),
            content_type="application/json",
        )
        self.assertIn(r.status_code, (401, 403))

    def test_create_and_list_review(self):
        self.c.force_login(self.user)
        r = self.c.post(
            f"/api/businesses/{self.biz.pk}/reviews/",
            data=json.dumps({"rating": 4, "body": "good"}),
            content_type="application/json",
        )
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.json()["rating"], 4)

        r2 = self.c.get(f"/api/businesses/{self.biz.pk}/reviews/")
        data = r2.json()
        self.assertEqual(data["count"], 1)
        self.assertEqual(data["average"], 4.0)
        self.assertEqual(data["reviews"][0]["rating"], 4)

        r3 = self.c.get("/api/businesses/")
        biz = next(b for b in r3.json() if b["id"] == self.biz.pk)
        self.assertEqual(biz["rating"], 4.0)
        self.assertEqual(biz["review_count"], 1)

    def test_update_existing_review(self):
        self.c.force_login(self.user)
        url = f"/api/businesses/{self.biz.pk}/reviews/"
        self.c.post(url, data=json.dumps({"rating": 3, "body": "meh"}),
                    content_type="application/json")
        r = self.c.post(url, data=json.dumps({"rating": 5, "body": "updated"}),
                        content_type="application/json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(
            BusinessReview.objects.filter(business=self.biz, author=self.user).count(), 1
        )
        self.assertEqual(r.json()["rating"], 5)


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


# ── Social: topics, comments, reactions ──────────────────────────────

class SocialTests(TestCase):
    """Discussion topics, comments on any content, like/dislike toggles."""

    def setUp(self):
        self.c = APIClient()
        self.user = User.objects.create_user(
            "socialuser", email="social@x.com", password="CorrectHorse1!"
        )
        self.token = Token.objects.create(user=self.user)
        self.news = NewsItem.objects.create(
            title="Test article", content="Body text", is_approved=True
        )
        self.event = Event.objects.create(
            title="Test event", description="Come!", location="Park",
            start_date="2026-09-01T18:00:00Z", category="community",
        )
        self.topic = DiscussionTopic.objects.create(
            title="First topic", body="Hello", author=self.user
        )
        self.news_ct = ContentType.objects.get_for_model(NewsItem)

    def _auth(self):
        self.c.credentials(HTTP_AUTHORIZATION=f"Token {self.token.key}")

    # -- topics --
    def test_topics_list_public(self):
        r = self.c.get("/api/topics/")
        self.assertEqual(r.status_code, 200)
        data = r.json()
        items = data["results"] if isinstance(data, dict) else data
        self.assertGreaterEqual(len(items), 1)
        first = items[0]
        self.assertEqual(first["title"], "First topic")
        self.assertEqual(first["author"], "socialuser")
        self.assertIn("comment_count", first)
        self.assertIn("likes", first)

    def test_create_topic_requires_auth(self):
        r = self.c.post("/api/topics/", {"title": "Anon", "body": "x"}, format="json")
        self.assertEqual(r.status_code, 401)  # NotAuthenticated

    def test_create_topic_sets_author(self):
        self._auth()
        r = self.c.post(
            "/api/topics/",
            {"title": "My topic", "body": "Details", "category": "news"},
            format="json",
        )
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.json()["author"], "socialuser")
        self.assertEqual(r.json()["category"], "news")
        self.assertEqual(DiscussionTopic.objects.count(), 2)

    # -- comments --
    def test_comments_list_filtered_by_target(self):
        Comment.objects.create(
            content_type=self.news_ct, object_id=self.news.id,
            author=self.user, body="Nice article",
        )
        r = self.c.get(f"/api/comments/?content_type=news&object_id={self.news.id}")
        self.assertEqual(r.status_code, 200)
        items = r.json()["results"]  # paginated
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["body"], "Nice article")
        self.assertEqual(items[0]["author"], "socialuser")
        self.assertEqual(items[0]["content_type"], "news")

    def test_comment_requires_auth(self):
        r = self.c.post(
            "/api/comments/",
            {"content_type": "news", "object_id": self.news.id, "body": "hi"},
            format="json",
        )
        # Unauthenticated + global TokenAuthentication -> 401 NotAuthenticated
        self.assertEqual(r.status_code, 401)

    def test_comment_on_missing_item_400(self):
        self._auth()
        r = self.c.post(
            "/api/comments/",
            {"content_type": "news", "object_id": 999999, "body": "hi"},
            format="json",
        )
        self.assertEqual(r.status_code, 400)

    def test_create_comment_and_reply(self):
        self._auth()
        r1 = self.c.post(
            "/api/comments/",
            {"content_type": "news", "object_id": self.news.id, "body": "First!"},
            format="json",
        )
        self.assertEqual(r1.status_code, 201)
        cid = r1.json()["id"]
        r2 = self.c.post(
            "/api/comments/",
            {"content_type": "news", "object_id": self.news.id,
             "body": "Reply", "parent": cid},
            format="json",
        )
        self.assertEqual(r2.status_code, 201)
        self.assertEqual(r2.json()["parent"], cid)
        r3 = self.c.get(f"/api/comments/?content_type=news&object_id={self.news.id}")
        self.assertEqual(len(r3.json()["results"]), 2)

    def test_delete_own_comment_only(self):
        self._auth()
        r = self.c.post(
            "/api/comments/",
            {"content_type": "news", "object_id": self.news.id, "body": "Mine"},
            format="json",
        )
        cid = r.json()["id"]
        other = User.objects.create_user("otheruser", password="CorrectHorse1!")
        t2 = Token.objects.create(user=other)
        self.c.credentials(HTTP_AUTHORIZATION=f"Token {t2.key}")
        self.assertEqual(self.c.delete(f"/api/comments/{cid}/").status_code, 403)
        self.c.credentials(HTTP_AUTHORIZATION=f"Token {self.token.key}")
        self.assertEqual(self.c.delete(f"/api/comments/{cid}/").status_code, 204)
        self.assertEqual(Comment.objects.count(), 0)

    # -- reactions --
    def test_reaction_toggle_like(self):
        self._auth()
        r = self.c.post(
            "/api/reactions/toggle/",
            {"content_type": "news", "object_id": self.news.id, "value": "like"},
            format="json",
        )
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()["likes"], 1)
        self.assertEqual(r.json()["my_value"], "like")
        # same value again → removed
        r2 = self.c.post(
            "/api/reactions/toggle/",
            {"content_type": "news", "object_id": self.news.id, "value": "like"},
            format="json",
        )
        self.assertEqual(r2.json()["likes"], 0)
        self.assertIsNone(r2.json()["my_value"])
        # switch to dislike
        r3 = self.c.post(
            "/api/reactions/toggle/",
            {"content_type": "news", "object_id": self.news.id, "value": "dislike"},
            format="json",
        )
        self.assertEqual(r3.json()["dislikes"], 1)
        self.assertEqual(r3.json()["my_value"], "dislike")

    def test_reaction_requires_auth(self):
        r = self.c.post(
            "/api/reactions/toggle/",
            {"content_type": "news", "object_id": self.news.id, "value": "like"},
            format="json",
        )
        self.assertEqual(r.status_code, 401)

    def test_reaction_summary_public(self):
        self._auth()
        self.c.post(
            "/api/reactions/toggle/",
            {"content_type": "event", "object_id": self.event.id, "value": "like"},
            format="json",
        )
        self.c.credentials()  # anonymous
        r = self.c.get(
            f"/api/reactions/summary/?content_type=event&object_id={self.event.id}"
        )
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()["likes"], 1)
        self.assertIsNone(r.json()["my_value"])

    def test_reaction_bulk(self):
        self._auth()
        self.c.post(
            "/api/reactions/toggle/",
            {"content_type": "news", "object_id": self.news.id, "value": "like"},
            format="json",
        )
        r = self.c.get(
            f"/api/reactions/bulk/?targets=news:{self.news.id},"
            f"event:{self.event.id},bogus:1"
        )
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()[f"news:{self.news.id}"]["likes"], 1)
        self.assertNotIn("bogus:1", r.json())

    def test_reactions_unique_per_user(self):
        self._auth()
        self.c.post(
            "/api/reactions/toggle/",
            {"content_type": "news", "object_id": self.news.id, "value": "like"},
            format="json",
        )
        self.c.post(
            "/api/reactions/toggle/",
            {"content_type": "news", "object_id": self.news.id, "value": "dislike"},
            format="json",
        )
        self.assertEqual(
            Reaction.objects.filter(content_type=self.news_ct, object_id=self.news.id).count(),
            1,
        )
