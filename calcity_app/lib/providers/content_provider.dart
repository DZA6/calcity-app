import 'package:flutter/foundation.dart';
import '../models/content.dart';
import '../services/api_service.dart';

class ContentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<NewsItem> _news = [];
  List<EventItem> _events = [];
  List<BusinessItem> _businesses = [];
  List<AlertItem> _alerts = [];
  List<CouncilAgendaItem> _councilAgendas = [];
  List<SchoolItem> _schools = [];
  WeatherInfo? _weather;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isLoadingAlerts = false;
  bool _isLoadingCouncil = false;
  String? _error;

  // ---- public read getters (no allocation per call) ----
  List<NewsItem> get news => _news;
  List<EventItem> get events => _events;
  List<BusinessItem> get businesses => _businesses;
  List<AlertItem> get alerts => _alerts;
  List<CouncilAgendaItem> get councilAgendas => _councilAgendas;
  List<SchoolItem> get schools => _schools;
  WeatherInfo? get weather => _weather;
  bool get isLoading => _isLoading;
  bool get isLoadingAlerts => _isLoadingAlerts;
  bool get isLoadingCouncil => _isLoadingCouncil;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // ---- cached derived getters (only recomputed when source lists change) ----
  late List<AlertItem> _cachedActiveAlerts;
  late List<NewsItem> _cachedFeaturedNews;
  late List<BusinessItem> _cachedFeaturedBusinesses;

  List<AlertItem> get activeAlerts => _cachedActiveAlerts;
  List<NewsItem> get featuredNews => _cachedFeaturedNews;
  List<BusinessItem> get featuredBusinesses => _cachedFeaturedBusinesses;

  // Featured placements + deals
  List<dynamic> _featured = [];
  List<dynamic> _deals = [];
  List<dynamic> get featured => _featured;
  List<dynamic> get deals => _deals;

  void _rebuildCaches() {
    _cachedActiveAlerts = _alerts.where((a) => a.isActive).toList();
    _cachedFeaturedNews = _news.where((n) => n.featured).toList();
    _cachedFeaturedBusinesses = _businesses.where((b) => b.isFeatured).toList();
  }

  ContentProvider() {
    _rebuildCaches();
  }

  List<NewsItem> newsByCategory(String category) =>
      _news.where((n) => n.category == category).toList();

  // ---- single-shot refresh: all fetches in parallel, one notify at end ----
  Future<void> refreshAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // ONE notify: show spinner

    final results = await Future.wait([
      _api.fetchNews(),
      _api.fetchEvents(),
      _api.fetchBusinesses(),
      _api.fetchAlerts(),
      _api.fetchCouncilAgendas(),
      _api.fetchWeather(),
      _api.fetchSchools(),
      _api.fetchFeatured(),
      _api.fetchDeals(),
    ]);

    _news = (results[0] as List<NewsItem>?) ?? _news;
    _events = (results[1] as List<EventItem>?) ?? _events;
    _businesses = (results[2] as List<BusinessItem>?) ?? _businesses;
    _alerts = (results[3] as List<AlertItem>?) ?? _alerts;
    _councilAgendas = (results[4] as List<CouncilAgendaItem>?) ?? _councilAgendas;
    if (results[5] is WeatherInfo) _weather = results[5] as WeatherInfo?;
    _schools = (results[6] as List<SchoolItem>?) ?? _schools;
    _featured = (results[7] as List<dynamic>?) ?? [];
    _deals = (results[8] as List<dynamic>?) ?? [];

    _rebuildCaches();
    _isLoading = false;
    _isInitialized = true;
    notifyListeners(); // ONE notify: data ready
  }

  // ---- individual refreshes (for dedicated screens) ----
  Future<void> fetchAlerts() async {
    _isLoadingAlerts = true;
    notifyListeners();
    try {
      _alerts = await _api.fetchAlerts();
      _rebuildCaches();
    } catch (_) {
      _error = 'Failed to load alerts';
    }
    _isLoadingAlerts = false;
    notifyListeners();
  }

  Future<void> refreshNews() async {
    try { _news = await _api.fetchNews(); _rebuildCaches(); } catch (_) {}
    notifyListeners();
  }

  Future<void> refreshEvents() async {
    try { _events = await _api.fetchEvents(); } catch (_) {}
    notifyListeners();
  }

  Future<void> refreshBusinesses() async {
    try { _businesses = await _api.fetchBusinesses(); _rebuildCaches(); } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchCouncilAgendas() async {
    _isLoadingCouncil = true;
    notifyListeners();
    try {
      _councilAgendas = await _api.fetchCouncilAgendas();
    } catch (_) {
      _error = 'Failed to load council agendas';
    }
    _isLoadingCouncil = false;
    notifyListeners();
  }

  Future<List<NewsItem>> fetchNewsByCategory(String category) async {
    try {
      return await _api.fetchCategoryNews(category);
    } catch (_) {
      return [];
    }
  }
}
