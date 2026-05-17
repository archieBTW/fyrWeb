import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../system_settings.dart';

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  Future<void> _pickWallpaper(SystemSettings settings) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      final bytes = result.files.first.bytes!;
      final base64String = 'data:image/png;base64,${base64.encode(bytes)}';
      settings.setWallpaper(base64String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: GoogleFonts.outfit(
              color: onSurfaceColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          _SettingSection(
            title: 'Theme Mode',
            child: Row(
              children: [
                _ThemeOption(
                  label: 'Dark',
                  isSelected: settings.isDarkMode,
                  onTap: () => settings.setDarkMode(true),
                  color: Colors.black,
                ),
                const SizedBox(width: 20),
                _ThemeOption(
                  label: 'Light',
                  isSelected: !settings.isDarkMode,
                  onTap: () => settings.setDarkMode(false),
                  color: Colors.white,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          _SettingSection(
            title: 'Accent Color',
            child: Wrap(
              spacing: 12,
              children: [
                _ColorCircle(
                  color: Colors.blue,
                  isSelected: settings.accentColor.value == Colors.blue.value,
                  onTap: () => settings.setAccentColor(Colors.blue),
                ),
                _ColorCircle(
                  color: Colors.purple,
                  isSelected: settings.accentColor.value == Colors.purple.value,
                  onTap: () => settings.setAccentColor(Colors.purple),
                ),
                _ColorCircle(
                  color: Colors.green,
                  isSelected: settings.accentColor.value == Colors.green.value,
                  onTap: () => settings.setAccentColor(Colors.green),
                ),
                _ColorCircle(
                  color: Colors.orange,
                  isSelected: settings.accentColor.value == Colors.orange.value,
                  onTap: () => settings.setAccentColor(Colors.orange),
                ),
                _ColorCircle(
                  color: Colors.pink,
                  isSelected: settings.accentColor.value == Colors.pink.value,
                  onTap: () => settings.setAccentColor(Colors.pink),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          _SettingSection(
            title: 'Wallpaper',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _WallpaperThumb(
                  path: 'assets/wallpaper.jpg',
                  isSelected: settings.wallpaperPath == 'assets/wallpaper.jpg',
                  onTap: () => settings.setWallpaper('assets/wallpaper.jpg'),
                ),
                _WallpaperThumb(
                  path:
                      'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?q=80&w=1000',
                  isSelected: settings.wallpaperPath.contains(
                    'photo-1477346611705',
                  ),
                  onTap: () => settings.setWallpaper(
                    'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?q=80&w=1000',
                  ),
                ),
                _WallpaperThumb(
                  path:
                      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1000',
                  isSelected: settings.wallpaperPath.contains(
                    'photo-1464822759023',
                  ),
                  onTap: () => settings.setWallpaper(
                    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1000',
                  ),
                ),

                GestureDetector(
                  onTap: () => _pickWallpaper(settings),
                  child: Container(
                    width: 140,
                    height: 80,
                    decoration: BoxDecoration(
                      color: onSurfaceColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: onSurfaceColor.withOpacity(0.2),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload,
                          color: onSurfaceColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload New',
                          style: GoogleFonts.inter(
                            color: onSurfaceColor.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isSelected ? onSurfaceColor.withOpacity(0.05) : Colors.transparent,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? onSurfaceColor
                : onSurfaceColor.withOpacity(0.5),
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected
                  ? onSurfaceColor
                  : onSurfaceColor.withOpacity(0.5),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _ThemeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Colors.blue
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _WallpaperThumb extends StatelessWidget {
  final String path;
  final bool isSelected;
  final VoidCallback onTap;

  const _WallpaperThumb({
    required this.path,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 3,
          ),
          image: DecorationImage(
            image: path.startsWith('assets')
                ? AssetImage(path) as ImageProvider
                : NetworkImage(path),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
