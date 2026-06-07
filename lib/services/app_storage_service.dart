import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/focus_session.dart';
import '../models/task.dart';

class AppStorageSnapshot {
  final List<Task> tasks;
  final List<FocusSession> focusSessions;

  const AppStorageSnapshot({required this.tasks, required this.focusSessions});
}

class AppStorageService {
  AppStorageService._();

  static final AppStorageService instance = AppStorageService._();

  static const String _tasksKey = 'app.tasks';
  static const String _focusSessionsKey = 'app.focus_sessions';

  Future<AppStorageSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorageSnapshot(
      tasks: _decodeTasks(prefs.getString(_tasksKey)),
      focusSessions: _decodeFocusSessions(prefs.getString(_focusSessionsKey)),
    );
  }

  Future<void> saveSnapshot({
    required List<Task> tasks,
    required List<FocusSession> focusSessions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
    await prefs.setString(
      _focusSessionsKey,
      jsonEncode(focusSessions.map((session) => session.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_focusSessionsKey);
  }

  List<Task> _decodeTasks(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => Task.fromJson(
            Map<String, dynamic>.from(item.cast<String, dynamic>()),
          ),
        )
        .toList();
  }

  List<FocusSession> _decodeFocusSessions(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => FocusSession.fromJson(
            Map<String, dynamic>.from(item.cast<String, dynamic>()),
          ),
        )
        .toList();
  }
}
