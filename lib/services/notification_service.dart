import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

/// บริการการแจ้งเตือนภายในแอป ที่ใช้กำหนดเวลาและส่งทดสอบการแจ้งเตือน
class NotificationService {
  NotificationService._();

  /// อินสแตนซ์ singleton ของบริการแจ้งเตือน
  static final NotificationService instance = NotificationService._();

  static const int _testNotificationId = 900000001;
  static const String _taskPayloadPrefix = 'task:';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final bool androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    final bool iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    final bool macosGranted =
        await macos?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidGranted && iosGranted && macosGranted;
  }

  Future<bool> areNotificationsEnabled() async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    final iosPermissions = await ios?.checkPermissions();
    if (iosPermissions != null) {
      return iosPermissions.isEnabled;
    }

    final macosPermissions = await macos?.checkPermissions();
    if (macosPermissions != null) {
      return macosPermissions.isEnabled;
    }

    return true;
  }

  Future<void> showTestNotification() async {
    await initialize();

    await _plugin.show(
      id: _testNotificationId,
      title: 'MePlan reminder',
      body:
          'Your notification setup is ready. We will keep your task reminders on track.',
      notificationDetails: _notificationDetails(),
      payload: 'test',
    );
  }

  Future<void> scheduleTaskReminder(Task task) async {
    await initialize();

    if (!task.canScheduleReminder) {
      await cancelTaskReminder(task);
      return;
    }

    await _plugin.zonedSchedule(
      id: _notificationIdForTask(task),
      title: task.title,
      body: _buildReminderBody(task),
      scheduledDate: tz.TZDateTime.from(task.reminderAt!, tz.local),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$_taskPayloadPrefix${task.id}',
    );
  }

  Future<void> cancelTaskReminder(Task task) async {
    await initialize();
    await _plugin.cancel(id: _notificationIdForTask(task));
  }

  Future<void> rescheduleTaskReminders(Iterable<Task> tasks) async {
    await initialize();

    final pendingRequests = await _plugin.pendingNotificationRequests();
    for (final request in pendingRequests) {
      if (request.payload?.startsWith(_taskPayloadPrefix) ?? false) {
        await _plugin.cancel(id: request.id);
      }
    }

    for (final task in tasks) {
      if (task.canScheduleReminder) {
        await scheduleTaskReminder(task);
      }
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Task reminders',
        channelDescription: 'Reminders for scheduled tasks in MePlan',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  static int _notificationIdForTask(Task task) {
    return task.id.hashCode & 0x7fffffff;
  }

  static String _buildReminderBody(Task task) {
    final parts = <String>[
      if (task.description.isNotEmpty) task.description,
      '${task.category} • ${task.focusMinutes} min focus block',
    ];

    return parts.join('  ');
  }
}
