import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/events/domain/tickr_event.dart';
import '../database/database_provider.dart';

class SyncService {
  final Isar _isar;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSyncing = false;
  bool _needsResync = false;

  SyncService(this._isar);

  // This is the main function we will call to trigger a sync
  Future<void> sync() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // Don't sync if nobody is logged in

    if (_isSyncing) {
      _needsResync = true;
      return;
    }

    _isSyncing = true;
    try {
      do {
        _needsResync = false;
        // 1. Push local changes to the cloud
        await _pushLocalChanges(user.id);
        // 2. Pull remote changes from the cloud
        await _pullRemoteChanges(user.id);
      } while (_needsResync);
    } catch (e) {
      debugPrint('Sync failed: $e');
      // If sync fails (e.g., no internet), we just quietly fail.
      // The app will try again next time!
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushLocalChanges(String userId) async {
    // --- HANDLE DELETIONS ---
    // Find events marked for deletion locally
    final deletedEvents = await _isar.tickrEvents.filter().isDeletedEqualTo(true).findAll();

    for (final event in deletedEvents) {
      await _pushDeletedEventToCloudAndPurgeLocal(event, userId);
    }

    // --- HANDLE CREATES & UPDATES ---
    // Find active events that haven't been synced yet (syncStatus == 0)
    final pendingEvents = await _isar.tickrEvents
        .filter()
        .syncStatusEqualTo(0)
        .isDeletedEqualTo(false)
        .findAll();

    for (final event in pendingEvents) {
      // Upsert (Update if exists, Insert if new) to Supabase
      await _supabase.from('tickr_events').upsert(
        {
          'sync_id': event.syncId,
          'user_id': userId,
          'title': event.title,
          'event_date': event.eventDate.toUtc().toIso8601String(),
          'is_recurring': event.isRecurring,
          'notes': event.notes,
          'created_at': event.createdAt.toUtc().toIso8601String(),
          'updated_at': event.updatedAt.toUtc().toIso8601String(),
          'is_deleted': false,
        },
        onConflict: 'sync_id',
      );

      // Mark as successfully synced locally
      event.syncStatus = 1;
      await _isar.writeTxn(() async {
        await _isar.tickrEvents.put(event);
      });
    }
  }

  /// Removes the row from Supabase (or marks deleted), then purges the local
  /// tombstone only when the cloud confirms — otherwise the next pull would
  /// re-insert the row (DELETE succeeds with 0 rows when RLS blocks it).
  Future<void> _pushDeletedEventToCloudAndPurgeLocal(TickrEvent event, String userId) async {
    try {
      final removed = await _supabase
          .from('tickr_events')
          .delete()
          .eq('sync_id', event.syncId)
          .eq('user_id', userId)
          .select('sync_id');

      if (removed.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.tickrEvents.delete(event.id);
        });
        return;
      }

      final tombstoned = await _supabase.from('tickr_events').update({
        'is_deleted': true,
        'updated_at': event.updatedAt.toUtc().toIso8601String(),
      }).eq('sync_id', event.syncId).eq('user_id', userId).select('sync_id');

      if (tombstoned.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.tickrEvents.delete(event.id);
        });
        return;
      }

      final stillThere = await _supabase
          .from('tickr_events')
          .select('sync_id')
          .eq('sync_id', event.syncId)
          .eq('user_id', userId)
          .maybeSingle();

      if (stillThere == null) {
        await _isar.writeTxn(() async {
          await _isar.tickrEvents.delete(event.id);
        });
        return;
      }

      debugPrint(
        'Cloud delete had no effect (check RLS); keeping local tombstone for ${event.syncId}',
      );
    } catch (e) {
      debugPrint('Cloud delete failed for ${event.syncId}: $e');
    }
  }

  Future<void> _pullRemoteChanges(String userId) async {
    // Get all events for this user from the cloud
    final remoteData = await _supabase.from('tickr_events').select().eq('user_id', userId);

    await _isar.writeTxn(() async {
      for (final remote in remoteData) {
        final syncId = remote['sync_id'] as String;
        final remoteUpdatedAt = DateTime.parse(remote['updated_at']).toLocal();

        // Check if we already have this event locally
        final localEvent = await _isar.tickrEvents.where().syncIdEqualTo(syncId).findFirst();

        if (localEvent == null) {
          // WE DON'T HAVE IT: It was created on another device.
          // Save it locally unless it was marked as deleted in the cloud.
          if (remote['is_deleted'] == true) continue;

          final newEvent = TickrEvent()
            ..syncId = syncId
            ..title = remote['title']
            ..eventDate = DateTime.parse(remote['event_date']).toLocal()
            ..isRecurring = remote['is_recurring']
            ..notes = remote['notes']
            ..createdAt = DateTime.parse(remote['created_at']).toLocal()
            ..updatedAt = remoteUpdatedAt
            ..syncStatus = 1 // Already synced because it came from the cloud
            ..isDeleted = false;

          await _isar.tickrEvents.put(newEvent);
        } else {
          if (localEvent.isDeleted) {
            // Pending local delete — don't let stale remote data touch this row.
            continue;
          }

          // WE DO HAVE IT: Conflict Resolution!
          // If the cloud version is newer than our local version, overwrite local.
          if (remoteUpdatedAt.isAfter(localEvent.updatedAt)) {

            if (remote['is_deleted'] == true) {
              // It was deleted on another device, delete it here too
              await _isar.tickrEvents.delete(localEvent.id);
            } else {
              // It was updated on another device, update it here
              localEvent
                ..title = remote['title']
                ..eventDate = DateTime.parse(remote['event_date']).toLocal()
                ..isRecurring = remote['is_recurring']
                ..notes = remote['notes']
                ..updatedAt = remoteUpdatedAt
                ..syncStatus = 1;

              await _isar.tickrEvents.put(localEvent);
            }
          }
        }
      }
    });
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final isar = ref.watch(isarProvider);
  return SyncService(isar);
});