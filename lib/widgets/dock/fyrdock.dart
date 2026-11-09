import 'dart:ui';
import 'package:flutter/material.dart';
import '../../fyr_theme.dart';
import '../../app_data.dart';
import '../../models/config_model.dart';
import '../../window_manager.dart';
import 'package:provider/provider.dart';
import '../portfolio_app_icon.dart';

class FyrDock extends StatefulWidget {
  final Function(String id, String title, Widget? content, dynamic icon, {String? url}) onOpenApp;
  final VoidCallback onOpenSearch;

  const FyrDock({
    super.key,
    required this.onOpenApp,
    required this.onOpenSearch,
  });

  @override
  State<FyrDock> createState() => _FyrDockState();
}

class _FyrDockState extends State<FyrDock> {
  // Pinned app IDs by default
  late List<String> _pinnedAppIds;
  String? _tooltipAppId;

  @override
  void initState() {
    super.initState();
    _pinnedAppIds = [
      'browser',
      'terminal',
      'files',
      'code',
      'beats_by_arch',
      'bybl',
      'friendly',
      'welledumacated',
      'carlyle',
      'we_iac',
      'infra_monitor',
      'grand_theft_ant',
      'resume',
      'music',
      'photos',
      'settings',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final windowManager = context.watch<WindowManager>();
    final allApps = getApps(config);
    final openWindows = windowManager.windows;

    // Filter pinned apps
    final pinnedApps = _pinnedAppIds
        .map((id) {
          final found = allApps.where((a) => a.id == id).toList();
          return found.isNotEmpty ? found.first : null;
        })
        .whereType<AppInfo>()
        .toList();

    // Filter unpinned open windows
    final unpinnedWindows = openWindows.where(
      (w) => !_pinnedAppIds.contains(w.appId) && !_pinnedAppIds.contains(w.id),
    ).toList();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimized Windows & New Instance Tooltip
          if (_tooltipAppId != null) ...[
            _buildMinimizedTooltip(context, windowManager, allApps),
            const SizedBox(height: 8),
          ],

          // Dock Container - Completely transparent background
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      // All Apps button
                      _AllAppsButton(onTap: () {
                        setState(() => _tooltipAppId = null);
                        widget.onOpenSearch();
                      }),
                      const SizedBox(width: 6),

                      // Pinned Apps
                      ...pinnedApps.map((app) {
                        final appWins = windowManager.getWindowsForApp(app.id);
                        final isRunning = appWins.isNotEmpty;
                        final hasMinimized = appWins.any((w) => w.isMinimized);
                        final isFocused = appWins.any((w) => w.isFocused);

                        return _DockIcon(
                          app: app,
                          isOpen: isRunning,
                          isMinimized: hasMinimized,
                          isFocused: isFocused,
                          onTap: () {
                            if (hasMinimized) {
                              // If app is minimized, show small tooltip with minimized window or option to launch a new one
                              setState(() {
                                _tooltipAppId = (_tooltipAppId == app.id) ? null : app.id;
                              });
                            } else {
                              // Opening apps should launch a new instance
                              setState(() => _tooltipAppId = null);
                              if (app.content != null) {
                                windowManager.openNewInstance(app.id, app.title, app.content!, app.icon);
                              } else {
                                widget.onOpenApp(
                                  app.id,
                                  app.title,
                                  app.content,
                                  app.icon,
                                  url: app.url,
                                );
                              }
                            }
                          },
                          onUnpin: () {
                            setState(() {
                              _pinnedAppIds.remove(app.id);
                            });
                          },
                        );
                      }),

                      // Unpinned running apps (if any)
                      if (unpinnedWindows.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                          child: VerticalDivider(
                            color: FyrTheme.textColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        ...unpinnedWindows.map((win) {
                          final appMatch = allApps.where((a) => a.id == win.appId || a.id == win.id).toList();
                          final appInfo = appMatch.isNotEmpty
                              ? appMatch.first
                              : AppInfo(
                                  id: win.appId,
                                  title: win.title,
                                  icon: win.icon,
                                  content: win.content,
                                );

                          return _DockIcon(
                            app: appInfo,
                            isOpen: true,
                            isMinimized: win.isMinimized,
                            isFocused: win.isFocused,
                            onTap: () {
                              if (win.isMinimized) {
                                windowManager.unminimizeWindow(win.id);
                              } else if (win.isFocused) {
                                windowManager.minimizeWindow(win.id);
                              } else {
                                windowManager.focusWindow(win.id);
                              }
                            },
                            onUnpin: null,
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildMinimizedTooltip(
    BuildContext context,
    WindowManager windowManager,
    List<AppInfo> allApps,
  ) {
    final appId = _tooltipAppId!;
    final appMatch = allApps.where((a) => a.id == appId).toList();
    final app = appMatch.isNotEmpty ? appMatch.first : null;
    final minWindows = windowManager.getMinimizedWindowsForApp(appId);

    if (minWindows.isEmpty || app == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tooltipAppId = null);
      });
      return const SizedBox.shrink();
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: FyrTheme.bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FyrTheme.cardColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.layers, size: 14, color: FyrTheme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${app.title} (Minimized)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: FyrTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _tooltipAppId = null),
                    child: Icon(Icons.close, size: 14, color: FyrTheme.textColorMuted),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: FyrTheme.dividerColor),

            // Minimized Windows List
            ...minWindows.map((win) {
              return InkWell(
                onTap: () {
                  windowManager.unminimizeWindow(win.id);
                  setState(() => _tooltipAppId = null);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_browser_rounded, size: 15, color: FyrTheme.accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          win.title,
                          style: TextStyle(fontSize: 12, color: FyrTheme.textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Restore',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: FyrTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            Divider(height: 1, color: FyrTheme.dividerColor),

            // Option to Launch a New One
            InkWell(
              onTap: () {
                setState(() => _tooltipAppId = null);
                if (app.content != null) {
                  windowManager.openNewInstance(app.id, app.title, app.content!, app.icon);
                } else {
                  widget.onOpenApp(
                    app.id,
                    app.title,
                    app.content,
                    app.icon,
                    url: app.url,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, size: 15, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    const Text(
                      '+ New Window',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
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

class _AllAppsButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AllAppsButton({required this.onTap});

  @override
  State<_AllAppsButton> createState() => _AllAppsButtonState();
}

class _AllAppsButtonState extends State<_AllAppsButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'All Apps (fyrSearch)',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: FyrTheme.hoverColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            width: _isHovered ? 60 : 54,
            height: 64,
            alignment: Alignment.center,
            child: AnimatedScale(
              scale: _isHovered ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                Icons.apps,
                color: FyrTheme.textColor,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatefulWidget {
  final AppInfo app;
  final bool isOpen;
  final bool isMinimized;
  final bool isFocused;
  final VoidCallback onTap;
  final VoidCallback? onUnpin;

  const _DockIcon({
    required this.app,
    required this.isOpen,
    required this.isMinimized,
    required this.isFocused,
    required this.onTap,
    this.onUnpin,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: widget.app.title,
        child: GestureDetector(
          onSecondaryTapDown: widget.onUnpin == null
              ? null
              : (details) {
                  showMenu(
                    context: context,
                    color: FyrTheme.bgColor,
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy - 60,
                      details.globalPosition.dx + 120,
                      0,
                    ),
                    items: [
                      PopupMenuItem(
                        value: 'unpin',
                        child: Text(
                          'Unpin from Dock',
                          style: TextStyle(color: FyrTheme.textColor, fontSize: 13),
                        ),
                        onTap: widget.onUnpin,
                      ),
                    ],
                  );
                },
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              hoverColor: FyrTheme.hoverColor,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                width: _isHovered ? 62 : 54,
                height: 64,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: _isHovered ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: _buildIconWidget(),
                    ),
                    if (widget.isOpen)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: widget.isFocused
                            ? 16
                            : (widget.isMinimized ? 24 : 8),
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.isMinimized
                              ? FyrTheme.accentColor
                              : FyrTheme.textColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(2),
                        ),
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

  Widget _buildIconWidget() {
    return PortfolioAppIcon(
      app: widget.app,
      size: 38,
    );
  }
}
