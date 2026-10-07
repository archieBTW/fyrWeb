import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'window_manager.dart';

class SystemController extends ChangeNotifier {
  final WindowManager windowManager;

  SystemController({required this.windowManager});

  void openApp(
    String id,
    String title,
    Widget? content,
    dynamic icon, {
    String? url,
  }) async {
    if (content != null) {
      windowManager.openWindow(id, title, content, icon);
      return;
    }
    if (url != null) {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
