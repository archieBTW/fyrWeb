import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'system_settings.dart';

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
    final settings = context.watch<SystemSettings>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    final timePattern = settings.use24HourClock
        ? (settings.showClockSeconds ? 'HH:mm:ss' : 'HH:mm')
        : (settings.showClockSeconds ? 'h:mm:ss a' : 'h:mm a');
    final dateFormatPattern = 'EEE MMM d  $timePattern';

    return GlassContainer.clearGlass(
      height: 32,
      width: double.infinity,
      borderWidth: 0,
      blur: 20,
      color: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.3),
      borderColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: onMenuTap,
              child: Icon(Icons.menu, color: onSurfaceColor, size: 18),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onQuickSettingsTap,
              child: Row(
                children: [
                  Icon(
                    settings.wifi ? Icons.wifi : Icons.wifi_off,
                    color: settings.wifi
                        ? onSurfaceColor
                        : onSurfaceColor.withValues(alpha: 0.4),
                    size: 16,
                  ),
                  if (settings.bluetooth) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.bluetooth,
                      color: settings.accentColor,
                      size: 16,
                    ),
                  ],
                  const SizedBox(width: 12),
                  Icon(
                    settings.soundVolume == 0
                        ? Icons.volume_off
                        : (settings.soundVolume < 0.5
                              ? Icons.volume_down
                              : Icons.volume_up),
                    color: onSurfaceColor,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.battery_full, color: onSurfaceColor, size: 16),
                  const SizedBox(width: 12),
                  Icon(Icons.tune, color: onSurfaceColor, size: 16),
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
                    DateFormat(dateFormatPattern).format(DateTime.now()),
                    style: GoogleFonts.inter(
                      color: onSurfaceColor,
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
