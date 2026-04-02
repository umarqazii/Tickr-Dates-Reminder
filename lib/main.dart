import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_provider.dart';
import 'core/notifications/notification_service.dart';
import 'features/events/presentation/main_nav_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isarDb = await initIsarDatabase();

  // Initialize the notification engine
  final notificationService = NotificationService();
  await notificationService.init();

  await Supabase.initialize(
    url: 'https://rxmqevgbhsxyobcmmtsi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4bXFldmdiaHN4eW9iY21tdHNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NDA1MDEsImV4cCI6MjA5MDUxNjUwMX0.sjCyCJOGHE8JuHmVkv2jI27JNXZLDBUAQ6Jkz_j-n9A',
  );

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

class TickrApp extends ConsumerWidget {
  const TickrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the authentication stream
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Tickr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Use .when() to handle the loading, error, and data states of the auth stream
      home: authState.when(
        data: (state) {
          // If we have a session, go to the main app. Otherwise, go to login.
          if (state.session != null) {
            return const MainNavScreen();
          }
          return const LoginScreen();
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const LoginScreen(),
      ),
    );
  }
}