import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_provider.dart';
import 'core/notifications/notification_service.dart';
import 'features/events/presentation/main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isarDb = await initIsarDatabase();

  // Initialize the notification engine
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isarDb),
        // Override the notification provider with our initialized instance
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const TickrApp(),
    ),
  );
}

class TickrApp extends StatelessWidget {
  const TickrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tickr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainNavScreen(),
    );
  }
}