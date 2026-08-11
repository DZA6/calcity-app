import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:calcity_app/services/weather_service.dart';

void main() {
  test('Open-Meteo live weather fetch + parse', () async {
    // flutter_test stubs HttpClient to return 400 — restore the real one.
    HttpOverrides.global = null;

    final w = await WeatherService.fetch();
    expect(w, isNotNull, reason: 'live fetch should succeed');
    if (w == null) return;

    // Sanity-check the parsed values for California City in August.
    expect(w.temp, inInclusiveRange(30, 130));
    expect(w.humidity, inInclusiveRange(0, 100));
    expect(w.windMph, greaterThanOrEqualTo(0));
    expect(w.highToday, greaterThanOrEqualTo(w.lowToday));
    expect(w.condition, isNotEmpty);
    expect(w.hourly.length, greaterThan(12));
    expect(w.nextHours(6).length, 6);

    // Hourly entries must be chronological.
    final hours = w.nextHours(6);
    for (var i = 1; i < hours.length; i++) {
      expect(hours[i].time.isAfter(hours[i - 1].time), isTrue,
          reason: 'hourly strip must be chronological');
    }

    // Print what the phone will show.
    // ignore: avoid_print
    print('SMOKE OK: ${w.temp}F ${w.condition} feels=${w.feelsLike}F '
        'hum=${w.humidity}% wind=${w.windMph}mph day=${w.isDay} '
        'H=${w.highToday} L=${w.lowToday} sunrise=${w.sunrise} sunset=${w.sunset}');
  });
}
