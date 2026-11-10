import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../fyr_theme.dart';
import '../system_settings.dart';

class SettingsCategory {
  final String name;
  final IconData icon;

  SettingsCategory(this.name, this.icon);
}

class FyrSettingsApp extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;

  const FyrSettingsApp({
    super.key,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
  });

  @override
  State<FyrSettingsApp> createState() => _FyrSettingsAppState();
}

class _FyrSettingsAppState extends State<FyrSettingsApp> {
  int _selectedIndex = 4; // Default to Personalization to match desktop focus
  bool _isSidebarCollapsed = false;
  bool _isUploadingWallpaper = false;

  static const List<Map<String, String>> _defaultWallpapers = [
    {
      'name': 'Deep Space',
      'path': 'assets/wallpaper.jpg',
    },
    {
      'name': 'fyr Abstract',
      'path': 'assets/wallpaper.png',
    },
    {
      'name': 'Alpine Sunset',
      'path': 'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?q=80&w=1920',
    },
    {
      'name': 'Cyber Grid',
      'path': 'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1920',
    },
    {
      'name': 'Mountain Fog',
      'path': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1920',
    },
  ];

  Future<void> _pickWallpaper(SystemSettings settings) async {
    setState(() => _isUploadingWallpaper = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final file = result.files.first;
        final bytes = file.bytes!;
        final ext = (file.extension ?? 'png').toLowerCase();
        final mimeType = (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/png';

        await settings.setCustomWallpaperFromBytes(bytes, mimeType: mimeType);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Custom wallpaper saved to local storage!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF1E1E1E),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking wallpaper: $e');
    } finally {
      if (mounted) setState(() => _isUploadingWallpaper = false);
    }
  }

  final List<SettingsCategory> _categories = [
    SettingsCategory('Wi-Fi', Icons.wifi),
    SettingsCategory('Bluetooth', Icons.bluetooth),
    SettingsCategory('Displays', Icons.monitor),
    SettingsCategory('Sound', Icons.volume_up),
    SettingsCategory('Personalization', Icons.palette),
    SettingsCategory('Default Apps', Icons.apps),
    SettingsCategory('Power', Icons.battery_charging_full),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    final accentColor = FyrTheme.accentColor;
    final isMobile = MediaQuery.of(context).size.width < 650;

    if (isMobile) {
      return Scaffold(
        backgroundColor: FyrTheme.bgColor,
        body: Column(
          children: [
            // Top Category Navigation Bar for Mobile
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                border: Border(
                  bottom: BorderSide(
                    color: FyrTheme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedIndex == index;
                    return InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : FyrTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? accentColor : FyrTheme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 16,
                              color: isSelected
                                  ? FyrTheme.onColor(accentColor)
                                  : (FyrTheme.isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.name,
                              style: TextStyle(
                                color: isSelected ? FyrTheme.onColor(accentColor) : FyrTheme.textColor,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Mobile Main Pane Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: _buildPane(_selectedIndex, settings, accentColor, true),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final onSidebarColor = FyrTheme.onColor(accentColor);
    final onSidebarMuted = onSidebarColor == Colors.black87 ? Colors.black54 : Colors.white70;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Frosted Purple Accent Sidebar (1:1 with fyrDE)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 72 : 260,
            color: accentColor.withValues(alpha: 0.82),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Settings Header Row
                if (!_isSidebarCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: onSidebarColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.menu_open, color: onSidebarColor),
                          onPressed: () => setState(() => _isSidebarCollapsed = true),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: IconButton(
                      icon: Icon(Icons.menu, color: onSidebarColor),
                      onPressed: () => setState(() => _isSidebarCollapsed = false),
                    ),
                  ),

                if (!_isSidebarCollapsed) const SizedBox(height: 28),

                // Navigation Category List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = index),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? FyrTheme.hoverColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  color: isSelected
                                      ? onSidebarColor
                                      : onSidebarMuted,
                                  size: 20,
                                ),
                                if (!_isSidebarCollapsed) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      category.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? onSidebarColor
                                            : onSidebarMuted,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Pane Area (1:1 with fyrDE)
          Expanded(
            child: Container(
              color: FyrTheme.bgColor,
              child: Column(
                children: [
                  Container(height: 48, color: Colors.transparent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 48.0,
                        right: 48.0,
                        bottom: 48.0,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey(_selectedIndex),
                          child: _buildPane(_selectedIndex, settings, accentColor, false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPane(int index, SystemSettings settings, Color accentColor, bool isMobile) {
    switch (index) {
      case 0:
        return _buildWiFiPane(accentColor);
      case 1:
        return _buildBluetoothPane(accentColor);
      case 2:
        return _buildDisplaysPane(accentColor);
      case 3:
        return _buildSoundPane(accentColor);
      case 4:
        return _buildPersonalizationPane(settings, accentColor, isMobile);
      case 5:
        return _buildDefaultAppsPane(accentColor);
      case 6:
        return _buildPowerPane(accentColor);
      default:
        return _buildPersonalizationPane(settings, accentColor, isMobile);
    }
  }

  // ==========================================
  // 1. Personalization Pane (Exact 1:1 replica of fyrDE personalization_pane.dart)
  // ==========================================

  Widget _buildPersonalizationPane(SystemSettings settings, Color accentColor, bool isMobile) {
    final ImageProvider activeWallpaperImage;
    if (settings.wallpaperBytes != null) {
      activeWallpaperImage = MemoryImage(settings.wallpaperBytes!);
    } else if (settings.wallpaperPath.startsWith('assets/')) {
      activeWallpaperImage = AssetImage(settings.wallpaperPath);
    } else {
      activeWallpaperImage = NetworkImage(settings.wallpaperPath);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalization',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: FyrTheme.textColor,
            ),
          ),
          const SizedBox(height: 24),

          // Card 1: Theme Mode
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: FyrTheme.isDark ? BorderSide.none : BorderSide(color: FyrTheme.dividerColor),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Mode',
                          style: TextStyle(
                            color: FyrTheme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => settings.setDarkMode(false)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: !settings.isDarkMode ? accentColor : FyrTheme.cardColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                    border: Border.all(color: accentColor),
                                  ),
                                  child: Text(
                                    'Light',
                                    style: TextStyle(
                                      color: !settings.isDarkMode ? FyrTheme.onColor(accentColor) : FyrTheme.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => settings.setDarkMode(true)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: settings.isDarkMode ? accentColor : FyrTheme.cardColor,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                    border: Border.all(color: accentColor),
                                  ),
                                  child: Text(
                                    'Dark',
                                    style: TextStyle(
                                      color: settings.isDarkMode ? FyrTheme.onColor(accentColor) : FyrTheme.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Theme Mode',
                          style: TextStyle(
                            color: FyrTheme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => settings.setDarkMode(false)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: !settings.isDarkMode ? accentColor : FyrTheme.cardColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                  border: Border.all(color: accentColor),
                                ),
                                child: Text(
                                  'Light',
                                  style: TextStyle(
                                    color: !settings.isDarkMode ? FyrTheme.onColor(accentColor) : FyrTheme.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => settings.setDarkMode(true)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: settings.isDarkMode ? accentColor : FyrTheme.cardColor,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                  border: Border.all(color: accentColor),
                                ),
                                child: Text(
                                  'Dark',
                                  style: TextStyle(
                                    color: settings.isDarkMode ? FyrTheme.onColor(accentColor) : FyrTheme.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Card 2: Desktop Background
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desktop Background',
                    style: TextStyle(
                      color: FyrTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 340),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accentColor,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: activeWallpaperImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Default Backgrounds',
                    style: TextStyle(
                      color: FyrTheme.textColorMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (settings.isCustomWallpaper && settings.wallpaperBytes != null)
                          _buildThumbnailBg(
                            image: MemoryImage(settings.wallpaperBytes!),
                            label: 'Custom Upload',
                            isSelected: true,
                            accentColor: accentColor,
                            onTap: () {},
                          ),
                        ..._defaultWallpapers.map((wp) {
                          final path = wp['path']!;
                          final name = wp['name']!;
                          final isSelected = !settings.isCustomWallpaper &&
                              settings.wallpaperPath == path;
                          final ImageProvider img = path.startsWith('assets/')
                              ? AssetImage(path)
                              : NetworkImage(path) as ImageProvider;

                          return _buildThumbnailBg(
                            image: img,
                            label: name,
                            isSelected: isSelected,
                            accentColor: accentColor,
                            onTap: () => settings.setWallpaper(path),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Reset Default'),
                        style: TextButton.styleFrom(
                          foregroundColor: FyrTheme.textColorMuted,
                        ),
                        onPressed: () => settings.resetWallpaper(),
                      ),
                      ElevatedButton.icon(
                        icon: _isUploadingWallpaper
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: FyrTheme.textColor,
                                ),
                              )
                            : Icon(Icons.folder_open, color: FyrTheme.textColor),
                        label: Text(
                          _isUploadingWallpaper ? 'Saving...' : 'Browse Files...',
                          style: TextStyle(color: FyrTheme.textColor),
                        ),
                        onPressed: _isUploadingWallpaper ? null : () => _pickWallpaper(settings),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FyrTheme.cardColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Card 3: Accent Color (RGB Sliders matching fyrDE)
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accent Color',
                          style: TextStyle(
                            color: FyrTheme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pull from Background',
                              style: TextStyle(color: FyrTheme.textColorMuted),
                            ),
                            Switch(
                              value: settings.pullColorFromBg,
                              onChanged: (val) {
                                settings.setPullColorFromBg(val);
                              },
                              activeColor: accentColor,
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Accent Color',
                          style: TextStyle(
                            color: FyrTheme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Pull from Background',
                              style: TextStyle(color: FyrTheme.textColorMuted),
                            ),
                            Switch(
                              value: settings.pullColorFromBg,
                              onChanged: (val) {
                                settings.setPullColorFromBg(val);
                              },
                              activeColor: accentColor,
                            ),
                          ],
                        )
                      ],
                    ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<Color>(
                    valueListenable: FyrTheme.accentColorNotifier,
                    builder: (context, color, child) {
                      final r = ((color.toARGB32() >> 16) & 0xFF);
                      final g = ((color.toARGB32() >> 8) & 0xFF);
                      final b = (color.toARGB32() & 0xFF);

                      return AbsorbPointer(
                        absorbing: settings.pullColorFromBg,
                        child: Opacity(
                          opacity: settings.pullColorFromBg ? 0.6 : 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: FyrTheme.textColor, width: 2),
                                ),
                                child: Text(
                                  '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                  style: TextStyle(
                                    color: FyrTheme.onColor(color),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildColorSlider('Red', r, Colors.red, (val) {
                                settings.setAccentColor(Color.fromARGB(255, val.toInt(), g, b));
                              }),
                              _buildColorSlider('Green', g, Colors.green, (val) {
                                settings.setAccentColor(Color.fromARGB(255, r, val.toInt(), b));
                              }),
                              _buildColorSlider('Blue', b, Colors.blue, (val) {
                                settings.setAccentColor(Color.fromARGB(255, r, g, val.toInt()));
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Card 4: Login Screen (SDDM)
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login Screen (SDDM)',
                    style: TextStyle(
                      color: FyrTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accentColor, width: 2),
                                  color: accentColor.withValues(alpha: 0.2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person, size: 44, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(backgroundColor: FyrTheme.cardColor),
                                child: Text('Change Avatar', style: TextStyle(color: FyrTheme.textColor)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Lock Screen Background',
                          style: TextStyle(color: FyrTheme.textColor, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                            image: DecorationImage(
                              image: activeWallpaperImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accentColor, width: 2),
                                color: accentColor.withValues(alpha: 0.2),
                              ),
                              child: const Center(
                                child: Icon(Icons.person, size: 48, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: FyrTheme.cardColor),
                              child: Text('Change Avatar', style: TextStyle(color: FyrTheme.textColor)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lock Screen Background',
                                style: TextStyle(color: FyrTheme.textColor, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                                  image: DecorationImage(
                                    image: activeWallpaperImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailBg({
    required ImageProvider image,
    required String label,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 150,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? accentColor : Colors.white12,
                width: isSelected ? 3 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
              image: DecorationImage(
                image: image,
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: FyrTheme.onColor(accentColor),
                        size: 12,
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSlider(String label, int value, Color activeColor, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: FyrTheme.textColor),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(0.0, 255.0),
            min: 0,
            max: 255,
            activeColor: activeColor,
            inactiveColor: activeColor.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toString(),
            style: TextStyle(color: FyrTheme.textColorMuted),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. Wi-Fi Pane
  // ==========================================
  bool _wifiEnabled = true;

  Widget _buildWiFiPane(Color accentColor) {
    final networks = [
      {'ssid': 'FyrNet-5G', 'security': 'WPA3', 'bars': '••••', 'connected': true},
      {'ssid': 'ArchNet_Ultra', 'security': 'WPA2', 'bars': '•••', 'connected': false},
      {'ssid': 'Public_Guest_IoT', 'security': 'Open', 'bars': '••', 'connected': false},
    ];

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wi-Fi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: FyrTheme.textColor,
              ),
            ),
            Switch(
              value: _wifiEnabled,
              onChanged: (val) => setState(() => _wifiEnabled = val),
              activeColor: accentColor,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!_wifiEnabled)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Text(
                'Wi-Fi is turned off',
                style: TextStyle(color: FyrTheme.textColorMuted),
              ),
            ),
          )
        else
          ...networks.map((net) {
            final isConnected = net['connected'] == true;
            return Card(
              color: FyrTheme.cardColor,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_outlined,
                  color: isConnected ? accentColor : FyrTheme.textColor,
                ),
                title: Text(
                  net['ssid'] as String,
                  style: TextStyle(color: FyrTheme.textColor),
                ),
                subtitle: Text(
                  '${net['security']} • Signal: ${net['bars']}',
                  style: TextStyle(color: FyrTheme.textColorMuted),
                ),
                trailing: isConnected
                    ? Icon(Icons.check_circle, color: accentColor)
                    : null,
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // 3. Bluetooth Pane
  // ==========================================
  bool _bluetoothEnabled = true;

  Widget _buildBluetoothPane(Color accentColor) {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bluetooth',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: FyrTheme.textColor,
              ),
            ),
            Switch(
              value: _bluetoothEnabled,
              onChanged: (val) => setState(() => _bluetoothEnabled = val),
              activeColor: accentColor,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: FyrTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAIRED DEVICES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: FyrTheme.textColorMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.headphones, color: Colors.white),
                  title: Text('Sony WH-1000XM5', style: TextStyle(color: FyrTheme.textColor)),
                  subtitle: Text('Connected • 85% Battery', style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 11)),
                  trailing: Icon(Icons.check, color: accentColor),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.keyboard, color: Colors.white),
                  title: Text('Keychron Q1 Pro', style: TextStyle(color: FyrTheme.textColor)),
                  subtitle: Text('Connected', style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 11)),
                  trailing: Icon(Icons.check, color: accentColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. Displays Pane
  // ==========================================
  Widget _buildDisplaysPane(Color accentColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Displays & Appearance',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: FyrTheme.textColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Monitors (Arrangement)',
            style: TextStyle(
              color: FyrTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 170,
                height: 110,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor, color: FyrTheme.textColor, size: 32),
                    const SizedBox(height: 6),
                    Text('eDP-1 (Primary)', style: TextStyle(color: FyrTheme.textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('1920x1080 @ 144Hz', style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. Sound Pane
  // ==========================================
  double _outputVolume = 75;
  double _inputVolume = 60;

  Widget _buildSoundPane(Color accentColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sound',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: FyrTheme.textColor,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Output Volume', style: TextStyle(color: FyrTheme.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _outputVolume,
                          min: 0,
                          max: 100,
                          activeColor: accentColor,
                          onChanged: (val) => setState(() => _outputVolume = val),
                        ),
                      ),
                      Text('${_outputVolume.round()}%', style: TextStyle(color: FyrTheme.textColorMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Input Volume (Microphone)', style: TextStyle(color: FyrTheme.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _inputVolume,
                          min: 0,
                          max: 100,
                          activeColor: accentColor,
                          onChanged: (val) => setState(() => _inputVolume = val),
                        ),
                      ),
                      Text('${_inputVolume.round()}%', style: TextStyle(color: FyrTheme.textColorMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. Default Apps Pane
  // ==========================================
  Widget _buildDefaultAppsPane(Color accentColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Applications',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: FyrTheme.textColor,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  title: Text('Web Browser', style: TextStyle(color: FyrTheme.textColor)),
                  subtitle: Text('fyrBrowser', style: TextStyle(color: accentColor)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                ),
                Divider(height: 1, color: FyrTheme.dividerColor),
                ListTile(
                  title: Text('File Manager', style: TextStyle(color: FyrTheme.textColor)),
                  subtitle: Text('fyrFiles', style: TextStyle(color: accentColor)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                ),
                Divider(height: 1, color: FyrTheme.dividerColor),
                ListTile(
                  title: Text('Terminal', style: TextStyle(color: FyrTheme.textColor)),
                  subtitle: Text('fyrTerm', style: TextStyle(color: accentColor)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                ),
                Divider(height: 1, color: FyrTheme.dividerColor),
                ListTile(
                  title: Text('Code Editor', style: TextStyle(color: FyrTheme.textColor)),
                  subtitle: Text('fyrCode', style: TextStyle(color: accentColor)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. Power Pane
  // ==========================================
  int _powerProfile = 1; // 0: Saver, 1: Balanced, 2: Performance

  Widget _buildPowerPane(Color accentColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Power & Battery',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: FyrTheme.textColor,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.battery_charging_full, size: 48, color: accentColor),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('100% Battery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FyrTheme.textColor)),
                      Text('Charging • AC Connected', style: TextStyle(color: FyrTheme.textColorMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Power Mode', style: TextStyle(color: FyrTheme.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            color: FyrTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                RadioListTile<int>(
                  value: 0,
                  groupValue: _powerProfile,
                  activeColor: accentColor,
                  title: Text('Power Saver', style: TextStyle(color: FyrTheme.textColor)),
                  onChanged: (val) => setState(() => _powerProfile = val!),
                ),
                RadioListTile<int>(
                  value: 1,
                  groupValue: _powerProfile,
                  activeColor: accentColor,
                  title: Text('Balanced', style: TextStyle(color: FyrTheme.textColor)),
                  onChanged: (val) => setState(() => _powerProfile = val!),
                ),
                RadioListTile<int>(
                  value: 2,
                  groupValue: _powerProfile,
                  activeColor: accentColor,
                  title: Text('Performance', style: TextStyle(color: FyrTheme.textColor)),
                  onChanged: (val) => setState(() => _powerProfile = val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
