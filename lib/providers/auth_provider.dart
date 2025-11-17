import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart'; // Impor ApiService

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token; // Tambahkan properti untuk menyimpan token
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token; // Getter untuk token
  bool get isLoading => _isLoading;

  final ApiService _apiService = ApiService(); // Instance ApiService

  AuthProvider() {
    _loadUserAndToken(); // Muat user dan token dari shared_prefs saat inisialisasi
  }

  Future<void> _loadUserAndToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final token = prefs.getString('token');

    if (userJson != null && token != null) {
      final userMap = jsonDecode(userJson);
      _user = User.fromJson(userMap as Map<String, dynamic>);
      _token = token;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Panggil API login
      final responseData = await _apiService.login(email, password);

      // Ekstrak token dan user dari response
      final token = responseData['token'];
      final userData = responseData['user'];
      final user = User.fromJson(userData as Map<String, dynamic>);

      // Simpan ke provider
      _token = token;
      _user = user;

      // Simpan ke shared preferences untuk persistensi
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user.toJson()));
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
      // Panggil API register
      final responseData = await _apiService.register(name, email, password);

      // Ekstrak token dan user dari response
      final token = responseData['token'];
      final userData = responseData['user'];
      final user = User.fromJson(userData as Map<String, dynamic>);

      // Simpan ke provider
      _token = token;
      _user = user;

      // Simpan ke shared preferences untuk persistensi
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Hapus data dari provider dan shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _token = null;
    _user = null;
    notifyListeners();
  }
}
