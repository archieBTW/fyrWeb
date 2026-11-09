import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../fyr_theme.dart';
import '../../window_manager.dart';
import 'package:provider/provider.dart';
import '../portfolio_app_icon.dart';

class FyrOverviewScreen extends StatelessWidget {
  final VoidCallback onClose;

  const FyrOverviewScreen({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final windowManager = context.watch<WindowManager>();
    final currentWs = windowManager.currentWorkspace;
    final maxWs = windowManager.maxWorkspaces < 9 ? 9 : windowManager.maxWorkspaces;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // 3x3 Grid of Workspaces
          SafeArea(
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  onClose();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
                child: GridView.builder(
                  itemCount: maxWs,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final wsNum = index + 1;
                    final isCurrent = currentWs == wsNum;
                    final wsWindows = windowManager
                        .getWindowsForWorkspace(wsNum)
                        .where((w) => !w.isMinimized)
                        .toList();

                    return _WorkspaceCard(
                      workspaceNumber: wsNum,
                      isFocused: isCurrent,
                      windows: wsWindows,
                      onTap: () {
                        windowManager.switchWorkspace(wsNum);
                        onClose();
                      },
                      onTapWindow: (winId) {
                        windowManager.switchWorkspace(wsNum);
                        windowManager.focusWindow(winId);
                        onClose();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatefulWidget {
  final int workspaceNumber;
  final bool isFocused;
  final List<WindowData> windows;
  final VoidCallback onTap;
  final Function(String winId) onTapWindow;

  const _WorkspaceCard({
    required this.workspaceNumber,
    required this.isFocused,
    required this.windows,
    required this.onTap,
    required this.onTapWindow,
  });

  @override
  State<_WorkspaceCard> createState() => _WorkspaceCardState();
}

class _WorkspaceCardState extends State<_WorkspaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = FyrTheme.accentColor;
    final isSelected = widget.isFocused || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: FyrTheme.bgColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.85)
                  : (widget.isFocused
                      ? accentColor.withValues(alpha: 0.4)
                      : FyrTheme.cardColor),
              width: isSelected ? 3 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Wallpaper tint inside card
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.4,
                    child: Image.asset(
                      'assets/space.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/wallpaper.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Large watermark number in center
                Center(
                  child: Text(
                    '${widget.workspaceNumber}',
                    style: TextStyle(
                      fontSize: 84,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),

                // Miniature Windows Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double cardW = constraints.maxWidth;
                    final double cardH = constraints.maxHeight;

                    return Stack(
                      children: widget.windows.asMap().entries.map((entry) {
                        final i = entry.key;
                        final win = entry.value;
                        final count = widget.windows.length;

                        // Layout mini window boxes inside card
                        double w, h, x, y;
                        if (count == 1) {
                          w = cardW * 0.75;
                          h = cardH * 0.75;
                          x = (cardW - w) / 2;
                          y = (cardH - h) / 2;
                        } else if (count == 2) {
                          w = (cardW - 32) / 2;
                          h = cardH * 0.7;
                          x = 12 + (i * (w + 8));
                          y = (cardH - h) / 2;
                        } else {
                          // Cascade / Tile representation
                          w = cardW * 0.55;
                          h = cardH * 0.55;
                          x = 12.0 + (i * 20.0).clamp(0.0, cardW - w - 12);
                          y = 12.0 + (i * 16.0).clamp(0.0, cardH - h - 12);
                        }

                        return Positioned(
                          left: x,
                          top: y,
                          width: w,
                          height: h,
                          child: GestureDetector(
                            onTap: () => widget.onTapWindow(win.id),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: win.isFocused
                                      ? accentColor
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: win.isFocused ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Mini title bar
                                  Container(
                                    height: 16,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    color: const Color(0xFF141414),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade300,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            win.title,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 8,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Mini content icon
                                  Expanded(
                                    child: Center(
                                      child: PortfolioAppIcon(
                                        appId: win.appId,
                                        icon: win.icon,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                // Workspace Label Pill at Bottom Center
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Workspace ${widget.workspaceNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
}

