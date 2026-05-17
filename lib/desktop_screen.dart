import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'system_settings.dart';
import 'top_bar.dart';
import 'dock.dart';
import 'window_manager.dart';
import 'window_frame.dart';
import 'app_menu.dart';
import 'quick_settings.dart';
import 'system_controller.dart';
import 'app_data.dart';
import 'models/config_model.dart';
import 'dart:convert';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  bool _showAppMenu = false;
  bool _showQuickSettings = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    final system = context.read<SystemController>();
    final windowManager = context.watch<WindowManager>();
    final config = context.watch<AppConfig>();
    final apps = getApps(config);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: ListenableBuilder(
        listenable: windowManager,
        builder: (context, child) {
          final openWindows = windowManager.windows
              .where((w) => !w.isMinimized)
              .toList();
          final focusedWindow = openWindows.isNotEmpty
              ? openWindows.last
              : null;
              
          final screenHeight = MediaQuery.of(context).size.height;
          final isMaximized = openWindows.any((w) => w.isMaximized);
          final isIntersectingDock = openWindows.any((w) => 
              !w.isMaximized && 
              (w.position.dy + w.size.height) > (screenHeight - 90)
          );
          final hideDock = isMaximized || isIntersectingDock;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAppMenu = false;
                      _showQuickSettings = false;
                    });
                  },
                  child: settings.wallpaperPath.startsWith('assets')
                      ? Image.asset(settings.wallpaperPath, fit: BoxFit.cover)
                      : settings.wallpaperBytes != null
                      ? Image.memory(
                          settings.wallpaperBytes!,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          settings.wallpaperPath,
                          fit: BoxFit.cover,
                        ),
                ),
              ),

              if (isMobile)
                _buildMobileLayout(
                  context,
                  settings,
                  windowManager,
                  system,
                  focusedWindow,
                  apps,
                )
              else
                _buildDesktopLayout(context, settings, windowManager, system, hideDock),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    SystemSettings settings,
    WindowManager windowManager,
    SystemController system,
    bool hideDock,
  ) {
    return Stack(
      children: [
        ...windowManager.windows
            .where((w) => !w.isMinimized)
            .map(
              (w) => WindowFrame(
                key: ValueKey(w.id),
                windowData: w,
                onClose: () => windowManager.closeWindow(w.id),
                onMinimize: () => windowManager.minimizeWindow(w.id),
                onMaximize: () => windowManager.toggleMaximize(w.id),
                onFocus: () => windowManager.focusWindow(w.id),
                onPositionChanged: (pos) =>
                    windowManager.updatePosition(w.id, pos),
                onSizeChanged: (size) => windowManager.updateSize(w.id, size),
              ),
            ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TopBar(
            onMenuTap: () {
              setState(() {
                _showAppMenu = !_showAppMenu;
                _showQuickSettings = false;
              });
            },
            onQuickSettingsTap: () {
              setState(() {
                _showQuickSettings = !_showQuickSettings;
                _showAppMenu = false;
              });
            },
          ),
        ),

        if (_showAppMenu)
          Positioned(
            top: 35,
            left: 10,
            child: AppMenu(
              onOpenApp: system.openApp,
              onClose: () => setState(() => _showAppMenu = false),
            ),
          ),

        if (_showQuickSettings)
          Positioned(top: 35, right: 10, child: const QuickSettings()),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: hideDock ? -100 : 20,
          left: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (_) {
              // Optionally we can show dock on hover even if it's hidden, 
              // but standard behavior is fine for now
            },
            child: Dock(onOpenApp: system.openApp),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    SystemSettings settings,
    WindowManager windowManager,
    SystemController system,
    WindowData? focusedWindow,
    List<AppInfo> apps,
  ) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Stack(
      children: [
        if (focusedWindow == null) _buildMobileHomeScreen(context, system, apps),

        if (focusedWindow != null)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  Container(
                    height: 80,
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 20,
                      right: 20,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: onSurfaceColor),
                          onPressed: () =>
                              windowManager.closeWindow(focusedWindow.id),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          focusedWindow.title,
                          style: GoogleFonts.inter(
                            color: onSurfaceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: focusedWindow.content),
                  GestureDetector(
                    onTap: () => windowManager.closeWindow(focusedWindow.id),
                    child: Container(
                      height: 30,
                      width: double.infinity,
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Container(
                        width: 140,
                        height: 5,
                        decoration: BoxDecoration(
                          color: onSurfaceColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TimeOfDay.now().format(context),
                  style: GoogleFonts.inter(
                    color: onSurfaceColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.wifi, size: 16, color: onSurfaceColor),
                    const SizedBox(width: 6),
                    Icon(Icons.battery_full, size: 16, color: onSurfaceColor),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (focusedWindow == null)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: apps
                    .take(4)
                    .map(
                      (app) => _buildMobileIcon(
                        app,
                        system,
                        size: 55,
                        showLabel: false,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileHomeScreen(BuildContext context, SystemController system, List<AppInfo> apps) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, left: 30, right: 30),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 30,
          crossAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return _buildMobileIcon(app, system);
        },
      ),
    );
  }

  Widget _buildMobileIcon(
    AppInfo app,
    SystemController system, {
    double size = 60,
    bool showLabel = true,
  }) {
    return GestureDetector(
      onTap: () => system.openApp(
        app.id,
        app.title,
        app.content,
        app.icon,
        url: app.url,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: app.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              app.icon is IconData ? app.icon : Icons.apps,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 8),
            Text(
              app.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [const Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
