import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar_screen.dart';
import 'events_screen.dart';
import 'widgets/add_event_sheet.dart';
import '../../../core/sync/sync_service.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../../tasks/presentation/widgets/add_task_sheet.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Change to ConsumerStatefulWidget
class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {

  @override
  void initState() {
    super.initState();
    // Fire off a silent background sync the moment the main screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const EventsScreen(),
      const CalendarScreen(),
      const TasksScreen(),
    ];

    // The Tasks tab (index 2) adds a task; every other tab adds an event.
    const tasksTabIndex = 2;
    final isTasksTab = currentIndex == tasksTabIndex;

    return Scaffold(
      body: screens[currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => isTasksTab
            ? showAddTaskSheet(context)
            : showAddEventSheet(context),
        child: const Icon(Icons.add_rounded, size: 22),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Upcoming',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}