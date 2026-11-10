import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'music_audio_engine.dart';
import 'music_audio_stub.dart'
    if (dart.library.js_interop) 'music_audio_web.dart';

class MusicService extends ChangeNotifier {
  static final MusicService instance = MusicService();

  late final MusicAudioEngine _engine;
  List<String> _tracks = [];
  int _currentTrackIndex = 0;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isInitialized = false;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _mediaActionSub;

  List<String> get tracks => List.unmodifiable(_tracks);
  int get currentTrackIndex => _currentTrackIndex;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isInitialized => _isInitialized;

  String get currentTrackPath =>
      _tracks.isNotEmpty && _currentTrackIndex < _tracks.length
          ? _tracks[_currentTrackIndex]
          : '';

  String get currentTrackTitle =>
      currentTrackPath.isNotEmpty ? cleanTrackName(currentTrackPath) : '';

  MusicService({MusicAudioEngine? engine}) {
    _engine = engine ?? createMusicAudioEngine();
    _setupListeners();
    init();
  }

  void _setupListeners() {
    _posSub = _engine.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _durSub = _engine.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _stateSub = _engine.onPlayerStateChanged.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _completeSub = _engine.onPlayerComplete.listen((_) {
      next();
    });

    _mediaActionSub = _engine.onMediaAction.listen((action) {
      if (action == 'play') {
        play();
      } else if (action == 'pause') {
        pause();
      } else if (action == 'nexttrack' || action == 'next') {
        next();
      } else if (action == 'previoustrack' || action == 'previous') {
        previous();
      } else if (action.startsWith('seekto:')) {
        final secStr = action.replaceFirst('seekto:', '');
        final sec = double.tryParse(secStr);
        if (sec != null) {
          seek(Duration(milliseconds: (sec * 1000).toInt()));
        }
      }
    });
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final tracks = manifest
          .listAssets()
          .where(
            (key) =>
                key.startsWith('assets/music/') &&
                (key.endsWith('.m4a') ||
                    key.endsWith('.mp3') ||
                    key.endsWith('.wav')),
          )
          .toList();

      tracks.sort();
      if (tracks.isNotEmpty) {
        _tracks = tracks;
        _isInitialized = true;
        final trackName = cleanTrackName(_tracks.first);
        await _engine.setSource(
          _tracks.first,
          title: trackName,
          artist: 'Archer Woods',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading music tracks: $e');
    }
  }

  Future<void> playTrackAtIndex(int index) async {
    if (_tracks.isEmpty || index < 0 || index >= _tracks.length) return;
    _currentTrackIndex = index;
    final trackPath = _tracks[_currentTrackIndex];
    final title = cleanTrackName(trackPath);

    await _engine.setSource(trackPath, title: title, artist: 'Archer Woods');
    await _engine.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> playPause() async {
    if (_tracks.isEmpty) return;
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    if (_tracks.isEmpty) return;
    if (_position == Duration.zero && _duration == Duration.zero) {
      await playTrackAtIndex(_currentTrackIndex);
    } else {
      await _engine.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _engine.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> next() async {
    if (_tracks.isEmpty) return;
    final nextIndex = (_currentTrackIndex + 1) % _tracks.length;
    await playTrackAtIndex(nextIndex);
  }

  Future<void> previous() async {
    if (_tracks.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    final prevIndex = (_currentTrackIndex - 1 + _tracks.length) % _tracks.length;
    await playTrackAtIndex(prevIndex);
  }

  Future<void> seek(Duration pos) async {
    _position = pos;
    await _engine.seek(pos);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    await _engine.setVolume(volume);
  }

  static String cleanTrackName(String path) {
    final fileName = path.split('/').last;
    return fileName
        .replaceAll('.wav', '')
        .replaceAll('.m4a', '')
        .replaceAll('.mp3', '')
        .replaceAll('_', ' ');
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _mediaActionSub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}

