import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  String? _token;
  String? _username;
  String? _email;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  String? get username => _username;
  String? get email => _email;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await http
          .post(
            Uri.parse('${_api.baseUrl}/api/login/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        _token = data['token'];
        _username = data['username'] ?? username;
        _email = data['email'] ?? '';
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      }
      final data = json.decode(resp.body);
      _error = data['error'] ?? 'Invalid username or password';
    } catch (e) {
      _error = 'Connection failed. Check your internet.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await http
          .post(
            Uri.parse('${_api.baseUrl}/api/register/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 201) {
        // Try auto-login after signup
        return await login(username, password);
      }
      final data = json.decode(resp.body);
      if (data['errors'] != null) {
        _error = data['errors'].values.join(', ');
      } else {
        _error = data['error'] ?? 'Registration failed';
      }
    } catch (e) {
      _error = 'Connection failed. Check your internet.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _token = null;
    _username = null;
    _email = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
