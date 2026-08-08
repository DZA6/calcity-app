import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkMode = 'dark_mode';
  static const _keyNotifications = 'notifications';
  static const _keyShowNews = 'show_news';
  static const _keyShowEvents = 'show_events';
  static const _keyShowBusinesses = 'show_businesses';
  static const _keyShowSchools = 'show_schools';
  static const _keyShowFreelancers = 'show_freelancers';
  static const _keyShowAlerts = 'show_alerts';
  static const _keyShowCouncil = 'show_council';

  bool _darkMode = false; // light by default
  bool _notifications = true;
  bool _showNews = true;
  bool _showEvents = true;
  bool _showBusinesses = true;
  bool _showSchools = true;
  bool _showFreelancers = true;
  bool _showAlerts = true;
  bool _showCouncil = true;
  bool _initialized = false;

  bool get darkMode => _darkMode;
  bool get notifications => _notifications;
  bool get showNews => _showNews;
  bool get showEvents => _showEvents;
  bool get showBusinesses => _showBusinesses;
  bool get showSchools => _showSchools;
  bool get showFreelancers => _showFreelancers;
  bool get showAlerts => _showAlerts;
  bool get showCouncil => _showCouncil;
  bool get initialized => _initialized;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_keyDarkMode) ?? false;
    _notifications = prefs.getBool(_keyNotifications) ?? true;
    _showNews = prefs.getBool(_keyShowNews) ?? true;
    _showEvents = prefs.getBool(_keyShowEvents) ?? true;
    _showBusinesses = prefs.getBool(_keyShowBusinesses) ?? true;
    _showSchools = prefs.getBool(_keyShowSchools) ?? true;
    _showFreelancers = prefs.getBool(_keyShowFreelancers) ?? true;
    _showAlerts = prefs.getBool(_keyShowAlerts) ?? true;
    _showCouncil = prefs.getBool(_keyShowCouncil) ?? true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  Future<void> setShowNews(bool value) async {
    _showNews = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowNews, value);
  }

  Future<void> setShowEvents(bool value) async {
    _showEvents = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowEvents, value);
  }

  Future<void> setShowBusinesses(bool value) async {
    _showBusinesses = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowBusinesses, value);
  }

  Future<void> setShowSchools(bool value) async {
    _showSchools = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowSchools, value);
  }

  Future<void> setShowFreelancers(bool value) async {
    _showFreelancers = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowFreelancers, value);
  }

  Future<void> setShowAlerts(bool value) async {
    _showAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAlerts, value);
  }

  Future<void> setShowCouncil(bool value) async {
    _showCouncil = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowCouncil, value);
  }
}
