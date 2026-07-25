import 'package:flutter/foundation.dart';
import '../models/content.dart';
import '../services/api_service.dart';

class ContentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<NewsItem> _news = [];
  List<EventItem> _events = [];
  List<BusinessItem> _businesses = [];
  bool _isLoading = false;
  String? _error;

  List<NewsItem> get news => _news;
  List<EventItem> get events => _events;
  List<BusinessItem> get businesses => _businesses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NewsItem> get featuredNews => _news.where((n) => n.featured).toList();
  List<BusinessItem> get featuredBusinesses =>
      _businesses.where((b) => b.isFeatured).toList();

  Future<void> refreshAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.wait([
      refreshNews(silent: true),
      refreshEvents(silent: true),
      refreshBusinesses(silent: true),
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
}
