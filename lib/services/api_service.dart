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

    dynamic formattedDueDate;
    if (task.dueDate.isNotEmpty) {
      try {
        // Parse the date string (bisa format YYYY-MM-DD atau ISO 8601)
        DateTime parsedDate = DateTime.parse(task.dueDate);
        // Konversi ke UTC ISO 8601 dengan timezone Z
        DateTime utcDate = parsedDate.toUtc();
        formattedDueDate = utcDate.toIso8601String().replaceFirst(
          RegExp(r'Z$'),
          'Z',
        );
        // Jika tidak ada Z, tambahkan
        if (!formattedDueDate.toString().endsWith('Z')) {
          formattedDueDate = '${formattedDueDate}Z';
        }
      } catch (e) {
        print(
          'Error parsing dueDate for create: ${task.dueDate}, sending as null. Error: $e',
        );
        formattedDueDate = null;
      }
    } else {
      formattedDueDate = null;
    }

    final requestBody = {
      'title': task.title,
      'description': task.description,
      'status': Task.toBackendStatus(task.status),
      'priority': Task.toBackendPriority(task.priority),
      if (formattedDueDate != null) 'dueDate': formattedDueDate,
    };

    print('Create Task Request - URL: $url');
    print('Create Task Request - Body: ${jsonEncode(requestBody)}');

    final response = await http.post(
      url,
      headers: _getHeadersWithAuth(token),
      body: jsonEncode(requestBody),
    );

    print('Create Task Response - Status: ${response.statusCode}');
    print('Create Task Response - Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
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

    dynamic formattedDueDate;
    if (task.dueDate.isNotEmpty) {
      try {
        // Parse the date string (bisa format YYYY-MM-DD atau ISO 8601)
        DateTime parsedDate = DateTime.parse(task.dueDate);
        // Konversi ke UTC ISO 8601 dengan timezone Z
        DateTime utcDate = parsedDate.toUtc();
        formattedDueDate = utcDate.toIso8601String().replaceFirst(
          RegExp(r'Z$'),
          'Z',
        );
        // Jika tidak ada Z, tambahkan
        if (!formattedDueDate.toString().endsWith('Z')) {
          formattedDueDate = '${formattedDueDate}Z';
        }
      } catch (e) {
        print(
          'Error parsing dueDate for update: ${task.dueDate}, sending as null. Error: $e',
        );
        formattedDueDate = null;
      }
    } else {
      formattedDueDate = null;
    }

    final requestBody = {
      'title': task.title,
      'description': task.description,
      'status': Task.toBackendStatus(task.status),
      'priority': Task.toBackendPriority(task.priority),
      if (formattedDueDate != null) 'dueDate': formattedDueDate,
    };

    print('Update Task Request - URL: $url');
    print('Update Task Request - Body: ${jsonEncode(requestBody)}');

    final response = await http.put(
      url,
      headers: _getHeadersWithAuth(token),
      body: jsonEncode(requestBody),
    );

    print('Update Task Response - Status: ${response.statusCode}');
    print('Update Task Response - Body: ${response.body}');

    if (response.statusCode == 200) {
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
