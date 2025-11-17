import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      _user = User.fromJson(userMap as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulasi login API call
      await Future.delayed(const Duration(seconds: 1));

      final user = User(id: '1', email: email, name: email.split('@')[0]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', user.toJson().toString());
      _user = user;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulasi register API call
      await Future.delayed(const Duration(seconds: 1));

      final user = User(id: '1', email: email, name: name);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', user.toJson().toString());
      _user = user;
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    _user = null;
    notifyListeners();
  }
}
