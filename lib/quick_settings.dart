import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickSettings extends StatefulWidget {
  const QuickSettings({super.key});

  @override
  State<QuickSettings> createState() => _QuickSettingsState();
}

class _QuickSettingsState extends State<QuickSettings> {
  bool wifi = true;
  bool bluetooth = false;
  bool airplaneMode = false;
  bool nightShift = false;
  double brightness = 0.8;
  double volume = 0.6;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return GlassContainer.clearGlass(
      width: 300,
      height: 380,
      borderRadius: BorderRadius.circular(16),
      blur: 30,
      color: isDark
          ? Colors.black.withOpacity(0.6)
          : Colors.white.withOpacity(0.8),
      borderColor: onSurfaceColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control Center',
              style: GoogleFonts.inter(
                color: onSurfaceColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickTile(
                  icon: Icons.wifi,
                  label: 'Wi-Fi',
                  isOn: wifi,
                  onTap: () => setState(() => wifi = !wifi),
                ),
                _QuickTile(
                  icon: Icons.bluetooth,
                  label: 'Bluetooth',
                  isOn: bluetooth,
                  onTap: () => setState(() => bluetooth = !bluetooth),
                ),
                _QuickTile(
                  icon: Icons.airplanemode_active,
                  label: 'Airplane',
                  isOn: airplaneMode,
                  onTap: () => setState(() => airplaneMode = !airplaneMode),
                ),
                _QuickTile(
                  icon: Icons.nightlight_round,
                  label: 'Night Shift',
                  isOn: nightShift,
                  onTap: () => setState(() => nightShift = !nightShift),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SliderRow(
              icon: Icons.brightness_high,
              value: brightness,
              onChanged: (v) => setState(() => brightness = v),
            ),
            const SizedBox(height: 16),
            _SliderRow(
              icon: Icons.volume_up,
              value: volume,
              onChanged: (v) => setState(() => volume = v),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Battery: 84%',
                  style: GoogleFonts.inter(
                    color: onSurfaceColor.withOpacity(0.5),
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
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOn
              ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
              : onSurfaceColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isOn ? Colors.white : onSurfaceColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isOn ? Colors.white : onSurfaceColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, color: onSurfaceColor.withOpacity(0.5), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 20,
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: onSurfaceColor.withOpacity(0.2),
              inactiveTrackColor: onSurfaceColor.withOpacity(0.05),
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
