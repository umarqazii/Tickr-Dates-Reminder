import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../features/events/domain/tickr_event.dart';
import 'reminder_prefs_keys.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _prefs = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  SharedPreferences? _sharedPreferences;

  Future<void> init([SharedPreferences? sharedPreferences]) async {
    if (_isInitialized) return;
    _sharedPreferences = sharedPreferences;

    // 1. Initialize Timezones (Updated for flutter_timezone v5.0+)
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    // 2. Initialize Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 3. Initialize Plugin (Updated to use named arguments)
    await _prefs.initialize(settings: initializationSettings);

    // 4. Request Permissions (Crucial for Android 13+)
    await _prefs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _prefs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _isInitialized = true;
  }

  ({int hour, int minute}) _reminderClock() {
    final prefs = _sharedPreferences;
    final hour = prefs?.getInt(ReminderPrefsKeys.hour) ?? 11;
    final minute = prefs?.getInt(ReminderPrefsKeys.minute) ?? 55;
    return (hour: hour, minute: minute);
  }

  Future<void> cancelAllEventNotifications() async {
    await _prefs.cancelAll();
  }

  // Wipes all existing notifications and recalculates the next 50
  Future<void> rescheduleAll(List<TickrEvent> activeEvents) async {
    await _prefs.cancelAll(); // Clean slate

    final now = DateTime.now();

    // Sort chronologically by next occurrence
    final sorted = List<TickrEvent>.from(activeEvents)
      ..sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));

    int scheduledCount = 0;
    const maxNotifications = 50; // OS safe limit

    for (final event in sorted) {
      if (scheduledCount >= maxNotifications) break;

      final nextDate = event.nextOccurrence;

      final clock = _reminderClock();
      final targetTime =
          DateTime(nextDate.year, nextDate.month, nextDate.day, clock.hour, clock.minute);
      // final targetTime = DateTime.now().add(const Duration(minutes: 1));
      // 7 Days Before
      final sevenDaysBefore = targetTime.subtract(const Duration(days: 7));
      if (sevenDaysBefore.isAfter(now)) {
        await _schedule(
          id: (event.id * 10) + 7,
          title: 'Upcoming: ${event.title}',
          body: 'Happening in a week!',
          scheduledDate: sevenDaysBefore,
        );
        scheduledCount++;
      }

      // 1 Day Before
      final oneDayBefore = targetTime.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(now) && scheduledCount < maxNotifications) {
        await _schedule(
          id: (event.id * 10) + 1,
          title: 'Tomorrow: ${event.title}',
          body: 'Don\'t forget, it\'s tomorrow!',
          scheduledDate: oneDayBefore,
        );
        scheduledCount++;
      }

      // Day Of
      if (targetTime.isAfter(now) && scheduledCount < maxNotifications) {
        await _schedule(
          id: (event.id * 10) + 0,
          title: 'Today: ${event.title}',
          body: 'It is finally here!',
          scheduledDate: targetTime,
        );
        scheduledCount++;
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _prefs.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tickr_alerts',
          'Tickr Alerts',
          channelDescription: 'Reminders for your upcoming events',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}