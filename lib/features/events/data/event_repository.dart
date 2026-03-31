import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../domain/tickr_event.dart';
import '../../../core/notifications/notification_service.dart';

// 1. The Repository Class
class EventRepository {
  final Isar _isar;
  final NotificationService _notifications;
  EventRepository(this._isar, this._notifications);

  // --- FETCHING ---
  // We return a Stream instead of a Future. This is Isar's superpower.
  // Whenever data changes in the database, this stream automatically pushes
  // the new list of events. Riverpod will use this to update the UI instantly.
  Stream<List<TickrEvent>> watchActiveEvents() {
    return _isar.tickrEvents
        .where()
        .filter()
        .isDeletedEqualTo(false) // Don't show soft-deleted items in the UI
        .watch(fireImmediately: true);
  }

  // --- SAVING ---
  Future<void> saveEvent({
    required String title,
    required DateTime eventDate,
    required bool isRecurring,
    String? notes,
  }) async {
    final now = DateTime.now();

    final newEvent = TickrEvent()
      ..syncId = const Uuid().v4() // Generate a unique cloud-safe ID
      ..title = title
      ..eventDate = eventDate.toUtc() // Always store dates in UTC
      ..isRecurring = isRecurring
      ..notes = notes
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = 0 // 0 means 'pending sync to cloud'
      ..isDeleted = false;

    // Isar requires all database modifications to happen inside a "writeTxn"
    await _isar.writeTxn(() async {
      await _isar.tickrEvents.put(newEvent);
    });

    await _syncNotifications();
  }

  // --- UPDATING ---
  Future<void> updateEvent({
    required TickrEvent event,
    required String title,
    required DateTime eventDate,
    required bool isRecurring,
    String? notes,
  }) async {
    // Update the properties of the existing event object
    event.title = title;
    event.eventDate = eventDate.toUtc(); // Keep it in UTC for the database
    event.isRecurring = isRecurring;
    event.notes = notes;
    event.updatedAt = DateTime.now();
    event.syncStatus = 0; // Mark as 0 so the background sync pushes the edit to Supabase

    await _isar.writeTxn(() async {
      await _isar.tickrEvents.put(event);
    });

    await _syncNotifications();
  }

  // --- DELETING ---
  // We do a "Soft Delete" here. We don't actually erase it from Isar yet,
  // we just mark it as deleted so the background sync knows to tell Supabase
  // to delete it from the cloud later.
  Future<void> deleteEvent(Id localId) async {
    final event = await _isar.tickrEvents.get(localId);

    if (event != null) {
      event.isDeleted = true;
      event.updatedAt = DateTime.now();
      event.syncStatus = 0; // Mark as pending sync again

      await _isar.writeTxn(() async {
        await _isar.tickrEvents.put(event);
      });

      await _syncNotifications();
    }
  }
  Future<void> _syncNotifications() async {
    // Fetch all active events directly
    final events = await _isar.tickrEvents.filter().isDeletedEqualTo(false).findAll();
    await _notifications.rescheduleAll(events);
  }
}

// 2. The Riverpod Provider
// This makes our repository available anywhere in the app.
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  // We read the Isar instance from the provider we made in the previous step
  final isar = ref.watch(isarProvider);
  final notifications = ref.watch(notificationServiceProvider); // Watch the new service
  return EventRepository(isar, notifications);
});