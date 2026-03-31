import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

// Notice we use ConsumerWidget instead of StatelessWidget
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch() listens to the stream. If the database changes,
    // this build method runs again instantly.
    final eventsAsyncValue = ref.watch(eventsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickr', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      // .when() handles the Stream's loading, error, and data states elegantly
      body: eventsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (_) {
          // We read the grouped data here!
          final groupedEvents = ref.watch(groupedEventsProvider);

          // Flatten the map into a list of widgets (Headers + ListTiles)
          final listItems = <Widget>[];

          void addSection(String title, List<TickrEvent> sectionEvents) {
            if (sectionEvents.isEmpty) return;

            // Section Header
            listItems.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );

            // The Events
            for (final event in sectionEvents) {
              final dateStr = DateFormat.yMMMd().format(event.nextOccurrence);
              final ann = event.anniversaryYear;
              final subtitleStr = dateStr;

              listItems.add(
                ListTile(
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(subtitleStr),
                  trailing: event.isRecurring
                      ?  Text('${_ordinalAnniversary(ann!)} Year')
                      : null,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => AddEventSheet(existingEvent: event),
                    );
                  },
                  // --- SAFE DELETION ON LONG PRESS ---
                  onLongPress: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Delete Event'),
                          content: Text('Are you sure you want to remove "${event.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
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
                ),
              );
            }
          }

          // Build the sections in order
          addSection('TODAY', groupedEvents[EventGroup.today]!);
          addSection('THIS WEEK', groupedEvents[EventGroup.thisWeek]!);
          addSection('LATER', groupedEvents[EventGroup.later]!);
          addSection('PAST', groupedEvents[EventGroup.past]!);

          if (listItems.isEmpty) {
            return const Center(child: Text('Nothing on the horizon.'));
          }

          return ListView(children: listItems);
        },
      ),
    );
  }
}