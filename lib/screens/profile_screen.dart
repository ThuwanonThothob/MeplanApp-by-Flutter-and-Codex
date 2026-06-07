import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/colors.dart';

class ProfileScreen extends StatelessWidget {
  final List<Task> tasks;
  final bool notificationsEnabled;
  final bool notificationsReady;
  final VoidCallback onEnableNotifications;
  final VoidCallback onSendTestNotification;
  final VoidCallback onResyncReminders;
  final Future<void> Function() onClearAllData;

  const ProfileScreen({
    super.key,
    required this.tasks,
    required this.notificationsEnabled,
    required this.notificationsReady,
    required this.onEnableNotifications,
    required this.onSendTestNotification,
    required this.onResyncReminders,
    required this.onClearAllData,
  });

  @override
  Widget build(BuildContext context) {
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final activeTasks = tasks.where((task) => !task.isCompleted).length;
    final totalFocusMinutes = tasks.fold<int>(
      0,
      (sum, task) => sum + task.focusMinutes,
    );
    final reminderCount = tasks.where((task) => task.hasReminder).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'MePlan Workspace',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your tasks, reminders, and focus records stay on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                child: _ProfileMetric(
                  label: 'Completed',
                  value: '$completedTasks',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileMetric(label: 'Active', value: '$activeTasks'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileMetric(
                  label: 'Focus',
                  value: totalFocusMinutes.asFocusDurationLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily note',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Keep the list small, choose one meaningful task, and let focus mode handle the rest.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _NotificationCard(
            notificationsEnabled: notificationsEnabled,
            notificationsReady: notificationsReady,
            reminderCount: reminderCount,
            onEnableNotifications: onEnableNotifications,
            onSendTestNotification: onSendTestNotification,
            onResyncReminders: onResyncReminders,
          ),
          const SizedBox(height: 18),
          _StorageCard(taskCount: tasks.length, onClearAllData: onClearAllData),
          const SizedBox(height: 18),
          const _ProfileSection(
            title: 'Ready for daily use',
            items: [
              'Tasks and focus records are saved locally on this device',
              'Tasks can be edited directly from the task list',
              'Reminders can be resynced whenever the system needs it',
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final bool notificationsEnabled;
  final bool notificationsReady;
  final int reminderCount;
  final VoidCallback onEnableNotifications;
  final VoidCallback onSendTestNotification;
  final VoidCallback onResyncReminders;

  const _NotificationCard({
    required this.notificationsEnabled,
    required this.notificationsReady,
    required this.reminderCount,
    required this.onEnableNotifications,
    required this.onSendTestNotification,
    required this.onResyncReminders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificationsReady
                          ? notificationsEnabled
                                ? '$reminderCount reminders ready to deliver.'
                                : 'Turn this on to deliver task reminders.'
                          : 'Checking notification status...',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: notificationsEnabled
                      ? AppColors.primarySoft
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  notificationsEnabled ? 'Enabled' : 'Off',
                  style: TextStyle(
                    color: notificationsEnabled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!notificationsEnabled)
            ElevatedButton(
              onPressed: onEnableNotifications,
              child: const Text('Enable notifications'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSendTestNotification,
                    child: const Text('Send test'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onResyncReminders,
                    child: const Text('Resync'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  final int taskCount;
  final Future<void> Function() onClearAllData;

  const _StorageCard({required this.taskCount, required this.onClearAllData});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Stored data',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$taskCount tasks are currently saved on this device.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Clear all app data'),
                    content: const Text(
                      'This will permanently remove all tasks and focus records saved on this device.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Clear all'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                await onClearAllData();
              }
            },
            child: const Text('Clear all data'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
