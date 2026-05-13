import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'apps/about_app.dart';
import 'apps/contact_app.dart';
import 'apps/terminal_app.dart';
import 'apps/file_explorer_app.dart';
import 'apps/settings_app.dart';
import 'apps/resume_app.dart';
import 'models/config_model.dart';

class AppInfo {
  final String id;
  final String title;
  final Widget? content;
  final dynamic icon;
  final Color color;
  final String? url;

  AppInfo({
    required this.id,
    required this.title,
    this.content,
    required this.icon,
    this.color = Colors.blue,
    this.url,
  });
}

List<AppInfo> getApps(AppConfig config) {
  final List<AppInfo> systemApps = [
    AppInfo(
      id: 'terminal',
      title: 'Terminal',
      content: const TerminalApp(),
      icon: Icons.terminal,
      color: Colors.black,
    ),
    AppInfo(
      id: 'files',
      title: 'File Explorer',
      content: const FileExplorerApp(),
      icon: Icons.folder,
      color: Colors.blue,
    ),
    AppInfo(
      id: 'settings',
      title: 'Settings',
      content: const SettingsApp(),
      icon: Icons.settings,
      color: Colors.grey,
    ),
    AppInfo(
      id: 'about',
      title: 'About Me',
      content: const AboutApp(),
      icon: Icons.person_outline,
      color: Colors.blue,
    ),
    AppInfo(
      id: 'resume',
      title: 'Resume',
      content: const ResumeApp(),
      icon: Icons.description_outlined,
      color: Colors.orange,
    ),
    AppInfo(
      id: 'contact',
      title: 'Contact Me',
      content: const ContactApp(),
      icon: Icons.mail_outline,
      color: Colors.green,
    ),
  ];

  final List<AppInfo> customApps = config.apps.map((app) {
    return AppInfo(
      id: app.id,
      title: app.title,
      url: app.url,
      icon: _getIconData(app.icon),
      color: Color(int.parse(app.color)),
    );
  }).toList();

  return [...systemApps, ...customApps];
}

dynamic _getIconData(String iconName) {
  switch (iconName) {
    case 'computer':
      return Icons.computer;
    case 'code':
      return Icons.code;
    case 'language':
      return Icons.language;
    case 'github':
      return FontAwesomeIcons.github;
    case 'link':
      return Icons.link;
    case 'smartphone':
      return Icons.smartphone;
    case 'album':
      return Icons.album;
    case 'headphones':
      return Icons.headphones;
    case 'book':
      return Icons.book;
    case 'favorite':
      return Icons.favorite;
    case 'newspaper':
      return Icons.newspaper;
    default:
      return Icons.apps;
  }
}
