import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';
import '../domain/tickr_event.dart';

// 1. The Raw Data Stream (Already existing)
final eventsListProvider = StreamProvider<List<TickrEvent>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.watchActiveEvents();
});

// 2. The UI Categories
enum EventGroup { today, thisWeek, later, past }

// 3. The Sorting Engine
final groupedEventsProvider = Provider<Map<EventGroup, List<TickrEvent>>>((ref) {
  // Listen to the raw data stream
  final eventsAsync = ref.watch(eventsListProvider);

  final grouped = {
    EventGroup.today: <TickrEvent>[],
    EventGroup.thisWeek: <TickrEvent>[],
    EventGroup.later: <TickrEvent>[],
    EventGroup.past: <TickrEvent>[], // For one-time events that are over
  };

  // If loading or empty, return the empty map
  final events = eventsAsync.valueOrNull ?? [];
  if (events.isEmpty) return grouped;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final endOfWeek = today.add(const Duration(days: 7));

  // Sort ALL events chronologically by their NEXT occurrence
  final sortedEvents = List<TickrEvent>.from(events)
    ..sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));

  // Drop them into the right buckets
  for (final event in sortedEvents) {
    final nextDate = event.nextOccurrence;
    final dateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);

    if (!event.isRecurring && dateOnly.isBefore(today)) {
      grouped[EventGroup.past]!.add(event);
    } else if (dateOnly.isAtSameMomentAs(today)) {
      grouped[EventGroup.today]!.add(event);
    } else if (dateOnly.isAfter(today) && dateOnly.isBefore(endOfWeek)) {
      grouped[EventGroup.thisWeek]!.add(event);
    } else {
      grouped[EventGroup.later]!.add(event);
    }
  }

  return grouped;
});