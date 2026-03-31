import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../domain/tickr_event.dart';
import 'events_controller.dart';
import 'widgets/add_event_sheet.dart';

// We use a simple StateProvider to track the selected date on the calendar.
// It defaults to today.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // Calendar requires a "focused day" (what month is showing)
  // and a "selected day" (what the user clicked).
  DateTime _focusedDay = DateTime.now();

  // This is the core logic that tells the calendar which dots to draw
  // and which events to list below the calendar.
  List<TickrEvent> _getEventsForDay(DateTime day, List<TickrEvent> allEvents) {
    return allEvents.where((event) {
      // 1. If recurring, just match the month and day (ignore the year)
      if (event.isRecurring) {
        return event.eventDate.toLocal().month == day.month &&
            event.eventDate.toLocal().day == day.day;
      }
      // 2. If one-time, match exact year, month, and day
      final localDate = event.eventDate.toLocal();
      return localDate.year == day.year &&
          localDate.month == day.month &&
          localDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(eventsListProvider);

    // Safely get the list of events, default to empty if loading
    final allEvents = eventsAsync.valueOrNull ?? [];

    // Get events specifically for the tapped day
    final selectedDayEvents = _getEventsForDay(selectedDay, allEvents);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // --- THE CALENDAR WIDGET ---
          TableCalendar<TickrEvent>(
            firstDay: DateTime(1900),
            lastDay: DateTime.now().add(const Duration(days: 365 * 10)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            calendarFormat: CalendarFormat.month,

            // This disables the button that changes month to 2-weeks/1-week views
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},

            // This feeds the little dots under the dates
            eventLoader: (day) => _getEventsForDay(day, allEvents),

            // Style it to look modern and clean
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),

            // Handle User Taps
            onDaySelected: (selected, focused) {
              if (!isSameDay(selectedDay, selected)) {
                // Update Riverpod state
                ref.read(selectedDateProvider.notifier).state = selected;
                // Update local UI state
                setState(() => _focusedDay = focused);
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),

          const Divider(height: 1),

          // --- THE EVENTS LIST FOR SELECTED DAY ---
          Expanded(
            child: selectedDayEvents.isEmpty
                ? const Center(child: Text('No events on this day.'))
                : ListView.builder(
              itemCount: selectedDayEvents.length,
              itemBuilder: (context, index) {
                final event = selectedDayEvents[index];
                return ListTile(
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(event.isRecurring ? 'Yearly' : 'One-time'),
                  trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => AddEventSheet(existingEvent: event),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}