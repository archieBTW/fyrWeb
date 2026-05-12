import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_data.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppMenu extends StatelessWidget {
  final Function(String, String, Widget?, dynamic, {String? url}) onOpenApp;
  final VoidCallback onClose;

  const AppMenu({
    super.key,
    required this.onOpenApp,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer.clearGlass(
      width: 250,
      height: 500,
      borderRadius: BorderRadius.circular(12),
      blur: 30,
      color: Colors.black.withOpacity(0.7),
      borderColor: Colors.white.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Applications',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: allApps.length,
              itemBuilder: (context, index) {
                final app = allApps[index];
                return ListTile(
                  dense: true,
                  leading: app.icon is IconData 
                    ? Icon(app.icon, color: app.color, size: 18)
                    : FaIcon(app.icon, color: app.color, size: 16),
                  title: Text(
                    app.title,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  ),
                  onTap: () {
                    onOpenApp(app.id, app.title, app.content, app.icon, url: app.url);
                    onClose();
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 18),
            title: Text(
              'Shut Down...',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}
