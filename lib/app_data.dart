import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'apps/about_app.dart';
import 'apps/contact_app.dart';
import 'apps/terminal_app.dart';
import 'apps/file_explorer_app.dart';
import 'apps/settings_app.dart';

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

final List<AppInfo> allApps = [
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
    id: 'contact',
    title: 'Contact Me',
    content: const ContactApp(),
    icon: Icons.mail_outline,
    color: Colors.green,
  ),
  AppInfo(
    id: 'fyr',
    title: 'fyr software',
    url: 'https://fyr.software',
    icon: Icons.computer,
    color: Colors.cyan,
  ),
  AppInfo(
    id: 'bybl',
    title: 'bybl',
    url: 'https://bybl.dev',
    icon: Icons.book,
    color: Colors.brown,
  ),
  AppInfo(
    id: 'libretrac',
    title: 'LibreTrac',
    url: 'https://libretrac.site',
    icon: Icons.favorite,
    color: Colors.red,
  ),
  AppInfo(
    id: 'olivebranch',
    title: 'Olive Branch',
    url: 'https://theolivebranch.press',
    icon: Icons.newspaper,
    color: Colors.greenAccent,
  ),
  AppInfo(
    id: 'beatsbyarch',
    title: 'Beats By Arch',
    url: 'https://beatsby.archbtw.sh',
    icon: Icons.headphones,
    color: Colors.deepPurpleAccent,
  ),
  AppInfo(
    id: 'github',
    title: 'GitHub',
    url: 'https://github.com/archieBTW',
    icon: FontAwesomeIcons.github,
    color: Colors.grey,
  ),
  AppInfo(
    id: 'violetapparition',
    title: 'Violet Apparition',
    url: 'https://violetapparition.com',
    icon: Icons.album,
    color: Colors.deepPurple,
  ),
];
