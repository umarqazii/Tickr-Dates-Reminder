import 'package:flutter/foundation.dart';
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

// 2. Auth stream. On irrecoverable session errors (e.g. refresh_token_already_used
// after Android backup restores a dead session), clear local auth and emit
// signedOut so the UI shows Login — never a raw error screen.
final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    await for (final state in supabase.auth.onAuthStateChange) {
      yield state;
    }
  } catch (error, stack) {
    debugPrint('Auth stream error: $error\n$stack');
    try {
      await supabase.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      debugPrint('Failed to clear broken local session: $e');
    }
    yield const AuthState(AuthChangeEvent.signedOut, null);
  }
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
