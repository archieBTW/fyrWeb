import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../fyr_theme.dart';
import '../../models/config_model.dart';
import '../../app_data.dart';
import 'package:provider/provider.dart';
import '../portfolio_app_icon.dart';

class FyrSearchScreen extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String id, String title, Widget? content, dynamic icon, {String? url}) onOpenApp;

  const FyrSearchScreen({
    super.key,
    required this.onClose,
    required this.onOpenApp,
  });

  @override
  State<FyrSearchScreen> createState() => _FyrSearchScreenState();
}

class _FyrSearchScreenState extends State<FyrSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PageController _pageController = PageController();

  int _selectedIndex = 0;
  int _currentPage = 0;
  final int _crossAxisCount = 5;
  final int _rowsPerPage = 2;
  late final int _itemsPerPage;

  @override
  void initState() {
    super.initState();
    _itemsPerPage = _crossAxisCount * _rowsPerPage;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _launchApp(AppInfo app) {
    widget.onClose();
    widget.onOpenApp(
      app.id,
      app.title,
      app.content,
      app.icon,
      url: app.url,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final allApps = getApps(config);
    final query = _searchController.text.toLowerCase().trim();
    final filteredApps = query.isEmpty
        ? allApps
        : allApps.where((a) {
            final titleLower = a.title.toLowerCase();
            final cleanQuery = query.replaceAll(' ', '');
            final cleanTitle = titleLower.replaceAll(' ', '');
            return titleLower.contains(query) ||
                cleanTitle.contains(cleanQuery) ||
                a.id.toLowerCase().contains(cleanQuery) ||
                (a.subtitle?.toLowerCase().contains(query) ?? false) ||
                (a.tags?.any((t) => t.toLowerCase().contains(query)) ?? false);
          }).toList();

    final int pageCount = filteredApps.isEmpty
        ? 1
        : ((filteredApps.length - 1) / _itemsPerPage).floor() + 1;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenHeight / 1080).clamp(0.65, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),

          // Main contents
          SafeArea(
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    widget.onClose();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.enter) {
                    if (filteredApps.isNotEmpty) {
                      final idx = _selectedIndex.clamp(0, filteredApps.length - 1);
                      _launchApp(filteredApps[idx]);
                    }
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.12),

                  // Center Stadium Search Bar
                  Center(
                    child: Container(
                      width: (700 * scale).clamp(320.0, screenWidth - 48),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: FyrTheme.bgColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: FyrTheme.dividerColor,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              autofocus: true,
                              controller: _searchController,
                              focusNode: _focusNode,
                              onChanged: (_) => setState(() => _selectedIndex = 0),
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type to search...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 20,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 24.0, right: 16.0),
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.06),

                  // 5x2 Grid of Apps
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: filteredApps.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching applications',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : PageView.builder(
                                controller: _pageController,
                                itemCount: pageCount,
                                onPageChanged: (p) => setState(() => _currentPage = p),
                                itemBuilder: (context, pageIndex) {
                                  final startIndex = pageIndex * _itemsPerPage;
                                  final endIndex = (startIndex + _itemsPerPage > filteredApps.length)
                                      ? filteredApps.length
                                      : startIndex + _itemsPerPage;
                                  final pageApps = filteredApps.sublist(startIndex, endIndex);

                                  return Center(
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 60),
                                      itemCount: pageApps.length,
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _crossAxisCount,
                                        crossAxisSpacing: 24,
                                        mainAxisSpacing: 36,
                                        childAspectRatio: 0.85,
                                      ),
                                      itemBuilder: (context, index) {
                                        final app = pageApps[index];
                                        final globalIndex = startIndex + index;
                                        final isSelected = globalIndex == _selectedIndex;

                                        return _AppGridItem(
                                          app: app,
                                          scale: scale,
                                          isSelected: isSelected,
                                          onTap: () => _launchApp(app),
                                          onHover: () {
                                            if (_selectedIndex != globalIndex) {
                                              setState(() => _selectedIndex = globalIndex);
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),

                  // Page dots if multiple pages
                  if (pageCount > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(pageCount, (index) {
                          final isCurrent = index == _currentPage;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isCurrent ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? FyrTheme.accentColor
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
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
}

class _AppGridItem extends StatefulWidget {
  final AppInfo app;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const _AppGridItem({
    required this.app,
    required this.scale,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_AppGridItem> createState() => _AppGridItemState();
}

class _AppGridItemState extends State<_AppGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover();
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(24),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: active ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: active
                  ? FyrTheme.accentColor.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: _buildLargeIcon(widget.app, size: 84 * widget.scale),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  widget.app.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeIcon(AppInfo app, {required double size}) {
    return PortfolioAppIcon(app: app, size: size);
  }
}

