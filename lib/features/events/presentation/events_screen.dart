import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/event_repository.dart';
import '../domain/tickr_event.dart';
import 'events_controller.dart';
import 'widgets/add_event_sheet.dart';

String _ordinalAnniversary(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsyncValue = ref.watch(eventsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
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
      body: eventsAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (_) {
          final groupedEvents = ref.watch(groupedEventsProvider);
          final listItems = <Widget>[];

          void addSection(String title, List<TickrEvent> sectionEvents) {
            if (sectionEvents.isEmpty) return;

            listItems.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );

            for (final event in sectionEvents) {
              final dateStr = DateFormat.yMMMd().format(event.nextOccurrence);
              final ann = event.anniversaryYear;
              final subtitleStr = dateStr;

              listItems.add(
                Padding(
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
                      onTap: () => showAddEventSheet(context, existingEvent: event),
                      onLongPress: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text('Delete event'),
                              content: Text('Remove “${event.title}”?'),
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
                          ref.read(eventRepositoryProvider).deleteEvent(event.id);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.event_rounded,
                                color: AppColors.primaryBright,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitleStr,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (event.isRecurring)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.recurring.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    ann != null ? '${_ordinalAnniversary(ann)} year' : 'Yearly',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.recurring,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          addSection('TODAY', groupedEvents[EventGroup.today]!);
          addSection('THIS WEEK', groupedEvents[EventGroup.thisWeek]!);
          addSection('LATER', groupedEvents[EventGroup.later]!);
          addSection('PAST', groupedEvents[EventGroup.past]!);

          if (listItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 56,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nothing on the horizon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add a date worth remembering.',
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
