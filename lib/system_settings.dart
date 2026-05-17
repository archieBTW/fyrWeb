import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemSettings extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  bool _isDarkMode = true;
  Color _accentColor = Colors.blue;
  String _wallpaperPath = 'assets/wallpaper.jpg';
  Uint8List? _wallpaperBytes;

  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _accentColor;
  String get wallpaperPath => _wallpaperPath;
  Uint8List? get wallpaperBytes => _wallpaperBytes;
  bool get isInitialized => _isInitialized;

  SystemSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? true;
    _accentColor = Color(_prefs.getInt('accentColor') ?? Colors.blue.value);
    _wallpaperPath =
        _prefs.getString('wallpaperPath') ?? 'assets/wallpaper.jpg';
    if (_wallpaperPath.startsWith('data:image')) {
      _decodeWallpaper(_wallpaperPath);
    }
    _isInitialized = true;
    notifyListeners();
  }

  void _decodeWallpaper(String path) {
    try {
      _wallpaperBytes = base64Decode(path.split(',').last);
    } catch (e) {
      _wallpaperBytes = null;
    }
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _prefs.setInt('accentColor', color.value);
    notifyListeners();
  }

  void setWallpaper(String path) {
    _wallpaperPath = path;
    if (path.startsWith('data:image')) {
      _decodeWallpaper(path);
    } else {
      _wallpaperBytes = null;
    }
    _prefs.setString('wallpaperPath', path);
    notifyListeners();
  }
}
