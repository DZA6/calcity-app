import 'package:flutter_test/flutter_test.dart';
import 'package:calcity_app/models/content.dart';
import 'package:calcity_app/main.dart';

void main() {
  group('BusinessItem', () {
    test('fromJson parses all optional fields', () {
      final json = {
        'id': 1,
        'name': 'Test Biz',
        'category': 'local_shop',
        'description': 'A test business.',
        'image_url': 'http://img.example.com/photo.png',
        'contact_phone': '555-0199',
        'contact_email': 'biz@test.com',
        'website': 'https://testbiz.com',
        'address': '123 Main St',
        'is_home_based': true,
        'is_featured': true,
      };
      final b = BusinessItem.fromJson(json);
      expect(b.name, 'Test Biz');
      expect(b.category, 'local_shop');
      expect(b.imageUrl, 'http://img.example.com/photo.png');
      expect(b.isFeatured, true);
      expect(b.isHomeBased, true);
      expect(b.website, 'https://testbiz.com');
    });

    test('fromJson defaults flags to false when absent', () {
      final b = BusinessItem.fromJson({
        'id': 1,
        'name': 'X',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(b.isFeatured, false);
      expect(b.isHomeBased, false);
      expect(b.website, null);
      expect(b.imageUrl, null);
    });
  });

  group('EventItem', () {
    test('fromJson parses start/end dates', () {
      final json = {
        'id': 1,
        'title': 'Test Event',
        'start_date': '2026-08-15T18:00:00-07:00',
        'end_date': '2026-08-15T20:00:00-07:00',
        'category': 'city',
        'location': 'City Hall',
      };
      final e = EventItem.fromJson(json);
      expect(e.title, 'Test Event');
      expect(e.startDate, isNotNull);
      expect(e.startDate!.year, 2026);
      expect(e.category, 'city');
    });

    test('fromJson handles null dates', () {
      final e = EventItem.fromJson({'id': 1, 'title': 'E'});
      expect(e.startDate, null);
      expect(e.endDate, null);
    });
  });

  group('SchoolItem', () {
    test('fromJson parses calendar_url and bell_schedule_url', () {
      final json = {
        'id': 1,
        'name': 'Cal City High',
        'type': 'high',
        'calendar_url': 'https://www.mojave.k12.ca.us/district/calendar',
        'bell_schedule_url': 'https://drive.google.com/file/bell-schedule.pdf',
      };
      final s = SchoolItem.fromJson(json);
      expect(s.name, 'Cal City High');
      expect(s.type, 'high');
      expect(s.calendarUrl, 'https://www.mojave.k12.ca.us/district/calendar');
      expect(
          s.bellScheduleUrl, 'https://drive.google.com/file/bell-schedule.pdf');
    });

    test('fromJson handles null calendar/bell', () {
      final s = SchoolItem.fromJson({'id': 1, 'name': 'S'});
      expect(s.calendarUrl, null);
      expect(s.bellScheduleUrl, null);
      expect(s.website, null);
    });
  });

  group('NewsItem', () {
    test('fromJson parses featured flag and excerpt', () {
      final json = {
        'id': 1,
        'title': 'Breaking News',
        'content': 'A' * 200,
        'featured': true,
        'created_at': '2026-08-08T12:00:00Z',
      };
      final n = NewsItem.fromJson(json);
      expect(n.featured, true);
      expect(n.excerpt.length, lessThanOrEqualTo(153));
      expect(n.excerpt, endsWith('...'));
    });
  });

  /// The main app must render without crashing in the test environment
  /// (Google Mobile Ads and Firebase degrade gracefully).
  testWidgets('CalCity app renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CalCityApp());
    await tester.pump();
    expect(find.byType(CalCityApp), findsOneWidget);
  });
}
