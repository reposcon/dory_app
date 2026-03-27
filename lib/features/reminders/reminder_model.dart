class Reminder {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime? createdAt;

  Reminder({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']).toLocal(),
      isCompleted: json['is_completed'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      if (description != null) 'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'is_completed': isCompleted,
    };
  }
}
