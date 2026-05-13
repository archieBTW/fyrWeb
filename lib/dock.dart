import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'app_data.dart';
import 'package:provider/provider.dart';
import 'models/config_model.dart';

class Dock extends StatelessWidget {
  final Function(String, String, Widget?, dynamic, {String? url}) onOpenApp;

  const Dock({super.key, required this.onOpenApp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = context.watch<AppConfig>();
    final apps = getApps(config);

    return Center(
      child: GlassContainer.clearGlass(
        height: 70,
        width: apps.length * 64.0 + 10,
        borderRadius: BorderRadius.circular(20),
        blur: 25,
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderColor: isDark
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.1),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: apps
                  .map(
                    (app) => _DockIcon(
                      icon: app.icon,
                      label: app.title,
                      color: app.color,
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

  const _DockIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.2 : 1.0),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (_isHovered)
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: widget.icon is IconData
                    ? Icon(widget.icon, color: Colors.white, size: 28)
                    : FaIcon(widget.icon, color: Colors.white, size: 26),
              ),
              if (_isHovered) const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
