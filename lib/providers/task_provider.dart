import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_service.dart'; // Impor ApiService

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService(); // Instance ApiService

  TaskProvider();

  // Fungsi untuk memuat task dari API
  Future<void> loadTasks(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Panggil API untuk mendapatkan tasks
      final tasksFromApi = await _apiService.getTasks(token);
      _tasks = tasksFromApi;
    } catch (e) {
      _error = e.toString();
      debugPrint('Load Tasks error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk menambah task ke API
  Future<void> addTask(String token, Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Panggil API untuk membuat task
      final newTaskFromApi = await _apiService.createTask(token, task);
      _tasks.add(newTaskFromApi); // Tambahkan task baru ke list lokal
    } catch (e) {
      _error = e.toString();
      debugPrint('Add Task error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk mengupdate task di API
  Future<void> updateTask(String token, String id, Task updatedTask) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Panggil API untuk mengupdate task
      final updatedTaskFromApi = await _apiService.updateTask(
        token,
        id,
        updatedTask,
      );
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index] = updatedTaskFromApi; // Update task di list lokal
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Update Task error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk menghapus task dari API
  Future<void> deleteTask(String token, String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Panggil API untuk menghapus task
      await _apiService.deleteTask(token, id);
      _tasks.removeWhere((task) => task.id == id); // Hapus task dari list lokal
    } catch (e) {
      _error = e.toString();
      debugPrint('Delete Task error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk mendapatkan task tunggal (jika diperlukan)
  // Future<Task?> getTask(String token, String id) async {
  //   try {
  //     return await _apiService.getTask(token, id);
  //   } catch (e) {
  //     _error = e.toString();
  //     debugPrint('Get Task error: $_error');
  //     return null;
  //   }
  // }
}
