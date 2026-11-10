import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'window_manager.dart';
import 'fyr_theme.dart';
import 'widgets/portfolio_app_icon.dart';
import 'apps/fyrsettings_app.dart';

class WindowFrame extends StatelessWidget {
  final WindowData windowData;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onFocus;
  final Function(Offset) onPositionChanged;
  final Function(Size) onSizeChanged;
  final Rect? tilingRect;
  final bool isDockFixed;

  const WindowFrame({
    super.key,
    required this.windowData,
    required this.onClose,
    required this.onMinimize,
    required this.onMaximize,
    required this.onFocus,
    required this.onPositionChanged,
    required this.onSizeChanged,
    this.tilingRect,
    this.isDockFixed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = FyrTheme.isDark;
    final accentColor = FyrTheme.accentColor;
    final isTiled = tilingRect != null;
    final screenSize = MediaQuery.of(context).size;

    final double maxBottomOffset = (windowData.isMaximized && isDockFixed) ? 84.0 : 0.0;
    final double targetWidth = windowData.isMaximized
        ? screenSize.width
        : (isTiled ? tilingRect!.width : windowData.size.width);
    final double targetHeight = windowData.isMaximized
        ? (screenSize.height - 56.0 - maxBottomOffset)
        : (isTiled ? tilingRect!.height : windowData.size.height);
    final double targetLeft = windowData.isMaximized
        ? 0.0
        : (isTiled ? tilingRect!.left : windowData.position.dx);
    final double targetTop = windowData.isMaximized
        ? 56.0
        : (isTiled ? tilingRect!.top : windowData.position.dy);

    final String appId = windowData.appId.toLowerCase();
    final bool isSettings = appId == 'fyrsettings' ||
                            windowData.title.toLowerCase().contains('settings');
    final bool isBrowser = appId == 'browser' ||
                           windowData.title.toLowerCase().contains('browser');
    final Color topBarColor = isBrowser ? const Color(0xFF1F1F23) : FyrTheme.surfaceColor;

    Widget topBarContent;
    if (isSettings) {
      topBarContent = ValueListenableBuilder<bool>(
        valueListenable: FyrSettingsApp.isSidebarCollapsedNotifier,
        builder: (context, isSidebarCollapsed, _) {
          final double sidebarWidth = isSidebarCollapsed ? 72.0 : 260.0;
          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: sidebarWidth,
                height: 42,
                color: accentColor.withValues(alpha: 0.82),
                padding: EdgeInsets.symmetric(
                  horizontal: isSidebarCollapsed ? 9.0 : 16.0,
                ),
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: 260,
                    minWidth: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WindowControl(
                          color: Colors.redAccent,
                          onTap: onClose,
                          icon: Icons.close,
                        ),
                        SizedBox(width: isSidebarCollapsed ? 6 : 8),
                        _WindowControl(
                          color: Colors.amber.shade300,
                          onTap: onMinimize,
                          icon: Icons.remove,
                        ),
                        SizedBox(width: isSidebarCollapsed ? 6 : 8),
                        _WindowControl(
                          color: Colors.greenAccent,
                          onTap: onMaximize,
                          icon: windowData.isMaximized
                              ? Icons.close_fullscreen
                              : Icons.fullscreen,
                        ),
                        if (!isSidebarCollapsed) ...[
                          const SizedBox(width: 16),
                          Text(
                            'Settings',
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              color: FyrTheme.onColor(accentColor),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 42,
                  color: FyrTheme.bgColor,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: isTiled
                      ? Icon(
                          Icons.grid_view,
                          size: 14,
                          color: FyrTheme.textColorMuted,
                        )
                      : null,
                ),
              ),
            ],
          );
        },
      );
    } else {
      topBarContent = Container(
        height: 42,
        width: double.infinity,
        color: topBarColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // macOS style traffic light dots
            _WindowControl(
              color: Colors.redAccent,
              onTap: onClose,
              icon: Icons.close,
            ),
            const SizedBox(width: 8),
            _WindowControl(
              color: Colors.amber.shade300,
              onTap: onMinimize,
              icon: Icons.remove,
            ),
            const SizedBox(width: 8),
            _WindowControl(
              color: Colors.greenAccent,
              onTap: onMaximize,
              icon: windowData.isMaximized
                  ? Icons.close_fullscreen
                  : Icons.fullscreen,
            ),
            const SizedBox(width: 16),
            _buildAppIcon(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                windowData.title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: FyrTheme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isTiled)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.grid_view,
                  size: 14,
                  color: FyrTheme.textColorMuted,
                ),
              ),
          ],
        ),
      );
    }

    final double radius = windowData.isMaximized ? 0.0 : 22.0;
    final double borderWidth = windowData.isFocused ? 5.0 : 1.5;
    final Color borderColor = windowData.isFocused
        ? accentColor
        : (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.15));

    Widget windowContent = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: windowData.isMaximized
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 0, // No spread on active or inactive windows
                    offset: const Offset(0, 8),
                  ),
                  if (windowData.isFocused)
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              // 1. Frosted background & Window App Content
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    color: isSettings ? Colors.transparent : FyrTheme.surfaceColor,
                    child: Column(
                      children: [
                        // Window Header / Titlebar - Natural continuation of the app
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (windowData.isMaximized || isTiled)
                              ? null
                              : (details) {
                                  onPositionChanged(
                                    windowData.position + details.delta,
                                  );
                                },
                          onDoubleTap: onMaximize,
                          child: topBarContent,
                        ),
                        // Window Body - State preserved via KeyedSubtree
                        Expanded(
                          child: Container(
                            color: isSettings ? Colors.transparent : FyrTheme.surfaceColor,
                            child: KeyedSubtree(
                              key: ValueKey('win_subtree_${windowData.id}'),
                              child: windowData.content,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Colored Window Border - Drawn ON TOP of content so corners NEVER leak out!
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Resize Handles (only active in floating mode and when not maximized)
              if (!windowData.isMaximized && !isTiled) ...[
                // Top Edge Handle
                Positioned(
                  top: 0,
                  left: 14,
                  right: 14,
                  height: 7,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        final newHeight = (windowData.size.height - details.delta.dy).clamp(240.0, 1600.0);
                        if (newHeight != windowData.size.height) {
                          onSizeChanged(Size(windowData.size.width, newHeight));
                          onPositionChanged(
                            windowData.position + Offset(0, details.delta.dy),
                          );
                        }
                      },
                    ),
                  ),
                ),
                // Top Left Corner
                Positioned(
                  top: 0,
                  left: 0,
                  width: 14,
                  height: 14,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpLeftDownRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        final newWidth = (windowData.size.width - details.delta.dx).clamp(360.0, 2400.0);
                        final newHeight = (windowData.size.height - details.delta.dy).clamp(240.0, 1600.0);
                        onSizeChanged(Size(newWidth, newHeight));
                        onPositionChanged(
                          windowData.position + Offset(details.delta.dx, details.delta.dy),
                        );
                      },
                    ),
                  ),
                ),
                // Top Right Corner
                Positioned(
                  top: 0,
                  right: 0,
                  width: 14,
                  height: 14,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpRightDownLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        final newWidth = (windowData.size.width + details.delta.dx).clamp(360.0, 2400.0);
                        final newHeight = (windowData.size.height - details.delta.dy).clamp(240.0, 1600.0);
                        onSizeChanged(Size(newWidth, newHeight));
                        onPositionChanged(
                          windowData.position + Offset(0, details.delta.dy),
                        );
                      },
                    ),
                  ),
                ),
                // Right Edge
                Positioned(
                  right: 0,
                  top: 14,
                  bottom: 14,
                  width: 8,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        onSizeChanged(
                          Size(
                            (windowData.size.width + details.delta.dx).clamp(360.0, 2400.0),
                            windowData.size.height,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Left Edge
                Positioned(
                  left: 0,
                  top: 14,
                  bottom: 14,
                  width: 8,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        final newWidth = (windowData.size.width - details.delta.dx).clamp(360.0, 2400.0);
                        if (newWidth != windowData.size.width) {
                          onSizeChanged(Size(newWidth, windowData.size.height));
                          onPositionChanged(
                            windowData.position + Offset(details.delta.dx, 0),
                          );
                        }
                      },
                    ),
                  ),
                ),
                // Bottom Edge
                Positioned(
                  bottom: 0,
                  left: 14,
                  right: 14,
                  height: 8,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        onSizeChanged(
                          Size(
                            windowData.size.width,
                            (windowData.size.height + details.delta.dy).clamp(240.0, 1600.0),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Bottom Right Corner
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: 18,
                  height: 18,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpLeftDownRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        onSizeChanged(
                          Size(
                            (windowData.size.width + details.delta.dx).clamp(360.0, 2400.0),
                            (windowData.size.height + details.delta.dy).clamp(240.0, 1600.0),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Bottom Left Corner
                Positioned(
                  left: 0,
                  bottom: 0,
                  width: 18,
                  height: 18,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpRightDownLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        final newWidth = (windowData.size.width - details.delta.dx).clamp(360.0, 2400.0);
                        final newHeight = (windowData.size.height + details.delta.dy).clamp(240.0, 1600.0);
                        onSizeChanged(Size(newWidth, newHeight));
                        onPositionChanged(
                          windowData.position + Offset(details.delta.dx, 0),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Single unified AnimatedPositioned preserves Flutter widget element & state across maximizes & retiles
    return AnimatedPositioned(
      key: ValueKey('win_anim_pos_${windowData.id}'),
      duration: (windowData.isMaximized || isTiled)
          ? const Duration(milliseconds: 200)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      left: targetLeft,
      top: targetTop,
      width: targetWidth,
      height: targetHeight,
      child: windowContent,
    );
  }

  Widget _buildAppIcon() {
    return PortfolioAppIcon(
      appId: windowData.appId,
      icon: windowData.icon,
      size: 16,
    );
  }
}

class _WindowControl extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final IconData icon;

  const _WindowControl({
    required this.color,
    required this.onTap,
    required this.icon,
  });

  @override
  State<_WindowControl> createState() => _WindowControlState();
}

class _WindowControlState extends State<_WindowControl> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
          child: _isHovered
              ? Center(child: Icon(widget.icon, size: 9, color: Colors.black87))
              : null,
        ),
      ),
    );
  }
}
