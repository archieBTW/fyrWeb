import 'package:flutter/material.dart';

class FyrNotification {
  final int id;
  final String appName;
  final String title;
  final String body;
  final String icon;
  final DateTime timestamp;
  final List<String> actions;
  final int timeout;

  FyrNotification({
    required this.id,
    required this.appName,
    required this.title,
    required this.body,
    this.icon = '',
    required this.timestamp,
    this.actions = const [],
    this.timeout = 5000,
  });
}

class NotificationCenter extends ChangeNotifier {
  static final NotificationCenter instance = NotificationCenter();

  final List<FyrNotification> _notifications = [
    FyrNotification(
      id: 1,
      appName: 'Gmail',
      title: 'Instacart (from phone)',
      body: 'Updates to the Instacart Terms of Service',
      icon: 'phone',
      timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
      actions: ['view', 'View'],
    ),
    FyrNotification(
      id: 2,
      appName: 'KDE Connect',
      title: 'Pixel 9 Connected',
      body: 'Battery at 38%. Media control and clipboard sync ready.',
      icon: 'phone',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    FyrNotification(
      id: 3,
      appName: 'System',
      title: 'fyrDE Desktop Active',
      body: 'Welcome to fyrDE. Press dashboard icon for Overview or apps for Search.',
      icon: '',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  final List<FyrNotification> _activePopups = [];

  List<FyrNotification> get notifications => List.unmodifiable(_notifications);
  List<FyrNotification> get activePopups => List.unmodifiable(_activePopups);

  void addNotification(FyrNotification notification, {bool showPopup = true}) {
    _notifications.insert(0, notification);
    if (showPopup) {
      _activePopups.add(notification);
    }
    notifyListeners();
  }

  void dismissNotification(int id) {
    _notifications.removeWhere((n) => n.id == id);
    _activePopups.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void dismissPopup(int id) {
    _activePopups.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _activePopups.clear();
    notifyListeners();
  }
}

