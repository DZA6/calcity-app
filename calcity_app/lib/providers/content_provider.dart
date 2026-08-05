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
  WeatherInfo? _weather;
  bool _isLoading = false;
  bool _isLoadingAlerts = false;
  bool _isLoadingCouncil = false;
  String? _error;

  List<NewsItem> get news => _news;
  List<EventItem> get events => _events;
  List<BusinessItem> get businesses => _businesses;
  List<AlertItem> get alerts => _alerts;
  List<CouncilAgendaItem> get councilAgendas => _councilAgendas;
  WeatherInfo? get weather => _weather;
  bool get isLoading => _isLoading;
  bool get isLoadingAlerts => _isLoadingAlerts;
  bool get isLoadingCouncil => _isLoadingCouncil;
  String? get error => _error;

  List<AlertItem> get activeAlerts => _alerts.where((a) => a.isActive).toList();
  List<NewsItem> get featuredNews => _news.where((n) => n.featured).toList();
  List<BusinessItem> get featuredBusinesses =>
      _businesses.where((b) => b.isFeatured).toList();

  /// News filtered by a specific category slug, e.g. 'church'.
  List<NewsItem> newsByCategory(String category) =>
      _news.where((n) => n.category == category).toList();

  Future<void> refreshAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.wait([
      refreshNews(silent: true),
      refreshEvents(silent: true),
      refreshBusinesses(silent: true),
      fetchAlerts(),
      fetchCouncilAgendas(),
      fetchWeather(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshNews({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _news = await _api.fetchNews();
    } catch (e) {
      _error = 'Failed to load news';
    }
    if (!silent) {
      _isLoading = false;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  Future<void> refreshEvents({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _events = await _api.fetchEvents();
    } catch (e) {
      _error = 'Failed to load events';
    }
    if (!silent) {
      _isLoading = false;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  Future<void> refreshBusinesses({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _businesses = await _api.fetchBusinesses();
    } catch (e) {
      _error = 'Failed to load businesses';
    }
    if (!silent) {
      _isLoading = false;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  Future<void> fetchAlerts() async {
    _isLoadingAlerts = true;
    try {
      _alerts = await _api.fetchAlerts();
    } catch (e) {
      _error = 'Failed to load alerts';
    }
    _isLoadingAlerts = false;
    notifyListeners();
  }

  Future<void> fetchCouncilAgendas() async {
    _isLoadingCouncil = true;
    try {
      _councilAgendas = await _api.fetchCouncilAgendas();
    } catch (e) {
      _error = 'Failed to load council agendas';
    }
    _isLoadingCouncil = false;
    notifyListeners();
  }

  Future<void> fetchWeather() async {
    try {
      _weather = await _api.fetchWeather();
      notifyListeners();
    } catch (e) {
      // Weather is non-blocking; silence errors
    }
  }

  Future<List<NewsItem>> fetchNewsByCategory(String category) async {
    try {
      return await _api.fetchCategoryNews(category);
    } catch (e) {
      return [];
    }
  }
}
