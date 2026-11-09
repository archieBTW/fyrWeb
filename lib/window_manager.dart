import 'dart:math';
import 'package:flutter/material.dart';

class WindowData {
  final String id;
  final String appId;
  final String title;
  final Widget content;
  final dynamic icon;
  Offset position;
  Size size;
  bool isMinimized;
  bool isMaximized;
  bool isFocused;
  int workspace;

  WindowData({
    required this.id,
    String? appId,
    required this.title,
    required this.content,
    required this.icon,
    this.position = const Offset(100, 100),
    this.size = const Size(800, 600),
    this.isMinimized = false,
    this.isMaximized = false,
    this.isFocused = true,
    this.workspace = 1,
  }) : appId = appId ?? (id.contains('_') ? id.split('_').first : id);
}

class WindowManager extends ChangeNotifier {
  final List<WindowData> _windows = [];
  List<WindowData> get windows => List.unmodifiable(_windows);

  int _currentWorkspace = 1;
  int _maxWorkspaces = 3;
  bool _isTilingMode = false;
  Axis _nextSplitAxis = Axis.horizontal; // default horizontal ('splith')
  double _splitRatio = 0.5; // Resizable split ratio between 0.15 and 0.85
  final Map<int, Map<String, Rect>> _workspaceNormRects = {};

  int get currentWorkspace => _currentWorkspace;
  int get maxWorkspaces => _maxWorkspaces;
  bool get isTilingMode => _isTilingMode;
  String get splitLayout => _nextSplitAxis == Axis.horizontal ? 'splith' : 'splitv';
  Axis get nextSplitAxis => _nextSplitAxis;
  double get splitRatio => _splitRatio;

  List<WindowData> get currentWorkspaceWindows =>
      _windows.where((w) => w.workspace == _currentWorkspace).toList();

  List<WindowData> getWindowsForWorkspace(int ws) =>
      _windows.where((w) => w.workspace == ws).toList();

  List<WindowData> getWindowsForApp(String appId) =>
      _windows.where((w) => w.appId == appId).toList();

  bool hasMinimizedWindowForApp(String appId) =>
      _windows.any((w) => w.appId == appId && w.isMinimized);

  List<WindowData> getMinimizedWindowsForApp(String appId) =>
      _windows.where((w) => w.appId == appId && w.isMinimized).toList();

  WindowData? get focusedWindow {
    final active = currentWorkspaceWindows.where((w) => !w.isMinimized && w.isFocused).toList();
    if (active.isNotEmpty) return active.last;
    final visible = currentWorkspaceWindows.where((w) => !w.isMinimized).toList();
    return visible.isNotEmpty ? visible.last : null;
  }

  void switchWorkspace(int ws) {
    if (ws < 1) return;
    if (ws > _maxWorkspaces) {
      _maxWorkspaces = ws;
    }
    _currentWorkspace = ws;
    final wsWins = getWindowsForWorkspace(ws).where((w) => !w.isMinimized).toList();
    if (wsWins.isNotEmpty) {
      for (var w in _windows) {
        w.isFocused = (w.id == wsWins.last.id);
      }
    }
    notifyListeners();
  }

  void addWorkspace() {
    _maxWorkspaces++;
    switchWorkspace(_maxWorkspaces);
  }

  void toggleTilingMode() {
    _isTilingMode = !_isTilingMode;
    if (_isTilingMode) {
      // When switching to tiling mode, any window that was fullscreen/maximized in floating mode
      // should now function as a tile.
      for (var w in currentWorkspaceWindows) {
        w.isMaximized = false;
      }
      // Switching to tiling mode with multiple windows open puts them in a perfect grid!
      retileWorkspace(_currentWorkspace);
    }
    notifyListeners();
  }

  void setSplitLayout(String layout) {
    final targetAxis = (layout == 'splitv') ? Axis.vertical : Axis.horizontal;
    if (_nextSplitAxis != targetAxis) {
      _nextSplitAxis = targetAxis;
      // Switching from vertical to horizontal applies to the NEXT tiled window,
      // without rearranging the existing windows on the screen.
      notifyListeners();
    }
  }

  void toggleSplitLayout() {
    _nextSplitAxis = (_nextSplitAxis == Axis.horizontal) ? Axis.vertical : Axis.horizontal;
    notifyListeners();
  }

  void setSplitRatio(double ratio) {
    _splitRatio = ratio.clamp(0.15, 0.85);
    final ws = _currentWorkspace;
    final active = _windows.where((w) => w.workspace == ws && !w.isMinimized).toList();
    if (active.length == 2) {
      final Map<String, Rect> newNorm = {};
      final isSplith = splitLayout == 'splith';
      if (isSplith) {
        newNorm[active[0].id] = Rect.fromLTWH(0, 0, _splitRatio, 1);
        newNorm[active[1].id] = Rect.fromLTWH(_splitRatio, 0, 1 - _splitRatio, 1);
      } else {
        newNorm[active[0].id] = Rect.fromLTWH(0, 0, 1, _splitRatio);
        newNorm[active[1].id] = Rect.fromLTWH(0, _splitRatio, 1, 1 - _splitRatio);
      }
      _workspaceNormRects[ws] = newNorm;
    }
    notifyListeners();
  }

  void adjustSplitRatio(double delta) {
    setSplitRatio(_splitRatio + delta);
  }

  void resizeFocusedTiledWindow(int dx, int dy, [double delta = 0.04]) {
    final ws = _currentWorkspace;
    final active = _windows.where((w) => w.workspace == ws && !w.isMinimized).toList();
    if (active.length <= 1) return;

    var normRects = _workspaceNormRects[ws];
    if (normRects == null || !active.every((w) => normRects!.containsKey(w.id))) {
      retileWorkspace(ws);
      normRects = _workspaceNormRects[ws] ?? {};
    }

    final focused = focusedWindow ?? active.first;
    final focusedRect = normRects[focused.id];
    if (focusedRect == null) return;

    final updated = Map<String, Rect>.from(normRects);
    const double eps = 0.025;
    const double minSize = 0.12;

    if (dx != 0) {
      final double change = dx * delta;

      // Determine which vertical boundary to move:
      // Does focused window have a boundary on its right edge that divides neighbors?
      double? targetX;
      if (focusedRect.right < 1.0 - eps) {
        final hasRightNeighbors = active.any((w) =>
            w.id != focused.id &&
            (updated[w.id]!.left - focusedRect.right).abs() < eps);
        if (hasRightNeighbors) {
          targetX = focusedRect.right;
        }
      }

      // If not on the right, does focused window have a boundary on its left edge?
      if (targetX == null && focusedRect.left > eps) {
        final hasLeftNeighbors = active.any((w) =>
            w.id != focused.id &&
            (updated[w.id]!.right - focusedRect.left).abs() < eps);
        if (hasLeftNeighbors) {
          targetX = focusedRect.left;
        }
      }

      if (targetX != null) {
        // All windows whose right edge meets targetX (left group)
        final leftGroup = active.where((w) =>
            (updated[w.id]!.right - targetX!).abs() < eps).toList();
        // All windows whose left edge meets targetX (right group)
        final rightGroup = active.where((w) =>
            (updated[w.id]!.left - targetX!).abs() < eps).toList();

        if (leftGroup.isNotEmpty && rightGroup.isNotEmpty) {
          double maxAllowedNegative = -1.0;
          double maxAllowedPositive = 1.0;

          for (var w in leftGroup) {
            final r = updated[w.id]!;
            final limit = minSize - r.width;
            if (limit > maxAllowedNegative) maxAllowedNegative = limit;
          }
          for (var w in rightGroup) {
            final r = updated[w.id]!;
            final limit = r.width - minSize;
            if (limit < maxAllowedPositive) maxAllowedPositive = limit;
          }

          final actualChange = change.clamp(maxAllowedNegative, maxAllowedPositive);
          final newX = targetX + actualChange;

          for (var w in leftGroup) {
            final r = updated[w.id]!;
            updated[w.id] = Rect.fromLTRB(r.left, r.top, newX, r.bottom);
          }
          for (var w in rightGroup) {
            final r = updated[w.id]!;
            updated[w.id] = Rect.fromLTRB(newX, r.top, r.right, r.bottom);
          }

          if (active.length == 2 && splitLayout == 'splith') {
            _splitRatio = newX.clamp(0.15, 0.85);
          }
        }
      } else if (active.length == 2) {
        adjustSplitRatio(change);
        return;
      }
    }

    if (dy != 0) {
      final double change = dy * delta;

      // Determine which horizontal boundary to move:
      double? targetY;
      if (focusedRect.bottom < 1.0 - eps) {
        final hasBottomNeighbors = active.any((w) =>
            w.id != focused.id &&
            (updated[w.id]!.top - focusedRect.bottom).abs() < eps);
        if (hasBottomNeighbors) {
          targetY = focusedRect.bottom;
        }
      }

      if (targetY == null && focusedRect.top > eps) {
        final hasTopNeighbors = active.any((w) =>
            w.id != focused.id &&
            (updated[w.id]!.bottom - focusedRect.top).abs() < eps);
        if (hasTopNeighbors) {
          targetY = focusedRect.top;
        }
      }

      if (targetY != null) {
        // All windows whose bottom edge meets targetY (top group)
        final topGroup = active.where((w) =>
            (updated[w.id]!.bottom - targetY!).abs() < eps).toList();
        // All windows whose top edge meets targetY (bottom group)
        final bottomGroup = active.where((w) =>
            (updated[w.id]!.top - targetY!).abs() < eps).toList();

        if (topGroup.isNotEmpty && bottomGroup.isNotEmpty) {
          double maxAllowedNegative = -1.0;
          double maxAllowedPositive = 1.0;

          for (var w in topGroup) {
            final r = updated[w.id]!;
            final limit = minSize - r.height;
            if (limit > maxAllowedNegative) maxAllowedNegative = limit;
          }
          for (var w in bottomGroup) {
            final r = updated[w.id]!;
            final limit = r.height - minSize;
            if (limit < maxAllowedPositive) maxAllowedPositive = limit;
          }

          final actualChange = change.clamp(maxAllowedNegative, maxAllowedPositive);
          final newY = targetY + actualChange;

          for (var w in topGroup) {
            final r = updated[w.id]!;
            updated[w.id] = Rect.fromLTRB(r.left, r.top, r.right, newY);
          }
          for (var w in bottomGroup) {
            final r = updated[w.id]!;
            updated[w.id] = Rect.fromLTRB(r.left, newY, r.right, r.bottom);
          }

          if (active.length == 2 && splitLayout == 'splitv') {
            _splitRatio = newY.clamp(0.15, 0.85);
          }
        }
      } else if (active.length == 2) {
        adjustSplitRatio(change);
        return;
      }
    }

    _workspaceNormRects[ws] = updated;
    notifyListeners();
  }

  void retile() {
    retileWorkspace(_currentWorkspace);
  }

  void retileWorkspace([int? workspace]) {
    final ws = workspace ?? _currentWorkspace;
    final activeWindows = _windows
        .where((w) => w.workspace == ws && !w.isMinimized)
        .toList();
    if (activeWindows.isEmpty) {
      _workspaceNormRects.remove(ws);
      notifyListeners();
      return;
    }

    final count = activeWindows.length;
    final Map<String, Rect> newNormRects = {};

    if (count == 1) {
      newNormRects[activeWindows[0].id] = const Rect.fromLTWH(0, 0, 1, 1);
    } else if (count == 2) {
      newNormRects[activeWindows[0].id] = const Rect.fromLTWH(0, 0, 0.5, 1);
      newNormRects[activeWindows[1].id] = const Rect.fromLTWH(0.5, 0, 0.5, 1);
    } else if (count == 3) {
      // 2 on top row, 1 on bottom row (balanced perfect grid)
      newNormRects[activeWindows[0].id] = const Rect.fromLTWH(0, 0, 0.5, 0.5);
      newNormRects[activeWindows[1].id] = const Rect.fromLTWH(0.5, 0, 0.5, 0.5);
      newNormRects[activeWindows[2].id] = const Rect.fromLTWH(0, 0.5, 1.0, 0.5);
    } else if (count == 4) {
      // 2x2 grid
      newNormRects[activeWindows[0].id] = const Rect.fromLTWH(0, 0, 0.5, 0.5);
      newNormRects[activeWindows[1].id] = const Rect.fromLTWH(0.5, 0, 0.5, 0.5);
      newNormRects[activeWindows[2].id] = const Rect.fromLTWH(0, 0.5, 0.5, 0.5);
      newNormRects[activeWindows[3].id] = const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5);
    } else {
      // General balanced grid algorithm:
      final int cols = sqrt(count).ceil();
      final int rows = (count / cols).ceil();
      final double cellH = 1.0 / rows;
      int idx = 0;
      for (int r = 0; r < rows; r++) {
        final int remaining = count - idx;
        final int windowsInThisRow = (r == rows - 1) ? remaining : cols;
        final double cellW = 1.0 / windowsInThisRow;
        for (int c = 0; c < windowsInThisRow; c++) {
          newNormRects[activeWindows[idx].id] = Rect.fromLTWH(
            c * cellW,
            r * cellH,
            cellW,
            cellH,
          );
          idx++;
        }
      }
    }

    _workspaceNormRects[ws] = newNormRects;
    notifyListeners();
  }

  void _tileNewWindow(String windowId, int ws) {
    var normRects = _workspaceNormRects[ws];
    final activeWindows = _windows
        .where((w) => w.workspace == ws && !w.isMinimized && w.id != windowId)
        .toList();

    if (activeWindows.isEmpty || normRects == null || normRects.isEmpty) {
      _workspaceNormRects[ws] = {windowId: const Rect.fromLTWH(0, 0, 1, 1)};
      return;
    }

    // Split the currently focused window, or the last active window
    final targetWin = activeWindows.firstWhere(
      (w) => w.isFocused,
      orElse: () => activeWindows.last,
    );
    final targetRect = normRects[targetWin.id] ?? const Rect.fromLTWH(0, 0, 1, 1);

    final updated = Map<String, Rect>.from(normRects);
    if (_nextSplitAxis == Axis.horizontal) {
      // Split horizontally: left and right
      final halfW = targetRect.width / 2.0;
      updated[targetWin.id] = Rect.fromLTWH(
        targetRect.left,
        targetRect.top,
        halfW,
        targetRect.height,
      );
      updated[windowId] = Rect.fromLTWH(
        targetRect.left + halfW,
        targetRect.top,
        halfW,
        targetRect.height,
      );
    } else {
      // Split vertically: top and bottom
      final halfH = targetRect.height / 2.0;
      updated[targetWin.id] = Rect.fromLTWH(
        targetRect.left,
        targetRect.top,
        targetRect.width,
        halfH,
      );
      updated[windowId] = Rect.fromLTWH(
        targetRect.left,
        targetRect.top + halfH,
        targetRect.width,
        halfH,
      );
    }

    _workspaceNormRects[ws] = updated;
  }

  void _handleWindowRemovedFromTiling(String windowId, int ws) {
    final normRects = _workspaceNormRects[ws];
    if (normRects != null && normRects.containsKey(windowId)) {
      normRects.remove(windowId);
      final activeWindows = _windows
          .where((w) => w.workspace == ws && !w.isMinimized && w.id != windowId)
          .toList();
      if (activeWindows.isEmpty) {
        _workspaceNormRects.remove(ws);
      } else {
        retileWorkspace(ws);
      }
    }
  }

  void openWindow(
    String id,
    String title,
    Widget content,
    dynamic icon, {
    String? appId,
    int? targetWorkspace,
  }) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      _windows[index].isMinimized = false;
      _windows[index].workspace = _currentWorkspace;
      focusWindow(id);
      return;
    }

    final newWindow = WindowData(
      id: id,
      appId: appId,
      title: title,
      content: content,
      icon: icon,
      workspace: targetWorkspace ?? _currentWorkspace,
      position: Offset(
        120.0 + ((_windows.length % 6) * 32),
        100.0 + ((_windows.length % 6) * 32),
      ),
    );
    _windows.add(newWindow);
    focusWindow(id);

    if (_isTilingMode) {
      _tileNewWindow(id, targetWorkspace ?? _currentWorkspace);
    }
  }

  void openNewInstance(
    String baseAppId,
    String title,
    Widget content,
    dynamic icon, {
    int? targetWorkspace,
  }) {
    final instanceId = '${baseAppId}_${DateTime.now().millisecondsSinceEpoch}';
    openWindow(
      instanceId,
      title,
      content,
      icon,
      appId: baseAppId,
      targetWorkspace: targetWorkspace,
    );
  }

  void closeWindow(String id) {
    final wsWins = _windows.where((w) => w.id == id).toList();
    final ws = wsWins.isNotEmpty ? wsWins.first.workspace : _currentWorkspace;
    _windows.removeWhere((w) => w.id == id);
    if (_isTilingMode) {
      _handleWindowRemovedFromTiling(id, ws);
    }
    notifyListeners();
  }

  void closeFocusedWindow() {
    final f = focusedWindow;
    if (f != null) {
      closeWindow(f.id);
    }
  }

  void minimizeWindow(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      final ws = _windows[index].workspace;
      _windows[index].isMinimized = true;
      _windows[index].isFocused = false;
      if (_isTilingMode) {
        _handleWindowRemovedFromTiling(id, ws);
      }
      final others = _windows
          .where((w) => w.workspace == _currentWorkspace && !w.isMinimized && w.id != id)
          .toList();
      if (others.isNotEmpty) {
        others.last.isFocused = true;
      }
      notifyListeners();
    }
  }

  void unminimizeWindow(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      _windows[index].isMinimized = false;
      _windows[index].workspace = _currentWorkspace;
      focusWindow(id);
      if (_isTilingMode) {
        _tileNewWindow(id, _currentWorkspace);
      }
      notifyListeners();
    }
  }

  void toggleMaximize(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      final window = _windows[index];
      // If in tiling mode and maximizing: move it to a new workspace
      if (_isTilingMode && !window.isMaximized) {
        final newWs = _maxWorkspaces + 1;
        _maxWorkspaces = newWs;
        window.workspace = newWs;
        window.isMaximized = true;
        switchWorkspace(newWs);
        focusWindow(id);
        return;
      }

      window.isMaximized = !window.isMaximized;
      notifyListeners();
    }
  }

  void toggleMaximizeFocusedWindow() {
    final f = focusedWindow;
    if (f != null) {
      toggleMaximize(f.id);
    }
  }

  void moveFocusedWindowToWorkspace(int targetWs) {
    final f = focusedWindow;
    if (f != null) {
      f.workspace = targetWs;
      notifyListeners();
    }
  }

  void focusWindow(String id) {
    for (var w in _windows) {
      w.isFocused = (w.id == id);
    }
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      final window = _windows.removeAt(index);
      _windows.add(window);
    }
    notifyListeners();
  }

  void focusNextWindow() {
    final visible = currentWorkspaceWindows.where((w) => !w.isMinimized).toList();
    if (visible.length <= 1) return;
    final currentIdx = visible.indexWhere((w) => w.isFocused);
    final nextIdx = (currentIdx + 1) % visible.length;
    focusWindow(visible[nextIdx].id);
  }

  void focusPreviousWindow() {
    final visible = currentWorkspaceWindows.where((w) => !w.isMinimized).toList();
    if (visible.length <= 1) return;
    final currentIdx = visible.indexWhere((w) => w.isFocused);
    final prevIdx = (currentIdx - 1 + visible.length) % visible.length;
    focusWindow(visible[prevIdx].id);
  }

  void updatePosition(String id, Offset newPosition) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      _windows[index].position = newPosition;
      notifyListeners();
    }
  }

  void updateSize(String id, Size newSize) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      _windows[index].size = newSize;
      notifyListeners();
    }
  }

  Map<String, Rect> calculateTilingRects({
    required Size screenSize,
    double topBarHeight = 56.0,
    double bottomReserved = 84.0,
    int? workspace,
  }) {
    final ws = workspace ?? _currentWorkspace;
    final activeWindows = _windows
        .where((w) => w.workspace == ws && !w.isMinimized)
        .toList();

    final Map<String, Rect> rects = {};
    if (activeWindows.isEmpty) return rects;

    const double outerGap = 20.0;
    const double innerGap = 20.0;

    final double startX = outerGap;
    final double startY = topBarHeight + outerGap;
    final double totalWidth = screenSize.width - (2 * outerGap);
    final double totalHeight = screenSize.height - topBarHeight - bottomReserved - (2 * outerGap);

    if (totalWidth <= 0 || totalHeight <= 0) return rects;

    var normRects = _workspaceNormRects[ws];
    // If not initialized or missing windows, retile into a perfect grid
    if (normRects == null || !activeWindows.every((w) => normRects!.containsKey(w.id))) {
      retileWorkspace(ws);
      normRects = _workspaceNormRects[ws] ?? {};
    }

    for (var w in activeWindows) {
      final norm = normRects[w.id] ?? const Rect.fromLTWH(0, 0, 1, 1);
      final double l = startX + (norm.left * totalWidth) + (norm.left > 0.001 ? innerGap / 2 : 0);
      final double t = startY + (norm.top * totalHeight) + (norm.top > 0.001 ? innerGap / 2 : 0);
      final double r = startX + ((norm.left + norm.width) * totalWidth) - ((norm.left + norm.width) < 0.999 ? innerGap / 2 : 0);
      final double b = startY + ((norm.top + norm.height) * totalHeight) - ((norm.top + norm.height) < 0.999 ? innerGap / 2 : 0);
      rects[w.id] = Rect.fromLTRB(
        l,
        t,
        r > l + 40 ? r : l + 40,
        b > t + 40 ? b : t + 40,
      );
    }

    return rects;
  }
}
