import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content.dart';

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
  String baseUrl = _envBaseUrl.isNotEmpty
      ? _envBaseUrl
      : 'http://10.0.2.2:8000';

  final Duration _timeout = const Duration(seconds: 15);

  Future<List<NewsItem>> fetchNews() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/news'))
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
          .get(Uri.parse('$baseUrl/api/events'))
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
          .get(Uri.parse('$baseUrl/api/businesses'))
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
          .get(Uri.parse('$baseUrl/api/alerts'))
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
          .get(Uri.parse('$baseUrl/api/council-agendas'))
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
        final List<dynamic> data =
            json.decode(response.body) as List<dynamic>;
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
      final response = await http
          .get(Uri.parse('$baseUrl/api/weather'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          return WeatherInfo.fromJson(data.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // offline — return null
    }
    return null;
  }

  Future<List<SchoolItem>> fetchSchools() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/schools'))
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
}
