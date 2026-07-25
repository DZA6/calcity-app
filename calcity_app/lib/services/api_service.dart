import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Base URL for the backend API.
  /// Defaults to Android emulator loopback (10.0.2.2 -> host machine).
  /// For a real device on the same network, change this to your machine's
  /// local IP, e.g. 'http://192.168.1.100:8000'.
  String baseUrl = 'http://10.0.2.2:8000';

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
}
