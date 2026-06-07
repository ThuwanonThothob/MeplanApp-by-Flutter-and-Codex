import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/colors.dart';

/// หน้าจอโฟกัสที่ให้ผู้ใช้เลือกงานและเริ่มตัวจับเวลาโฟกัสงานเดียว
class FocusModeScreen extends StatefulWidget {
  /// งานทั้งหมดที่ยังไม่เสร็จ เพื่อเลือกงานสำหรับโฟกัส
  final List<Task> tasks;

  /// ฟังก์ชันเรียกเมื่อผู้ใช้ทำงานเสร็จระหว่างโฟกัส
  final ValueChanged<Task> onToggleComplete;

  /// ฟังก์ชันเรียกเมื่อโฟกัสเซสชันเสร็จสิ้นและบันทึกเซสชัน
  final void Function(
    Task task,
    DateTime startedAt,
    DateTime endedAt,
    int durationMinutes,
  )
  onSessionCompleted;

  const FocusModeScreen({
    super.key,
    required this.tasks,
    required this.onToggleComplete,
    required this.onSessionCompleted,
  });

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  String? _selectedTaskId;
  DateTime? _sessionStartedAt;

  List<Task> get _pendingTasks =>
      widget.tasks.where((task) => !task.isCompleted).toList()..sort((a, b) {
        final byPriority = b.priority.index.compareTo(a.priority.index);
        if (byPriority != 0) {
          return byPriority;
        }
        return a.dueDate.compareTo(b.dueDate);
      });

  Task? get _selectedTask {
    for (final task in widget.tasks) {
      if (task.id == _selectedTaskId) {
        return task;
      }
    }
    return null;
  }

  int get _selectedTaskSeconds => (_selectedTask?.focusMinutes ?? 0) * 60;

  @override
  void initState() {
    super.initState();
    _syncSelectedTask(initialSetup: true);
  }

  @override
  void didUpdateWidget(covariant FocusModeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedTask();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncSelectedTask({bool initialSetup = false}) {
    final currentTaskExists = _pendingTasks.any(
      (task) => task.id == _selectedTaskId,
    );

    if (!currentTaskExists) {
      _selectedTaskId = _pendingTasks.isEmpty ? null : _pendingTasks.first.id;
    }

    if (!_isRunning || initialSetup) {
      _remainingSeconds = _selectedTaskSeconds;
    }
  }

  void _toggleTimer() {
    final task = _selectedTask;
    if (task == null) {
      return;
    }

    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
      return;
    }

    if (_remainingSeconds == 0) {
      _remainingSeconds = _selectedTaskSeconds;
      _sessionStartedAt = null;
    }

    _sessionStartedAt ??= DateTime.now();

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        final completedAt = DateTime.now();
        final startedAt =
            _sessionStartedAt ??
            completedAt.subtract(Duration(minutes: task.focusMinutes));

        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });

        widget.onSessionCompleted(
          task,
          startedAt,
          completedAt,
          task.focusMinutes,
        );
        _sessionStartedAt = null;
        _showCompletedSnackBar(task);
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedTaskSeconds;
      _sessionStartedAt = null;
    });
  }

  void _selectTask(Task task) {
    if (_isRunning) {
      return;
    }

    setState(() {
      _selectedTaskId = task.id;
      _remainingSeconds = task.focusMinutes * 60;
      _sessionStartedAt = null;
    });
  }

  void _showCompletedSnackBar(Task task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session complete for "${task.title}".'),
        action: task.isCompleted
            ? null
            : SnackBarAction(
                label: 'Complete task',
                onPressed: () => widget.onToggleComplete(task),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = _selectedTask;
    final totalSeconds = _selectedTaskSeconds == 0 ? 1 : _selectedTaskSeconds;
    final progress = 1 - (_remainingSeconds / totalSeconds);
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Mode')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFF143B35), Color(0xFF1F7A6C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'One task, one fixed timer',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  task?.title ?? 'Select a task to start focusing',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task == null
                      ? 'Your timer will appear here.'
                      : '${task.category} • locked to ${task.focusMinutes.asFocusDurationLabel}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  width: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 220,
                        width: 220,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0, 1),
                          strokeWidth: 14,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFE3A1),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$minutes:$seconds',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRunning
                                ? 'Stay with it'
                                : 'Tap start when ready',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: task == null ? null : _toggleTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(_isRunning ? 'Pause' : 'Start'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: task == null ? null : _resetTimer,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Locked focus length',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task == null
                            ? 'Create or choose a task first.'
                            : 'This timer always follows the ${task.focusMinutes.asFocusDurationLabel} plan from the task.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Choose a task',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_pendingTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'All tasks are complete. Add a new one to start another focus block.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            )
          else
            ..._pendingTasks.map(
              (taskItem) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _selectTask(taskItem),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: taskItem.id == _selectedTaskId
                          ? AppColors.primarySoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: taskItem.id == _selectedTaskId
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                taskItem.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${taskItem.category} • ${taskItem.focusMinutes.asFocusDurationLabel}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (taskItem.id == _selectedTaskId)
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
