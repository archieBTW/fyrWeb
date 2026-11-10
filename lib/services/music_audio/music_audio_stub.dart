import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'music_audio_engine.dart';

class StubMusicAudioEngine implements MusicAudioEngine {
  final AudioPlayer _player = AudioPlayer();
  final _mediaActionController = StreamController<String>.broadcast();

  @override
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  @override
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  @override
  Stream<bool> get onPlayerStateChanged =>
      _player.onPlayerStateChanged.map((s) => s == PlayerState.playing);

  @override
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  @override
  Stream<String> get onMediaAction => _mediaActionController.stream;

  @override
  Future<void> setSource(String path, {String? title, String? artist}) async {
    final rel =
        path.startsWith('assets/') ? path.replaceFirst('assets/', '') : path;
    await _player.setSource(AssetSource(rel));
  }

  @override
  Future<void> play() async {
    await _player.resume();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  void dispose() {
    _mediaActionController.close();
    _player.dispose();
  }
}

MusicAudioEngine createMusicAudioEngine() => StubMusicAudioEngine();

