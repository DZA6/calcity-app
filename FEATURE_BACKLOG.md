# CalCity — Feature & Fix Backlog

Captured 2026-08-12 from the user's request list. Grounded in the current codebase
(repo @ DZA6/calcity-app, local clone ~/calcity-app).

Legend: [QF] quick fix · [MED] medium feature · [LARGE] large feature · [RES] research
Status: OPEN / IN PROGRESS / DONE

---

## 1. [QF] Fix "old image" flash before weather widget  — OPEN
- Root cause: `home_screen.dart` `_weatherHero()` returns `_staticHero()` while
  `_liveWeather == null` (async Open-Meteo fetch not done yet), then swaps to the
  live gradient card once loaded → user sees the static image first.
- Fix: show a themed skeleton/shimmer while loading, or cache last weather and
  animate the transition instead of a hard image→widget swap.

## 2. [QF] Seed examples for "Lost Pets" + "Gigs"  — OPEN
- `seed_content.py` seeds no NewsItem at all. Add NewsItem examples for
  `lost_pets` and `gigs` categories (a lost dog post, a yard-work gig, etc.).

## 3. [MED] Deals beyond food  — OPEN
- Deal model is generic (any Business); food is just what's posted. Add:
  - seed examples of non-food deals (auto, home services, retail, etc.)
  - a category filter in `deals_screen.dart` (serializer already exposes
    `business_category`).

## 4. [MED] Alerts/notices: recurring cron updates  — OPEN
- Scrapers (`scrape_kern_news`, `scrape_cities`) + `post_topic` write to whichever
  DB the command runs against. For PRODUCTION they must run on PythonAnywhere
  (Tasks tab / Scheduled Tasks), not this machine.
- Deliver: exact PA Scheduled Tasks config (hourly news, daily 8am topic, and any
  alert/notice rotation), plus Hermes cron on this box for dev parity.

## 5. [MED] Council: yearly filter + video fix  — OPEN (needs clarification)
- Model `CouncilAgenda` has only `pdf_url`, no video field; "View Agenda" opens the
  PDF externally. NEED TO CONFIRM where the "video" lives (a NewsItem video? a URL
  stored in pdf_url? new field needed?).
- Yearly filter: add `?year=` to `CouncilAgendaViewSet` + year chips in
  `council_screen.dart` (2024 / 2025 / 2026 / All).

## 6. [QF] Light-theme neon-green text  — OPEN
- Default accent = 'neon' (#00FF41), used as `primary` on light background.
- Fix: change the 'neon' palette value to a readable green (fixes existing users
  via stored key), change the default, and update hardcoded neon colors in the
  home drawer (`#00FF41`, `#76FF03`).

## 7. [MED] Education: per-school detail with buttons  — OPEN
- Add a SchoolDetailScreen with buttons: Schedule (bell_schedule_url), Calendar
  (calendar_url), Information (description/address/phone/website), News (news
  filtered by school), etc. Data-driven for all schools (currently 4 in seed).

## 8. [LARGE] Explore: full month calendar + reminders  — OPEN
- Replace the horizontal date chips in `ExploreScreen` (main.dart) with a real
  month calendar (table_calendar pkg or custom). Click a date → events that day.
- Add "set reminder/alarm" per event → needs `flutter_local_notifications` +
  timezone + permission plumbing.

## 9. [LARGE] Church/Faith: churches up front in tabs  — OPEN
- Currently "church" is just a NewsItem category. Needs a `Church` model (name,
  denomination, address, phone, website, service times, events, food giveaways),
  migration, API, and a screen with tabs → detail.

## 10. [RES] Mobile backend dashboard (admin/staff)  — OPEN
- Research options: mobile-friendly Django admin vs custom Flutter admin app vs
  headless-CMS/low-code (Budibase/Retool/Appsmith). Deliver a recommendation.

## 11. [MED] Settings: new actions  — OPEN
- Add to Settings: Report a bug · Request info removal/update · Sign up for
  Business promotion · Sign up for Freelancer promotion.
- Backend: reuse/extend CommunityTip or new request models; frontend: forms.

## 12. [RES] App security research  — OPEN
- Threat model + hardening for Django (SQLite locking, auth, rate limiting, CORS,
  admin access) and Flutter (token storage, cert pinning, obfuscation). Deliver a
  written assessment + prioritized fixes.

---

## Proposed sequencing
1. Quick wins first: #6 (theme), #2 (seed), #5-filter (year, once video clarified),
   #11 (settings).
2. Medium: #3 (deals), #4 (cron), #7 (education).
3. Large: #8 (calendar), #9 (church).
4. Research in parallel: #10 (dashboard), #12 (security) — can run as background
   tasks while features are built.
