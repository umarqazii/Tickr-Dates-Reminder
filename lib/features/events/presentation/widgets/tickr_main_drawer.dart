import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../reminder_time_provider.dart';

String _profileDisplayName(Map<String, dynamic>? meta, String? email) {
  if (meta == null) return email ?? 'Signed in';
  final fullName = meta['full_name'] as String?;
  final name = meta['name'] as String?;
  return fullName?.trim().isNotEmpty == true
      ? fullName!.trim()
      : (name?.trim().isNotEmpty == true ? name!.trim() : (email ?? 'Signed in'));
}

String? _profilePhotoUrl(Map<String, dynamic>? meta) {
  if (meta == null) return null;
  final avatar = meta['avatar_url'] as String?;
  final picture = meta['picture'] as String?;
  return avatar?.isNotEmpty == true ? avatar : (picture?.isNotEmpty == true ? picture : null);
}

/// Drawer: Google profile, reminder time, sign out.
class TickrMainDrawer extends ConsumerWidget {
  const TickrMainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull?.session?.user;
    final rawMeta = user?.userMetadata;
    final meta = rawMeta != null ? Map<String, dynamic>.from(rawMeta) : null;
    final name = _profileDisplayName(meta, user?.email);
    final photoUrl = _profilePhotoUrl(meta);
    final email = user?.email;
    final reminderTime = ref.watch(reminderTimeNotifierProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  _DrawerAvatar(photoUrl: photoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email != null && email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineVariant),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
              title: const Text(
                'Reminder time',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              subtitle: Text(
                'Alerts on the event day at ${reminderTime.format(context)}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: reminderTime,
                  builder: (ctx, child) {
                    return Theme(
                      data: Theme.of(ctx).copyWith(
                        timePickerTheme: TimePickerThemeData(
                          dayPeriodColor: WidgetStateColor.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary;
                            }
                            return Colors.transparent;
                          }),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && context.mounted) {
                  await ref.read(reminderTimeNotifierProvider.notifier).setTime(picked);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reminders set for ${picked.format(context)}'),
                      ),
                    );
                  }
                }
              },
            ),
            const Spacer(),
            const Divider(height: 1, color: AppColors.outlineVariant),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Sign out',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await signOutFromApp(
                  isar: ref.read(isarProvider),
                  notificationService: ref.read(notificationServiceProvider),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerAvatar extends StatelessWidget {
  const _DrawerAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    const radius = 36.0;
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
            size: 36,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
