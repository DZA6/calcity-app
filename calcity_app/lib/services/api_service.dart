import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content.dart';
import '../models/social.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Base URL for the backend API.
  ///
  /// Override at build time with:
  ///   flutter build apk --dart-define=API_BASE_URL=https://calcityapp.pythonanywhere.com
  /// Defaults (in order of preference):
  ///   1. --dart-define API_BASE_URL (production: PythonAnywhere)
  ///   2. Android emulator loopback (10.0.2.2 -> host machine, dev)
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  String baseUrl =
      _envBaseUrl.isNotEmpty ? _envBaseUrl : 'http://10.0.2.2:8000';

  final Duration _timeout = const Duration(seconds: 15);

  /// Auth token for social endpoints — synced by AuthProvider on login/logout.
  String? authToken;

  Map<String, String> _headers({bool auth = false}) => {
        'Content-Type': 'application/json',
        if (auth && authToken != null) 'Authorization': 'Token $authToken',
      };

  // ── Social: comments ──────────────────────────────────────────────

  Future<List<CommentItem>> fetchComments(
      String contentType, int objectId) async {
    try {
      final resp = await http
          .get(Uri.parse(
              '$baseUrl/api/comments/?content_type=$contentType&object_id=$objectId'))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final List<dynamic> items = data is Map<String, dynamic>
            ? data['results'] as List<dynamic>
            : data;
        return items
            .map((e) => CommentItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // offline — empty list
    }
    return [];
  }

  Future<CommentItem?> postComment({
    required String contentType,
    required int objectId,
    required String body,
    int? parentId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'content_type': contentType,
        'object_id': objectId,
        'body': body,
        if (parentId != null) 'parent': parentId,
      };
      final resp = await http
          .post(Uri.parse('$baseUrl/api/comments/'),
              headers: _headers(auth: true), body: json.encode(payload))
          .timeout(_timeout);
      if (resp.statusCode == 201) {
        return CommentItem.fromJson(
            json.decode(resp.body) as Map<String, dynamic>);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<bool> deleteComment(int id) async {
    try {
      final resp = await http
          .delete(Uri.parse('$baseUrl/api/comments/$id/'),
              headers: _headers(auth: true))
          .timeout(_timeout);
      return resp.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ── Social: reactions ─────────────────────────────────────────────

  /// Toggle a like/dislike; returns the fresh summary, or null on failure.
  Future<ReactionSummary?> toggleReaction({
    required String contentType,
    required int objectId,
    required String value, // 'like' | 'dislike'
  }) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/api/reactions/toggle/'),
              headers: _headers(auth: true),
              body: json.encode({
                'content_type': contentType,
                'object_id': objectId,
                'value': value,
              }))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        return ReactionSummary.fromJson(
            json.decode(resp.body) as Map<String, dynamic>);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<ReactionSummary?> fetchReactionSummary(
      String contentType, int objectId) async {
    try {
      final resp = await http
          .get(Uri.parse(
              '$baseUrl/api/reactions/summary/?content_type=$contentType&object_id=$objectId'))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        return ReactionSummary.fromJson(
            json.decode(resp.body) as Map<String, dynamic>);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Batch summaries for a list screen: targets = {'news': [1,2,3], ...}.
  Future<Map<String, ReactionSummary>> fetchReactionBulk(
      Map<String, List<int>> targets) async {
    final result = <String, ReactionSummary>{};
    final parts = <String>[];
    targets.forEach((key, ids) {
      for (final id in ids) {
        parts.add('$key:$id');
      }
    });
    if (parts.isEmpty) return result;
    try {
      final resp = await http
          .get(Uri.parse(
              '$baseUrl/api/reactions/bulk/?targets=${parts.join(',')}'))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        data.forEach((key, value) {
          result[key] = ReactionSummary.fromJson(value as Map<String, dynamic>);
        });
      }
    } catch (e) {
      // ignore
    }
    return result;
  }

  // ── Social: discussion topics ─────────────────────────────────────

  Future<List<DiscussionTopicItem>> fetchTopics({String? category}) async {
    try {
      final url = category != null && category.isNotEmpty
          ? '$baseUrl/api/topics/?category=$category'
          : '$baseUrl/api/topics/';
      final resp = await http.get(Uri.parse(url)).timeout(_timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final List<dynamic> items = data is Map<String, dynamic>
            ? data['results'] as List<dynamic>
            : data;
        return items
            .map((e) => DiscussionTopicItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  Future<DiscussionTopicItem?> fetchTopic(int id) async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/topics/$id/'))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        return DiscussionTopicItem.fromJson(
            json.decode(resp.body) as Map<String, dynamic>);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<DiscussionTopicItem?> createTopic({
    required String title,
    required String body,
    String category = 'general',
  }) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/api/topics/'),
              headers: _headers(auth: true),
              body: json.encode({
                'title': title,
                'body': body,
                'category': category,
              }))
          .timeout(_timeout);
      if (resp.statusCode == 201) {
        return DiscussionTopicItem.fromJson(
            json.decode(resp.body) as Map<String, dynamic>);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<List<NewsItem>> fetchNews() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/news?limit=50'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Network error or timeout — return empty list
    }
    return [];
  }

  Future<List<EventItem>> fetchEvents() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/events?limit=30'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Network error or timeout — return empty list
    }
    return [];
  }

  Future<List<BusinessItem>> fetchBusinesses() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/businesses?limit=50'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((e) => BusinessItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Network error or timeout — return empty list
    }
    return [];
  }

  Future<List<AlertItem>> fetchAlerts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/alerts?limit=20'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Network error or timeout — return empty list
    }
    return [];
  }

  Future<List<CouncilAgendaItem>> fetchCouncilAgendas() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/council-agendas?limit=20'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((e) => CouncilAgendaItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Network error or timeout — return empty list
    }
    return [];
  }

  Future<bool> submitTip({
    required String content,
    String? name,
    String? email,
    String? category,
  }) async {
    try {
      final body = <String, dynamic>{
        'content': content,
      };
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (category != null && category.isNotEmpty) body['category'] = category;

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/tips'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<NewsItem>> fetchCategoryNews(String category) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/news?category=$category'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // ignore — return empty
    }
    return [];
  }

  Future<WeatherInfo?> fetchWeather() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/weather')).timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          return WeatherInfo.fromJson(data.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // offline — return null
    }
    return null;
  }

  // ── Auth: password reset ─────────────────────────────────────────

  /// Step 1 — request a 6-digit reset code for [email].
  /// Returns the server message, or an error string on failure.
  Future<String?> requestPasswordReset(String email) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/api/auth/password-reset/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email.trim()}),
          )
          .timeout(_timeout);
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200) {
        return data['message'] as String? ??
            'Check your email for the reset code.';
      }
      return data['error'] as String? ?? 'Something went wrong. Try again.';
    } catch (_) {
      return 'Network error. Check your connection and try again.';
    }
  }

  /// Step 2 — confirm the code and set a new password.
  /// Returns null on success, or an error string on failure.
  Future<String?> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/api/auth/password-reset/confirm/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email.trim(),
              'code': code.trim(),
              'new_password': newPassword,
            }),
          )
          .timeout(_timeout);
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200) {
        return null; // success
      }
      return data['error'] as String? ?? 'Something went wrong. Try again.';
    } catch (_) {
      return 'Network error. Check your connection and try again.';
    }
  }

  Future<List<SchoolItem>> fetchSchools() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/schools?limit=20'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((e) => SchoolItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Network error or timeout — return empty list
    }
    return [];
  }

  Future<List<ChurchItem>> fetchChurches() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/churches?limit=20'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((e) => ChurchItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Network error or timeout — return empty list
    }
    return [];
  }

  Future<List<dynamic>> fetchFeatured() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/featured/'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> fetchDeals() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/deals/'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return (data['results'] as List<dynamic>?) ?? [];
      }
    } catch (_) {}
    return [];
  }

  // ── Classifieds & newsletter ─────────────────────────────────────

  /// Submit a classified or announcement. Returns the new item id on success.
  Future<int?> postClassified({
    required String title,
    required String content,
    required String category, // 'for_sale' | 'announcements'
  }) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/api/classifieds/'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'title': title,
                'content': content,
                'category': category,
              }))
          .timeout(_timeout);
      if (resp.statusCode == 201) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return data['id'] as int?;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Subscribe an email to the community digest.
  Future<bool> subscribeNewsletter(String email) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/api/newsletter/subscribe/'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'email': email.trim()}))
          .timeout(_timeout);
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
