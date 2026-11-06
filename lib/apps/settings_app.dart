import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../system_settings.dart';

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  int _selectedSection = 0;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _hexColorController = TextEditingController();
  bool _isUploading = false;

  final List<Map<String, dynamic>> _sections = [
    {'title': 'Appearance', 'icon': Icons.palette_outlined},
    {'title': 'Wallpaper', 'icon': Icons.wallpaper_rounded},
    {'title': 'Desktop & Dock', 'icon': Icons.desktop_windows_outlined},
    {'title': 'Time & Sound', 'icon': Icons.access_time_rounded},
    {'title': 'About fyrOS', 'icon': Icons.info_outline_rounded},
  ];

  final List<Map<String, String>> _presets = [
    {'name': 'Cyberpunk Neon', 'path': 'assets/wallpaper.jpg'},
    {
      'name': 'Alpine Sunset',
      'path':
          'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?q=80&w=1920',
    },
    {
      'name': 'Deep Space',
      'path':
          'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?q=80&w=1920',
    },
    {
      'name': 'Cyber Grid',
      'path':
          'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1920',
    },
    {
      'name': 'Mountain Fog',
      'path':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1920',
    },
  ];

  final List<Map<String, dynamic>> _accentPalette = [
    {'name': 'Cyber Purple', 'color': Color(0xFF9C27B0)},
    {'name': 'Neon Cyan', 'color': Color(0xFF00B0FF)},
    {'name': 'Matrix Green', 'color': Color(0xFF00E676)},
    {'name': 'Sunset Orange', 'color': Color(0xFFFF9100)},
    {'name': 'Vapor Pink', 'color': Color(0xFFF50057)},
    {'name': 'Amber Gold', 'color': Color(0xFFFFD600)},
    {'name': 'Crimson Red', 'color': Color(0xFFFF1744)},
  ];

  @override
  void dispose() {
    _urlController.dispose();
    _hexColorController.dispose();
    super.dispose();
  }

  Future<void> _pickWallpaper(SystemSettings settings) async {
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final file = result.files.first;
        final bytes = file.bytes!;
        final ext = (file.extension ?? 'png').toLowerCase();
        final mimeType =
            (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/png';

        await settings.setCustomWallpaperFromBytes(bytes, mimeType: mimeType);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Custom wallpaper saved locally (IndexedDB)!',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1F2430),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking wallpaper: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _applyCustomUrl(SystemSettings settings) {
    final url = _urlController.text.trim();
    if (url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      settings.setWallpaper(url);
      _urlController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Custom background URL applied & saved!',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1F2430),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final isDark = settings.isDarkMode;
    final isNarrow = MediaQuery.of(context).size.width < 640;

    return Container(
      color: isDark ? const Color(0xFF101216) : const Color(0xFFF7F8FA),
      child: isNarrow
          ? Column(
              children: [
                _buildNarrowNav(settings),
                Expanded(child: _buildSectionContent(settings, onSurfaceColor)),
              ],
            )
          : Row(
              children: [
                _buildSidebar(settings, onSurfaceColor),
                Container(
                  width: 1,
                  color: onSurfaceColor.withValues(alpha: 0.08),
                ),
                Expanded(child: _buildSectionContent(settings, onSurfaceColor)),
              ],
            ),
    );
  }

  Widget _buildNarrowNav(SystemSettings settings) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.08),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: _sections.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedSection == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(_sections[i]['title'] as String),
              selected: isSelected,
              selectedColor: settings.accentColor.withValues(alpha: 0.2),
              onSelected: (_) => setState(() => _selectedSection = i),
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? settings.accentColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebar(SystemSettings settings, Color onSurfaceColor) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.settings_suggest_rounded,
                  color: settings.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: GoogleFonts.outfit(
                    color: onSurfaceColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = _sections[index];
                final isSelected = _selectedSection == index;

                return InkWell(
                  onTap: () => setState(() => _selectedSection = index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? settings.accentColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? settings.accentColor
                              : onSurfaceColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? settings.accentColor
                                  : onSurfaceColor.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(SystemSettings settings, Color onSurfaceColor) {
    switch (_selectedSection) {
      case 0:
        return _buildAppearanceSection(settings, onSurfaceColor);
      case 1:
        return _buildWallpaperSection(settings, onSurfaceColor);
      case 2:
        return _buildDesktopDockSection(settings, onSurfaceColor);
      case 3:
        return _buildTimeSoundSection(settings, onSurfaceColor);
      case 4:
        return _buildAboutSection(settings, onSurfaceColor);
      default:
        return _buildAppearanceSection(settings, onSurfaceColor);
    }
  }

  Widget _buildAppearanceSection(
    SystemSettings settings,
    Color onSurfaceColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(
            'Appearance',
            'Customize system theme mode, UI colors, and glass effects.',
            onSurfaceColor,
          ),
          const SizedBox(height: 28),

          // Theme Mode
          _SettingCard(
            title: 'Theme Mode',
            description: 'Select dark or light interface theme for the system.',
            child: Row(
              children: [
                _ThemeCard(
                  label: 'Dark Mode',
                  icon: Icons.dark_mode_rounded,
                  isSelected: settings.isDarkMode,
                  accentColor: settings.accentColor,
                  onTap: () => settings.setDarkMode(true),
                  isDark: true,
                ),
                const SizedBox(width: 16),
                _ThemeCard(
                  label: 'Light Mode',
                  icon: Icons.light_mode_rounded,
                  isSelected: !settings.isDarkMode,
                  accentColor: settings.accentColor,
                  onTap: () => settings.setDarkMode(false),
                  isDark: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accent Color
          _SettingCard(
            title: 'System Accent Color',
            description:
                'Controls highlight tint across window headers, buttons, dock, and indicators.',
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._accentPalette.map((palette) {
                  final col = palette['color'] as Color;
                  final isSelected =
                      settings.accentColor.toARGB32() == col.toARGB32();
                  return Tooltip(
                    message: palette['name'] as String,
                    child: GestureDetector(
                      onTap: () => settings.setAccentColor(col),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: col.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Window Glass Effects
          _SettingCard(
            title: 'Window Glassmorphism & Blur',
            description:
                'Enable backdrop filters and frosted glass effects on windows and dock.',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Enable Frosted Glass Blur',
                style: GoogleFonts.inter(
                  color: onSurfaceColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Uses GPU hardware-accelerated background filters',
                style: GoogleFonts.inter(
                  color: onSurfaceColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              value: settings.enableGlassEffects,
              activeTrackColor: settings.accentColor,
              onChanged: (val) => settings.setEnableGlassEffects(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperSection(SystemSettings settings, Color onSurfaceColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(
            'Desktop Wallpaper',
            'Set custom wallpapers, choose presets, or paste web image URLs. All changes persist locally.',
            onSurfaceColor,
          ),
          const SizedBox(height: 28),

          // Active Wallpaper Status Card
          _buildActiveWallpaperCard(settings, onSurfaceColor),
          const SizedBox(height: 24),

          // Presets & Upload Section
          _SettingCard(
            title: 'Choose Wallpaper',
            description:
                'Pick a curated preset or upload your own image from your computer.',
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                // Preset Thumbnails
                ..._presets.map((preset) {
                  final path = preset['path']!;
                  final name = preset['name']!;
                  final isSelected = !settings.isCustomWallpaper &&
                      settings.wallpaperPath == path;

                  return _WallpaperPreviewCard(
                    path: path,
                    title: name,
                    isSelected: isSelected,
                    accentColor: settings.accentColor,
                    onTap: () => settings.setWallpaper(path),
                  );
                }),

                // Upload New Tile
                InkWell(
                  onTap: _isUploading ? null : () => _pickWallpaper(settings),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 150,
                    height: 100,
                    decoration: BoxDecoration(
                      color: settings.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: settings.accentColor.withValues(alpha: 0.4),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isUploading)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: settings.accentColor,
                            ),
                          )
                        else
                          Icon(
                            Icons.cloud_upload_rounded,
                            color: settings.accentColor,
                            size: 26,
                          ),
                        const SizedBox(height: 6),
                        Text(
                          _isUploading ? 'Optimizing...' : 'Upload Image',
                          style: GoogleFonts.inter(
                            color: settings.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'IndexedDB Persistent',
                          style: GoogleFonts.inter(
                            color: onSurfaceColor.withValues(alpha: 0.4),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Image URL Input
          _SettingCard(
            title: 'Set from Image URL',
            description:
                'Paste any direct image link (Unsplash, Imgur, GitHub, etc.) to set as wallpaper.',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: GoogleFonts.inter(fontSize: 13, color: onSurfaceColor),
                    decoration: InputDecoration(
                      hintText: 'https://images.unsplash.com/...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: onSurfaceColor.withValues(alpha: 0.35),
                      ),
                      prefixIcon: const Icon(Icons.link_rounded, size: 18),
                      filled: true,
                      fillColor: onSurfaceColor.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: onSurfaceColor.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: onSurfaceColor.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: settings.accentColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _applyCustomUrl(settings),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _applyCustomUrl(settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Apply URL',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Wallpaper Blur & Dim Controls
          _SettingCard(
            title: 'Desktop Background Adjustments',
            description:
                'Fine-tune desktop contrast and blur to keep app windows easily readable.',
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.blur_on_rounded,
                      size: 20,
                      color: onSurfaceColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Background Blur',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: onSurfaceColor,
                                ),
                              ),
                              Text(
                                '${settings.wallpaperBlur.toStringAsFixed(0)} px',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: settings.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: settings.wallpaperBlur,
                            min: 0.0,
                            max: 20.0,
                            divisions: 20,
                            activeColor: settings.accentColor,
                            onChanged: (v) => settings.setWallpaperBlur(v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.brightness_medium_rounded,
                      size: 20,
                      color: onSurfaceColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Background Dimming',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: onSurfaceColor,
                                ),
                              ),
                              Text(
                                '${(settings.wallpaperDim * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: settings.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: settings.wallpaperDim,
                            min: 0.0,
                            max: 0.6,
                            divisions: 12,
                            activeColor: settings.accentColor,
                            onChanged: (v) => settings.setWallpaperDim(v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWallpaperCard(
    SystemSettings settings,
    Color onSurfaceColor,
  ) {
    final isCustom = settings.isCustomWallpaper;
    final isPreset = !isCustom && settings.wallpaperPath.startsWith('assets');
    final isWebUrl = !isCustom && !isPreset;

    String statusLabel = 'Preset Wallpaper';
    if (isCustom) {
      statusLabel = 'Custom Upload (IndexedDB Persistent)';
    } else if (isWebUrl) {
      statusLabel = 'Web URL Background';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurfaceColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: onSurfaceColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Active Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 120,
              height: 72,
              child: settings.wallpaperBytes != null
                  ? Image.memory(
                      settings.wallpaperBytes!,
                      fit: BoxFit.cover,
                    )
                  : settings.wallpaperPath.startsWith('assets')
                      ? Image.asset(
                          settings.wallpaperPath,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          settings.wallpaperPath,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Image.asset(
                            'assets/wallpaper.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: settings.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: GoogleFonts.inter(
                          color: settings.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          color: onSurfaceColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isCustom
                      ? 'Stored safely in browser storage across sessions.'
                      : (isWebUrl ? settings.wallpaperPath : 'Default fyrOS Neon City'),
                  style: GoogleFonts.inter(
                    color: onSurfaceColor.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => settings.resetWallpaper(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Default'),
            style: OutlinedButton.styleFrom(
              foregroundColor: onSurfaceColor.withValues(alpha: 0.8),
              side: BorderSide(color: onSurfaceColor.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDockSection(
    SystemSettings settings,
    Color onSurfaceColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(
            'Desktop & Dock',
            'Configure desktop behavior, dock auto-hiding, and icon scaling.',
            onSurfaceColor,
          ),
          const SizedBox(height: 28),

          _SettingCard(
            title: 'Dock Auto-Hide',
            description:
                'Automatically hides the dock when windows overlap or when not hovered.',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Auto-Hide Dock',
                style: GoogleFonts.inter(
                  color: onSurfaceColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Move mouse to bottom edge of screen to reveal dock',
                style: GoogleFonts.inter(
                  color: onSurfaceColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              value: settings.dockAutoHide,
              activeTrackColor: settings.accentColor,
              onChanged: (val) => settings.setDockAutoHide(val),
            ),
          ),
          const SizedBox(height: 24),

          _SettingCard(
            title: 'Dock Icon Scale',
            description:
                'Adjust the sizing of icons and height of the desktop dock.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scale: ${(settings.dockScale * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: settings.accentColor,
                      ),
                    ),
                    Text(
                      settings.dockScale < 0.95
                          ? 'Compact'
                          : (settings.dockScale > 1.1 ? 'Large' : 'Standard'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: onSurfaceColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.dockScale,
                  min: 0.8,
                  max: 1.25,
                  divisions: 9,
                  activeColor: settings.accentColor,
                  onChanged: (v) => settings.setDockScale(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSoundSection(
    SystemSettings settings,
    Color onSurfaceColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(
            'Time & Audio',
            'Configure top bar clock formats, system audio volume, and game synthesizer effects.',
            onSurfaceColor,
          ),
          const SizedBox(height: 28),

          _SettingCard(
            title: 'Top Bar Clock Format',
            description:
                'Select between 12-hour AM/PM and 24-hour military clock display.',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '24-Hour Clock (Military Time)',
                    style: GoogleFonts.inter(
                      color: onSurfaceColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    settings.use24HourClock
                        ? 'Display format: 14:30'
                        : 'Display format: 2:30 PM',
                    style: GoogleFonts.inter(
                      color: onSurfaceColor.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  value: settings.use24HourClock,
                  activeTrackColor: settings.accentColor,
                  onChanged: (val) => settings.setUse24HourClock(val),
                ),
                const Divider(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Display Clock Seconds',
                    style: GoogleFonts.inter(
                      color: onSurfaceColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Shows live seconds in top system bar',
                    style: GoogleFonts.inter(
                      color: onSurfaceColor.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  value: settings.showClockSeconds,
                  activeTrackColor: settings.accentColor,
                  onChanged: (val) => settings.setShowClockSeconds(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SettingCard(
            title: 'Audio & Sound Effects',
            description:
                'Controls system volume level and retro synthesizer effects.',
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      settings.soundVolume == 0
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      size: 22,
                      color: onSurfaceColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Master Volume',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: onSurfaceColor,
                                ),
                              ),
                              Text(
                                '${(settings.soundVolume * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: settings.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: settings.soundVolume,
                            min: 0.0,
                            max: 1.0,
                            activeColor: settings.accentColor,
                            onChanged: (v) => settings.setSoundVolume(v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Audio & Synthesizer Effects',
                    style: GoogleFonts.inter(
                      color: onSurfaceColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Enables game audio, laser synth, and sound cues',
                    style: GoogleFonts.inter(
                      color: onSurfaceColor.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  value: settings.soundEffectsEnabled,
                  activeTrackColor: settings.accentColor,
                  onChanged: (val) => settings.setSoundEffectsEnabled(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(SystemSettings settings, Color onSurfaceColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(
            'About fyrOS',
            'System telemetry, hardened kernel configuration, and developer environment info.',
            onSurfaceColor,
          ),
          const SizedBox(height: 28),

          _SettingCard(
            title: 'System Information',
            description:
                'Running live on Google Cloud Platform (us-central1) with automated Ansible/Terraform orchestration.',
            child: Column(
              children: [
                _buildInfoRow('Operating System', 'fyrOS 2.4.0-hardened (Debian 12)', onSurfaceColor),
                _buildInfoRow('Orchestration', 'WE-IAC (Terraform 1.7 + Ansible 9.2)', onSurfaceColor),
                _buildInfoRow('Host Specs', 'GCP e2-medium (2 vCPU, 4GB RAM, 30GB SSD)', onSurfaceColor),
                _buildInfoRow('Kernel Version', 'Linux 6.1.0-28-cloud-amd64', onSurfaceColor),
                _buildInfoRow('Swappiness Tuning', 'vm.swappiness = 20', onSurfaceColor),
                _buildInfoRow('Zero-Trust Network', 'Docker Internal Bridge (172.28.0.0/16)', onSurfaceColor),
                _buildInfoRow('Firewall', 'UFW Active (22/TCP, 80/TCP, 443/TCP)', onSurfaceColor),
                _buildInfoRow('Web Engine', 'Flutter 3.x Web (CanvasKit / WebGL)', onSurfaceColor),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SettingCard(
            title: 'Reset Preferences',
            description:
                'Clear all customized wallpapers, themes, and dock configurations back to system defaults.',
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _confirmResetAll(settings),
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Reset All Settings to Defaults'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                      ),
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

  Widget _buildInfoRow(String label, String value, Color onSurfaceColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: onSurfaceColor.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                color: onSurfaceColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetAll(SystemSettings settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E212B),
        title: Text(
          'Reset All Settings?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will reset all theme options, wallpapers, dock scales, and audio volume back to factory defaults. Custom uploaded wallpapers will be cleared.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              settings.resetAllSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All settings restored to defaults.'),
                  backgroundColor: Color(0xFF2A2D39),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeading(String title, String subtitle, Color onSurfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: onSurfaceColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            color: onSurfaceColor.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _SettingCard({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: onSurfaceColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onSurfaceColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: onSurfaceColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              color: onSurfaceColor.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16181E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : onSurfaceColor.withValues(alpha: 0.15),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? accentColor
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperPreviewCard extends StatelessWidget {
  final String path;
  final String title;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _WallpaperPreviewCard({
    required this.path,
    required this.title,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 150,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accentColor : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
              image: DecorationImage(
                image: path.startsWith('assets')
                    ? AssetImage(path) as ImageProvider
                    : NetworkImage(path),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? accentColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
