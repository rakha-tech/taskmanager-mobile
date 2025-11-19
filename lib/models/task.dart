import 'dart:convert';
import 'package:intl/intl.dart'; // Tambahkan package intl untuk formatting tanggal

class Task {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in-progress', 'done'
  final String priority; // 'low', 'medium', 'high'
  final String dueDate; // Format ISO 8601: "2025-11-16T00:00:00Z"
  final String createdAt;
  final String userId;

  // Konstanta
  static const String statusTodo = 'todo';
  static const String statusInProgress = 'in-progress';
  static const String statusDone = 'done';

  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';

  static String toBackendStatus(String status) {
    // Backend menerima lowercase: 'todo', 'in-progress', 'done'
    return status;
  }

  static String toBackendPriority(String priority) {
    // Backend menerima lowercase: 'low', 'medium', 'high'
    return priority;
  }

  // Fungsi helper untuk mendapatkan tanggal dalam format YYYY-MM-DD
  String get formattedDueDate {
    if (dueDate.isEmpty) return '';
    try {
      final date = DateTime.parse(dueDate);
      return DateFormat('yyyy-MM-dd').format(date); // Format ke YYYY -MM-DD
    } catch (e) {
      return dueDate; // Jika parsing gagal, kembalikan string aslinya
    }
  }

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    required this.userId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Backend mengembalikan status dengan format Title Case: 'Done', 'InProgress', dll
    // Konversi ke lowercase untuk konsistensi dengan model
    String statusValue = (json['status'] ?? '').toString().toLowerCase();
    if (statusValue == 'todo') {
      statusValue = statusTodo;
    } else if (statusValue == 'in-progress' ||
        statusValue == 'inprogress' ||
        statusValue == 'in_progress') {
      statusValue = statusInProgress;
    } else if (statusValue == 'done') {
      statusValue = statusDone;
    } else {
      statusValue = statusTodo; // Default
    }

    // Backend mengembalikan priority dengan format Title Case: 'Low', 'Medium', 'High'
    // Konversi ke lowercase untuk konsistensi dengan model
    String priorityValue = (json['priority'] ?? '').toString().toLowerCase();
    if (priorityValue == 'low') {
      priorityValue = priorityLow;
    } else if (priorityValue == 'medium') {
      priorityValue = priorityMedium;
    } else if (priorityValue == 'high') {
      priorityValue = priorityHigh;
    } else {
      priorityValue = priorityMedium; // Default
    }

    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: statusValue, // Gunakan nilai yang sudah dinormalisasi
      priority: priorityValue, // Gunakan nilai yang sudah dinormalisasi
      dueDate: json['dueDate'] ?? '', // Biarkan sebagai string ISO 8601
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate, // Kirim kembali dalam format ISO 8601
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory Task.fromJsonString(String jsonString) {
    return Task.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
