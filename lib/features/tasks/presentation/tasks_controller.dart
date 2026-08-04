import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_repository.dart';
import '../domain/tickr_task.dart';

final tasksListProvider = StreamProvider<List<TickrTask>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks();
});

enum TaskGroup { overdue, today, upcoming, completed }

/// Buckets active tasks by their due time and pulls out completed ones.
final groupedTasksProvider = Provider<Map<TaskGroup, List<TickrTask>>>((ref) {
  final tasksAsync = ref.watch(tasksListProvider);

  final grouped = {
    TaskGroup.overdue: <TickrTask>[],
    TaskGroup.today: <TickrTask>[],
    TaskGroup.upcoming: <TickrTask>[],
    TaskGroup.completed: <TickrTask>[],
  };

  final tasks = tasksAsync.valueOrNull ?? [];
  if (tasks.isEmpty) return grouped;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  final sorted = List<TickrTask>.from(tasks)
    ..sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));

  for (final task in sorted) {
    if (task.isCompleted) {
      grouped[TaskGroup.completed]!.add(task);
      continue;
    }

    final due = task.dueDateTime.toLocal();

    if (due.isBefore(now)) {
      grouped[TaskGroup.overdue]!.add(task);
    } else if (due.isBefore(tomorrow)) {
      grouped[TaskGroup.today]!.add(task);
    } else {
      grouped[TaskGroup.upcoming]!.add(task);
    }
  }

  return grouped;
});
