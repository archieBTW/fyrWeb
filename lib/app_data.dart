import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'apps/contact_app.dart';
import 'apps/terminal_app.dart';
import 'apps/fyrfiles_app.dart';
import 'apps/fyrsettings_app.dart';
import 'apps/browser_app.dart';
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
  final Widget? _content;
  final Widget Function()? contentBuilder;
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
    Widget? content,
    this.contentBuilder,
    required this.icon,
    this.color = Colors.blue,
    this.url,
    this.caseStudy,
    this.devopsStudy,
    this.sysadminStudy,
    this.architectureBadge,
    this.tags,
  }) : _content = content;

  Widget? get content => contentBuilder != null ? contentBuilder!() : _content;
}

List<AppInfo> getApps(AppConfig config) {
  final List<AppInfo> systemApps = [
    AppInfo(
      id: 'browser',
      title: 'fyrBrowser',
      contentBuilder: () => const BrowserApp(url: 'https://duckduckgo.com'),
      icon: 'assets/icons/browser.png',
      color: Colors.blueAccent,
    ),
    AppInfo(
      id: 'terminal',
      title: 'fyrTerm',
      contentBuilder: () => const TerminalApp(),
      icon: 'assets/icons/terminal.png',
      color: Colors.black,
    ),
    AppInfo(
      id: 'files',
      title: 'fyrFiles',
      contentBuilder: () => const FyrFilesApp(),
      icon: 'assets/icons/folderfile.png',
      color: Colors.blue,
    ),
    AppInfo(
      id: 'code',
      title: 'fyrCode',
      contentBuilder: () => const CodeEditorApp(),
      icon: 'assets/icons/code.png',
      color: const Color(0xFF1E1E1E),
    ),
    AppInfo(
      id: 'photos',
      title: 'fyrPhotos',
      contentBuilder: () => const PhotoAlbumApp(),
      icon: 'assets/icons/photos.png',
      color: Colors.purple,
    ),
    AppInfo(
      id: 'music',
      title: 'fyrMusic',
      contentBuilder: () => const MusicPlayerApp(),
      icon: 'assets/icons/music.png',
      color: Colors.teal,
    ),
    AppInfo(
      id: 'settings',
      title: 'fyrSettings',
      contentBuilder: () => const FyrSettingsApp(),
      icon: 'assets/icons/settings.png',
      color: Colors.grey,
    ),
    AppInfo(
      id: 'resume',
      title: 'Resume',
      contentBuilder: () => const ResumeApp(),
      icon: Icons.description_outlined,
      color: Colors.orange,
    ),
    AppInfo(
      id: 'infra_monitor',
      title: 'Infra Monitor',
      subtitle: 'GCP Cloud & SysAdmin Telemetry',
      contentBuilder: () => const InfraMonitorApp(),
      icon: Icons.dns_rounded,
      color: const Color(0xFF00B0FF),
    ),
    AppInfo(
      id: 'grand_theft_ant',
      title: 'Grand Theft Ant',
      subtitle: '3D Open-World Bug Simulation',
      contentBuilder: () => const GrandTheftAntApp(),
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
      return Icons.people_alt_rounded;
    case 'code':
      return Icons.code;
    case 'article':
      return Icons.article_rounded;
    case 'game':
      return Icons.sports_esports_rounded;
    case 'cloud':
      return Icons.cloud;
    case 'chart':
      return Icons.bar_chart_rounded;
    case 'github':
      return FontAwesomeIcons.github;
    case 'linkedin':
      return FontAwesomeIcons.linkedin;
    case 'headphones':
      return Icons.headphones_rounded;
    case 'terminal':
      return Icons.terminal_rounded;
    case 'album':
      return Icons.album_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'newspaper':
      return Icons.newspaper_rounded;
    case 'speedometer':
      return Icons.speed_rounded;
    case 'graphic_eq':
      return Icons.graphic_eq_rounded;
    case 'school':
      return Icons.school_rounded;
    default:
      return Icons.apps;
  }
}
