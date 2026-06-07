class FocusSession {
  final String id;
  final String taskId;
  final String taskTitle;
  final String category;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;

  const FocusSession({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.category,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'category': category,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      taskId: json['taskId'] as String? ?? '',
      taskTitle: json['taskTitle'] as String? ?? '',
      category: json['category'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
    );
  }
}
