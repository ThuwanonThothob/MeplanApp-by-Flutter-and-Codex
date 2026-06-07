import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task.dart';
import '../utils/colors.dart';

/// หน้าจอปฏิทินที่แสดงงานตามวันที่และสรุปงานในสัปดาห์ถัดไป
class CalendarScreen extends StatefulWidget {
  /// งานทั้งหมดที่จะแสดงในปฏิทิน
  final List<Task> tasks;

  const CalendarScreen({super.key, required this.tasks});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// วันที่ที่ปฏิทินกำลังแสดงอยู่ในมุมมองปัจจุบัน
  late DateTime _focusedDay;

  /// วันที่ที่ผู้ใช้เลือกในตารางปฏิทิน
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = Task.normalizeDate(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
  }

  /// คืนรายการงานทั้งหมดของวันที่ระบุ
  ///
  /// และจัดเรียงตาม priority จากสูงไปต่ำ
  List<Task> _tasksForDay(DateTime day) {
    return widget.tasks
        .where((task) => Task.isSameDate(task.dueDate, day))
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _tasksForDay(_selectedDay);

    // จำนวนงานในอีก 7 วันข้างหน้า
    final weekCount = widget.tasks
        .where(
          (task) =>
              task.dueDate.isAfter(
                Task.normalizeDate(
                  DateTime.now(),
                ).subtract(const Duration(days: 1)),
              ) &&
              task.dueDate.isBefore(
                Task.normalizeDate(DateTime.now()).add(const Duration(days: 7)),
              ),
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'See the shape of your week',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$weekCount scheduled tasks in the next 7 days.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                // ปฏิทินที่แสดงงานตามวันที่
                TableCalendar<Task>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      Task.isSameDate(day, _selectedDay),
                  eventLoader: _tasksForDay,
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    weekendTextStyle: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    outsideTextStyle: const TextStyle(color: Color(0xFFB0BAB6)),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, tasks) {
                      if (tasks.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          height: 6,
                          width: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = Task.normalizeDate(selectedDay);
                      _focusedDay = focusedDay;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _titleForSelectedDay(_selectedDay),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          // ถ้าวันนี้ไม่มีงาน ให้แสดงข้อความว่าง
          if (selectedTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.calendar_view_day_outlined,
                    size: 34,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No tasks scheduled for this day.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            // ถ้ามีงานตามวันที่เลือก ก็สร้างบัตรรายการงานแต่ละชิ้น
            ...selectedTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _priorityColor(task.priority),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${task.category} • ${task.focusMinutes.asFocusDurationLabel} focus',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (task.isCompleted)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// แปลง priority ของงานเป็นสีที่ใช้กำกับบัตรงาน
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

  /// สร้างหัวข้อที่อ่านง่ายสำหรับวันที่เลือก
  static String _titleForSelectedDay(DateTime day) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
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

    return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
  }
}
