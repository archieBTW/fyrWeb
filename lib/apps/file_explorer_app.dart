import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../system_controller.dart';
import 'resume_app.dart';

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
        'name': 'Music',
        'icon': Icons.folder,
        'color': Colors.blue,
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
    final files = _folders[_currentPath] ?? [];

    return Column(
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
              const Icon(Icons.arrow_forward, size: 18, color: Colors.white54),
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
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
                      color: file['color'] as Color,
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
    );
  }
}
