import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/tickr_task.dart';

/// Handles short-term tasks (a to-do list with a reminder at an exact time).
/// This is intentionally local-only and fully independent of the event/sync flow.
class TaskRepository {
  final Isar _isar;
  final NotificationService _notifications;

  TaskRepository(this._isar, this._notifications);

  Stream<List<TickrTask>> watchTasks() {
    return _isar.tickrTasks
        .where()
        .sortByDueDateTime()
        .watch(fireImmediately: true);
  }

  Future<void> saveTask({
    required String title,
    required DateTime dueDateTime,
    String? notes,
  }) async {
    final now = DateTime.now();

    final task = TickrTask()
      ..syncId = const Uuid().v4()
      ..title = title
      ..dueDateTime = dueDateTime
      ..isCompleted = false
      ..notes = notes
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = 0
      ..isDeleted = false;

    await _isar.writeTxn(() async {
      await _isar.tickrTasks.put(task);
    });

    await _notifications.scheduleTaskNotification(
      taskId: task.id,
      title: task.title,
      body: task.notes,
      dueDateTime: task.dueDateTime,
    );
  }

  Future<void> updateTask({
    required TickrTask task,
    required String title,
    required DateTime dueDateTime,
    String? notes,
  }) async {
    task
      ..title = title
      ..dueDateTime = dueDateTime
      ..notes = notes
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tickrTasks.put(task);
    });

    // Reschedule; a completed task stays silent.
    if (task.isCompleted) {
      await _notifications.cancelTaskNotification(task.id);
    } else {
      await _notifications.scheduleTaskNotification(
        taskId: task.id,
        title: task.title,
        body: task.notes,
        dueDateTime: task.dueDateTime,
      );
    }
  }

  Future<void> setCompleted(TickrTask task, bool isCompleted) async {
    task
      ..isCompleted = isCompleted
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tickrTasks.put(task);
    });

    if (isCompleted) {
      await _notifications.cancelTaskNotification(task.id);
    } else {
      await _notifications.scheduleTaskNotification(
        taskId: task.id,
        title: task.title,
        body: task.notes,
        dueDateTime: task.dueDateTime,
      );
    }
  }

  Future<void> deleteTask(Id localId) async {
    final task = await _isar.tickrTasks.get(localId);
    if (task == null) return;

    await _notifications.cancelTaskNotification(task.id);

    await _isar.writeTxn(() async {
      await _isar.tickrTasks.delete(localId);
    });
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final notifications = ref.watch(notificationServiceProvider);
  return TaskRepository(isar, notifications);
});
