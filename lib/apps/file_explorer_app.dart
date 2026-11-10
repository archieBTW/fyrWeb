import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../system_controller.dart';
import '../system_settings.dart';
import '../fyr_theme.dart';
import 'resume_app.dart';
import 'infra_monitor_app.dart';
import 'code_editor_app.dart';
import 'grand_theft_ant/grand_theft_ant_app.dart';

class FileExplorerApp extends StatefulWidget {
  const FileExplorerApp({super.key});

  @override
  State<FileExplorerApp> createState() => _FileExplorerAppState();
}

class _FileExplorerAppState extends State<FileExplorerApp> {
  String _currentPath = 'Home';

  final Map<String, List<Map<String, dynamic>>> _folders = {
    'Home': [
      {
        'name': 'Projects',
        'icon': Icons.folder,
        'color': Colors.blue,
        'isFolder': true,
      },
      {
        'name': 'Infrastructure',
        'icon': Icons.folder,
        'color': Colors.cyan,
        'isFolder': true,
      },
      {
        'name': 'Music',
        'icon': Icons.folder,
        'color': Colors.purpleAccent,
        'isFolder': true,
      },
      {
        'name': 'resume.pdf',
        'icon': Icons.picture_as_pdf,
        'color': Colors.red,
        'isFolder': false,
      },
    ],
    'Projects': [
      {
        'name': 'friend.ly.html',
        'icon': Icons.html,
        'color': Colors.cyanAccent,
        'isFolder': false,
        'url': 'https://friendly.archerwoods.dev',
        'external': true,
      },
      {
        'name': 'grand_theft_ant.game',
        'icon': Icons.sports_esports_rounded,
        'color': const Color(0xFF7FA650),
        'isFolder': false,
        'openGame': true,
      },
      {
        'name': 'libretrac.html',
        'icon': Icons.html,
        'color': Colors.orange,
        'isFolder': false,
        'url': 'https://libretrac.site',
        'external': true,
      },
      {
        'name': 'welledumacated.html',
        'icon': Icons.html,
        'color': Colors.orange,
        'isFolder': false,
        'url': 'https://welledumacated.dev',
        'external': true,
      },
      {
        'name': 'bybl.html',
        'icon': Icons.html,
        'color': Colors.orange,
        'isFolder': false,
        'url': 'https://bybl.dev',
        'external': true,
      },
      {
        'name': 'theolivebranch.html',
        'icon': Icons.html,
        'color': Colors.orange,
        'isFolder': false,
        'url': 'https://theolivebranch.press',
        'external': true,
      },
      {
        'name': 'fyr.html',
        'icon': Icons.html,
        'color': Colors.orange,
        'isFolder': false,
        'url': 'https://fyr.software',
        'external': true,
      },
      {
        'name': 'beats_by_arch.html',
        'icon': Icons.html,
        'color': const Color(0xFF7C4DFF),
        'isFolder': false,
        'url': 'https://beats.archerwoods.dev',
        'external': true,
      },
    ],
    'Infrastructure': [
      {
        'name': 'WE-IAC-Terraform',
        'icon': Icons.cloud_outlined,
        'color': Colors.purpleAccent,
        'isFolder': false,
        'openCode': true,
      },
      {
        'name': 'Ansible-Deploy',
        'icon': Icons.bolt,
        'color': Colors.greenAccent,
        'isFolder': false,
        'openCode': true,
      },
      {
        'name': 'Docker-Compose',
        'icon': Icons.view_in_ar,
        'color': Colors.blueAccent,
        'isFolder': false,
        'openCode': true,
      },
      {
        'name': 'Infra-Monitor.app',
        'icon': Icons.dns_rounded,
        'color': Colors.cyanAccent,
        'isFolder': false,
        'openInfra': true,
      },
    ],
    'Music': [
      {
        'name': 'archbtw.wav',
        'icon': Icons.music_note,
        'color': Colors.purple,
        'isFolder': false,
        'url': 'https://archBTW.sh',
        'external': true,
      },
      {
        'name': 'violetapparition.mp3',
        'icon': Icons.music_note,
        'color': Colors.purple,
        'isFolder': false,
        'url': 'https://violetapparition.com',
        'external': true,
      },
      {
        'name': 'beats_by_arch.app',
        'icon': Icons.headphones,
        'color': const Color(0xFF7C4DFF),
        'isFolder': false,
        'url': 'https://beats.archerwoods.dev',
        'external': true,
      },
    ],
  };

  void _navigateTo(String folder) {
    if (_folders.containsKey(folder)) {
      setState(() {
        _currentPath = folder;
      });
    }
  }

  void _goBack() {
    if (_currentPath != 'Home') {
      setState(() {
        _currentPath = 'Home';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemSettings = context.watch<SystemSettings?>();
    final accentColor = systemSettings?.accentColor ?? FyrTheme.accentColor;
    final files = _folders[_currentPath] ?? [];
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withValues(alpha: 0.05),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Colors.white54,
                  ),
                  onPressed: _currentPath == 'Home' ? null : _goBack,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Colors.white54,
                ),
                const SizedBox(width: 24),
                Text(
                  'Home > $_currentPath',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.search, size: 18, color: Colors.white54),
                const SizedBox(width: 16),
                const Icon(Icons.view_module, size: 18, color: Colors.white54),
              ],
            ),
          ),
          // Content
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 3 : 6,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return InkWell(
                  onTap: () {
                    if (file['isFolder'] == true) {
                      _navigateTo(file['name'] as String);
                    } else if (file['name'] == 'resume.pdf') {
                      context.read<SystemController>().openApp(
                        'resume',
                        'Resume',
                        const ResumeApp(),
                        Icons.picture_as_pdf,
                      );
                    } else if (file['openGame'] == true) {
                      context.read<SystemController>().openApp(
                        'grand_theft_ant',
                        'Grand Theft Ant',
                        const GrandTheftAntApp(),
                        Icons.sports_esports_rounded,
                      );
                    } else if (file['openInfra'] == true) {
                      context.read<SystemController>().openApp(
                        'infra_monitor',
                        'Infra Monitor',
                        const InfraMonitorApp(),
                        Icons.dns_rounded,
                      );
                    } else if (file['openCode'] == true) {
                      context.read<SystemController>().openApp(
                        'code',
                        'Source Code',
                        const CodeEditorApp(),
                        Icons.code,
                      );
                    } else if (file['url'] != null) {
                      final url = file['url'] as String;
                      context.read<SystemController>().openApp(
                        file['name'] as String,
                        file['name'] as String,
                        null,
                        null,
                        url: url,
                      );
                    }
                  },
                  child: Column(
                    children: [
                      Icon(
                        file['icon'] as IconData,
                        color: (file['isFolder'] == true ||
                                file['icon'] == Icons.folder)
                            ? accentColor
                            : (file['color'] as Color),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        file['name'] as String,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
