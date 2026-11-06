import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'system_settings.dart';

class QuickSettings extends StatelessWidget {
  const QuickSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return GlassContainer.clearGlass(
      width: 300,
      height: 380,
      borderRadius: BorderRadius.circular(16),
      blur: 30,
      color: isDark
          ? Colors.black.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.8),
      borderColor: onSurfaceColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Control Center',
                  style: GoogleFonts.inter(
                    color: onSurfaceColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.tune, color: settings.accentColor, size: 18),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickTile(
                  icon: Icons.wifi,
                  label: 'Wi-Fi',
                  isOn: settings.wifi,
                  accentColor: settings.accentColor,
                  onTap: () => settings.setWifi(!settings.wifi),
                ),
                _QuickTile(
                  icon: Icons.bluetooth,
                  label: 'Bluetooth',
                  isOn: settings.bluetooth,
                  accentColor: settings.accentColor,
                  onTap: () => settings.setBluetooth(!settings.bluetooth),
                ),
                _QuickTile(
                  icon: settings.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  label: settings.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  isOn: settings.isDarkMode,
                  accentColor: settings.accentColor,
                  onTap: () => settings.setDarkMode(!settings.isDarkMode),
                ),
                _QuickTile(
                  icon: Icons.nightlight_round,
                  label: 'Night Shift',
                  isOn: settings.nightShift,
                  accentColor: settings.accentColor,
                  onTap: () => settings.setNightShift(!settings.nightShift),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SliderRow(
              icon: Icons.brightness_high,
              value: settings.screenBrightness,
              accentColor: settings.accentColor,
              onChanged: (v) => settings.setScreenBrightness(v),
            ),
            const SizedBox(height: 16),
            _SliderRow(
              icon: settings.soundVolume == 0
                  ? Icons.volume_off
                  : (settings.soundVolume < 0.5
                        ? Icons.volume_down
                        : Icons.volume_up),
              value: settings.soundVolume,
              accentColor: settings.accentColor,
              onChanged: (v) => settings.setSoundVolume(v),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Battery: 84% • fyrOS 2.4',
                  style: GoogleFonts.inter(
                    color: onSurfaceColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const Icon(Icons.battery_4_bar, color: Colors.green, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOn;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 124,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOn
              ? accentColor.withValues(alpha: 0.85)
              : onSurfaceColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOn
                ? accentColor.withValues(alpha: 0.9)
                : onSurfaceColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isOn ? Colors.white : onSurfaceColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: isOn ? Colors.white : onSurfaceColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final double value;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, color: onSurfaceColor.withValues(alpha: 0.6), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 18,
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: accentColor.withValues(alpha: 0.8),
              inactiveTrackColor: onSurfaceColor.withValues(alpha: 0.08),
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
