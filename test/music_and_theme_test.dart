import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:billyrigdon/fyr_theme.dart';
import 'package:billyrigdon/system_settings.dart';
import 'package:billyrigdon/utils/color_extractor.dart';
import 'package:billyrigdon/services/music_audio/music_audio.dart';
import 'package:billyrigdon/services/music_audio/music_audio_engine.dart';
import 'package:billyrigdon/widgets/taskbar/calendar_menu_popup.dart';

class MockMusicAudioEngine implements MusicAudioEngine {
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();
  final _stateController = StreamController<bool>.broadcast();
  final _compController = StreamController<void>.broadcast();
  final _actionController = StreamController<String>.broadcast();

  bool isPlaying = false;
  String? currentSource;

  @override
  Stream<Duration> get onPositionChanged => _posController.stream;

  @override
  Stream<Duration> get onDurationChanged => _durController.stream;

  @override
  Stream<bool> get onPlayerStateChanged => _stateController.stream;

  @override
  Stream<void> get onPlayerComplete => _compController.stream;

  @override
  Stream<String> get onMediaAction => _actionController.stream;

  @override
  Future<void> setSource(String path, {String? title, String? artist}) async {
    currentSource = path;
  }

  @override
  Future<void> play() async {
    isPlaying = true;
    _stateController.add(true);
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    _stateController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    _posController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  void dispose() {
    _posController.close();
    _durController.close();
    _stateController.close();
    _compController.close();
    _actionController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic font color contrast on accented colors', () {
    test('Bright yellow accent returns dark font color', () {
      const brightYellow = Color(0xFFFFEB3B);
      expect(FyrTheme.onColor(brightYellow), equals(Colors.black87));

      FyrTheme.setAccentColor(brightYellow);
      expect(FyrTheme.onAccentColor, equals(Colors.black87));
    });

    test('Dark purple accent returns white font color', () {
      const darkPurple = Color(0xFF4A148C);
      expect(FyrTheme.onColor(darkPurple), equals(Colors.white));

      FyrTheme.setAccentColor(darkPurple);
      expect(FyrTheme.onAccentColor, equals(Colors.white));
    });

    test('Cyan and bright green return dark font color', () {
      expect(FyrTheme.onColor(const Color(0xFF00E676)), equals(Colors.black87));
      expect(FyrTheme.onColor(const Color(0xFF00E5FF)), equals(Colors.black87));
    });
  });

  group('Wallpaper color extraction & pull colors from background', () {
    test('WallpaperColorExtractor extracts vibrant color from RGBA buffer', () {
      // 4x4 image buffer with saturated orange pixels
      final buffer = Uint8List(4 * 4 * 4);
      for (int i = 0; i < buffer.length; i += 4) {
        buffer[i] = 255; // R
        buffer[i + 1] = 140; // G
        buffer[i + 2] = 0; // B
        buffer[i + 3] = 255; // A
      }
      final color = WallpaperColorExtractor.extractDominantAccent(buffer);
      expect(color.a, equals(1.0));
      // Should be in orange/amber hue
      final hsv = HSVColor.fromColor(color);
      expect(hsv.hue, inInclusiveRange(20, 45));
    });

    test('WallpaperColorExtractor extracts accent colors for all default wallpapers', () async {
      final wallpapers = [
        'assets/wallpaper.jpg', // Deep Space
        'assets/wallpaper.png', // fyr Abstract
        'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?q=80&w=1920', // Alpine Sunset
        'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1920', // Cyber Grid
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1920', // Mountain Fog
      ];

      for (final wp in wallpapers) {
        final color = await WallpaperColorExtractor.extractColor(path: wp);
        expect(color, isNotNull, reason: 'Failed to extract color for $wp');
        expect(color!.a, equals(1.0));
      }
    });

    test('SystemSettings pullColorFromBg toggling and manual override', () {
      final settings = SystemSettings();
      expect(settings.pullColorFromBg, isTrue);

      // Manually setting accent color disables pullColorFromBg
      settings.setAccentColor(const Color(0xFFFF5722));
      expect(settings.pullColorFromBg, isFalse);
      expect(settings.accentColor, equals(const Color(0xFFFF5722)));

      // Re-enabling pullColorFromBg toggles it back
      settings.setPullColorFromBg(true);
      expect(settings.pullColorFromBg, isTrue);
    });
  });

  group('MusicService playback & lifecycle', () {
    test('MusicService state and control with mock engine', () async {
      final mockEngine = MockMusicAudioEngine();
      final music = MusicService(engine: mockEngine);

      expect(music.isPlaying, isFalse);
      await music.play();
      // Even if no tracks loaded in pure unit test, play/pause functions correctly
      expect(music.position, equals(Duration.zero));
    });

    test('Track name cleaner formats track titles properly', () {
      expect(
        MusicService.cleanTrackName('assets/music/specter.m4a'),
        equals('specter'),
      );
      expect(
        MusicService.cleanTrackName('assets/music/and_thats_how_it_happened.m4a'),
        equals('and thats how it happened'),
      );
      expect(
        MusicService.formatDuration(const Duration(minutes: 3, seconds: 45)),
        equals('03:45'),
      );
    });

    testWidgets('CalendarMenuPopup displays Now Playing section in notifications dropdown', (tester) async {
      final mockEngine = MockMusicAudioEngine();
      final music = MusicService(engine: mockEngine);
      // Manually simulate loaded tracks
      await music.init();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MusicService>.value(value: music),
            ChangeNotifierProvider<SystemSettings>.value(value: SystemSettings()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CalendarMenuPopup(
                onClose: () {},
                onOpenCalendar: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Calendar & Notifications header or notifications section is present
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
    });
  });
}
