import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shared app bar for main tabs (Upcoming, Calendar): brand title and menu to open [Drawer].
class TickrHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TickrHomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Builder(
            builder: (scaffoldContext) {
              return Tooltip(
                message: 'Menu',
                child: InkWell(
                  onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Text('Tickr'),
        ],
      ),
    );
  }
}
