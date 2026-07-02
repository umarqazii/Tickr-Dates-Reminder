import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/tickr_event.dart';
import 'events_controller.dart';
import 'widgets/add_event_sheet.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

String? _profilePhotoUrl(Map<String, dynamic>? meta) {
  if (meta == null) return null;
  final avatar = meta['avatar_url'] as String?;
  final picture = meta['picture'] as String?;
  return avatar?.isNotEmpty == true ? avatar : (picture?.isNotEmpty == true ? picture : null);
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  List<TickrEvent> _getEventsForDay(DateTime day, List<TickrEvent> allEvents) {
    return allEvents.where((event) {
      if (event.isRecurring) {
        return event.eventDate.toLocal().month == day.month &&
            event.eventDate.toLocal().day == day.day;
      }
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
    final allEvents = eventsAsync.valueOrNull ?? [];
    final selectedDayEvents = _getEventsForDay(selectedDay, allEvents);
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull?.session?.user;
    final rawMeta = user?.userMetadata;
    final meta = rawMeta != null ? Map<String, dynamic>.from(rawMeta) : null;
    final photoUrl = _profilePhotoUrl(meta);

    final primary = Theme.of(context).colorScheme.primary;

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
      body: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
              child: const Text('CALENDAR', style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              )),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: TableCalendar<TickrEvent>(
              firstDay: DateTime(1900),
              lastDay: DateTime.now().add(const Duration(days: 365 * 10)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: (day) => _getEventsForDay(day, allEvents),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: const EdgeInsets.all(5),
                defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
                weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
                todayDecoration: BoxDecoration(
                  color: AppColors.todayHighlight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.calendarMarker.withValues(alpha: 0.6)),
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                selectedDecoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.calendarMarker,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                leftChevronVisible: true,
                rightChevronVisible: true,
                leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              onDaySelected: (selected, focused) {
                if (!isSameDay(selectedDay, selected)) {
                  ref.read(selectedDateProvider.notifier).state = selected;
                  setState(() => _focusedDay = focused);
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  DateFormat.yMMMEd().format(selectedDay),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selectedDayEvents.length} event${selectedDayEvents.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: selectedDayEvents.isEmpty
                ? Center(
                    child: Text(
                      'No events on this day',
                      style: TextStyle(
                        color: AppColors.textTertiary.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedDayEvents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => showAddEventSheet(context, existingEvent: event),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    event.isRecurring ? Icons.autorenew_rounded : Icons.event_rounded,
                                    color: AppColors.primaryBright,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          event.isRecurring ? 'Repeats yearly' : 'One-time',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
