import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/task_repository.dart';
import '../domain/tickr_task.dart';
import 'tasks_controller.dart';
import 'widgets/add_task_sheet.dart';

String? _profilePhotoUrl(Map<String, dynamic>? meta) {
  if (meta == null) return null;
  final avatar = meta['avatar_url'] as String?;
  final picture = meta['picture'] as String?;
  return avatar?.isNotEmpty == true ? avatar : (picture?.isNotEmpty == true ? picture : null);
}

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsyncValue = ref.watch(tasksListProvider);
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull?.session?.user;
    final rawMeta = user?.userMetadata;
    final meta = rawMeta != null ? Map<String, dynamic>.from(rawMeta) : null;
    final photoUrl = _profilePhotoUrl(meta);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _AppBarAvatar(photoUrl: photoUrl),
            const SizedBox(width: 10),
            const Text('Tickr'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await signOutFromApp(
                isar: ref.read(isarProvider),
                notificationService: ref.read(notificationServiceProvider),
              );
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: tasksAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (_) {
          final grouped = ref.watch(groupedTasksProvider);
          final listItems = <Widget>[];

          void addSection(String title, List<TickrTask> tasks, {Color? accent}) {
            if (tasks.isEmpty) return;

            listItems.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: accent ?? AppColors.textSecondary,
                  ),
                ),
              ),
            );

            for (final task in tasks) {
              listItems.add(_TaskCard(task: task, ref: ref));
            }
          }

          addSection('OVERDUE', grouped[TaskGroup.overdue]!, accent: AppColors.error);
          addSection('TODAY', grouped[TaskGroup.today]!);
          addSection('UPCOMING', grouped[TaskGroup.upcoming]!);
          addSection('COMPLETED', grouped[TaskGroup.completed]!);

          if (listItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 56,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No tasks yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add a reminder for a specific time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(padding: const EdgeInsets.only(bottom: 100), children: listItems);
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.ref});

  final TickrTask task;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final due = task.dueDateTime.toLocal();
    final now = DateTime.now();
    final isOverdue = !task.isCompleted && due.isBefore(now);
    final subtitle = '${DateFormat.yMMMd().format(due)}  ·  ${DateFormat.jm().format(due)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showAddTaskSheet(context, existingTask: task),
          onLongPress: () async {
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('Delete task'),
                  content: Text('Remove “${task.title}”?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );

            if (shouldDelete == true) {
              ref.read(taskRepositoryProvider).deleteTask(task.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: task.isCompleted,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  onChanged: (val) {
                    ref.read(taskRepositoryProvider).setCompleted(task, val ?? false);
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: task.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                          color: isOverdue ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                      if ((task.notes ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.notes!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textTertiary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarAvatar extends StatelessWidget {
  const _AppBarAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    const size = radius * 2;
    final url = photoUrl;
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: const Icon(Icons.person_rounded, size: 36, color: AppColors.primary),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person_rounded,
            size: 20,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
