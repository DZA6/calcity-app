# CalCity — Ops Runbook (Scheduled Tasks + Staff Tools)

Two things: (A) keeping content fresh automatically, and (B) giving staff a way to
manage the app from a phone.

---

## A. Content freshness — scheduled tasks

The scrapers and daily-topic poster write to **whichever database they run
against**. Your live app reads the PythonAnywhere (PA) database, so for production
these MUST run as PA "Scheduled Tasks" (Tasks tab), not on this dev machine.

In the PA **Tasks tab**, add these (paths use your PA username MMSantelopevalley):

| Frequency | Command |
|-----------|---------|
| Hourly    | `cd /home/MMSantelopevalley/calcity-app && /home/MMSantelopevalley/.virtualenvs/<venv>/bin/python manage.py scrape_kern_news` |
| Daily 08:00 | `cd /home/MMSantelopevalley/calcity-app && /home/MMSantelopevalley/.virtualenvs/<venv>/bin/python manage.py post_topic` |
| Daily 02:00 | `cd /home/MMSantelopevalley/calcity-app && /home/MMSantelopevalley/.virtualenvs/<venv>/bin/python manage.py scrape_cities --city calcity` |
| Daily 03:00 | `cd /home/MMSantelopevalley/calcity-app && /home/MMSantelopevalley/.virtualenvs/<venv>/bin/python manage.py expire_stale_alerts` |

Notes:
- `<venv>` is the virtualenv name you created on PA (run `workon` or check the
  Web tab to find it).
- `scrape_kern_news` fetches 12 Google News feeds (Kern, Antelope Valley, food
  giveaways, church outreach, school giveaways, etc.) and dedupes.
- `post_topic` posts the daily community discussion prompt as the `CalCityDaily`
  bot and rotates pinned topics.
- `expire_stale_alerts` (new) deactivates alerts older than 14 days so the Alerts
  feed doesn't show a stale "All Clear" forever.

Dev parity (optional, local only): the same commands can run via Hermes cron on
this box, but they only update the local `db.sqlite3`, so it's for testing only.

---

## B. Mobile staff dashboard (recommendation)

Goal: let admin/staff update content and push notifications from their phone,
without a desk.

Options, in order of effort:

1. **Make the existing `/manage/` dashboard mobile-friendly (recommended first).**
   The app already has a custom staff dashboard (`community/management_views.py`)
   at `/manage/` with a "Send Push" button. Add responsive CSS + a PWA manifest so
   staff can "Add to Home Screen" and use it like a native app. Zero new
   infrastructure, works today.

2. **Native staff mode inside the existing Flutter app.**
   Add a role-gated "Staff" area (login → admin screens) that reuses the DRF API
   and the existing Firebase push plumbing. Best UX + native push-from-phone, but
   the most build work.

3. **Low-code layer (Budibase / Appsmith / Retool).** Point at the DRF API for a
   drag-and-drop admin UI. Fast to stand up, but adds a third-party dependency/cost
   and a generic (non-native) mobile experience.

Recommendation: ship option 1 now (responsive `/manage/` + PWA), and treat option 2
as a follow-up if staff want a true native experience. Both reuse the exact
same backend endpoints, so no rework.
