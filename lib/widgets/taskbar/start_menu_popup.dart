import 'dart:ui';
import 'package:flutter/material.dart';
import '../../fyr_theme.dart';
import '../../models/config_model.dart';
import '../../app_data.dart';
import 'package:provider/provider.dart';
import '../portfolio_app_icon.dart';

class StartMenuPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String id, String title, Widget? content, dynamic icon, {String? url}) onOpenApp;

  const StartMenuPopup({
    super.key,
    required this.onClose,
    required this.onOpenApp,
  });

  @override
  State<StartMenuPopup> createState() => _StartMenuPopupState();
}

class _StartMenuPopupState extends State<StartMenuPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final allApps = getApps(config);
    final filteredApps = allApps;

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: FyrTheme.bgColor.withValues(alpha: 0.45),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(16),
            ),
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(4, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              children: [
              const SizedBox(height: 20),

              // Apps List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      hoverColor: FyrTheme.hoverColor,
                      leading: _buildAppIcon(app),
                      title: Text(
                        app.title,
                        style: TextStyle(
                          color: FyrTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: app.subtitle != null
                          ? Text(
                              app.subtitle!,
                              style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () {
                        widget.onClose();
                        widget.onOpenApp(
                          app.id,
                          app.title,
                          app.content,
                          app.icon,
                          url: app.url,
                        );
                      },
                    );
                  },
                ),
              ),

              // Power Bar at bottom: Lock, Logout, Restart, Shutdown - Blends in with same transparency (no border)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PowerButton(
                      icon: Icons.lock_outline,
                      label: 'Lock',
                      onTap: () {
                        widget.onClose();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Screen locked'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                    _PowerButton(
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () {
                        widget.onClose();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logging out...'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                    _PowerButton(
                      icon: Icons.restart_alt,
                      label: 'Restart',
                      onTap: () {
                        widget.onClose();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Restarting fyrWeb desktop...'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                    _PowerButton(
                      icon: Icons.power_settings_new,
                      label: 'Shutdown',
                      color: Colors.redAccent,
                      onTap: () {
                        widget.onClose();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shutting down...'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildAppIcon(AppInfo app) {
    return PortfolioAppIcon(app: app, size: 32);
  }
}

class _PowerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _PowerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? FyrTheme.textColor.withValues(alpha: 0.85);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: FyrTheme.hoverColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: FyrTheme.textColorMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

