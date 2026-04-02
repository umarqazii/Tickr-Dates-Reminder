import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar_screen.dart';
import 'events_screen.dart';
import 'widgets/add_event_sheet.dart';
import '../../../core/sync/sync_service.dart';

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
    ];

    return Scaffold(
      body: screens[currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEventSheet(context),
        child: const Icon(Icons.add_rounded, size: 28),
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
        ],
      ),
    );
  }
}