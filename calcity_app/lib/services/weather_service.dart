import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Live weather for California City, CA — fetched directly from
/// Open-Meteo (free, no API key) so conditions update through the day.
class HourlyForecast {
  final DateTime time;
  final int temp;
  final int code;
  final int precipProb;

  const HourlyForecast({
    required this.time,
    required this.temp,
    required this.code,
    required this.precipProb,
  });
}

class LiveWeather {
  final int temp; // °F now
  final int feelsLike; // °F apparent
  final int humidity; // %
  final double windMph;
  final bool isDay;
  final int conditionCode; // WMO code
  final int highToday;
  final int lowToday;
  final String sunrise;
  final String sunset;
  final List<HourlyForecast> hourly;
  final DateTime fetchedAt;

  const LiveWeather({
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windMph,
    required this.isDay,
    required this.conditionCode,
    required this.highToday,
    required this.lowToday,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
    required this.fetchedAt,
  });

  String get condition => _wmoInfo(conditionCode, isDay).$2;

  IconData get icon => wmoIcon(conditionCode, isDay);

  /// Public WMO-code → icon mapper (used by widgets).
  static IconData wmoIcon(int code, bool isDay) => _wmoInfo(code, isDay).$1;

  /// Hourly strip starting at the current hour (up to [count] entries).
  List<HourlyForecast> nextHours(int count) {
    final now = DateTime.now();
    final start = hourly.indexWhere((h) =>
        h.time.isAfter(now.subtract(const Duration(minutes: 30))));
    final from = start < 0 ? 0 : start;
    return hourly.skip(from).take(count).toList();
  }

  factory LiveWeather.fromJson(Map<String, dynamic> json) {
    final current = (json['current'] ?? {}) as Map<String, dynamic>;
    final hourlyRaw = (json['hourly'] ?? {}) as Map<String, dynamic>;
    final dailyRaw = (json['daily'] ?? {}) as Map<String, dynamic>;

    final times = (hourlyRaw['time'] as List?) ?? [];
    final temps = (hourlyRaw['temperature_2m'] as List?) ?? [];
    final codes = (hourlyRaw['weather_code'] as List?) ?? [];
    final precipp = (hourlyRaw['precipitation_probability'] as List?) ?? [];

    final hourly = <HourlyForecast>[];
    for (var i = 0; i < times.length; i++) {
      hourly.add(HourlyForecast(
        time: DateTime.parse(times[i] as String),
        temp: (temps[i] as num?)?.round() ?? 0,
        code: (codes[i] as num?)?.toInt() ?? 0,
        precipProb: (precipp[i] as num?)?.round() ?? 0,
      ));
    }

    final dailyTimes = (dailyRaw['time'] as List?) ?? [];
    final dailyMax = (dailyRaw['temperature_2m_max'] as List?) ?? [];
    final dailyMin = (dailyRaw['temperature_2m_min'] as List?) ?? [];
    final sunrises = (dailyRaw['sunrise'] as List?) ?? [];
    final sunsets = (dailyRaw['sunset'] as List?) ?? [];

    int? high, low;
    String sunrise = '', sunset = '';
    final nowDate = DateTime.now();
    for (var i = 0; i < dailyTimes.length; i++) {
      final d = DateTime.parse(dailyTimes[i] as String);
      if (d.year == nowDate.year && d.month == nowDate.month && d.day == nowDate.day) {
        high = (dailyMax[i] as num?)?.round();
        low = (dailyMin[i] as num?)?.round();
        final sr = (sunrises[i] as String?);
        final ss = (sunsets[i] as String?);
        if (sr != null && sr.isNotEmpty) {
          sunrise = _formatTime(DateTime.parse(sr));
        }
        if (ss != null && ss.isNotEmpty) {
          sunset = _formatTime(DateTime.parse(ss));
        }
      }
    }

    return LiveWeather(
      temp: (current['temperature_2m'] as num?)?.round() ?? 0,
      feelsLike: (current['apparent_temperature'] as num?)?.round() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.round() ?? 0,
      windMph: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      isDay: (current['is_day'] as num?)?.toInt() == 1,
      conditionCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      highToday: high ?? 0,
      lowToday: low ?? 0,
      sunrise: sunrise,
      sunset: sunset,
      hourly: hourly,
      fetchedAt: DateTime.now(),
    );
  }

  static String _formatTime(DateTime dt) {
    var h = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$min $ampm';
  }

  /// WMO weather code → (icon, short label).
  static (IconData, String) _wmoInfo(int code, bool isDay) {
    if (code == 0) {
      return isDay
          ? (Icons.wb_sunny_rounded, 'Clear')
          : (Icons.nightlight_round, 'Clear');
    }
    if (code == 1) {
      return isDay
          ? (Icons.wb_sunny_outlined, 'Mostly clear')
          : (Icons.nights_stay_outlined, 'Mostly clear');
    }
    if (code == 2) return (Icons.cloud_queue_rounded, 'Partly cloudy');
    if (code == 3) return (Icons.cloud_rounded, 'Overcast');
    if (code == 45 || code == 48) return (Icons.foggy, 'Fog');
    if (code >= 51 && code <= 57) return (Icons.grain_rounded, 'Drizzle');
    if (code >= 61 && code <= 67) return (Icons.water_drop_rounded, 'Rain');
    if (code >= 71 && code <= 77) return (Icons.ac_unit_rounded, 'Snow');
    if (code >= 80 && code <= 82) return (Icons.umbrella_rounded, 'Showers');
    if (code >= 85 && code <= 86) return (Icons.ac_unit_rounded, 'Snow showers');
    if (code == 95) return (Icons.thunderstorm_rounded, 'Thunderstorm');
    if (code >= 96) return (Icons.thunderstorm_rounded, 'Storm');
    return (Icons.cloud_rounded, 'Unknown');
  }
}

class WeatherService {
  WeatherService._();

  static const String _base = 'https://api.open-meteo.com/v1/forecast';

  /// California City, CA (35.1258, -117.9859).
  static const double _lat = 35.1258;
  static const double _lon = -117.9859;

  /// Fetches current + hourly + daily weather. Returns null on any failure
  /// (offline, timeout, malformed) — callers fall back to their last value.
  static Future<LiveWeather?> fetch() async {
    final url = Uri.parse(
        '$_base?latitude=$_lat&longitude=$_lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m'
        '&hourly=temperature_2m,weather_code,precipitation_probability'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset'
        '&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch'
        '&timezone=America%2FLos_Angeles&forecast_days=2');
    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      return LiveWeather.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } catch (_) {
      return null; // offline or timeout — keep showing the last known
    }
  }
}
