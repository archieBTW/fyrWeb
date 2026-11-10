import 'package:flutter/material.dart';
import '../fyr_theme.dart';
import '../system_controller.dart';
import '../system_settings.dart';
import 'package:provider/provider.dart';
import 'grand_theft_ant/grand_theft_ant_app.dart';
import 'resume_app.dart';

class FyrFilesApp extends StatefulWidget {
  const FyrFilesApp({super.key});

  @override
  State<FyrFilesApp> createState() => _FyrFilesAppState();
}

class _FyrFilesAppState extends State<FyrFilesApp> {
  String _currentDirectory = 'Home';
  final List<String> _history = ['Home'];
  bool _isSidebarCollapsed = false;
  bool? _didInitMobile;
  bool _isListView = false;
  String _sortBy = 'name'; // 'name', 'date', 'size'
  bool _sortAscending = true;
  String? _selectedTag;
  final Set<String> _selectedItems = {};
  String _searchFilter = '';

  final List<Map<String, dynamic>> _customTags = [
    {'id': 'work', 'name': 'Work', 'color': Colors.blueAccent},
    {'id': 'personal', 'name': 'Personal', 'color': Colors.greenAccent},
    {'id': 'fyr', 'name': 'fyrOS', 'color': Colors.purpleAccent},
  ];

  final Map<String, List<Map<String, dynamic>>> _fileSystem = {
    'Home': [
      {'name': 'Desktop', 'isDir': true, 'tag': null, 'date': '2026-10-04', 'size': '--'},
      {'name': 'Downloads', 'isDir': true, 'tag': null, 'date': '2026-10-04', 'size': '--'},
      {'name': 'Code', 'isDir': true, 'tag': 'work', 'date': '2026-10-04', 'size': '--'},
      {'name': 'Pictures', 'isDir': true, 'tag': 'personal', 'date': '2026-10-04', 'size': '--'},
      {'name': 'Music', 'isDir': true, 'tag': 'personal', 'date': '2026-10-04', 'size': '--'},
      {'name': 'FyrDAW', 'isDir': true, 'tag': 'fyr', 'date': '2026-10-04', 'size': '--'},
      {'name': 'Videos', 'isDir': true, 'tag': null, 'date': '2026-10-04', 'size': '--'},
      {'name': 'fyrjournal', 'isDir': true, 'tag': 'fyr', 'date': '2026-10-04', 'size': '--'},
      {'name': 'resume.pdf', 'isDir': false, 'type': 'pdf', 'tag': 'work', 'date': '2026-11-01', 'size': '245 KB'},
    ],
    'Home/Desktop': [
      {'name': 'fyrBrowser.desktop', 'isDir': false, 'type': 'web', 'date': '2026-10-04', 'size': '4 KB'},
      {'name': 'fyrFiles.desktop', 'isDir': false, 'type': 'app', 'date': '2026-10-04', 'size': '4 KB'},
      {'name': 'fyrCode.desktop', 'isDir': false, 'type': 'app', 'date': '2026-10-04', 'size': '4 KB'},
      {'name': 'fyrTerm.desktop', 'isDir': false, 'type': 'app', 'date': '2026-10-04', 'size': '4 KB'},
      {'name': 'notes.txt', 'isDir': false, 'type': 'text', 'date': '2026-11-01', 'size': '1.2 KB'},
    ],
    'Home/Trash': [],
    'Home/Root': [
      {'name': 'bin', 'isDir': true, 'date': '2026-10-04', 'size': '--'},
      {'name': 'etc', 'isDir': true, 'date': '2026-10-04', 'size': '--'},
      {'name': 'home', 'isDir': true, 'date': '2026-10-04', 'size': '--'},
      {'name': 'opt', 'isDir': true, 'date': '2026-10-04', 'size': '--'},
      {'name': 'usr', 'isDir': true, 'date': '2026-10-04', 'size': '--'},
      {'name': 'var', 'isDir': true, 'date': '2026-10-04', 'size': '--'},
    ],
    'Home/Code': [
      {'name': 'friend.ly', 'isDir': false, 'type': 'web', 'url': 'https://friendly.archerwoods.dev', 'date': '2026-09-12', 'size': '1.2 MB'},
      {'name': 'grand_theft_ant.game', 'isDir': false, 'type': 'game', 'date': '2026-10-04', 'size': '18 MB'},
      {'name': 'libretrac', 'isDir': false, 'type': 'web', 'url': 'https://libretrac.site', 'date': '2026-08-20', 'size': '3.4 MB'},
      {'name': 'welledumacated', 'isDir': false, 'type': 'web', 'url': 'https://welledumacated.dev', 'date': '2026-07-15', 'size': '4.1 MB'},
      {'name': 'bybl', 'isDir': false, 'type': 'web', 'url': 'https://bybl.dev', 'date': '2026-09-01', 'size': '2.8 MB'},
      {'name': 'theolivebranch', 'isDir': false, 'type': 'web', 'url': 'https://theolivebranch.press', 'date': '2026-06-10', 'size': '5.2 MB'},
      {'name': 'fyr.software', 'isDir': false, 'type': 'web', 'url': 'https://fyr.software', 'date': '2026-10-01', 'size': '8.6 MB'},
      {'name': 'beats_by_arch', 'isDir': false, 'type': 'web', 'url': 'https://beats.archerwoods.dev', 'date': '2026-10-15', 'size': '6.4 MB'},
    ],
    'Home/Pictures': [
      {'name': 'desktop_preview.png', 'isDir': false, 'type': 'image', 'date': '2026-10-04', 'size': '2.9 MB'},
      {'name': 'space_wallpaper.jpg', 'isDir': false, 'type': 'image', 'date': '2026-10-04', 'size': '1.0 MB'},
      {'name': 'fyrDE_architecture.png', 'isDir': false, 'type': 'image', 'date': '2026-09-28', 'size': '840 KB'},
    ],
    'Home/Downloads': [
      {'name': 'fyrDE_x86_64.iso', 'isDir': false, 'type': 'iso', 'date': '2026-11-05', 'size': '2.1 GB'},
      {'name': 'kernel-7.0.3-arch1.tar.zst', 'isDir': false, 'type': 'archive', 'date': '2026-11-08', 'size': '124 MB'},
    ],
    'Home/Music': [
      {'name': 'synthwave_session_01.flac', 'isDir': false, 'type': 'audio', 'date': '2026-10-20', 'size': '42 MB'},
      {'name': 'ambient_nebula.wav', 'isDir': false, 'type': 'audio', 'date': '2026-10-22', 'size': '58 MB'},
    ],
    'Home/Videos': [
      {'name': 'wf-recorder-2026-10-04.mp4', 'isDir': false, 'type': 'video', 'date': '2026-10-04', 'size': '112 MB'},
    ],
    'Home/FyrDAW': [
      {'name': 'project_darkwave.fdw', 'isDir': false, 'type': 'daw', 'date': '2026-10-18', 'size': '14 MB'},
    ],
    'Home/fyrjournal': [
      {'name': 'journal_2026-11.md', 'isDir': false, 'type': 'text', 'date': '2026-11-02', 'size': '12 KB'},
    ],
  };

  void _navigateTo(String dir) {
    setState(() {
      _currentDirectory = dir;
      _history.add(dir);
      _selectedItems.clear();
    });
  }

  void _navigateBack() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _currentDirectory = _history.last;
        _selectedItems.clear();
      });
    }
  }

  void _openItem(Map<String, dynamic> item) {
    if (item['isDir'] == true) {
      final newPath = '$_currentDirectory/${item['name']}';
      if (_fileSystem.containsKey(newPath)) {
        _navigateTo(newPath);
      } else {
        _fileSystem[newPath] = [];
        _navigateTo(newPath);
      }
    } else {
      final system = Provider.of<SystemController>(context, listen: false);
      if (item['type'] == 'pdf') {
        system.openApp('resume', 'Resume', const ResumeApp(), Icons.picture_as_pdf);
      } else if (item['type'] == 'game') {
        system.openApp('grand_theft_ant', 'Grand Theft Ant', const GrandTheftAntApp(), Icons.sports_esports_rounded);
      } else if (item['type'] == 'web' && item['url'] != null) {
        system.openApp(item['name'], item['name'], null, Icons.html, url: item['url']);
      } else if (item['type'] == 'image') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${item['name']} in Photo Viewer...'), duration: const Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${item['name']}...'), duration: const Duration(seconds: 1)),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getCurrentFiles() {
    List<Map<String, dynamic>> list = _fileSystem[_currentDirectory] ?? [];
    if (_selectedTag != null) {
      list = list.where((item) => item['tag'] == _selectedTag).toList();
    }
    if (_searchFilter.isNotEmpty) {
      list = list
          .where((item) => item['name'].toString().toLowerCase().contains(_searchFilter.toLowerCase()))
          .toList();
    }

    list = List.from(list);
    list.sort((a, b) {
      final bool isDirA = a['isDir'] == true;
      final bool isDirB = b['isDir'] == true;
      if (isDirA != isDirB) return isDirA ? -1 : 1;

      int comp;
      switch (_sortBy) {
        case 'date':
          comp = (a['date'] ?? '').compareTo(b['date'] ?? '');
          break;
        case 'size':
          comp = (a['size'] ?? '').compareTo(b['size'] ?? '');
          break;
        case 'name':
        default:
          comp = (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase());
          break;
      }
      return _sortAscending ? comp : -comp;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final systemSettings = context.watch<SystemSettings?>();
    final accentColor = systemSettings?.accentColor ?? FyrTheme.accentColor;
    final files = _getCurrentFiles();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    if (_didInitMobile == null) {
      _didInitMobile = true;
      if (isMobile) {
        _isSidebarCollapsed = true;
      }
    }

    return Container(
      color: FyrTheme.bgColor,
      child: Column(
        children: [
          // Toolbar
          Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 14),
            decoration: BoxDecoration(
              color: FyrTheme.isDark ? const Color(0xFF000000) : const Color(0xFFF0F0F0),
              border: Border(
                bottom: BorderSide(color: FyrTheme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _history.length > 1 ? _navigateBack : null,
                  color: _history.length > 1 ? FyrTheme.textColor : FyrTheme.textColorMuted,
                ),
                const SizedBox(width: 8),

                // Directory Breadcrumbs (e.g. root > home > archie > ...)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _buildBreadcrumbs(accentColor),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Search button
                IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: FyrTheme.textColor,
                  onPressed: () => _showSearchDialog(),
                ),
                const SizedBox(width: 8),

                if (!isMobile) ...[
                  // Filter Tag dropdown (desktop)
                  const Text('Filter:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: FyrTheme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedTag,
                        dropdownColor: FyrTheme.bgColor,
                        isDense: true,
                        style: TextStyle(color: FyrTheme.textColor, fontSize: 12),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Files'),
                          ),
                          ..._customTags.map(
                            (tag) => DropdownMenuItem<String?>(
                              value: tag['id'],
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: tag['color'],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(tag['name']),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _selectedTag = val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // View mode toggle: Grid / List
                IconButton(
                  icon: Icon(_isListView ? Icons.grid_view : Icons.list, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: FyrTheme.textColor,
                  onPressed: () => setState(() => _isListView = !_isListView),
                ),
                const SizedBox(width: 8),

                // Sort & Filter dropdown
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: FyrTheme.bgColor,
                  onSelected: (val) {
                    if (val.startsWith('tag:')) {
                      final tagId = val.substring(4);
                      setState(() => _selectedTag = tagId == 'all' ? null : tagId);
                    } else {
                      setState(() {
                        if (_sortBy == val) {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortBy = val;
                          _sortAscending = true;
                        }
                      });
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'name',
                      child: Text('Sort by Name ${_sortBy == "name" ? (_sortAscending ? "▲" : "▼") : ""}',
                        style: TextStyle(color: FyrTheme.textColor)),
                    ),
                    PopupMenuItem(
                      value: 'date',
                      child: Text('Sort by Date ${_sortBy == "date" ? (_sortAscending ? "▲" : "▼") : ""}',
                        style: TextStyle(color: FyrTheme.textColor)),
                    ),
                    PopupMenuItem(
                      value: 'size',
                      child: Text('Sort by Size ${_sortBy == "size" ? (_sortAscending ? "▲" : "▼") : ""}',
                        style: TextStyle(color: FyrTheme.textColor)),
                    ),
                    if (isMobile) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'tag:all',
                        child: Text('Filter: All Files', style: TextStyle(color: FyrTheme.textColor)),
                      ),
                      ..._customTags.map((t) => PopupMenuItem(
                        value: 'tag:${t['id']}',
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: t['color'], shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Filter: ${t['name']}', style: TextStyle(color: FyrTheme.textColor)),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),

                if (isMobile) ...[
                  const SizedBox(width: 8),
                  // Mobile sidebar drawer toggle
                  IconButton(
                    icon: Icon(Icons.folder_special_outlined, size: 20, color: accentColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Folders',
                    onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  ),
                ],
              ],
            ),
          ),

          // Main body: Sidebar + Content
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    // Desktop Sidebar
                    if (!isMobile) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isSidebarCollapsed ? 56 : 200,
                        color: FyrTheme.isDark ? const Color(0xFF000000) : const Color(0xFFF7F7F7),
                        child: _buildSidebarContent(accentColor, false),
                      ),
                      VerticalDivider(width: 1, thickness: 1, color: FyrTheme.dividerColor),
                    ],

                    // Content View
                    Expanded(
                      child: files.isEmpty
                          ? Center(
                              child: Text(
                                'Empty Directory',
                                style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 16),
                              ),
                            )
                          : (_isListView
                              ? _buildListView(files, isMobile, accentColor)
                              : _buildGridView(files, isMobile, accentColor)),
                    ),
                  ],
                ),

                // Mobile Slide-out Drawer
                if (isMobile && !_isSidebarCollapsed) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSidebarCollapsed = true),
                      child: Container(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 240,
                    child: Container(
                      decoration: BoxDecoration(
                        color: FyrTheme.isDark ? const Color(0xFF141414) : const Color(0xFFF7F7F7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(4, 0),
                          ),
                        ],
                      ),
                      child: _buildSidebarContent(accentColor, true),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(Color accentColor, bool isMobile) {
    return Column(
      children: [
        if (!isMobile)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
              child: IconButton(
                icon: Icon(
                  _isSidebarCollapsed ? Icons.menu : Icons.menu_open,
                  color: accentColor,
                  size: 20,
                ),
                onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              ),
            ),
          )
        else
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Places',
                  style: TextStyle(
                    color: FyrTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: FyrTheme.textColorMuted,
                  onPressed: () => setState(() => _isSidebarCollapsed = true),
                ),
              ],
            ),
          ),
        Divider(height: 1, color: FyrTheme.dividerColor),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildSidebarItem(Icons.home, 'Home', 'Home', accentColor, isMobile),
              _buildSidebarItem(Icons.desktop_mac, 'Desktop', 'Home/Desktop', accentColor, isMobile),
              _buildSidebarItem(Icons.library_music, 'Music', 'Home/Music', accentColor, isMobile),
              _buildSidebarItem(Icons.photo_library, 'Pictures', 'Home/Pictures', accentColor, isMobile),
              _buildSidebarItem(Icons.file_download, 'Downloads', 'Home/Downloads', accentColor, isMobile),
              _buildSidebarItem(Icons.delete, 'Trash', 'Home/Trash', accentColor, isMobile),
              _buildSidebarItem(Icons.computer, 'My Computer', 'Home/Root', accentColor, isMobile),
              Divider(color: FyrTheme.dividerColor),
              if (!_isSidebarCollapsed || isMobile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    'Custom Pins',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: FyrTheme.textColorMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              _buildSidebarItem(Icons.folder, 'Code', 'Home/Code', accentColor, isMobile),
              _buildSidebarItem(Icons.folder, 'FyrDAW', 'Home/FyrDAW', accentColor, isMobile),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBreadcrumbs(Color accentColor) {
    final parts = _currentDirectory.split('/');
    final List<Widget> widgets = [];

    widgets.add(
      InkWell(
        onTap: () => _navigateTo('Home'),
        child: const Text('root > home > archie', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );

    if (parts.length > 1) {
      for (int i = 1; i < parts.length; i++) {
        final subPath = parts.sublist(0, i + 1).join('/');
        widgets.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(' > ', style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 13)),
              InkWell(
                onTap: () => _navigateTo(subPath),
                child: Text(
                  parts[i],
                  style: TextStyle(
                    color: i == parts.length - 1 ? accentColor : FyrTheme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildSidebarItem(IconData icon, String title, String path, Color accentColor, [bool isMobile = false]) {
    final isSelected = _currentDirectory == path;

    return InkWell(
      onTap: () {
        _navigateTo(path);
        if (isMobile) {
          setState(() => _isSidebarCollapsed = true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? accentColor
                  : (icon == Icons.folder ? accentColor : FyrTheme.textColor.withValues(alpha: 0.8)),
              size: 18,
            ),
            if (!_isSidebarCollapsed || isMobile) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? accentColor : FyrTheme.textColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> files, bool isMobile, Color accentColor) {
    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 3 : 5,
        crossAxisSpacing: isMobile ? 10 : 20,
        mainAxisSpacing: isMobile ? 12 : 24,
        childAspectRatio: isMobile ? 0.85 : 0.9,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final item = files[index];
        final name = item['name'] as String;
        final isSelected = _selectedItems.contains(name);

        return GestureDetector(
          onTap: isMobile
              ? () => _openItem(item)
              : () {
                  setState(() {
                    _selectedItems.clear();
                    _selectedItems.add(name);
                  });
                },
          onLongPress: isMobile
              ? () {
                  setState(() {
                    if (_selectedItems.contains(name)) {
                      _selectedItems.remove(name);
                    } else {
                      _selectedItems.add(name);
                    }
                  });
                }
              : null,
          onDoubleTap: !isMobile ? () => _openItem(item) : null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accentColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildItemIcon(item, accentColor, size: isMobile ? 38 : 56),
                SizedBox(height: isMobile ? 6 : 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FyrTheme.textColor,
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> files, bool isMobile, Color accentColor) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 8),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final item = files[index];
        final name = item['name'] as String;
        final isSelected = _selectedItems.contains(name);

        return GestureDetector(
          onDoubleTap: !isMobile ? () => _openItem(item) : null,
          child: ListTile(
            dense: true,
            selected: isSelected,
            selectedTileColor: accentColor.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            leading: SizedBox(width: 28, height: 28, child: _buildItemIcon(item, accentColor, size: 24)),
            title: Text(name, style: TextStyle(color: FyrTheme.textColor, fontSize: isMobile ? 12 : 13)),
            trailing: isMobile
                ? Text(item['size'] ?? '', style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 10))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item['date'] ?? '', style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 11)),
                      const SizedBox(width: 20),
                      Text(item['size'] ?? '', style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 11)),
                    ],
                  ),
            onTap: isMobile
                ? () => _openItem(item)
                : () {
                    setState(() {
                      _selectedItems.clear();
                      _selectedItems.add(name);
                    });
                  },
          ),
        );
      },
    );
  }

  Widget _buildItemIcon(Map<String, dynamic> item, Color accentColor, {double size = 56}) {
    if (item['isDir'] == true) {
      // Folder icon using dynamic accent color!
      return Icon(
        Icons.folder,
        color: accentColor,
        size: size,
      );
    }
    final type = item['type'];
    if (type == 'pdf') {
      return Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: size);
    }
    if (type == 'web') {
      return Icon(Icons.language, color: Colors.cyanAccent, size: size);
    }
    if (type == 'game') {
      return Icon(Icons.sports_esports_rounded, color: const Color(0xFF7FA650), size: size);
    }
    if (type == 'image') {
      return Icon(Icons.image, color: Colors.purpleAccent, size: size);
    }
    if (type == 'audio') {
      return Icon(Icons.audiotrack, color: Colors.tealAccent, size: size);
    }
    if (type == 'video') {
      return Icon(Icons.movie, color: Colors.orangeAccent, size: size);
    }
    return Icon(Icons.insert_drive_file, color: Colors.grey, size: size);
  }

  void _showSearchDialog() {
    final textController = TextEditingController(text: _searchFilter);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FyrTheme.bgColor,
        title: Text('Search Files', style: TextStyle(color: FyrTheme.textColor)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(color: FyrTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Search files in current directory...',
            hintStyle: TextStyle(color: FyrTheme.textColorMuted),
          ),
          onSubmitted: (val) {
            setState(() => _searchFilter = val.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchFilter = '');
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: TextStyle(color: FyrTheme.textColorMuted)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _searchFilter = textController.text.trim());
              Navigator.pop(ctx);
            },
            child: Text('Filter', style: TextStyle(color: FyrTheme.accentColor)),
          ),
        ],
      ),
    );
  }
}
