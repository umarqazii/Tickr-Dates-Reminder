import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';

/// Web client ID (OAuth 2.0) used by Google Sign-In — must match [LoginScreen] / Google Cloud Console.
const String kGoogleWebServerClientId =
    '249842779602-26fltbsjmnrgaegcpr5poaq7ksp2266a.apps.googleusercontent.com';

// 1. A simple provider to access the Supabase client anywhere
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 2. This stream listens to Supabase. If the user logs in or out,
// this stream instantly updates our UI.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange;
});

/// Clears local Isar data and notifications, then Supabase session and Google Sign-In
/// so another account does not see the previous user's events.
Future<void> signOutFromApp({
  required Isar isar,
  required NotificationService notificationService,
}) async {
  await notificationService.cancelAllEventNotifications();
  await wipeAllLocalTickrData(isar);

  await Supabase.instance.client.auth.signOut();

  final google = GoogleSignIn.instance;
  await google.initialize(serverClientId: kGoogleWebServerClientId);
  try {
    await google.disconnect();
  } catch (_) {
    try {
      await google.signOut();
    } catch (_) {}
  }
}