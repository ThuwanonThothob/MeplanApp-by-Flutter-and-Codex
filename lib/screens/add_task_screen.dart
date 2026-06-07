import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/colors.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? initialTask;

  const AddTaskScreen({super.key, this.initialTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _focusMinutesController;
  final List<String> _categories = ['Work', 'Study', 'Personal', 'Health'];

  late TaskPriority _priority;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _reminderTime;
  late bool _reminderEnabled;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _focusMinutesController = TextEditingController(
      text: '${task?.focusMinutes ?? 25}',
    );
    _priority = task?.priority ?? TaskPriority.medium;
    _selectedCategory = task?.category ?? 'Work';
    _selectedDate = task?.dueDate ?? DateTime.now();
    _reminderEnabled = task?.remindersEnabled ?? false;
    final reminderAt = task?.reminderAt;
    _reminderTime = reminderAt == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(hour: reminderAt.hour, minute: reminderAt.minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _focusMinutesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (pickedTime != null) {
      setState(() {
        _reminderTime = pickedTime;
      });
    }
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a task title first.')),
      );
      return;
    }

    final focusMinutes = int.tryParse(_focusMinutesController.text.trim());
    if (focusMinutes == null || focusMinutes < 1 || focusMinutes > 1440) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Focus time must be between 1 and 1440 minutes.'),
        ),
      );
      return;
    }

    final baseTask = widget.initialTask;
    final savedTask = (baseTask ?? Task(title: _titleController.text.trim()))
        .copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _selectedCategory,
          dueDate: _selectedDate,
          reminderAt: _reminderEnabled ? _selectedReminderDateTime : null,
          clearReminderAt: !_reminderEnabled,
          remindersEnabled: _reminderEnabled,
          priority: _priority,
          focusMinutes: focusMinutes,
        );

    Navigator.of(context).pop(savedTask);
  }

  DateTime get _selectedReminderDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _reminderTime.hour,
      _reminderTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit task' : 'Create task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Refine your plan' : 'Keep it simple',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set your task, choose a reminder if you want one, and define focus time from 1 minute up to 24 hours.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'Finish wireframes for onboarding',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText:
                      'Add the small context that helps you start quickly.',
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Category',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories
                    .map(
                      (category) => ChoiceChip(
                        label: Text(category),
                        selected: category == _selectedCategory,
                        showCheckmark: false,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primarySoft,
                        side: const BorderSide(color: AppColors.border),
                        labelStyle: TextStyle(
                          color: category == _selectedCategory
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
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
                        Icons.event_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due date',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Focus time',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter the exact number of minutes you want to lock this task to.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _focusMinutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Focus minutes',
                        hintText: '1 - 1440',
                        suffixText: 'min',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Examples: 1 minute, 25 minutes, 120 minutes, up to 24 hours.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reminder',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Turn this on only if you want a notification for this task.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _reminderEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _reminderEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_reminderEnabled) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _pickReminderTime,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Remind me at ${_formatTime(_reminderTime)}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Priority',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: TaskPriority.values
                    .map(
                      (priority) => ChoiceChip(
                        label: Text(priority.label),
                        selected: priority == _priority,
                        showCheckmark: false,
                        backgroundColor: AppColors.surface,
                        selectedColor: _priorityColor(
                          priority,
                        ).withValues(alpha: 0.12),
                        side: BorderSide(color: _priorityColor(priority)),
                        labelStyle: TextStyle(
                          color: _priorityColor(priority),
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _priority = priority;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saveTask,
                child: Text(_isEditing ? 'Update task' : 'Save task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.high:
        return AppColors.danger;
    }
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
