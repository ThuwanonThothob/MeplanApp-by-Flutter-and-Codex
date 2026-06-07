import 'dart:async';

import 'package:flutter/material.dart';

import '../models/focus_session.dart';
import '../models/task.dart';
import '../services/app_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import 'calendar_screen.dart';
import 'focus_mode_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';
import 'task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _notificationsEnabled = false;
  bool _notificationsLoaded = false;
  bool _isHydrating = true;

  final List<Task> _tasks = [];
  final List<FocusSession> _focusSessions = [];

  @override
  void initState() {
    super.initState();
    unawaited(_initializeApp());
  }

  Future<void> _initializeApp() async {
    try {
      final snapshot = await AppStorageService.instance.loadSnapshot();
      _tasks
        ..clear()
        ..addAll(snapshot.tasks);
      _focusSessions
        ..clear()
        ..addAll(snapshot.focusSessions);
    } catch (_) {
      if (mounted) {
        _showMessage('Stored data could not be loaded. Starting fresh.');
      }
    }

    if (mounted) {
      setState(() {
        _isHydrating = false;
      });
    }

    await _loadNotificationState();
  }

  Future<void> _persistData() {
    return AppStorageService.instance.saveSnapshot(
      tasks: _tasks,
      focusSessions: _focusSessions,
    );
  }

  Future<void> _loadNotificationState() async {
    try {
      final enabled = await NotificationService.instance
          .areNotificationsEnabled();
      if (!mounted) {
        return;
      }

      setState(() {
        _notificationsEnabled = enabled;
        _notificationsLoaded = true;
      });

      if (enabled) {
        await NotificationService.instance.rescheduleTaskReminders(_tasks);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _notificationsLoaded = true;
      });
      _showMessage('Could not prepare reminders yet. Please try again.');
    }
  }

  Future<void> _enableNotifications() async {
    try {
      final granted = await NotificationService.instance.requestPermissions();
      if (!mounted) {
        return;
      }

      setState(() {
        _notificationsEnabled = granted;
        _notificationsLoaded = true;
      });

      if (granted) {
        await NotificationService.instance.rescheduleTaskReminders(_tasks);
        _showMessage('Notifications are on and your reminders are scheduled.');
      } else {
        _showMessage('Notifications are still off on this device.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Notification permission could not be requested.');
      }
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      if (!_notificationsEnabled) {
        await _enableNotifications();
      }

      if (!_notificationsEnabled) {
        return;
      }

      await NotificationService.instance.showTestNotification();
      if (mounted) {
        _showMessage('Test reminder sent.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Test reminder could not be sent.');
      }
    }
  }

  Future<void> _resyncReminders() async {
    try {
      if (!_notificationsEnabled) {
        await _enableNotifications();
      }

      if (!_notificationsEnabled) {
        return;
      }

      await NotificationService.instance.rescheduleTaskReminders(_tasks);
      if (mounted) {
        _showMessage('Task reminders refreshed.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Task reminders could not be refreshed.');
      }
    }
  }

  Future<void> _clearAllData() async {
    try {
      _tasks.clear();
      _focusSessions.clear();
      await AppStorageService.instance.clearAll();
      await NotificationService.instance.rescheduleTaskReminders(
        const <Task>[],
      );

      if (!mounted) {
        return;
      }

      setState(() {});
      _showMessage('All app data has been cleared.');
    } catch (_) {
      if (mounted) {
        _showMessage('App data could not be cleared.');
      }
    }
  }

  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
    });

    unawaited(_persistData());
    unawaited(_syncTaskReminder(task));
  }

  void _updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index == -1) {
      return;
    }

    final previousTask = _tasks[index];
    setState(() {
      _tasks[index] = updatedTask;
    });

    unawaited(_persistData());
    unawaited(_cancelTaskReminder(previousTask));
    unawaited(_syncTaskReminder(updatedTask));
  }

  void _toggleTask(Task task) {
    setState(() {
      task.toggleComplete();
    });

    unawaited(_persistData());
    unawaited(_syncTaskReminder(task));
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.removeWhere((item) => item.id == task.id);
      _focusSessions.removeWhere((session) => session.taskId == task.id);
    });

    unawaited(_persistData());
    unawaited(_cancelTaskReminder(task));
  }

  void _recordFocusSession(
    Task task,
    DateTime startedAt,
    DateTime endedAt,
    int durationMinutes,
  ) {
    setState(() {
      _focusSessions.insert(
        0,
        FocusSession(
          id: '${task.id}-${endedAt.microsecondsSinceEpoch}',
          taskId: task.id,
          taskTitle: task.title,
          category: task.category,
          startedAt: startedAt,
          endedAt: endedAt,
          durationMinutes: durationMinutes,
        ),
      );
    });

    unawaited(_persistData());
  }

  Future<void> _syncTaskReminder(Task task) async {
    if (!_notificationsLoaded) {
      await _loadNotificationState();
    }

    if (task.hasReminder && !_notificationsEnabled) {
      _showMessage(
        'Reminder saved. Enable notifications in Profile to deliver it.',
      );
      return;
    }

    try {
      if (task.canScheduleReminder && !task.isCompleted) {
        await NotificationService.instance.scheduleTaskReminder(task);
      } else {
        await NotificationService.instance.cancelTaskReminder(task);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('A reminder could not be updated for "${task.title}".');
      }
    }
  }

  Future<void> _cancelTaskReminder(Task task) async {
    try {
      await NotificationService.instance.cancelTaskReminder(task);
    } catch (_) {
      if (mounted) {
        _showMessage('A reminder could not be removed for "${task.title}".');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isHydrating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 14),
              Text(
                'Loading your workspace...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final pages = [
      TaskListScreen(
        tasks: _tasks,
        onAddTask: _addTask,
        onUpdateTask: _updateTask,
        onToggleComplete: _toggleTask,
        onDeleteTask: _deleteTask,
      ),
      CalendarScreen(tasks: _tasks),
      FocusModeScreen(
        tasks: _tasks,
        onToggleComplete: _toggleTask,
        onSessionCompleted: _recordFocusSession,
      ),
      StatisticsScreen(tasks: _tasks, focusSessions: _focusSessions),
      ProfileScreen(
        tasks: _tasks,
        notificationsEnabled: _notificationsEnabled,
        notificationsReady: _notificationsLoaded,
        onEnableNotifications: _enableNotifications,
        onSendTestNotification: _sendTestNotification,
        onResyncReminders: _resyncReminders,
        onClearAllData: _clearAllData,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
