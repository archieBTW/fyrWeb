import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import '../generated/source_code.dart';
import '../fyr_theme.dart';

final Map<String, TextStyle> catppuccinTheme = {
  'root': TextStyle(
    backgroundColor: FyrTheme.bgColor,
    color: FyrTheme.textColor,
    height: 1.5,
  ),
  'keyword': TextStyle(
    color: FyrTheme.accentColor, // Mauve
    fontWeight: FontWeight.bold,
  ),
  'object': const TextStyle(color: Color(0xFFF9E2AF)), // Yellow
  'built_in': const TextStyle(color: Color(0xFF89B4FA)), // Blue
  'type': const TextStyle(color: Color(0xFFF9E2AF), fontWeight: FontWeight.w500),
  'literal': const TextStyle(color: Color(0xFFFAB387)), // Peach
  'number': const TextStyle(color: Color(0xFFFAB387)), // Peach
  'string': const TextStyle(color: Color(0xFFA6E3A1)), // Green
  'title': const TextStyle(color: Color(0xFF89B4FA)), // Blue
  'title.class': const TextStyle(color: Color(0xFFF9E2AF), fontWeight: FontWeight.bold),
  'title.function': const TextStyle(color: Color(0xFF89B4FA)),
  'class': const TextStyle(color: Color(0xFFF9E2AF)),
  'function': const TextStyle(color: Color(0xFF89B4FA)),
  'comment': const TextStyle(
    color: Color(0xFF6C7086), // Surface 2
    fontStyle: FontStyle.italic,
  ),
  'meta': const TextStyle(color: Color(0xFF94E2D5)), // Teal
  'operator': const TextStyle(color: Color(0xFF89DCEB)), // Sky
  'property': const TextStyle(color: Color(0xFFB4BEFE)), // Lavender
  'variable': TextStyle(color: FyrTheme.textColor),
  'attr': const TextStyle(color: Color(0xFFF2CDCD)), // Flamingo
};

class FileNode {
  final String name;
  final String? fullPath;
  final List<FileNode> children;

  FileNode({
    required this.name,
    this.fullPath,
    List<FileNode>? children,
  }) : children = children ?? [];

  bool get isFile => fullPath != null;
}

class CodeEditorApp extends StatefulWidget {
  const CodeEditorApp({super.key});

  @override
  State<CodeEditorApp> createState() => _CodeEditorAppState();
}

class _CodeEditorAppState extends State<CodeEditorApp> {
  final List<String> _openFiles = [
    'lib/main.dart',
    'lib/desktop_screen.dart',
    'lib/window_manager.dart',
  ];
  String? _activeFile = 'lib/main.dart';
  bool _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Tree sizing & collapsible state
  double _treeWidth = 240.0;
  bool _isTreeCollapsed = false;
  final Set<String> _collapsedDirs = {};

  final Map<String, int> _fileErrorCounts = {
    'lib/apps/browser_app.dart': 0,
    'lib/desktop_screen.dart': 0,
  };

  String _detectLanguage(String? path) {
    if (path == null) return 'dart';
    final lower = path.toLowerCase();
    if (lower.endsWith('.yaml') || lower.endsWith('.yml')) return 'yaml';
    if (lower.endsWith('.json')) return 'json';
    if (lower.endsWith('.tf')) return 'yaml';
    if (lower.endsWith('.conf') || lower.endsWith('.j2')) return 'nginx';
    if (lower.endsWith('.sh') || lower.endsWith('.bash')) return 'bash';
    if (lower.endsWith('.md')) return 'markdown';
    return 'dart';
  }

  void _openFile(String path) {
    setState(() {
      if (!_openFiles.contains(path)) {
        _openFiles.add(path);
      }
      _activeFile = path;
    });
  }

  void _closeTab(String path) {
    setState(() {
      final index = _openFiles.indexOf(path);
      _openFiles.remove(path);
      if (_activeFile == path) {
        if (_openFiles.isNotEmpty) {
          _activeFile = _openFiles[(index - 1).clamp(0, _openFiles.length - 1)];
        } else {
          _activeFile = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 650.0;
    final content = _activeFile != null ? (sourceCodeFiles[_activeFile!] ?? '// File not found') : null;

    return Container(
      color: FyrTheme.bgColor,
      child: Column(
        children: [
          // Search bar (if toggled via Ctrl+Shift+F or search icon)
          if (_showSearch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: FyrTheme.cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: FyrTheme.textColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search files or symbols...',
                        hintStyle: TextStyle(color: FyrTheme.textColorMuted),
                        prefixIcon: Icon(Icons.search, size: 14, color: FyrTheme.textColorMuted),
                        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: FyrTheme.dividerColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, size: 14, color: FyrTheme.textColorMuted),
                    onPressed: () {
                      setState(() {
                        _showSearch = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Main Body: File Tree (Desktop) + Tabs + Editor
          Expanded(
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left File Tree (if desktop and not collapsed)
                      if (!_isTreeCollapsed) ...[
                        SizedBox(
                          width: _treeWidth,
                          child: Container(
                            color: FyrTheme.sidebarColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.folder_copy_outlined, size: 14, color: FyrTheme.accentColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'WORKSPACE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: FyrTheme.textColorMuted,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () => setState(() => _showSearch = !_showSearch),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.search,
                                            size: 14,
                                            color: _showSearch ? FyrTheme.accentColor : FyrTheme.textColorMuted,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      InkWell(
                                        onTap: () => setState(() => _isTreeCollapsed = true),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.view_sidebar_outlined,
                                            size: 14,
                                            color: FyrTheme.textColorMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: FyrTheme.dividerColor),
                                Expanded(
                                  child: _buildFileTree(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Resizable Divider
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _treeWidth = (_treeWidth + details.delta.dx).clamp(140.0, 500.0);
                              });
                            },
                            child: Container(
                              width: 6,
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: Container(
                                width: 1,
                                color: FyrTheme.dividerColor,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Right Pane: Tab bar + Editor + Status bar
                      Expanded(
                        child: _buildEditorPane(isDesktop, content),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // Mobile Dropdown File Tree
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Icon(Icons.folder_open, size: 16, color: FyrTheme.accentColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Explorer: ${_activeFile ?? "Select file"}',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: FyrTheme.textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          iconColor: FyrTheme.textColorMuted,
                          collapsedIconColor: FyrTheme.textColorMuted,
                          backgroundColor: FyrTheme.sidebarColor,
                          collapsedBackgroundColor: FyrTheme.sidebarColor,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.40,
                              ),
                              child: Container(
                                color: FyrTheme.sidebarColor,
                                child: _buildFileTree(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildEditorPane(isDesktop, content),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPane(bool isDesktop, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Bar
        Container(
          height: 36,
          color: FyrTheme.isDark ? const Color(0xFF000000) : FyrTheme.cardColor,
          child: Row(
            children: [
              if (isDesktop && _isTreeCollapsed)
                InkWell(
                  onTap: () => setState(() => _isTreeCollapsed = false),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: FyrTheme.cardColor,
                      border: Border(
                        right: BorderSide(color: FyrTheme.dividerColor, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.view_sidebar_outlined, size: 14, color: FyrTheme.accentColor),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 14, color: FyrTheme.textColorMuted),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _openFiles.length,
                  itemBuilder: (context, index) {
                    final path = _openFiles[index];
                    final filename = path.split('/').last;
                    final isActive = path == _activeFile;

                    return GestureDetector(
                      onTap: () => setState(() => _activeFile = path),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isActive ? FyrTheme.bgColor : FyrTheme.cardColor,
                          border: Border(
                            top: BorderSide(
                              color: isActive ? FyrTheme.accentColor : Colors.transparent,
                              width: 2,
                            ),
                            right: BorderSide(
                              color: FyrTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _getFileIcon(filename),
                            const SizedBox(width: 6),
                            Text(
                              filename,
                              style: GoogleFonts.jetBrainsMono(
                                color: isActive ? FyrTheme.textColor : FyrTheme.textColorMuted,
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _closeTab(path),
                              child: Icon(
                                Icons.close,
                                size: 13,
                                color: isActive ? FyrTheme.textColor : FyrTheme.textColorMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.search,
                  size: 15,
                  color: _showSearch ? FyrTheme.accentColor : FyrTheme.textColorMuted,
                ),
                tooltip: 'Search (Ctrl+Shift+F)',
                onPressed: () => setState(() => _showSearch = !_showSearch),
              ),
            ],
          ),
        ),

        // Code Editor Pane
        Expanded(
          child: _activeFile == null || content == null
              ? Center(
                  child: Text(
                    'Select a file from the explorer to view',
                    style: TextStyle(color: FyrTheme.textColorMuted),
                  ),
                )
              : _buildCodeView(content, isDesktop),
        ),

        // Bottom Status Bar (1:1 replica of fyrCode)
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: FyrTheme.isDark ? const Color(0xFF000000) : FyrTheme.cardColor,
            border: Border(
              top: BorderSide(color: FyrTheme.dividerColor, width: 0.8),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Ln 1, Col 1',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: FyrTheme.textColorMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Spaces: 2',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: FyrTheme.textColorMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'UTF-8',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: FyrTheme.textColorMuted,
                  ),
                ),
                const SizedBox(width: 24),
                Icon(Icons.call_split, size: 11, color: FyrTheme.textColorMuted),
                const SizedBox(width: 4),
                Text(
                  'main',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: FyrTheme.textColorMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  _detectLanguage(_activeFile).toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: FyrTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.check_circle_outline, size: 11, color: Colors.greenAccent),
                const SizedBox(width: 4),
                Text(
                  'Ready',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  FileNode _buildTree() {
    final root = FileNode(name: 'root');

    for (final path in sourceCodeFiles.keys) {
      final parts = path.split('/');
      FileNode current = root;

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        final isFile = i == parts.length - 1;

        FileNode? child;
        for (final c in current.children) {
          if (c.name == part) {
            child = c;
            break;
          }
        }

        if (child == null) {
          child = FileNode(
            name: part,
            fullPath: isFile ? path : null,
          );
          current.children.add(child);
        }
        current = child;
      }
    }

    void sortNode(FileNode node) {
      node.children.sort((a, b) {
        if (!a.isFile && b.isFile) return -1;
        if (a.isFile && !b.isFile) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      for (final child in node.children) {
        sortNode(child);
      }
    }

    sortNode(root);
    return root;
  }

  Widget _buildFileTree() {
    if (_searchQuery.isNotEmpty) {
      final matches = sourceCodeFiles.keys
          .where((k) => k.toLowerCase().contains(_searchQuery))
          .toList();

      if (matches.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No matching files',
              style: TextStyle(color: FyrTheme.textColorMuted, fontSize: 12),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final path = matches[index];
          final filename = path.split('/').last;
          final isSelected = path == _activeFile;

          return InkWell(
            onTap: () => _openFile(path),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              color: isSelected ? FyrTheme.accentColor.withValues(alpha: 0.12) : Colors.transparent,
              child: Row(
                children: [
                  _getFileIcon(filename),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: isSelected ? FyrTheme.accentColor : FyrTheme.textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final tree = _buildTree();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: tree.children
          .map((child) => _buildTreeNode(child, 0, child.name))
          .toList(),
    );
  }

  Widget _buildTreeNode(FileNode node, int depth, String currentPath) {
    if (node.isFile) {
      final isSelected = node.fullPath == _activeFile;
      final errorCount = _fileErrorCounts[node.fullPath] ?? 0;

      return InkWell(
        onTap: () => _openFile(node.fullPath!),
        child: Container(
          padding: EdgeInsets.only(
            left: 10.0 + (depth * 14.0),
            right: 10.0,
            top: 4.0,
            bottom: 4.0,
          ),
          color: isSelected ? FyrTheme.accentColor.withValues(alpha: 0.15) : Colors.transparent,
          child: Row(
            children: [
              _getFileIcon(node.name),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    color: isSelected ? FyrTheme.accentColor : FyrTheme.textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (errorCount > 0)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFED8796),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      final isExpanded = !_collapsedDirs.contains(currentPath);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _collapsedDirs.add(currentPath);
                } else {
                  _collapsedDirs.remove(currentPath);
                }
              });
            },
            child: Container(
              padding: EdgeInsets.only(
                left: 6.0 + (depth * 14.0),
                right: 10.0,
                top: 4.0,
                bottom: 4.0,
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 14,
                    color: FyrTheme.textColorMuted,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    isExpanded ? Icons.folder_open : Icons.folder,
                    size: 15,
                    color: FyrTheme.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      node.name,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: FyrTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ...node.children.map((child) => _buildTreeNode(
                  child,
                  depth + 1,
                  '$currentPath/${child.name}',
                )),
        ],
      );
    }
  }

  Widget _buildCodeView(String content, bool isDesktop) {
    final lines = content.split('\n');
    final double fontSize = isDesktop ? 12.5 : 11.0;

    return Container(
      width: double.infinity,
      color: FyrTheme.bgColor,
      alignment: Alignment.topLeft,
      child: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line numbers gutter (anchored to the left side against the file tree)
              SelectionContainer.disabled(
                child: Container(
                  padding: const EdgeInsets.only(left: 10.0, right: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(lines.length, (index) {
                      return Text(
                        '${index + 1}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: fontSize,
                          color: FyrTheme.textColorMuted.withValues(alpha: 0.45),
                          height: 1.5,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // Highlighted Code (anchored next to line numbers, scrollable horizontally if needed)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: HighlightView(
                    content,
                    language: _detectLanguage(_activeFile),
                    theme: catppuccinTheme,
                    padding: EdgeInsets.zero,
                    textStyle: GoogleFonts.jetBrainsMono(
                      fontSize: fontSize,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getFileIcon(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.dart')) {
      return const Icon(Icons.code, size: 14, color: Color(0xFF89DCEB));
    }
    if (lower.endsWith('.yaml') || lower.endsWith('.yml')) {
      return const Icon(Icons.settings, size: 14, color: Color(0xFFF9E2AF));
    }
    if (lower.endsWith('.json')) {
      return const Icon(Icons.data_object, size: 14, color: Color(0xFFFAB387));
    }
    if (lower.endsWith('.md') || lower.endsWith('.txt')) {
      return const Icon(Icons.description_outlined, size: 14, color: Color(0xFFF5E0DC));
    }
    if (lower.endsWith('.sh') || lower.endsWith('.bash')) {
      return const Icon(Icons.terminal, size: 14, color: Color(0xFFA6E3A1));
    }
    return Icon(Icons.insert_drive_file_outlined, size: 14, color: FyrTheme.textColorMuted);
  }
}
