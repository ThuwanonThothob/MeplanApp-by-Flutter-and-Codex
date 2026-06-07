enum TaskPriority { low, medium, high }

extension TaskPriorityLabel on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

extension FocusMinutesLabel on int {
  String get asFocusDurationLabel {
    final hours = this ~/ 60;
    final minutes = this % 60;

    if (hours == 0) {
      return '$this min';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime dueDate;
  final DateTime? reminderAt;
  final int focusMinutes;
  final TaskPriority priority;
  final bool remindersEnabled;
  bool isCompleted;
  DateTime? completedAt;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    DateTime? dueDate,
    this.reminderAt,
    this.focusMinutes = 25,
    this.priority = TaskPriority.medium,
    this.remindersEnabled = false,
    this.isCompleted = false,
    this.completedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       dueDate = Task.normalizeDate(dueDate ?? DateTime.now());

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool get isDueToday => isSameDate(dueDate, normalizeDate(DateTime.now()));

  bool get isOverdue {
    return !isCompleted && dueDate.isBefore(normalizeDate(DateTime.now()));
  }

  bool get hasReminder => remindersEnabled && reminderAt != null;

  bool get canScheduleReminder {
    return hasReminder && reminderAt!.isAfter(DateTime.now());
  }

  void toggleComplete() {
    isCompleted = !isCompleted;
    completedAt = isCompleted ? DateTime.now() : null;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool? clearReminderAt,
    int? focusMinutes,
    TaskPriority? priority,
    bool? remindersEnabled,
    bool? isCompleted,
    DateTime? completedAt,
    bool? clearCompletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: clearReminderAt == true
          ? null
          : (reminderAt ?? this.reminderAt),
      focusMinutes: focusMinutes ?? this.focusMinutes,
      priority: priority ?? this.priority,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt == true
          ? null
          : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'dueDate': dueDate.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'focusMinutes': focusMinutes,
      'priority': priority.index,
      'remindersEnabled': remindersEnabled,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final priorityIndex =
        (json['priority'] as int? ?? TaskPriority.medium.index).clamp(
          0,
          TaskPriority.values.length - 1,
        );

    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Personal',
      dueDate: DateTime.parse(json['dueDate'] as String),
      reminderAt: json['reminderAt'] == null
          ? null
          : DateTime.parse(json['reminderAt'] as String),
      focusMinutes: json['focusMinutes'] as int? ?? 25,
      priority: TaskPriority.values[priorityIndex],
      remindersEnabled: json['remindersEnabled'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}
