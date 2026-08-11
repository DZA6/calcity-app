"""Live weather for the management dashboard — Open-Meteo, no API key.

The mobile app fetches Open-Meteo directly; this service gives the Django
dashboard the same live data (current conditions + today's forecast) so the
dashboard weather changes through the day instead of only when someone
manually posts an update.

Fetches are cached for 20 minutes (per-process LocMemCache is fine here —
the dashboard is low-traffic; worst case is one extra fetch per process).
Manual advisory posts (fire risk, heat advisories) live on WeatherInfo and
are shown alongside.
"""
import json
from datetime import datetime
from urllib.request import urlopen

from django.core.cache import cache

LAT, LON = 35.1258, -117.9859  # California City, CA
CACHE_KEY = "calcity_live_weather"
CACHE_TTL = 20 * 60  # 20 minutes

# WMO weather codes -> (label, emoji)
WMO = {
    0: ("Clear", "\u2600\ufe0f"),
    1: ("Mostly clear", "\u2600\ufe0f"),
    2: ("Partly cloudy", "\u26c5"),
    3: ("Overcast", "\u2601\ufe0f"),
    45: ("Fog", "\ud83c\udf2b\ufe0f"),
    48: ("Fog", "\ud83c\udf2b\ufe0f"),
    51: ("Drizzle", "\ud83c\udf27\ufe0f"),
    53: ("Drizzle", "\ud83c\udf27\ufe0f"),
    55: ("Drizzle", "\ud83c\udf27\ufe0f"),
    61: ("Rain", "\ud83c\udf27\ufe0f"),
    63: ("Rain", "\ud83c\udf27\ufe0f"),
    65: ("Rain", "\ud83c\udf27\ufe0f"),
    80: ("Showers", "\ud83c\udf27\ufe0f"),
    81: ("Showers", "\ud83c\udf27\ufe0f"),
    82: ("Showers", "\ud83c\udf27\ufe0f"),
    95: ("Thunderstorm", "\u26c8\ufe0f"),
    96: ("Storm", "\u26c8\ufe0f"),
    99: ("Storm", "\u26c8\ufe0f"),
}

API_URL = (
    "https://api.open-meteo.com/v1/forecast"
    f"?latitude={LAT}&longitude={LON}"
    "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m"
    "&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset"
    "&temperature_unit=fahrenheit&wind_speed_unit=mph"
    "&timezone=America%2FLos_Angeles&forecast_days=1"
)


def _fmt_time(iso):
    try:
        dt = datetime.fromisoformat(iso)
    except (TypeError, ValueError):
        return ""
    h = dt.hour % 12 or 12
    return f"{h}:{dt.minute:02d} {'PM' if dt.hour >= 12 else 'AM'}"


def _fetch():
    with urlopen(API_URL, timeout=12) as resp:
        data = json.loads(resp.read())
    cur = data.get("current", {})
    daily = data.get("daily", {})
    code = int(cur.get("weather_code", 0))
    label, emoji = WMO.get(code, ("Unknown", "\u2753"))
    return {
        "temp": round(cur.get("temperature_2m", 0)),
        "feels_like": round(cur.get("apparent_temperature", 0)),
        "condition": label,
        "emoji": emoji,
        "humidity": cur.get("relative_humidity_2m"),
        "wind_mph": round(cur.get("wind_speed_10m", 0)),
        "is_day": cur.get("is_day") == 1,
        "high": round(daily.get("temperature_2m_max", [0])[0]),
        "low": round(daily.get("temperature_2m_min", [0])[0]),
        "sunrise": _fmt_time(daily.get("sunrise", [""])[0]),
        "sunset": _fmt_time(daily.get("sunset", [""])[0]),
        "updated": datetime.now(),
    }


def get_live_weather(force=False):
    """Return a dict of live weather, or None if the fetch fails.

    Cached for CACHE_TTL; pass force=True to bypass the cache.
    """
    if not force:
        cached = cache.get(CACHE_KEY)
        if cached:
            return cached
    try:
        data = _fetch()
    except Exception:
        return None
    cache.set(CACHE_KEY, data, CACHE_TTL)
    return data
