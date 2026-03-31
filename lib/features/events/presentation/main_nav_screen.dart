import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar_screen.dart';
import 'events_screen.dart';
import 'widgets/add_event_sheet.dart';

// Tracks which tab we are currently looking at (0 = Upcoming, 1 = Calendar)
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavScreen extends ConsumerWidget {
  const MainNavScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // The screens for each tab
    final screens = [
      const EventsScreen(),
      const CalendarScreen(),
    ];

    return Scaffold(
      // Show the active screen without animations for maximum speed
      body: screens[currentIndex],

      // Floating Action Button sits above the BottomNav
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddEventSheet(),
          );
        },
        elevation: 2,
        child: const Icon(Icons.add),
      ),

      // The Bottom Navigation Bar
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