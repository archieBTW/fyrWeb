import 'dart:async';

abstract class MusicAudioEngine {
  Stream<Duration> get onPositionChanged;
  Stream<Duration> get onDurationChanged;
  Stream<bool> get onPlayerStateChanged;
  Stream<void> get onPlayerComplete;
  Stream<String> get onMediaAction;

  Future<void> setSource(String path, {String? title, String? artist});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  void dispose();
}

