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
import 'dart:ui';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  bool _showAppMenu = false;
  bool _showQuickSettings = false;
  bool _isDockHovered = false;
  ModalRoute<dynamic>? _route;
  LocalHistoryEntry? _historyEntry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    if (_historyEntry != null) {
      _route?.removeLocalHistoryEntry(_historyEntry!);
    }
    super.dispose();
  }

  void _updateHistoryEntry(bool shouldHaveEntry) {
    if (shouldHaveEntry && _historyEntry == null) {
      _historyEntry = LocalHistoryEntry(
        onRemove: () {
          _historyEntry = null;
          if (!mounted) return;
          final windowManager = context.read<WindowManager>();
          final openWindows = windowManager.windows
              .where((w) => !w.isMinimized)
              .toList();
          if (openWindows.isNotEmpty) {
            windowManager.closeWindow(openWindows.last.id);
          } else if (_showAppMenu || _showQuickSettings) {
            setState(() {
              _showAppMenu = false;
              _showQuickSettings = false;
            });
          }
        },
      );
      _route?.addLocalHistoryEntry(_historyEntry!);
    } else if (!shouldHaveEntry && _historyEntry != null) {
      _route?.removeLocalHistoryEntry(_historyEntry!);
      _historyEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    final system = context.read<SystemController>();
    final windowManager = context.watch<WindowManager>();
    final config = context.watch<AppConfig>();
    final apps = getApps(config);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final openWindowsForPop = windowManager.windows
        .where((w) => !w.isMinimized)
        .toList();
    final focusedWindowForPop = openWindowsForPop.isNotEmpty
        ? openWindowsForPop.last
        : null;
    final hasActiveOverlay =
        focusedWindowForPop != null || _showAppMenu || _showQuickSettings;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHistoryEntry(hasActiveOverlay);
    });

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
          final screenWidth = MediaQuery.of(context).size.width;
          final isMaximized = openWindows.any((w) => w.isMaximized);

          // Dynamic dock dimensions matching Dock scaling
          const baseItemWidth = 56.0;
          const baseDockPadding = 18.0;
          final maxDockWidth = (screenWidth - 32.0).clamp(
            240.0,
            double.infinity,
          );
          final idealContentWidth =
              (apps.length * baseItemWidth) + baseDockPadding;
          final autoScale = (maxDockWidth / idealContentWidth).clamp(0.40, 1.0);
          final effectiveDockScale = autoScale * settings.dockScale;
          final currentDockHeight = (70.0 * effectiveDockScale).clamp(
            38.0,
            95.0,
          );

          final isIntersectingDock = openWindows.any(
            (w) =>
                !w.isMaximized &&
                (w.position.dy + w.size.height) >
                    (screenHeight - (currentDockHeight + 24)),
          );
          final hideDock =
              ((isMaximized || isIntersectingDock) && !_isDockHovered) ||
              (settings.dockAutoHide && !_isDockHovered);

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
                  child: _buildWallpaper(settings),
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
                _buildDesktopLayout(
                  context,
                  settings,
                  windowManager,
                  system,
                  hideDock,
                ),
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

        if (settings.dockAutoHide || hideDock)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 28,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isDockHovered = true),
              child: const SizedBox.expand(),
            ),
          ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          bottom: hideDock ? -100 : 20,
          left: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isDockHovered = true),
            onExit: (_) => setState(() => _isDockHovered = false),
            child: Dock(onOpenApp: system.openApp),
          ),
        ),
      ],
    );
  }

  Widget _buildWallpaper(SystemSettings settings) {
    Widget imageWidget;
    if (settings.wallpaperBytes != null) {
      imageWidget = Image.memory(
        settings.wallpaperBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
      );
    } else if (settings.wallpaperPath.startsWith('assets')) {
      imageWidget = Image.asset(
        settings.wallpaperPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
      );
    } else if (settings.wallpaperPath.startsWith('http://') ||
        settings.wallpaperPath.startsWith('https://')) {
      imageWidget = Image.network(
        settings.wallpaperPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
      );
    } else {
      imageWidget = Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover);
    }

    if (settings.wallpaperBlur > 0.1) {
      imageWidget = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: settings.wallpaperBlur,
          sigmaY: settings.wallpaperBlur,
        ),
        child: imageWidget,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        if (settings.wallpaperDim > 0.02)
          Container(
            color: Colors.black.withValues(alpha: settings.wallpaperDim),
          ),
        if (settings.nightShift)
          IgnorePointer(
            child: Container(color: Colors.amber.withValues(alpha: 0.12)),
          ),
        if (settings.screenBrightness < 0.98)
          IgnorePointer(
            child: Container(
              color: Colors.black.withValues(
                alpha: (1.0 - settings.screenBrightness) * 0.75,
              ),
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
    final screenHeight = MediaQuery.of(context).size.height;

    final dockHeight = (screenHeight * 0.09).clamp(58.0, 76.0);
    final dockBottomMargin = (screenHeight * 0.02).clamp(10.0, 20.0);
    final dockTotalBottom = dockHeight + dockBottomMargin + 8.0;

    return Stack(
      children: [
        if (focusedWindow == null) ...[
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            bottom: dockTotalBottom,
            child: _buildMobileHomeScreen(context, system, apps),
          ),
          Positioned(
            bottom: dockBottomMargin,
            left: 20,
            right: 20,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildMobileDock(context, system, apps, dockHeight),
              ),
            ),
          ),
        ],

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
                          color: onSurfaceColor.withValues(alpha: 0.2),
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
      ],
    );
  }

  Widget _buildMobileDock(
    BuildContext context,
    SystemController system,
    List<AppInfo> apps,
    double height,
  ) {
    final dockApps = apps.take(4).toList();
    final iconBoxSize = (height * 0.64).clamp(36.0, 54.0);
    final glyphSize = (iconBoxSize * 0.56).clamp(18.0, 28.0);
    final iconRadius = (iconBoxSize * 0.28).clamp(8.0, 15.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: dockApps.map((app) {
              return GestureDetector(
                onTap: () => system.openApp(
                  app.id,
                  app.title,
                  app.content,
                  app.icon,
                  url: app.url,
                ),
                child: Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: app.color,
                    borderRadius: BorderRadius.circular(iconRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: app.icon is IconData
                      ? Icon(app.icon, color: Colors.white, size: glyphSize)
                      : FaIcon(
                          app.icon,
                          color: Colors.white,
                          size: glyphSize * 0.9,
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHomeScreen(
    BuildContext context,
    SystemController system,
    List<AppInfo> apps,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = constraints.maxHeight;

        // Choose 5 columns on wider devices / landscape, 4 columns on standard mobile
        final int cols = availW >= 480 ? 5 : 4;
        final int rows = (apps.length / cols).ceil();

        const topPadding = 10.0;
        const bottomPadding = 6.0;
        const horizontalPadding = 16.0;

        final contentH = (availH - topPadding - bottomPadding).clamp(
          120.0,
          double.infinity,
        );
        final contentW = (availW - (horizontalPadding * 2)).clamp(
          120.0,
          double.infinity,
        );

        final cellW = contentW / cols;
        final cellH = contentH / rows;

        // Proportional sizing based on cell dimensions so all apps always fit
        final minDim = min(cellW, cellH);
        final iconBoxSize = (minDim * 0.50).clamp(28.0, 56.0);
        final iconGlyphSize = (iconBoxSize * 0.56).clamp(15.0, 30.0);
        final fontSize = (iconBoxSize * 0.22).clamp(9.0, 11.5);
        final iconRadius = (iconBoxSize * 0.28).clamp(7.0, 16.0);

        return Padding(
          padding: const EdgeInsets.only(
            top: topPadding,
            bottom: bottomPadding,
            left: horizontalPadding,
            right: horizontalPadding,
          ),
          child: SizedBox(
            width: contentW,
            height: contentH,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                childAspectRatio: cellW / cellH,
              ),
              itemBuilder: (context, index) {
                final app = apps[index];
                return _buildMobileIcon(
                  app,
                  system,
                  boxSize: iconBoxSize,
                  glyphSize: iconGlyphSize,
                  fontSize: fontSize,
                  borderRadius: iconRadius,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileIcon(
    AppInfo app,
    SystemController system, {
    required double boxSize,
    required double glyphSize,
    required double fontSize,
    required double borderRadius,
  }) {
    return GestureDetector(
      onTap: () => system.openApp(
        app.id,
        app.title,
        app.content,
        app.icon,
        url: app.url,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: boxSize,
              height: boxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: app.color,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: app.icon is IconData
                  ? Icon(app.icon, color: Colors.white, size: glyphSize)
                  : FaIcon(
                      app.icon,
                      color: Colors.white,
                      size: glyphSize * 0.9,
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: boxSize * 1.5,
              child: Text(
                app.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
