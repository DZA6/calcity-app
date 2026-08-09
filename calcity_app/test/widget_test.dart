import 'package:flutter_test/flutter_test.dart';
import 'package:calcity_app/models/content.dart';
import 'package:calcity_app/models/social.dart';
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

  group('ReactionSummary', () {
    test('fromJson parses counts and my_value', () {
      final s = ReactionSummary.fromJson(
          {'likes': 3, 'dislikes': 1, 'my_value': 'like'});
      expect(s.likes, 3);
      expect(s.dislikes, 1);
      expect(s.myValue, 'like');
      expect(s.total, 4);
    });

    test('fromJson defaults when keys absent', () {
      final s = ReactionSummary.fromJson({});
      expect(s.likes, 0);
      expect(s.dislikes, 0);
      expect(s.myValue, null);
    });
  });

  group('CommentItem', () {
    test('fromJson parses full payload incl. parent', () {
      final c = CommentItem.fromJson({
        'id': 7,
        'content_type': 'news',
        'object_id': 42,
        'author': 'calcitizen',
        'author_id': 5,
        'body': 'Great article!',
        'parent': 3,
        'created_at': '2026-08-08T12:00:00Z',
      });
      expect(c.id, 7);
      expect(c.contentType, 'news');
      expect(c.objectId, 42);
      expect(c.author, 'calcitizen');
      expect(c.parentId, 3);
      expect(c.createdAt.year, 2026);
    });

    test('fromJson handles top-level comment (parent null)', () {
      final c = CommentItem.fromJson({
        'id': 1,
        'content_type': 'event',
        'object_id': 9,
        'author': 'x',
        'author_id': 1,
        'body': 'hi',
      });
      expect(c.parentId, null);
    });
  });

  group('DiscussionTopicItem', () {
    test('fromJson parses topic fields', () {
      final t = DiscussionTopicItem.fromJson({
        'id': 1,
        'title': 'Best taco spot?',
        'body': 'Looking for recommendations',
        'author': 'foodie',
        'author_id': 2,
        'category': 'general',
        'is_pinned': true,
        'is_closed': false,
        'created_at': '2026-08-08T12:00:00Z',
        'updated_at': '2026-08-08T13:00:00Z',
        'comment_count': 5,
        'likes': 12,
        'dislikes': 1,
        'my_value': 'like',
      });
      expect(t.title, 'Best taco spot?');
      expect(t.isPinned, true);
      expect(t.commentCount, 5);
      expect(t.likes, 12);
      expect(t.myValue, 'like');
    });

    test('fromJson defaults booleans/counts', () {
      final t = DiscussionTopicItem.fromJson(
          {'id': 2, 'title': 'T', 'body': 'B', 'author': 'a'});
      expect(t.isPinned, false);
      expect(t.commentCount, 0);
      expect(t.likes, 0);
      expect(t.myValue, null);
      expect(t.category, 'general');
    });
  });

  group('timeAgo', () {
    test('formats relative times', () {
      final now = DateTime(2026, 8, 8, 12, 0, 0);
      expect(timeAgo(now.subtract(const Duration(seconds: 30)), now: now),
          'just now');
      expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5m');
      expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3h');
      expect(timeAgo(now.subtract(const Duration(days: 2)), now: now), '2d');
    });
  });
}
