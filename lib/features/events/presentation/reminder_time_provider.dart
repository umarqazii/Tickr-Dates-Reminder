import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_prefs_keys.dart';
import '../../../core/preferences/shared_preferences_provider.dart';
import '../data/event_repository.dart';

class ReminderTimeNotifier extends Notifier<TimeOfDay> {
  @override
  TimeOfDay build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return TimeOfDay(
      hour: prefs.getInt(ReminderPrefsKeys.hour) ?? 11,
      minute: prefs.getInt(ReminderPrefsKeys.minute) ?? 55,
    );
  }

  Future<void> setTime(TimeOfDay time) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(ReminderPrefsKeys.hour, time.hour);
    await prefs.setInt(ReminderPrefsKeys.minute, time.minute);
    state = time;
    await ref.read(eventRepositoryProvider).rescheduleNotificationsFromStorage();
  }
}

final reminderTimeNotifierProvider = NotifierProvider<ReminderTimeNotifier, TimeOfDay>(
  ReminderTimeNotifier.new,
);
