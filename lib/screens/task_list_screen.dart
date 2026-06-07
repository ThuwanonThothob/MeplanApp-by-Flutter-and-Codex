import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/colors.dart';
import 'add_task_screen.dart';

enum _TaskFilter { all, today, upcoming, completed }

class TaskListScreen extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<Task> onAddTask;
  final ValueChanged<Task> onUpdateTask;
  final ValueChanged<Task> onToggleComplete;
  final ValueChanged<Task> onDeleteTask;

  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onToggleComplete,
    required this.onDeleteTask,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  _TaskFilter _filter = _TaskFilter.all;

  Future<void> _openAddTask() async {
    final newTask = await Navigator.of(
      context,
    ).push<Task>(MaterialPageRoute(builder: (_) => const AddTaskScreen()));

    if (newTask != null) {
      widget.onAddTask(newTask);
    }
  }

  Future<void> _openEditTask(Task task) async {
    final updatedTask = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => AddTaskScreen(initialTask: task)),
    );

    if (updatedTask != null) {
      widget.onUpdateTask(updatedTask);
    }
  }

  List<Task> get _filteredTasks {
    final pending = widget.tasks.where((task) => !task.isCompleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    switch (_filter) {
      case _TaskFilter.today:
        return widget.tasks.where((task) => task.isDueToday).toList();
      case _TaskFilter.upcoming:
        return pending.where((task) => !task.isDueToday).toList();
      case _TaskFilter.completed:
        return widget.tasks.where((task) => task.isCompleted).toList();
      case _TaskFilter.all:
        return widget.tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.tasks
        .where((task) => task.isCompleted)
        .length;
    final progress = widget.tasks.isEmpty
        ? 0.0
        : completedCount / widget.tasks.length;
    final focusTask = widget.tasks.where((task) => !task.isCompleted).toList()
      ..sort((a, b) {
        final priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return a.dueDate.compareTo(b.dueDate);
      });

    final nextTask = focusTask.isEmpty ? null : focusTask.first;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTask,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          children: [
            Text(
              'Plan with clarity',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Build your own system, keep it saved, and come back anytime.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F7A6C), Color(0xFF3C9A83)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s rhythm',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedCount/${widget.tasks.length} tasks completed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFE8B4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _SummaryChip(
                        icon: Icons.flash_on_rounded,
                        label:
                            '${widget.tasks.where((task) => !task.isCompleted).length} active',
                      ),
                      const SizedBox(width: 10),
                      _SummaryChip(
                        icon: Icons.today_rounded,
                        label:
                            '${widget.tasks.where((task) => task.isDueToday).length} due today',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (nextTask != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Best next step',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nextTask.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${nextTask.category} • ${nextTask.focusMinutes.asFocusDurationLabel} focus',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == _TaskFilter.all,
                    onTap: () => setState(() => _filter = _TaskFilter.all),
                  ),
                  _FilterChip(
                    label: 'Today',
                    selected: _filter == _TaskFilter.today,
                    onTap: () => setState(() => _filter = _TaskFilter.today),
                  ),
                  _FilterChip(
                    label: 'Upcoming',
                    selected: _filter == _TaskFilter.upcoming,
                    onTap: () => setState(() => _filter = _TaskFilter.upcoming),
                  ),
                  _FilterChip(
                    label: 'Completed',
                    selected: _filter == _TaskFilter.completed,
                    onTap: () =>
                        setState(() => _filter = _TaskFilter.completed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _filteredTasks.isEmpty
                  ? _EmptyTasksState(onCreateTask: _openAddTask)
                  : Column(
                      key: ValueKey(_filter.name),
                      children: _filteredTasks
                          .map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Dismissible(
                                key: ValueKey(task.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) => showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete task'),
                                      content: Text(
                                        'Delete "${task.title}" permanently?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                onDismissed: (_) => widget.onDeleteTask(task),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                child: _TaskCard(
                                  task: task,
                                  onEdit: () => _openEditTask(task),
                                  onToggleComplete: () =>
                                      widget.onToggleComplete(task),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onToggleComplete;

  const _TaskCard({
    required this.task,
    required this.onEdit,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      TaskPriority.low => AppColors.success,
      TaskPriority.medium => AppColors.warning,
      TaskPriority.high => AppColors.danger,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: task.isCompleted
                  ? AppColors.primarySoft
                  : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: task.isCompleted,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (_) => onToggleComplete(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          icon: Icons.folder_open_rounded,
                          text: task.category,
                        ),
                        _MetaPill(
                          icon: Icons.calendar_today_rounded,
                          text: _formatDate(task.dueDate),
                        ),
                        _MetaPill(
                          icon: Icons.timelapse_rounded,
                          text: task.focusMinutes.asFocusDurationLabel,
                        ),
                        if (task.hasReminder)
                          _MetaPill(
                            icon: Icons.notifications_none_rounded,
                            text: _formatReminder(task.reminderAt!),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${task.priority.label} priority',
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
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

    return '${months[date.month - 1]} ${date.day}';
  }

  static String _formatReminder(DateTime reminderAt) {
    final hour = reminderAt.hour % 12 == 0 ? 12 : reminderAt.hour % 12;
    final minute = reminderAt.minute.toString().padLeft(2, '0');
    final period = reminderAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  final VoidCallback onCreateTask;

  const _EmptyTasksState({required this.onCreateTask});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('empty-state'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 40, color: AppColors.primary),
          const SizedBox(height: 14),
          const Text(
            'Nothing here yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first task to start planning, focusing, and tracking real progress.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onCreateTask,
            child: const Text('Create first task'),
          ),
        ],
      ),
    );
  }
}
