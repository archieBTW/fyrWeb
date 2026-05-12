import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'window_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WindowFrame extends StatelessWidget {
  final WindowData windowData;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onFocus;
  final Function(Offset) onPositionChanged;
  final Function(Size) onSizeChanged;

  const WindowFrame({
    super.key,
    required this.windowData,
    required this.onClose,
    required this.onMinimize,
    required this.onFocus,
    required this.onPositionChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Positioned(
      left: windowData.position.dx,
      top: windowData.position.dy,
      child: GestureDetector(
        onTap: onFocus,
        child: Container(
          width: windowData.size.width,
          height: windowData.size.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: windowData.isFocused
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: windowData.isFocused ? 40 : 30,
                spreadRadius: windowData.isFocused ? 8 : 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                GestureDetector(
                  onPanUpdate: (details) {
                    onPositionChanged(windowData.position + details.delta);
                  },
                  child: Container(
                    height: 38,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.9)
                          : Colors.white.withOpacity(0.95),
                      border: Border(
                        bottom: BorderSide(
                          color: onSurfaceColor.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          // Control Buttons
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
                            onTap: () {},
                            icon: Icons.fullscreen,
                          ),
                          const SizedBox(width: 12),
                          windowData.icon is IconData
                              ? Icon(
                                  windowData.icon,
                                  color: onSurfaceColor.withOpacity(0.7),
                                  size: 14,
                                )
                              : FaIcon(
                                  windowData.icon,
                                  color: onSurfaceColor.withOpacity(0.7),
                                  size: 12,
                                ),
                          const SizedBox(width: 8),
                          Text(
                            windowData.title,
                            style: GoogleFonts.inter(
                              color: onSurfaceColor.withOpacity(0.9),
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
                    color: surfaceColor.withOpacity(0.9),
                    child: windowData.content,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      onSizeChanged(
                        Size(
                          (windowData.size.width + details.delta.dx).clamp(
                            300,
                            1200,
                          ),
                          (windowData.size.height + details.delta.dy).clamp(
                            200,
                            800,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 15,
                      height: 15,
                      color: Colors.transparent,
                      child: const Icon(
                        Icons.drag_handle,
                        size: 12,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
