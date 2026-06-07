import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/focus_session.dart';
import '../models/task.dart';
import '../utils/colors.dart';

/// หน้าจอสถิติที่สรุปการโฟกัส งานที่ทำแล้ว และรูปแบบความคืบหน้า
class StatisticsScreen extends StatelessWidget {
  /// งานทั้งหมดที่ใช้คำนวณสถิติความคืบหน้า
  final List<Task> tasks;

  /// เซสชันโฟกัสทั้งหมดที่ใช้สร้างกราฟและสรุปเวลา
  final List<FocusSession> focusSessions;

  const StatisticsScreen({
    super.key,
    required this.tasks,
    required this.focusSessions,
  });

  @override
  Widget build(BuildContext context) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;
    final totalFocusedMinutes = focusSessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final totalSessions = focusSessions.length;
    final averageFocus = totalSessions == 0
        ? 0
        : (totalFocusedMinutes / totalSessions).round();
    final weeklyFocus = _buildWeeklyFocus(focusSessions);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Focus summary',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalSessions == 0
                      ? 'Start one focus session to build your activity timeline.'
                      : '$totalSessions sessions completed with $totalFocusedMinutes focused minutes in total.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Focused',
                  value: _formatDuration(totalFocusedMinutes),
                  color: AppColors.primary,
                  icon: Icons.bolt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Sessions',
                  value: '$totalSessions',
                  color: AppColors.success,
                  icon: Icons.timer_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Average',
                  value: _formatDuration(averageFocus),
                  color: AppColors.warning,
                  icon: Icons.insights_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Pending',
                  value: '$pendingTasks',
                  color: AppColors.danger,
                  icon: Icons.timelapse_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7-day focus graph',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Minutes completed each day.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: weeklyFocus.every((entry) => entry.minutes == 0)
                      ? const Center(
                          child: Text(
                            'No focus data yet.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : _FocusBarChart(entries: weeklyFocus),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Focus activity table',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (focusSessions.isEmpty)
            const _EmptyStatisticsCard(
              message:
                  'Complete a focus session and your daily log will appear here.',
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  columnSpacing: 20,
                  headingTextStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  columns: const [
                    DataColumn(label: Text('Day')),
                    DataColumn(label: Text('Task')),
                    DataColumn(label: Text('Start')),
                    DataColumn(label: Text('End')),
                    DataColumn(label: Text('Minutes')),
                  ],
                  rows: focusSessions.take(12).map((session) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatDay(session.startedAt))),
                        DataCell(Text(session.taskTitle)),
                        DataCell(Text(_formatTime(session.startedAt))),
                        DataCell(Text(_formatTime(session.endedAt))),
                        DataCell(
                          Text(_formatDuration(session.durationMinutes)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 22),
          const Text(
            'Task progress',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const _EmptyStatisticsCard(
              message: 'Add tasks to start seeing your progress patterns.',
            )
          else
            ..._buildCategoryProgress(tasks),
        ],
      ),
    );
  }

  static List<_DailyFocusEntry> _buildWeeklyFocus(List<FocusSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <_DailyFocusEntry>[];

    for (var index = 6; index >= 0; index--) {
      final day = today.subtract(Duration(days: index));
      final minutes = sessions
          .where(
            (session) =>
                session.startedAt.year == day.year &&
                session.startedAt.month == day.month &&
                session.startedAt.day == day.day,
          )
          .fold<int>(0, (sum, session) => sum + session.durationMinutes);
      results.add(_DailyFocusEntry(day: day, minutes: minutes));
    }

    return results;
  }

  static List<Widget> _buildCategoryProgress(List<Task> tasks) {
    final categories = <String, List<Task>>{};
    for (final task in tasks) {
      categories.putIfAbsent(task.category, () => []).add(task);
    }

    return categories.entries.map((entry) {
      final entryTasks = entry.value;
      final doneCount = entryTasks.where((task) => task.isCompleted).length;
      final progress = entryTasks.isEmpty ? 0.0 : doneCount / entryTasks.length;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$doneCount/${entryTasks.length}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  static String _formatDay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }
}

class _FocusBarChart extends StatelessWidget {
  final List<_DailyFocusEntry> entries;

  const _FocusBarChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final maxMinutes = entries.fold<int>(
      0,
      (currentMax, entry) => math.max(currentMax, entry.minutes),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((entry) {
        final ratio = maxMinutes == 0 ? 0.0 : entry.minutes / maxMinutes;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  StatisticsScreen._formatDuration(entry.minutes),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 24 + (ratio * 120),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F7A6C), Color(0xFFF4B860)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _chartDateLabel(entry.day),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _chartDateLabel(DateTime day) {
    final date = day.day.toString().padLeft(2, '0');
    final month = day.month.toString().padLeft(2, '0');
    return '$date/$month\n${day.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStatisticsCard extends StatelessWidget {
  final String message;

  const _EmptyStatisticsCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DailyFocusEntry {
  final DateTime day;
  final int minutes;

  const _DailyFocusEntry({required this.day, required this.minutes});
}
