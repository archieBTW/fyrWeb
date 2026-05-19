import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'apps/contact_app.dart';
import 'apps/terminal_app.dart';
import 'apps/file_explorer_app.dart';
import 'apps/settings_app.dart';
import 'apps/resume_app.dart';
import 'apps/code_editor_app.dart';
import 'apps/photo_album_app.dart';
import 'apps/music_player_app.dart';
import 'apps/snake_game_app.dart';
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
      id: 'resume',
      title: 'Resume',
      content: const ResumeApp(),
      icon: Icons.description_outlined,
      color: Colors.orange,
    ),
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
      id: 'code',
      title: 'Source Code',
      content: const CodeEditorApp(),
      icon: Icons.code,
      color: const Color(0xFF1E1E1E),
    ),
    AppInfo(
      id: 'photos',
      title: 'Photos',
      content: const PhotoAlbumApp(),
      icon: Icons.photo_album,
      color: Colors.purple,
    ),
    AppInfo(
      id: 'music',
      title: 'Music Player',
      content: const MusicPlayerApp(),
      icon: Icons.headphones,
      color: Colors.teal,
    ),
    AppInfo(
      id: 'snake',
      title: 'Snake Game',
      content: const SnakeGameApp(),
      icon: Icons.gamepad,
      color: Colors.purple,
    ),
    AppInfo(
      id: 'contact',
      title: 'Contact Me',
      content: const ContactApp(),
      icon: Icons.mail_outline,
      color: Colors.green,
    ),
    AppInfo(
      id: 'settings',
      title: 'Settings',
      content: const SettingsApp(),
      icon: Icons.settings,
      color: Colors.grey,
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
