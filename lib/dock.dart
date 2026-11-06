import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'app_data.dart';
import 'package:provider/provider.dart';
import 'models/config_model.dart';
import 'system_settings.dart';
import 'dart:ui';

class Dock extends StatelessWidget {
  final Function(String, String, Widget?, dynamic, {String? url}) onOpenApp;

  const Dock({super.key, required this.onOpenApp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SystemSettings>();
    final config = context.watch<AppConfig>();
    final apps = getApps(config);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive scaling based on window width
    const baseItemWidth = 56.0;
    const baseDockPadding = 18.0;
    final maxDockWidth = (screenWidth - 32.0).clamp(240.0, double.infinity);
    final idealContentWidth = (apps.length * baseItemWidth) + baseDockPadding;

    // Compute automatic scale factor so all icons always fit on screen
    final autoScale = (maxDockWidth / idealContentWidth).clamp(0.40, 1.0);
    final effectiveScale = autoScale * settings.dockScale;

    final dockHeight = (70.0 * effectiveScale).clamp(38.0, 95.0);
    final dockBorderRadius = (20.0 * effectiveScale).clamp(10.0, 24.0);
    final dockHorizontalPadding = (9.0 * effectiveScale).clamp(4.0, 14.0);

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(dockBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: dockHeight,
            padding: EdgeInsets.symmetric(horizontal: dockHorizontalPadding),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(dockBorderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: apps
                  .map(
                    (app) => _DockIcon(
                      icon: app.icon,
                      label: app.title,
                      color: app.color,
                      scale: effectiveScale,
                      onTap: () => onOpenApp(
                        app.id,
                        app.title,
                        app.content,
                        app.icon,
                        url: app.url,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatefulWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double scale;

  const _DockIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale.clamp(0.40, 1.4);
    final iconSize = (28.0 * s).clamp(13.0, 38.0);
    final faIconSize = (26.0 * s).clamp(12.0, 36.0);
    final containerPadding = (8.0 * s).clamp(3.0, 12.0);
    final itemHorizontalPadding = (3.0 * s).clamp(1.0, 6.0);
    final borderRadius = (12.0 * s).clamp(5.0, 16.0);

    return Tooltip(
      message: widget.label,
      verticalOffset: -45 * s,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.diagonal3Values(
              _isHovered ? 1.18 : 1.0,
              _isHovered ? 1.18 : 1.0,
              1.0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: itemHorizontalPadding,
              vertical: 2.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(containerPadding),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      if (_isHovered)
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 10 * s,
                          spreadRadius: 2 * s,
                        ),
                    ],
                  ),
                  child: widget.icon is IconData
                      ? Icon(widget.icon, color: Colors.white, size: iconSize)
                      : FaIcon(
                          widget.icon,
                          color: Colors.white,
                          size: faIconSize,
                        ),
                ),
                if (_isHovered && s > 0.75) SizedBox(height: 2 * s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
