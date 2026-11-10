import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../fyr_theme.dart';
import '../../system_settings.dart';
import '../../window_manager.dart';
import '../../models/fyr_notification.dart';
import 'package:provider/provider.dart';

class FyrTaskbar extends StatelessWidget {
  final VoidCallback onToggleStartMenu;
  final VoidCallback onToggleCalendar;
  final VoidCallback onToggleQuickSettings;
  final VoidCallback onToggleOverview;

  const FyrTaskbar({
    super.key,
    required this.onToggleStartMenu,
    required this.onToggleCalendar,
    required this.onToggleQuickSettings,
    required this.onToggleOverview,
  });

  @override
  Widget build(BuildContext context) {
    final windowManager = context.watch<WindowManager>();
    final settings = context.watch<SystemSettings>();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: FyrTheme.bgColor.withValues(alpha: 0.35),
          ),
          child: Stack(
        children: [
          // Center: Clock & Weather Widget
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: onToggleCalendar,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.transparent,
                child: const _ClockWidget(),
              ),
            ),
          ),

          // Left: Fyr Logo & Workspace Switcher
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Start Menu (fyr)',
                  child: GestureDetector(
                    onTap: onToggleStartMenu,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/icons/fyr_icon.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.local_fire_department,
                          color: FyrTheme.accentColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const _WorkspaceSwitcher(),
              ],
            ),
          ),

          // Right: Action Icons (Overview, Retile, Tiling Toggle, Split Toggle, Quick Settings Pill)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. fyrOverview icon
                Tooltip(
                  message: 'Workspace Overview',
                  child: GestureDetector(
                    onTap: onToggleOverview,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.dashboard,
                        color: FyrTheme.textColor.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // 2. Retile icon
                Tooltip(
                  message: 'Retile Windows',
                  child: GestureDetector(
                    onTap: () {
                      windowManager.retile();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Windows Retiled'),
                          backgroundColor: FyrTheme.accentColor,
                          duration: const Duration(milliseconds: 1200),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.sort,
                        color: FyrTheme.textColor.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // 3. Tiling / Window Management toggle
                Tooltip(
                  message: windowManager.isTilingMode
                      ? 'Switch to Floating Windows'
                      : 'Switch to Tiling Mode',
                  child: GestureDetector(
                    onTap: () {
                      windowManager.toggleTilingMode();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            windowManager.isTilingMode
                                ? 'Tiling Mode Enabled'
                                : 'Floating Window Management Enabled',
                          ),
                          backgroundColor: FyrTheme.accentColor,
                          duration: const Duration(milliseconds: 1400),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      alignment: Alignment.center,
                      child: Icon(
                        windowManager.isTilingMode ? Icons.grid_view : Icons.layers,
                        color: windowManager.isTilingMode
                            ? FyrTheme.accentColor
                            : FyrTheme.textColor.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // 4. Split orientation toggle for next window
                Tooltip(
                  message: windowManager.splitLayout == 'splith'
                      ? 'Next Split: Side-by-Side (splith)'
                      : 'Next Split: Stacked (splitv)',
                  child: GestureDetector(
                    onTap: () {
                      windowManager.toggleSplitLayout();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            windowManager.splitLayout == 'splith'
                                ? 'Next Split Orientation: Side-by-Side (Horizontal)'
                                : 'Next Split Orientation: Stacked (Vertical)',
                          ),
                          backgroundColor: FyrTheme.accentColor,
                          duration: const Duration(milliseconds: 1200),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      alignment: Alignment.center,
                      child: Icon(
                        windowManager.splitLayout == 'splitv'
                            ? Icons.splitscreen
                            : Icons.vertical_split,
                        color: FyrTheme.textColor.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // 5. Retile Grid button (active when in tiling mode)
                if (windowManager.isTilingMode)
                  Tooltip(
                    message: 'Retile Windows to Perfect Grid',
                    child: GestureDetector(
                      onTap: () {
                        windowManager.retileWorkspace();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Windows Retiled to Grid'),
                            backgroundColor: FyrTheme.accentColor,
                            duration: const Duration(milliseconds: 1000),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.grid_4x4,
                          color: FyrTheme.textColor.withValues(alpha: 0.9),
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                // 5. Quick Settings tray pill
                GestureDetector(
                  onTap: onToggleQuickSettings,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.only(left: 12, right: 18),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Phone icon + battery
                        Row(
                          children: [
                            Icon(
                              Icons.smartphone,
                              color: FyrTheme.textColor.withValues(alpha: 0.9),
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '38%',
                              style: TextStyle(
                                color: FyrTheme.textColor.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),

                        // Wi-Fi
                        Icon(
                          settings.wifi ? Icons.wifi : Icons.wifi_off,
                          color: settings.wifi
                              ? FyrTheme.textColor.withValues(alpha: 0.9)
                              : FyrTheme.textColor.withValues(alpha: 0.4),
                          size: 17,
                        ),
                        const SizedBox(width: 12),

                        // Bluetooth
                        Icon(
                          settings.bluetooth
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth,
                          color: settings.bluetooth
                              ? FyrTheme.textColor.withValues(alpha: 0.9)
                              : FyrTheme.textColor.withValues(alpha: 0.4),
                          size: 17,
                        ),
                        const SizedBox(width: 12),

                        // Battery
                        Row(
                          children: [
                            Icon(
                              Icons.battery_full,
                              color: FyrTheme.textColor.withValues(alpha: 0.9),
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '72%',
                              style: TextStyle(
                                color: FyrTheme.textColor.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _ClockWidget extends StatefulWidget {
  const _ClockWidget();

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late Timer _timer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final formatted = DateFormat('EEE, MMM d  •  h:mm a').format(DateTime.now());
    if (mounted) {
      setState(() => _timeString = formatted);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationCenter.instance,
      builder: (context, _) {
        final hasNotifications = NotificationCenter.instance.notifications.isNotEmpty;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Weather
            Icon(Icons.wb_sunny, color: Colors.amberAccent, size: 14),
            const SizedBox(width: 4),
            Text(
              '55°F',
              style: TextStyle(
                color: FyrTheme.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            // Date & Time
            Text(
              _timeString,
              style: TextStyle(
                color: FyrTheme.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            // Notification bell indicator
            if (hasNotifications)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.notifications_active,
                  color: FyrTheme.accentColor,
                  size: 14,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WorkspaceSwitcher extends StatelessWidget {
  const _WorkspaceSwitcher();

  @override
  Widget build(BuildContext context) {
    final windowManager = context.watch<WindowManager>();
    final currentWs = windowManager.currentWorkspace;
    final maxWs = windowManager.maxWorkspaces;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= maxWs; i++) ...[
          GestureDetector(
            onTap: () => windowManager.switchWorkspace(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: currentWs == i ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: currentWs == i
                      ? FyrTheme.textColor
                      : FyrTheme.textColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: currentWs == i
                      ? [
                          BoxShadow(
                            color: FyrTheme.textColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ],
        // Plus button to add workspace
        GestureDetector(
          onTap: () => windowManager.addWorkspace(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: FyrTheme.textColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  size: 10,
                  color: FyrTheme.textColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

