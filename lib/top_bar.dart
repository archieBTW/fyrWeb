import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/config_model.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onQuickSettingsTap;

  const TopBar({
    super.key,
    required this.onMenuTap,
    required this.onQuickSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer.clearGlass(
      height: 32,
      width: double.infinity,
      borderWidth: 0,
      blur: 20,
      color: isDark
          ? Colors.black.withOpacity(0.3)
          : Colors.white.withOpacity(0.3),
      borderColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: onMenuTap,
              child: Icon(
                Icons.menu,
                color: Theme.of(context).colorScheme.onSurface,
                size: 18,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onQuickSettingsTap,
              child: Row(
                children: [
                  Icon(
                    Icons.wifi,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.battery_full,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.tune,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onQuickSettingsTap,
              child: StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Text(
                    DateFormat('EEE MMM d  h:mm a').format(DateTime.now()),
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
