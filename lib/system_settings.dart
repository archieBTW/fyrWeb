import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/wallpaper_storage/wallpaper_storage.dart';

class SystemSettings extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  final WallpaperStorageService _storageService = WallpaperStorageService();

  // Appearance & Wallpaper
  bool _isDarkMode = true;
  Color _accentColor = const Color(0xFF9C27B0); // Modern purple
  String _wallpaperPath = 'assets/wallpaper.jpg';
  Uint8List? _wallpaperBytes;
  bool _isCustomWallpaper = false;
  double _wallpaperBlur = 0.0;
  double _wallpaperDim = 0.0;

  // Desktop & Dock
  bool _dockAutoHide = false;
  double _dockScale = 1.0;

  // Date & Time
  bool _use24HourClock = false;
  bool _showClockSeconds = false;

  // Sound & Glass
  double _soundVolume = 0.8;
  bool _soundEffectsEnabled = true;
  bool _enableGlassEffects = true;

  // Quick Controls / Control Center
  double _screenBrightness = 1.0;
  bool _nightShift = false;
  bool _wifi = true;
  bool _bluetooth = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _accentColor;
  String get wallpaperPath => _wallpaperPath;
  Uint8List? get wallpaperBytes => _wallpaperBytes;
  bool get isCustomWallpaper => _isCustomWallpaper;
  double get wallpaperBlur => _wallpaperBlur;
  double get wallpaperDim => _wallpaperDim;
  bool get dockAutoHide => _dockAutoHide;
  double get dockScale => _dockScale;
  bool get use24HourClock => _use24HourClock;
  bool get showClockSeconds => _showClockSeconds;
  double get soundVolume => _soundVolume;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  bool get enableGlassEffects => _enableGlassEffects;
  double get screenBrightness => _screenBrightness;
  bool get nightShift => _nightShift;
  bool get wifi => _wifi;
  bool get bluetooth => _bluetooth;

  SystemSettings() {
    init();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final p = _prefs;
      if (p != null) {
        _isDarkMode = p.getBool('isDarkMode') ?? true;
        _accentColor = Color(p.getInt('accentColor') ?? 0xFF9C27B0);
        _wallpaperPath = p.getString('wallpaperPath') ?? 'assets/wallpaper.jpg';
        _isCustomWallpaper = p.getBool('isCustomWallpaper') ?? false;
        _wallpaperBlur = p.getDouble('wallpaperBlur') ?? 0.0;
        _wallpaperDim = p.getDouble('wallpaperDim') ?? 0.0;
        _dockAutoHide = p.getBool('dockAutoHide') ?? false;
        _dockScale = p.getDouble('dockScale') ?? 1.0;
        _use24HourClock = p.getBool('use24HourClock') ?? false;
        _showClockSeconds = p.getBool('showClockSeconds') ?? false;
        _soundVolume = p.getDouble('soundVolume') ?? 0.8;
        _soundEffectsEnabled = p.getBool('soundEffectsEnabled') ?? true;
        _enableGlassEffects = p.getBool('enableGlassEffects') ?? true;
        _screenBrightness = p.getDouble('screenBrightness') ?? 1.0;
        _nightShift = p.getBool('nightShift') ?? false;
        _wifi = p.getBool('wifi') ?? true;
        _bluetooth = p.getBool('bluetooth') ?? false;
      }

      if (_isCustomWallpaper ||
          _wallpaperPath == 'custom' ||
          _wallpaperPath.startsWith('data:image')) {
        final customData = await _storageService.loadWallpaper();
        if (customData != null && customData.isNotEmpty) {
          _wallpaperPath = 'custom';
          _isCustomWallpaper = true;
          _decodeWallpaper(customData);
        } else if (_wallpaperPath.startsWith('data:image')) {
          _decodeWallpaper(_wallpaperPath);
        }
      }
    } catch (e) {
      debugPrint('Error loading SystemSettings: $e');
    }
    _isInitialized = true;
    notifyListeners();
  }

  void _decodeWallpaper(String path) {
    try {
      final base64Part = path.contains(',') ? path.split(',').last : path;
      _wallpaperBytes = base64Decode(base64Part);
    } catch (e) {
      _wallpaperBytes = null;
      debugPrint('Failed to decode wallpaper: $e');
    }
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _prefs?.setBool('isDarkMode', value);
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _prefs?.setInt('accentColor', color.toARGB32());
    notifyListeners();
  }

  Future<void> setWallpaper(String path) async {
    if (path.startsWith('data:image')) {
      await setCustomWallpaperFromDataUrl(path);
      return;
    }

    _wallpaperPath = path;
    _wallpaperBytes = null;
    _isCustomWallpaper = false;
    _prefs?.setString('wallpaperPath', path);
    _prefs?.setBool('isCustomWallpaper', false);
    _storageService.clearWallpaper();
    notifyListeners();
  }

  Future<void> setCustomWallpaperFromDataUrl(String rawDataUrl) async {
    try {
      // Compress if needed to optimize memory and fast rendering
      final compressed = await _storageService.compressImage(
        rawDataUrl,
        maxDim: 1920,
        quality: 0.85,
      );

      _decodeWallpaper(compressed);
      _wallpaperPath = 'custom';
      _isCustomWallpaper = true;

      // Save to IndexedDB (unlimited quota)
      await _storageService.saveWallpaper(compressed);

      // Save settings state
      _prefs?.setString('wallpaperPath', 'custom');
      _prefs?.setBool('isCustomWallpaper', true);

      // Fast-cache to SharedPreferences if lightweight (< 1MB)
      if (compressed.length < 1000000) {
        _prefs?.setString('cachedWallpaperData', compressed);
      } else {
        _prefs?.remove('cachedWallpaperData');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving custom wallpaper: $e');
    }
  }

  Future<void> setCustomWallpaperFromBytes(
    Uint8List bytes, {
    String mimeType = 'image/png',
  }) async {
    final base64String = 'data:$mimeType;base64,${base64Encode(bytes)}';
    await setCustomWallpaperFromDataUrl(base64String);
  }

  Future<void> resetWallpaper() async {
    _wallpaperPath = 'assets/wallpaper.jpg';
    _wallpaperBytes = null;
    _isCustomWallpaper = false;
    _wallpaperBlur = 0.0;
    _wallpaperDim = 0.0;
    _prefs?.setString('wallpaperPath', _wallpaperPath);
    _prefs?.setBool('isCustomWallpaper', false);
    _prefs?.remove('cachedWallpaperData');
    _prefs?.setDouble('wallpaperBlur', 0.0);
    _prefs?.setDouble('wallpaperDim', 0.0);
    await _storageService.clearWallpaper();
    notifyListeners();
  }

  void setWallpaperBlur(double value) {
    _wallpaperBlur = value.clamp(0.0, 20.0);
    _prefs?.setDouble('wallpaperBlur', _wallpaperBlur);
    notifyListeners();
  }

  void setWallpaperDim(double value) {
    _wallpaperDim = value.clamp(0.0, 0.7);
    _prefs?.setDouble('wallpaperDim', _wallpaperDim);
    notifyListeners();
  }

  void setDockAutoHide(bool value) {
    _dockAutoHide = value;
    _prefs?.setBool('dockAutoHide', value);
    notifyListeners();
  }

  void setDockScale(double value) {
    _dockScale = value.clamp(0.8, 1.3);
    _prefs?.setDouble('dockScale', _dockScale);
    notifyListeners();
  }

  void setUse24HourClock(bool value) {
    _use24HourClock = value;
    _prefs?.setBool('use24HourClock', value);
    notifyListeners();
  }

  void setShowClockSeconds(bool value) {
    _showClockSeconds = value;
    _prefs?.setBool('showClockSeconds', value);
    notifyListeners();
  }

  void setSoundVolume(double value) {
    _soundVolume = value.clamp(0.0, 1.0);
    _prefs?.setDouble('soundVolume', _soundVolume);
    notifyListeners();
  }

  void setSoundEffectsEnabled(bool value) {
    _soundEffectsEnabled = value;
    _prefs?.setBool('soundEffectsEnabled', value);
    notifyListeners();
  }

  void setEnableGlassEffects(bool value) {
    _enableGlassEffects = value;
    _prefs?.setBool('enableGlassEffects', value);
    notifyListeners();
  }

  void setScreenBrightness(double value) {
    _screenBrightness = value.clamp(0.3, 1.0);
    _prefs?.setDouble('screenBrightness', _screenBrightness);
    notifyListeners();
  }

  void setNightShift(bool value) {
    _nightShift = value;
    _prefs?.setBool('nightShift', value);
    notifyListeners();
  }

  void setWifi(bool value) {
    _wifi = value;
    _prefs?.setBool('wifi', value);
    notifyListeners();
  }

  void setBluetooth(bool value) {
    _bluetooth = value;
    _prefs?.setBool('bluetooth', value);
    notifyListeners();
  }

  Future<void> resetAllSettings() async {
    _isDarkMode = true;
    _accentColor = const Color(0xFF9C27B0);
    _wallpaperPath = 'assets/wallpaper.jpg';
    _wallpaperBytes = null;
    _isCustomWallpaper = false;
    _wallpaperBlur = 0.0;
    _wallpaperDim = 0.0;
    _dockAutoHide = false;
    _dockScale = 1.0;
    _use24HourClock = false;
    _showClockSeconds = false;
    _soundVolume = 0.8;
    _soundEffectsEnabled = true;
    _enableGlassEffects = true;
    _screenBrightness = 1.0;
    _nightShift = false;
    _wifi = true;
    _bluetooth = false;

    await _prefs?.clear();
    await _storageService.clearWallpaper();
    notifyListeners();
  }
}
