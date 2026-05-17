import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'window_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WindowFrame extends StatelessWidget {
  final WindowData windowData;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onFocus;
  final Function(Offset) onPositionChanged;
  final Function(Size) onSizeChanged;

  const WindowFrame({
    super.key,
    required this.windowData,
    required this.onClose,
    required this.onMinimize,
    required this.onMaximize,
    required this.onFocus,
    required this.onPositionChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    Widget windowContent = GestureDetector(
      onTap: onFocus,
      child: Container(
        width: windowData.isMaximized ? null : windowData.size.width,
        height: windowData.isMaximized ? null : windowData.size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(windowData.isMaximized ? 0 : 12),
          boxShadow: windowData.isMaximized
              ? []
              : [
                  BoxShadow(
                    color: windowData.isFocused
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                    blurRadius: windowData.isFocused ? 40 : 30,
                    spreadRadius: windowData.isFocused ? 8 : 5,
                  ),
                ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  windowData.isMaximized ? 0 : 12,
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onPanUpdate: windowData.isMaximized
                          ? null
                          : (details) {
                              onPositionChanged(
                                windowData.position + details.delta,
                              );
                            },
                      onDoubleTap: onMaximize,
                      child: Container(
                        height: 38,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.95),
                          border: Border(
                            bottom: BorderSide(
                              color: onSurfaceColor.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              _WindowControl(
                                color: Colors.redAccent,
                                onTap: onClose,
                                icon: Icons.close,
                              ),
                              const SizedBox(width: 8),
                              _WindowControl(
                                color: Colors.orangeAccent,
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
                              const SizedBox(width: 12),
                              windowData.icon is IconData
                                  ? Icon(
                                      windowData.icon,
                                      color: onSurfaceColor.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 14,
                                    )
                                  : FaIcon(
                                      windowData.icon,
                                      color: onSurfaceColor.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 12,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                windowData.title,
                                style: GoogleFonts.inter(
                                  color: onSurfaceColor.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 60),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: surfaceColor.withValues(alpha: 0.9),
                        child: windowData.content,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Resize Handles
            if (!windowData.isMaximized) ...[
              // Right Edge
              Positioned(
                right: 0,
                top: 0,
                bottom: 15,
                width: 6,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      onSizeChanged(
                        Size(
                          (windowData.size.width + details.delta.dx).clamp(
                            300.0,
                            1200.0,
                          ),
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
                top: 0,
                bottom: 15,
                width: 6,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final newWidth =
                          (windowData.size.width - details.delta.dx).clamp(
                            300.0,
                            1200.0,
                          );
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
                left: 0,
                right: 15,
                height: 6,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      onSizeChanged(
                        Size(
                          windowData.size.width,
                          (windowData.size.height + details.delta.dy).clamp(
                            200.0,
                            800.0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Top Edge
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 6,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final newHeight =
                          (windowData.size.height - details.delta.dy).clamp(
                            200.0,
                            800.0,
                          );
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
              // Bottom Right Corner
              Positioned(
                right: 0,
                bottom: 0,
                width: 15,
                height: 15,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      onSizeChanged(
                        Size(
                          (windowData.size.width + details.delta.dx).clamp(
                            300.0,
                            1200.0,
                          ),
                          (windowData.size.height + details.delta.dy).clamp(
                            200.0,
                            800.0,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: const Icon(
                        Icons.drag_handle,
                        size: 12,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (windowData.isMaximized) {
      return Positioned(
        left: 0,
        top: 35,
        right: 0,
        bottom: 0,
        child: windowContent,
      );
    }

    return Positioned(
      left: windowData.position.dx,
      top: windowData.position.dy,
      child: windowContent,
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
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          child: _isHovered
              ? Center(child: Icon(widget.icon, size: 8, color: Colors.black54))
              : null,
        ),
      ),
    );
  }
}
