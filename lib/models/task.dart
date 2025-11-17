import 'dart:convert';

class Task {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in-progress', 'done'
  final String priority; // 'low', 'medium', 'high'
  final String dueDate;
  final String createdAt;
  final String userId;

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
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      dueDate: json['dueDate'] ?? '',
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
      'dueDate': dueDate,
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
