# CalCity — Security Review & Hardening Plan

Prepared 2026-08-12 by inspecting the actual codebase (Django 5.2 backend + Flutter
client). Findings are real (verified in code where noted), not hypothetical.

Severity: HIGH / MED / LOW.

---

## 1. Threat model

Attackers and their goals:
- **Spammers / bots** — flood accounts, post fake gigs/lost-pets, inflate likes.
- **Script kiddies** — look for exposed secrets, admin panels, open endpoints.
- **Competitors / scrapers** — harvest your curated business list & content.
- **Malicious content injection** — abuse auto-approved scraped news to publish
  phishing links or misinformation under your app's brand.
- **Device-level theft** — a stolen/rooted phone exposing the user's auth token.

Assets: user accounts, auth tokens, the business directory (255 city-licensed
businesses), council agendas, and the app's trust/rating.

---

## 2. Backend findings (Django)

### HIGH-1 — Hardcoded SECRET_KEY fallback
`backend/settings.py` line ~20 falls back to
`django-insecure-z&8*6ka!...` if `DJANGO_SECRET_KEY` isn't set. If PythonAnywhere
hasn't set this env var, session/signature forging and cookie tampering become
possible.
Fix: confirm `DJANGO_SECRET_KEY` is set in the PA WSGI file, and remove the
insecure default (or make DEBUG/secret fail closed when unset in prod).

### HIGH-2 — Legacy registration bypasses email verification
`/api/register/` returns a DRF token immediately (no email check). A second,
correct endpoint `/api/auth/register/` (EmailVerificationToken) exists but the
Flutter app still calls the legacy one. This lets anyone mint unlimited accounts →
spam discussions, manipulate reaction counts, and hit authenticated endpoints.
Fix: point `AuthProvider`/`api_service.dart` at `/api/auth/register/`, add a
"verify your email" screen, and either remove or rate-limit the legacy endpoint.

### MED-3 — Unmoderated auto-approval of scraped content
`scrapers/base.py` + `scrape_kern_news.py` create `NewsItem(is_approved=True)`.
Scraped text can include cookie banners, ads, or outright malicious content, and it
publishes instantly with no human review.
Fix: default `is_approved=False`, add a confidence score (content length, keyword
presence, trafilatura parse quality); auto-approve only above a high threshold
(roadmap Phase 2).

### MED-4 — SQLite single-writer lock (availability)
Concurrent writes (scraper cron + a user toggling a reaction/comment/tip) can hit
`sqlite3.OperationalError: database is locked` → 500s. On PA's shared infra this is
a cheap DoS.
Fix: migrate to PostgreSQL/MySQL (roadmap Phase 1), or at minimum wrap writes with
`timeout` and retry.

### MED-5 — Rate-limit enforcement semantics
Tips use `@ratelimit(..., block=False)` + a manual 429 (correct). Verify the same
is true for register (3/h), topics (30/h), comments (60/h), and that `block=True`
isn't silently dropping legitimate PA-shared-IP traffic. A bypass = unbounded
account/content spam.

### LOW-6 — CORS and ALLOWED_HOSTS are environment-dependent
Dev fallback allows `localhost` + `*` when `CALCITY_CORS_ORIGINS=*`. Production
should pin an explicit allow-list, not `*`, and `pa_wsgi.py` builds ALLOWED_HOSTS
via fragile string manipulation (a stray newline = `DisallowedHost`).

### LOW-7 — Video FileField isn't MIME-restricted
`NewsItem.video` is a generic `FileField`. It's admin-uploaded only, but a bad
actor with admin access (or a compromised account) could host arbitrary files.

Positives already in place: `django-axes` brute-force lockout keyed on username
(for PA's shared IP), per-endpoint rate limits, HTTPS redirect, Django ORM (no raw
SQL → no SQLi), auto-escaped templates, and token-auth on write endpoints.

---

## 3. Flutter client findings

### HIGH-1 — Auth token stored in plaintext
`providers/auth_provider.dart` stores the token in `SharedPreferences` (unencrypted
XML on Android). Any app with storage access, backup, or a rooted device can read it.
Fix: switch to `flutter_secure_storage` (Android Keystore / iOS Keychain).

### MED-2 — No certificate pinning
The `http` client trusts the system store only → a MITM (e.g. public Wi-Fi) could
intercept credentials. Fix: pin the PA cert (or at minimum enforce HTTPS-only and
reject non-HTTPS API bases in release builds).

### LOW-3 — Release builds not obfuscated
Builds use plain `flutter build apk --release`. Add `--obfuscate
--split-debug-info=...` to raise the bar on reverse-engineering (API schema, ad
logic). Consider `flutter build appbundle` for Play Store.

### LOW-4 — Secrets hygiene
`google-services.json` and AdMob IDs are client-side by design (fine), but the
Firebase *service-account* JSON must never ship in the APK — verify it's only in
`firebase-service-account.json` on the server. Ensure test ad IDs aren't the
shipping default when monetizing.

---

## 4. Prioritized hardening checklist

1. Verify/set `DJANGO_SECRET_KEY` + `DEBUG=False` + explicit `ALLOWED_HOSTS` on PA.
2. Switch the app to `/api/auth/register/` (email verification); retire legacy route.
3. Move auth token to `flutter_secure_storage`.
4. Default scraper `is_approved=False` + confidence scoring.
5. Migrate SQLite → PostgreSQL (also fixes the lock contention).
6. Audit every rate-limited endpoint for correct 429 enforcement; pin CORS origins.
7. Obfuscate + (optionally) pin certs in release builds.

Each item is small and independently shippable; 1–3 are the highest ROI and can be
done without a DB change.
