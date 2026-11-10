import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'system_settings.dart';
import 'window_manager.dart';
import 'window_frame.dart';
import 'system_controller.dart';
import 'app_data.dart';
import 'models/config_model.dart';
import 'widgets/taskbar/fyrtaskbar.dart';
import 'widgets/taskbar/start_menu_popup.dart';
import 'widgets/taskbar/calendar_menu_popup.dart';
import 'widgets/taskbar/quick_settings_popup.dart';
import 'widgets/dock/fyrdock.dart';
import 'widgets/fyrsearch/fyrsearch_screen.dart';
import 'widgets/fyroverview/fyroverview_screen.dart';
import 'widgets/portfolio_app_icon.dart';
import 'apps/fyrsettings_app.dart';
import 'apps/music_player_app.dart';
import 'services/music_audio/music_audio.dart';
import 'fyr_theme.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  bool _showStartMenu = false;
  bool _showCalendar = false;
  bool _showQuickSettings = false;
  bool _showSearch = false;
  bool _showOverview = false;
  bool _isDockHovered = false;
  bool _didPrecacheAssets = false;
  bool _showMobileMusicToast = false;
  Timer? _mobileMusicToastTimer;
  bool _isDisposed = false;
  ModalRoute<dynamic>? _route;
  LocalHistoryEntry? _historyEntry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    if (!_didPrecacheAssets) {
      _didPrecacheAssets = true;
      _precacheCriticalImages();
    }
  }

  Future<void> _precacheCriticalImages() async {
    // Skip heavy disk asset precaching during widget tests
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;

    final config = context.read<AppConfig>();
    unawaited(precacheImage(const AssetImage('assets/space.jpg'), context));
    unawaited(precacheImage(const AssetImage('assets/wallpaper.jpg'), context));
    unawaited(precacheImage(const AssetImage('assets/icons/fyr_icon.png'), context));
    if (config.profile.profilePic.isNotEmpty) {
      unawaited(precacheImage(AssetImage(config.profile.profilePic), context));
    }
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!mounted) return;
      final photos = manifest.listAssets().where(
        (k) =>
            k.startsWith('assets/photos/') &&
            (k.endsWith('.webp') ||
                k.endsWith('.png') ||
                k.endsWith('.jpg') ||
                k.endsWith('.jpeg')),
      );
      for (final path in photos) {
        if (!mounted) break;
        unawaited(
          precacheImage(
            ResizeImage(AssetImage(path), width: 400),
            context,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mobileMusicToastTimer?.cancel();
    if (_historyEntry != null) {
      final entry = _historyEntry!;
      _historyEntry = null;
      _route?.removeLocalHistoryEntry(entry);
    }
    super.dispose();
  }

  void _triggerMobileMusicToast() {
    _mobileMusicToastTimer?.cancel();
    setState(() {
      _showMobileMusicToast = true;
    });
    _mobileMusicToastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showMobileMusicToast = false;
        });
      }
    });
  }

  void _closeMobileWindow(String windowId, WindowManager windowManager) {
    final music = context.read<MusicService>();
    final isMusic = windowId == 'music' || windowId.startsWith('music');
    windowManager.closeWindow(windowId);
    if (isMusic && music.isPlaying) {
      _triggerMobileMusicToast();
    }
  }

  void _updateHistoryEntry(bool shouldHaveEntry) {
    if (shouldHaveEntry && _historyEntry == null) {
      _historyEntry = LocalHistoryEntry(
        onRemove: () {
          _historyEntry = null;
          if (!mounted || _isDisposed) return;
          final windowManager = context.read<WindowManager>();
          if (_showOverview || _showSearch) {
            setState(() {
              _showOverview = false;
              _showSearch = false;
            });
            return;
          }
          if (_showStartMenu || _showCalendar || _showQuickSettings) {
            setState(() {
              _showStartMenu = false;
              _showCalendar = false;
              _showQuickSettings = false;
            });
            return;
          }
          final openWindows = windowManager.windows
              .where((w) => !w.isMinimized)
              .toList();
          if (openWindows.isNotEmpty) {
            final closing = openWindows.last;
            windowManager.closeWindow(closing.id);
            final isMobile = MediaQuery.of(context).size.width < 600;
            final music = context.read<MusicService>();
            if (isMobile && (closing.id == 'music' || closing.appId == 'music') && music.isPlaying) {
              _triggerMobileMusicToast();
            }
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
    final hasActiveOverlay = focusedWindowForPop != null ||
        _showStartMenu ||
        _showCalendar ||
        _showQuickSettings ||
        _showSearch ||
        _showOverview;

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

          // Dock autohide should only hide the dock when a window goes over it
          final dockZone = Rect.fromLTWH(0, screenHeight - 88, screenWidth, 88);
          final isWindowOverDock = openWindows.any((w) {
            if (w.isMinimized) return false;
            if (w.isMaximized) return true;
            final winRect = Rect.fromLTWH(w.position.dx, w.position.dy, w.size.width, w.size.height);
            return winRect.overlaps(dockZone);
          });

          // Fixed dock keeps the dock up the entire time. Autohide only hides when window goes over it.
          final hideDock = settings.dockAutoHide && isWindowOverDock && !_isDockHovered;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showStartMenu = false;
                      _showCalendar = false;
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
    final screenSize = MediaQuery.of(context).size;
    final currentWs = windowManager.currentWorkspace;
    final activeWindows = windowManager
        .getWindowsForWorkspace(currentWs)
        .where((w) => !w.isMinimized)
        .toList();

    final Map<String, Rect> tilingRects = windowManager.isTilingMode
        ? windowManager.calculateTilingRects(
            screenSize: screenSize,
            topBarHeight: 56.0,
            bottomReserved: hideDock ? 0.0 : 84.0,
          )
        : {};

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        // Escape closes overlays
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (_showOverview || _showSearch || _showStartMenu || _showCalendar || _showQuickSettings) {
            setState(() {
              _showOverview = false;
              _showSearch = false;
              _showStartMenu = false;
              _showCalendar = false;
              _showQuickSettings = false;
            });
            return KeyEventResult.handled;
          }
        }

        final isMeta = HardwareKeyboard.instance.isMetaPressed;
        final isAlt = HardwareKeyboard.instance.isAltPressed;
        final isControl = HardwareKeyboard.instance.isControlPressed;
        final isShift = HardwareKeyboard.instance.isShiftPressed;

        // Never intercept if Control is pressed (preserves app/terminal shortcuts like Ctrl+V, Ctrl+C, Ctrl+E, Ctrl+A)
        if (isControl) return KeyEventResult.ignored;

        // Never intercept if an editable input/text field currently has focus
        final focusNode = FocusManager.instance.primaryFocus;
        if (focusNode != null && focusNode.context?.widget is EditableText) {
          return KeyEventResult.ignored;
        }

        // Mod key is Alt (Option on macOS, Alt on Linux/Windows) or Super/Meta
        final isMod = isAlt || isMeta;
        if (!isMod) return KeyEventResult.ignored;

        // If Meta/Cmd is pressed without Alt, protect standard OS/browser shortcuts (Cmd+V, Cmd+C, Cmd+Z, etc.)
        if (isMeta && !isAlt) {
          if (event.logicalKey == LogicalKeyboardKey.keyV ||
              event.logicalKey == LogicalKeyboardKey.keyC ||
              event.logicalKey == LogicalKeyboardKey.keyX ||
              event.logicalKey == LogicalKeyboardKey.keyZ ||
              event.logicalKey == LogicalKeyboardKey.keyA ||
              event.logicalKey == LogicalKeyboardKey.keyW ||
              event.logicalKey == LogicalKeyboardKey.keyR) {
            return KeyEventResult.ignored;
          }
        }
          // $mod + q: kill focused window
          if (event.logicalKey == LogicalKeyboardKey.keyQ) {
            windowManager.closeFocusedWindow();
            return KeyEventResult.handled;
          }

          // $mod + m: toggle tiling/floating mode
          if (event.logicalKey == LogicalKeyboardKey.keyM) {
            windowManager.toggleTilingMode();
            return KeyEventResult.handled;
          }

          // $mod + f: toggle maximize
          if (event.logicalKey == LogicalKeyboardKey.keyF && !isShift) {
            windowManager.toggleMaximizeFocusedWindow();
            return KeyEventResult.handled;
          }

          // $mod + v: split vertical (splitv)
          if (event.logicalKey == LogicalKeyboardKey.keyV) {
            windowManager.setSplitLayout('splitv');
            return KeyEventResult.handled;
          }

          // $mod + h: split horizontal (splith)
          if (event.logicalKey == LogicalKeyboardKey.keyH) {
            windowManager.setSplitLayout('splith');
            return KeyEventResult.handled;
          }

          // $mod + e: toggle split layout
          if (event.logicalKey == LogicalKeyboardKey.keyE) {
            windowManager.toggleSplitLayout();
            return KeyEventResult.handled;
          }

          // $mod + r: retile windows into perfect grid
          if (event.logicalKey == LogicalKeyboardKey.keyR) {
            windowManager.retileWorkspace();
            return KeyEventResult.handled;
          }

          // $mod + space: toggle search
          if (event.logicalKey == LogicalKeyboardKey.space) {
            setState(() {
              _showSearch = !_showSearch;
              _showOverview = false;
              _showStartMenu = false;
              _showCalendar = false;
              _showQuickSettings = false;
            });
            return KeyEventResult.handled;
          }

          // $mod + Tab: toggle overview
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            setState(() {
              _showOverview = !_showOverview;
              _showSearch = false;
              _showStartMenu = false;
              _showCalendar = false;
              _showQuickSettings = false;
            });
            return KeyEventResult.handled;
          }

          // $mod + t: open terminal
          if (event.logicalKey == LogicalKeyboardKey.keyT) {
            final appList = getApps(context.read<AppConfig>());
            final termApp = appList.firstWhere((a) => a.id == 'terminal');
            windowManager.openNewInstance('terminal', 'fyrTerm', termApp.content!, termApp.icon);
            return KeyEventResult.handled;
          }

          // $mod + Shift + Arrows: resize tiled window (same shortcut as fyrDE)
          if (isShift) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              windowManager.resizeFocusedTiledWindow(-1, 0);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              windowManager.resizeFocusedTiledWindow(1, 0);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              windowManager.resizeFocusedTiledWindow(0, -1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              windowManager.resizeFocusedTiledWindow(0, 1);
              return KeyEventResult.handled;
            }
          } else {
            // $mod + Arrows: cycle focus
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.arrowUp) {
              windowManager.focusPreviousWindow();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.arrowDown) {
              windowManager.focusNextWindow();
              return KeyEventResult.handled;
            }
          }

          // $mod + 1..9: switch workspace, or $mod + Shift + 1..9: move container
          final digitKeys = [
            LogicalKeyboardKey.digit1,
            LogicalKeyboardKey.digit2,
            LogicalKeyboardKey.digit3,
            LogicalKeyboardKey.digit4,
            LogicalKeyboardKey.digit5,
            LogicalKeyboardKey.digit6,
            LogicalKeyboardKey.digit7,
            LogicalKeyboardKey.digit8,
            LogicalKeyboardKey.digit9,
          ];
          for (int i = 0; i < digitKeys.length; i++) {
            if (event.logicalKey == digitKeys[i]) {
              final wsNum = i + 1;
              if (isShift) {
                windowManager.moveFocusedWindowToWorkspace(wsNum);
              } else {
                windowManager.switchWorkspace(wsNum);
              }
              return KeyEventResult.handled;
            }
          }

        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          // Windows in current workspace
          ...activeWindows.map(
            (w) => WindowFrame(
              key: ValueKey(w.id),
              windowData: w,
              tilingRect: windowManager.isTilingMode ? tilingRects[w.id] : null,
              isDockFixed: !settings.dockAutoHide,
              onClose: () => windowManager.closeWindow(w.id),
              onMinimize: () => windowManager.minimizeWindow(w.id),
              onMaximize: () => windowManager.toggleMaximize(w.id),
              onFocus: () => windowManager.focusWindow(w.id),
              onPositionChanged: (pos) => windowManager.updatePosition(w.id, pos),
              onSizeChanged: (size) => windowManager.updateSize(w.id, size),
            ),
          ),

          // Tiling Mode Resizing Divider (for 2 tiled windows)
          if (windowManager.isTilingMode && activeWindows.length == 2)
            _buildTilingDivider(context, screenSize, windowManager, hideDock),

          // Dock Hover detection zone if autohide
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

          // Bottom Dock (64px) - 1:1 replica of fyrDE fyrdock
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: hideDock ? -100 : 0,
            left: 0,
            right: 0,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isDockHovered = true),
              onExit: (_) => setState(() => _isDockHovered = false),
              child: FyrDock(
                onOpenApp: system.openApp,
                onOpenSearch: () {
                  setState(() {
                    _showSearch = true;
                    _showStartMenu = false;
                    _showCalendar = false;
                    _showQuickSettings = false;
                  });
                },
              ),
            ),
          ),

          // Top Taskbar (56px) - 1:1 replica of fyrDE fyrtaskbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FyrTaskbar(
              onToggleStartMenu: () {
                setState(() {
                  _showStartMenu = !_showStartMenu;
                  _showCalendar = false;
                  _showQuickSettings = false;
                });
              },
              onToggleCalendar: () {
                setState(() {
                  _showCalendar = !_showCalendar;
                  _showStartMenu = false;
                  _showQuickSettings = false;
                });
              },
              onToggleQuickSettings: () {
                setState(() {
                  _showQuickSettings = !_showQuickSettings;
                  _showStartMenu = false;
                  _showCalendar = false;
                });
              },
              onToggleOverview: () {
                setState(() {
                  _showOverview = !_showOverview;
                  _showStartMenu = false;
                  _showCalendar = false;
                  _showQuickSettings = false;
                  _showSearch = false;
                });
              },
            ),
          ),

          // Start Menu Popup (renders in front of dock and taskbar)
          if (_showStartMenu)
            Positioned(
              top: 56,
              left: 0,
              bottom: 0,
              child: StartMenuPopup(
                onClose: () => setState(() => _showStartMenu = false),
                onOpenApp: system.openApp,
              ),
            ),

          // Calendar & Notifications Menu Popup (under clock)
          if (_showCalendar)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: CalendarMenuPopup(
                  onClose: () => setState(() => _showCalendar = false),
                  onOpenCalendar: () => system.openApp(
                    'calendar',
                    'fyrCalendar',
                    null,
                    'assets/icons/calendar.png',
                  ),
                ),
              ),
            ),

          // Quick Settings Popup (top right corner)
          if (_showQuickSettings)
            Positioned(
              top: 56,
              right: 0,
              child: QuickSettingsPopup(
                onClose: () => setState(() => _showQuickSettings = false),
                onOpenSettings: () => system.openApp(
                  'settings',
                  'fyrSettings',
                  const FyrSettingsApp(),
                  'assets/icons/settings.png',
                ),
              ),
            ),

          // Full-screen fyrSearch
          if (_showSearch)
            Positioned.fill(
              child: FyrSearchScreen(
                onClose: () => setState(() => _showSearch = false),
                onOpenApp: system.openApp,
              ),
            ),

          // Full-screen fyrOverview
          if (_showOverview)
            Positioned.fill(
              child: FyrOverviewScreen(
                onClose: () => setState(() => _showOverview = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTilingDivider(
    BuildContext context,
    Size screenSize,
    WindowManager windowManager,
    bool hideDock,
  ) {
    const double outerGap = 20.0;
    const double innerGap = 20.0;
    const double topBarHeight = 56.0;
    final double bottomReserved = hideDock ? 0.0 : 84.0;

    final double totalWidth = screenSize.width - (2 * outerGap);
    final double totalHeight = screenSize.height - topBarHeight - bottomReserved - (2 * outerGap);
    if (totalWidth <= 0 || totalHeight <= 0) return const SizedBox.shrink();

    final isHorizontalSplit = windowManager.splitLayout == 'splith';

    if (isHorizontalSplit) {
      final double availableW = totalWidth - innerGap;
      final double leftW = availableW * windowManager.splitRatio;
      final double dividerX = outerGap + leftW;

      return Positioned(
        left: dividerX,
        top: topBarHeight + outerGap,
        width: innerGap,
        height: totalHeight,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              windowManager.adjustSplitRatio(details.delta.dx / availableW);
            },
            child: Center(
              child: Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: FyrTheme.accentColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      final double availableH = totalHeight - innerGap;
      final double topH = availableH * windowManager.splitRatio;
      final double dividerY = topBarHeight + outerGap + topH;

      return Positioned(
        left: outerGap,
        top: dividerY,
        width: totalWidth,
        height: innerGap,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              windowManager.adjustSplitRatio(details.delta.dy / availableH);
            },
            child: Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: FyrTheme.accentColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildWallpaper(SystemSettings settings) {
    Widget imageWidget;
    if (settings.wallpaperBytes != null) {
      imageWidget = Image.memory(
        settings.wallpaperBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/space.jpg', fit: BoxFit.cover, gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover)),
      );
    } else if (settings.wallpaperPath.startsWith('assets')) {
      imageWidget = Image.asset(
        settings.wallpaperPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/space.jpg', fit: BoxFit.cover, gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover)),
      );
    } else if (settings.wallpaperPath.startsWith('http://') ||
        settings.wallpaperPath.startsWith('https://')) {
      imageWidget = Image.network(
        settings.wallpaperPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/space.jpg', fit: BoxFit.cover, gaplessPlayback: true),
      );
    } else {
      imageWidget = Image.asset('assets/space.jpg', fit: BoxFit.cover, gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover));
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
          if (_showMobileMusicToast)
            _buildMobileMusicToast(context, system, settings),
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
                              _closeMobileWindow(focusedWindow.id, windowManager),
                        ),
                        const SizedBox(width: 4),
                        PortfolioAppIcon(appId: focusedWindow.id, size: 22),
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
                    onTap: () => _closeMobileWindow(focusedWindow.id, windowManager),
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
                child: SizedBox(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  child: Center(
                    child: PortfolioAppIcon(
                      app: app,
                      size: iconBoxSize,
                      solidBackground: true,
                    ),
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

        final double vPad = (availH * 0.015).clamp(2.0, 10.0);
        final topPadding = vPad;
        final bottomPadding = vPad * 0.6;
        final double horizontalPadding = (availW * 0.03).clamp(8.0, 16.0);

        final contentH = (availH - topPadding - bottomPadding).clamp(
          100.0,
          double.infinity,
        );
        final contentW = (availW - (horizontalPadding * 2)).clamp(
          100.0,
          double.infinity,
        );

        final cellW = contentW / cols;
        final cellH = contentH / rows;

        // Proportional sizing based on cell dimensions so all apps always fit without scrolling
        final minDim = min(cellW, cellH);
        final maxBoxFromH = (cellH - 16.0).clamp(16.0, 56.0);
        final iconBoxSize = min(minDim * 0.50, maxBoxFromH).clamp(20.0, 54.0);
        final fontSize = (iconBoxSize * 0.22).clamp(8.5, 11.5);
        final spacing = (cellH * 0.04).clamp(1.0, 4.0);

        return Padding(
          padding: EdgeInsets.only(
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
                  fontSize: fontSize,
                  spacing: spacing,
                  cellW: cellW,
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
    required double fontSize,
    required double spacing,
    required double cellW,
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
            SizedBox(
              width: boxSize,
              height: boxSize,
              child: Center(
                child: PortfolioAppIcon(
                  app: app,
                  size: boxSize,
                  solidBackground: true,
                ),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              width: (cellW - 4.0).clamp(boxSize, cellW),
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

  Widget _buildMobileMusicToast(
    BuildContext context,
    SystemController system,
    SystemSettings settings,
  ) {
    final music = context.watch<MusicService>();
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = settings.accentColor;
    final trackName = music.currentTrackTitle.isNotEmpty
        ? music.currentTrackTitle
        : 'Unknown Track';

    return Positioned(
      top: 48,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141414).withValues(alpha: 0.88)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.graphic_eq_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _showMobileMusicToast = false);
                          system.openApp(
                            'music',
                            'fyrMusic',
                            const MusicPlayerApp(),
                            'assets/icons/music.png',
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              trackName.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        music.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: onSurfaceColor,
                        size: 22,
                      ),
                      onPressed: () => music.playPause(),
                      tooltip: music.isPlaying ? 'Pause' : 'Play',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: onSurfaceColor.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() => _showMobileMusicToast = false);
                      },
                      tooltip: 'Dismiss',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
