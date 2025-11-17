import 'dart:convert';
import 'package:http/http.dart' as http;
// import '../models/user.dart';
import '../models/task.dart';

class ApiService {
  // Ganti BASE_URL dengan URL deployment Railway kamu
  static const String BASE_URL =
      'https://taskmanager-api-production-2c84.up.railway.app';

  // Headers umum
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // Headers dengan Authorization (untuk endpoint yang dilindungi)
  Map<String, String> _getHeadersWithAuth(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- AUTHENTICATION ---

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$BASE_URL/api/auth/login');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // Login berhasil, kembalikan token dan user data
      final data = jsonDecode(response.body);
      return data; // Contoh: {"token": "...", "user": {...}}
    } else {
      // Login gagal, lemparkan error
      throw Exception(
        'Login failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Register
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$BASE_URL/api/auth/register');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // Register berhasil, kembalikan token dan user data
      final data = jsonDecode(response.body);
      return data; // Contoh: {"token": "...", "user": {...}}
    } else {
      // Register gagal, lemparkan error
      throw Exception(
        'Registration failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // --- TASKS ---

  // Get all tasks
  Future<List<Task>> getTasks(String token) async {
    final url = Uri.parse('$BASE_URL/api/tasks');
    final response = await http.get(url, headers: _getHeadersWithAuth(token));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load tasks: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Create a new task
  Future<Task> createTask(String token, Task task) async {
    final url = Uri.parse('$BASE_URL/api/tasks');
    final response = await http.post(
      url,
      headers: _getHeadersWithAuth(token),
      body: jsonEncode({
        'title': task.title,
        'description': task.description,
        'status': task.status,
        'priority': task.priority,
        'dueDate': task.dueDate, // Format tanggal mungkin perlu disesuaikan
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Task berhasil dibuat, kembalikan task baru
      final data = jsonDecode(response.body);
      return Task.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(
        'Failed to create task: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Update an existing task
  Future<Task> updateTask(String token, String taskId, Task task) async {
    final url = Uri.parse('$BASE_URL/api/tasks/$taskId');
    final response = await http.put(
      url,
      headers: _getHeadersWithAuth(token),
      body: jsonEncode({
        'title': task.title,
        'description': task.description,
        'status': task.status,
        'priority': task.priority,
        'dueDate': task.dueDate,
      }),
    );

    if (response.statusCode == 200) {
      // Task berhasil diupdate, kembalikan task baru
      final data = jsonDecode(response.body);
      return Task.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(
        'Failed to update task: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Delete a task
  Future<void> deleteTask(String token, String taskId) async {
    final url = Uri.parse('$BASE_URL/api/tasks/$taskId');
    final response = await http.delete(
      url,
      headers: _getHeadersWithAuth(token),
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to delete task: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
