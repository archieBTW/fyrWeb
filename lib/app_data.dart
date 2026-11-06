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
import 'apps/grand_theft_ant/grand_theft_ant_app.dart';
import 'apps/case_study_app.dart';
import 'apps/infra_monitor_app.dart';
import 'models/config_model.dart';

class AppInfo {
  final String id;
  final String title;
  final String? subtitle;
  final Widget? content;
  final dynamic icon;
  final Color color;
  final String? url;
  final List<String>? caseStudy;
  final List<String>? devopsStudy;
  final List<String>? sysadminStudy;
  final String? architectureBadge;
  final List<String>? tags;

  AppInfo({
    required this.id,
    required this.title,
    this.subtitle,
    this.content,
    required this.icon,
    this.color = Colors.blue,
    this.url,
    this.caseStudy,
    this.devopsStudy,
    this.sysadminStudy,
    this.architectureBadge,
    this.tags,
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
      id: 'infra_monitor',
      title: 'Infra Monitor',
      subtitle: 'GCP Cloud & SysAdmin Telemetry',
      content: const InfraMonitorApp(),
      icon: Icons.dns_rounded,
      color: const Color(0xFF00B0FF),
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
      id: 'grand_theft_ant',
      title: 'Grand Theft Ant',
      subtitle: '3D Open-World Bug Simulation',
      content: const GrandTheftAntApp(),
      icon: Icons.sports_esports_rounded,
      color: const Color(0xFF7FA650),
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
      subtitle: app.subtitle,
      url: app.url,
      content: app.caseStudy != null ? CaseStudyApp(app: app) : null,
      icon: _getIconData(app.icon),
      color: Color(int.parse(app.color)),
      caseStudy: app.caseStudy,
      devopsStudy: app.devopsStudy,
      sysadminStudy: app.sysadminStudy,
      architectureBadge: app.architectureBadge,
      tags: app.tags,
    );
  }).toList();

  return [...systemApps, ...customApps];
}

dynamic _getIconData(String iconName) {
  switch (iconName) {
    case 'computer':
      return Icons.computer;
    case 'people':
    case 'group':
    case 'social':
      return Icons.people_alt_rounded;
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
    case 'speedometer':
    case 'speed':
    case 'gauge':
      return Icons.speed;
    case 'cloud':
      return Icons.cloud_done_rounded;
    case 'dns':
    case 'server':
      return Icons.dns_rounded;
    case 'terminal':
      return Icons.terminal_rounded;
    case 'docker':
      return FontAwesomeIcons.docker;
    case 'shield':
    case 'security':
      return Icons.shield_outlined;
    case 'layers':
      return Icons.layers_rounded;
    case 'gamepad':
    case 'game':
    case 'sports_esports':
      return Icons.sports_esports_rounded;
    case 'bug':
    case 'ant':
      return Icons.pest_control_rounded;
    default:
      return Icons.apps;
  }
}
