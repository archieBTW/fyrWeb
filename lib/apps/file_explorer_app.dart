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
        'name': 'Documents',
        'icon': Icons.folder,
        'color': Colors.blue,
        'isFolder': true,
      },
      {
        'name': 'Pictures',
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
    'Documents': [
      {
        'name': 'projects.txt',
        'icon': Icons.description,
        'color': Colors.grey,
        'isFolder': false,
      },
      {
        'name': 'notes.md',
        'icon': Icons.description,
        'color': Colors.grey,
        'isFolder': false,
      },
    ],
    'Pictures': [
      {
        'name': 'avatar.png',
        'icon': Icons.image,
        'color': Colors.purple,
        'isFolder': false,
      },
      {
        'name': 'wallpaper_backup.png',
        'icon': Icons.image,
        'color': Colors.purple,
        'isFolder': false,
      },
    ],
    'Music': [
      {
        'name': 'beats.mp3',
        'icon': Icons.music_note,
        'color': Colors.orange,
        'isFolder': false,
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
          color: Colors.white.withOpacity(0.05),
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
