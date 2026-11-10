import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'music_audio_engine.dart';

@JS('window')
external JSObject get _window;

class WebMusicAudioEngine implements MusicAudioEngine {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _stateController = StreamController<bool>.broadcast();
  final _completeController = StreamController<void>.broadcast();
  final _mediaActionController = StreamController<String>.broadcast();

  bool _initialized = false;

  WebMusicAudioEngine() {
    _initBridge();
  }

  void _initBridge() {
    if (_initialized) return;
    try {
      final storage = _window['fyrMusicPlayer'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsPlayer = storage as JSObject;

        final posCb = ((JSNumber seconds) {
          _positionController.add(
            Duration(milliseconds: (seconds.toDartDouble * 1000).toInt()),
          );
        }).toJS;
        jsPlayer.callMethod('onPosition'.toJS, posCb);

        final durCb = ((JSNumber seconds) {
          _durationController.add(
            Duration(milliseconds: (seconds.toDartDouble * 1000).toInt()),
          );
        }).toJS;
        jsPlayer.callMethod('onDuration'.toJS, durCb);

        final stateCb = ((JSBoolean playing) {
          _stateController.add(playing.toDart);
        }).toJS;
        jsPlayer.callMethod('onState'.toJS, stateCb);

        final endedCb = (() {
          _completeController.add(null);
        }).toJS;
        jsPlayer.callMethod('onEnded'.toJS, endedCb);

        final actionCb = ((JSString action) {
          _mediaActionController.add(action.toDart);
        }).toJS;
        jsPlayer.callMethod('onMediaAction'.toJS, actionCb);

        _initialized = true;
      }
    } catch (e) {
      debugPrint('Error initializing WebMusicAudioEngine: $e');
    }
  }

  @override
  Stream<Duration> get onPositionChanged => _positionController.stream;

  @override
  Stream<Duration> get onDurationChanged => _durationController.stream;

  @override
  Stream<bool> get onPlayerStateChanged => _stateController.stream;

  @override
  Stream<void> get onPlayerComplete => _completeController.stream;

  @override
  Stream<String> get onMediaAction => _mediaActionController.stream;

  @override
  Future<void> setSource(String path, {String? title, String? artist}) async {
    _initBridge();
    try {
      final storage = _window['fyrMusicPlayer'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsPlayer = storage as JSObject;
        String webUrl = path;
        if (!webUrl.startsWith('http://') && !webUrl.startsWith('https://')) {
          if (webUrl.startsWith('assets/')) {
            webUrl = 'assets/$webUrl';
          } else {
            webUrl = 'assets/assets/$webUrl';
          }
        }
        jsPlayer.callMethod(
          'setSource'.toJS,
          webUrl.toJS,
          (title ?? '').toJS,
          (artist ?? 'Archer Woods').toJS,
        );
      }
    } catch (e) {
      debugPrint('Error setting source in WebMusicAudioEngine: $e');
    }
  }

  @override
  Future<void> play() async {
    _initBridge();
    try {
      final storage = _window['fyrMusicPlayer'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsPlayer = storage as JSObject;
        jsPlayer.callMethod('play'.toJS);
      }
    } catch (e) {
      debugPrint('Error playing in WebMusicAudioEngine: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      final storage = _window['fyrMusicPlayer'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsPlayer = storage as JSObject;
        jsPlayer.callMethod('pause'.toJS);
      }
    } catch (e) {
      debugPrint('Error pausing in WebMusicAudioEngine: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      final storage = _window['fyrMusicPlayer'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsPlayer = storage as JSObject;
        jsPlayer.callMethod(
          'seek'.toJS,
          (position.inMilliseconds / 1000.0).toJS,
        );
      }
    } catch (e) {
      debugPrint('Error seeking in WebMusicAudioEngine: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      final storage = _window['fyrMusicPlayer'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsPlayer = storage as JSObject;
        jsPlayer.callMethod('setVolume'.toJS, volume.toJS);
      }
    } catch (e) {
      debugPrint('Error setting volume in WebMusicAudioEngine: $e');
    }
  }

  @override
  void dispose() {
    _positionController.close();
    _durationController.close();
    _stateController.close();
    _completeController.close();
    _mediaActionController.close();
  }
}

MusicAudioEngine createMusicAudioEngine() => WebMusicAudioEngine();

