import 'package:flutter/material.dart';

class WindowData {
  final String id;
  final String title;
  final Widget content;
  final dynamic icon;
  Offset position;
  Size size;
  bool isMinimized;
  bool isMaximized;
  bool isFocused;

  WindowData({
    required this.id,
    required this.title,
    required this.content,
    required this.icon,
    this.position = const Offset(100, 100),
    this.size = const Size(800, 600),
    this.isMinimized = false,
    this.isMaximized = false,
    this.isFocused = true,
  });
}

class WindowManager extends ChangeNotifier {
  final List<WindowData> _windows = [];
  List<WindowData> get windows => List.unmodifiable(_windows);

  void openWindow(String id, String title, Widget content, dynamic icon) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      _windows[index].isMinimized = false;
      focusWindow(id);
      return;
    }

    final newWindow = WindowData(
      id: id,
      title: title,
      content: content,
      icon: icon,
      position: Offset(
        100.0 + (_windows.length * 30),
        100.0 + (_windows.length * 30),
      ),
    );
    _windows.add(newWindow);
    focusWindow(id);
  }

  void closeWindow(String id) {
    _windows.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  void minimizeWindow(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      _windows[index].isMinimized = true;
      notifyListeners();
    }
  }

  void toggleMaximize(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1) {
      _windows[index].isMaximized = !_windows[index].isMaximized;
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
}
