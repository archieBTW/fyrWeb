import 'dart:ui';
import 'package:flutter/material.dart';
import '../../fyr_theme.dart';
import '../../system_settings.dart';
import 'package:provider/provider.dart';

enum QuickSettingsMenu { main, wifi, bluetooth, screenshot, audio }

class QuickSettingsPopup extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onOpenSettings;

  const QuickSettingsPopup({
    super.key,
    required this.onClose,
    required this.onOpenSettings,
  });

  @override
  State<QuickSettingsPopup> createState() => _QuickSettingsPopupState();
}

class _QuickSettingsPopupState extends State<QuickSettingsPopup>
    with SingleTickerProviderStateMixin {
  QuickSettingsMenu _currentMenu = QuickSettingsMenu.main;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> _wifiNetworks = [
    {'ssid': 'fyr-5G-Ultra', 'signal': '98', 'security': 'WPA2'},
    {'ssid': 'ArcherWoods-Studio', 'signal': '85', 'security': 'WPA3'},
    {'ssid': 'Homestead_IoT', 'signal': '72', 'security': 'WPA2'},
    {'ssid': 'Guest-Free', 'signal': '60', 'security': ''},
  ];

  final List<Map<String, String>> _btDevices = [
    {'name': 'Pixel 9', 'status': 'Connected • 38%'},
    {'name': 'Sony WH-1000XM5', 'status': 'Connected • 90%'},
    {'name': 'Keychron K2 Pro', 'status': 'Paired'},
    {'name': 'Magic Trackpad', 'status': 'Paired'},
  ];

  String _selectedSink = 'Default Built-in Speakers';
  final List<String> _audioSinks = [
    'Default Built-in Speakers',
    'Sony WH-1000XM5 (Bluetooth)',
    'External Display HDMI Audio',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 472,
          decoration: BoxDecoration(
            color: FyrTheme.bgColor.withValues(alpha: 0.45),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: _buildCurrentMenu(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMenu() {
    switch (_currentMenu) {
      case QuickSettingsMenu.wifi:
        return _buildWifiMenu();
      case QuickSettingsMenu.bluetooth:
        return _buildBluetoothMenu();
      case QuickSettingsMenu.screenshot:
        return _buildScreenshotMenu();
      case QuickSettingsMenu.audio:
        return _buildAudioMenu();
      case QuickSettingsMenu.main:
        return _buildMainMenu();
    }
  }

  Widget _buildMainMenu() {
    final settings = context.watch<SystemSettings>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 4x2 Grid of Toggles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickToggle(
              icon: settings.wifi ? Icons.wifi : Icons.wifi_off,
              label: settings.wifi ? 'Wi-Fi' : 'Wi-Fi Off',
              isActive: settings.wifi,
              onTap: () => settings.setWifi(!settings.wifi),
              onLongPress: () => setState(() => _currentMenu = QuickSettingsMenu.wifi),
            ),
            _QuickToggle(
              icon: settings.bluetooth ? Icons.bluetooth_connected : Icons.bluetooth,
              label: settings.bluetooth ? 'Pixel 9' : 'Bluetooth',
              isActive: settings.bluetooth,
              onTap: () => settings.setBluetooth(!settings.bluetooth),
              onLongPress: () => setState(() => _currentMenu = QuickSettingsMenu.bluetooth),
            ),
            _QuickToggle(
              icon: Icons.airplanemode_active,
              label: 'Airplane',
              isActive: !settings.wifi && !settings.bluetooth,
              onTap: () {
                final airplane = settings.wifi || settings.bluetooth;
                settings.setWifi(!airplane);
                settings.setBluetooth(!airplane);
              },
            ),
            _QuickToggle(
              icon: Icons.nightlight_round,
              label: 'Night Light',
              isActive: settings.nightShift,
              onTap: () => settings.setNightShift(!settings.nightShift),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickToggle(
              icon: Icons.screenshot_monitor,
              label: 'Screenshot',
              isActive: false,
              onTap: () => setState(() => _currentMenu = QuickSettingsMenu.screenshot),
            ),
            _QuickToggle(
              icon: settings.dockAutoHide ? Icons.visibility_off : Icons.dock,
              label: settings.dockAutoHide ? 'Autohide' : 'Dock Fixed',
              isActive: settings.dockAutoHide,
              onTap: () => settings.setDockAutoHide(!settings.dockAutoHide),
            ),
            _QuickToggle(
              icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              label: settings.isDarkMode ? 'Dark Mode' : 'Light Mode',
              isActive: settings.isDarkMode,
              onTap: () {
                final newMode = !settings.isDarkMode;
                settings.setDarkMode(newMode);
                FyrTheme.setThemeMode(newMode ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            _QuickToggle(
              icon: Icons.settings,
              label: 'Settings',
              isActive: false,
              onTap: () {
                widget.onClose();
                widget.onOpenSettings();
              },
            ),
          ],
        ),

        const SizedBox(height: 26),

        // Sliders
        _SliderRow(
          icon: Icons.light_mode,
          value: settings.screenBrightness,
          onChanged: (val) => settings.setScreenBrightness(val),
        ),
        const SizedBox(height: 16),
        _SliderRow(
          icon: settings.soundVolume == 0 ? Icons.volume_off : Icons.volume_up,
          value: settings.soundVolume,
          onChanged: (val) => settings.setSoundVolume(val),
          trailing: IconButton(
            icon: Icon(Icons.keyboard_arrow_right, color: FyrTheme.textColor, size: 20),
            onPressed: () => setState(() => _currentMenu = QuickSettingsMenu.audio),
          ),
        ),
      ],
    );
  }

  Widget _buildWifiMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: FyrTheme.textColor, size: 20),
              onPressed: () => setState(() => _currentMenu = QuickSettingsMenu.main),
            ),
            Text(
              'Wi-Fi Networks',
              style: TextStyle(
                color: FyrTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._wifiNetworks.map(
          (net) => ListTile(
            dense: true,
            leading: Icon(Icons.wifi, color: FyrTheme.textColor, size: 20),
            title: Text(net['ssid']!, style: TextStyle(color: FyrTheme.textColor, fontSize: 13)),
            subtitle: Text(net['security']!.isEmpty ? 'Open Network' : net['security']!,
                style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 11)),
            trailing: Text('${net['signal']}%', style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 11)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connected to ${net['ssid']}'),
                  backgroundColor: FyrTheme.accentColor,
                  duration: const Duration(seconds: 2),
                ),
              );
              setState(() => _currentMenu = QuickSettingsMenu.main);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBluetoothMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: FyrTheme.textColor, size: 20),
              onPressed: () => setState(() => _currentMenu = QuickSettingsMenu.main),
            ),
            Text(
              'Bluetooth Devices',
              style: TextStyle(
                color: FyrTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._btDevices.map(
          (dev) => ListTile(
            dense: true,
            leading: Icon(Icons.bluetooth, color: FyrTheme.textColor, size: 20),
            title: Text(dev['name']!, style: TextStyle(color: FyrTheme.textColor, fontSize: 13)),
            subtitle: Text(dev['status']!, style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 11)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected ${dev['name']}'),
                  backgroundColor: FyrTheme.accentColor,
                  duration: const Duration(seconds: 2),
                ),
              );
              setState(() => _currentMenu = QuickSettingsMenu.main);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshotMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: FyrTheme.textColor, size: 20),
              onPressed: () => setState(() => _currentMenu = QuickSettingsMenu.main),
            ),
            Text(
              'Screenshot Utility',
              style: TextStyle(
                color: FyrTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListTile(
          dense: true,
          leading: Icon(Icons.fullscreen, color: FyrTheme.accentColor),
          title: Text('Capture Entire Screen', style: TextStyle(color: FyrTheme.textColor)),
          onTap: () {
            widget.onClose();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Screenshot captured and copied to clipboard!'),
                backgroundColor: FyrTheme.accentColor,
              ),
            );
          },
        ),
        ListTile(
          dense: true,
          leading: Icon(Icons.crop, color: FyrTheme.accentColor),
          title: Text('Capture Active Window', style: TextStyle(color: FyrTheme.textColor)),
          onTap: () {
            widget.onClose();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Window screenshot copied to clipboard!'),
                backgroundColor: FyrTheme.accentColor,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAudioMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: FyrTheme.textColor, size: 20),
              onPressed: () => setState(() => _currentMenu = QuickSettingsMenu.main),
            ),
            Text(
              'Audio Output Sinks',
              style: TextStyle(
                color: FyrTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._audioSinks.map(
          (sink) => ListTile(
            dense: true,
            leading: Icon(
              sink == _selectedSink ? Icons.check_circle : Icons.radio_button_unchecked,
              color: sink == _selectedSink ? FyrTheme.accentColor : FyrTheme.textColorMuted,
              size: 20,
            ),
            title: Text(sink, style: TextStyle(color: FyrTheme.textColor, fontSize: 13)),
            onTap: () {
              setState(() {
                _selectedSink = sink;
                _currentMenu = QuickSettingsMenu.main;
              });
            },
          ),
        ),
      ],
    );
  }
}

class _QuickToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _QuickToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = FyrTheme.accentColor;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: const CircleBorder(),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? accentColor.withValues(alpha: 0.3)
                    : FyrTheme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? accentColor.withValues(alpha: 0.6)
                      : FyrTheme.dividerColor,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? FyrTheme.textColor
                    : FyrTheme.textColor.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final Widget? trailing;

  const _SliderRow({
    required this.icon,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = FyrTheme.accentColor;

    return Row(
      children: [
        Icon(icon, color: FyrTheme.textColor.withValues(alpha: 0.8), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: accentColor,
              inactiveTrackColor: FyrTheme.hoverColor,
              thumbColor: Colors.white,
              overlayColor: accentColor.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}
