import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../system_settings.dart';

class MusicPlayerApp extends StatefulWidget {
  const MusicPlayerApp({super.key});

  @override
  State<MusicPlayerApp> createState() => _MusicPlayerAppState();
}

class _MusicPlayerAppState extends State<MusicPlayerApp> {
  late Future<List<String>> _tracksFuture;
  List<String> _tracks = [];
  
  late AudioPlayer _audioPlayer;
  int _currentTrackIndex = 0;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
    _tracksFuture = _loadTracks();
  }

  Future<List<String>> _loadTracks() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final tracks = assetManifest
        .listAssets()
        .where((key) => key.startsWith('assets/music/') && key.endsWith('.wav'))
        .toList();
    
    // Sort tracks by name
    tracks.sort();
    
    if (tracks.isNotEmpty && mounted) {
      setState(() {
        _tracks = tracks;
      });
    }
    return tracks;
  }

  void _setupAudioListeners() {
    _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) _next();
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_tracks.isEmpty) return;
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position == Duration.zero && _duration == Duration.zero) {
        await _playTrack();
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> _playTrack() async {
    if (_tracks.isEmpty) return;
    
    final trackPath = _tracks[_currentTrackIndex];
    // audioplayers AssetSource expects a path relative to 'assets/' by default
    final relativePath = trackPath.replaceFirst('assets/', '');
    
    await _audioPlayer.setSource(AssetSource(relativePath));
    await _audioPlayer.resume();
  }

  Future<void> _next() async {
    if (_tracks.isEmpty) return;
    setState(() {
      _currentTrackIndex = (_currentTrackIndex + 1) % _tracks.length;
    });
    await _playTrack();
  }

  Future<void> _previous() async {
    if (_tracks.isEmpty) return;
    setState(() {
      _currentTrackIndex = (_currentTrackIndex - 1 + _tracks.length) % _tracks.length;
    });
    await _playTrack();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String _cleanTrackName(String name) {
    // Extract filename from path and remove extension
    final fileName = name.split('/').last;
    return fileName.replaceAll('.wav', '').replaceAll('.m4a', '').replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    final accentColor = settings.accentColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return FutureBuilder<List<String>>(
      future: _tracksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_tracks.isEmpty) {
          return Center(
            child: Text(
              'No music found in assets/music/',
              style: GoogleFonts.inter(
                color: onSurfaceColor.withOpacity(0.5),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Now Playing',
                style: GoogleFonts.outfit(
                  color: onSurfaceColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildPlayerControls(accentColor, onSurfaceColor),
              const SizedBox(height: 32),
              Expanded(
                child: _buildTracklist(accentColor, onSurfaceColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerControls(Color accentColor, Color onSurfaceColor) {
    final trackName = _tracks.isNotEmpty ? _cleanTrackName(_tracks[_currentTrackIndex]) : 'Unknown';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: onSurfaceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onSurfaceColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            trackName.toUpperCase(),
            style: GoogleFonts.inter(
              color: onSurfaceColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: GoogleFonts.jetBrainsMono(
                  color: onSurfaceColor.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    activeTrackColor: accentColor,
                    inactiveTrackColor: onSurfaceColor.withOpacity(0.1),
                    thumbColor: accentColor,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds.toDouble() > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: GoogleFonts.jetBrainsMono(
                  color: onSurfaceColor.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                color: onSurfaceColor,
                iconSize: 32,
                onPressed: _previous,
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: _playPause,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next),
                color: onSurfaceColor,
                iconSize: 32,
                onPressed: _next,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTracklist(Color accentColor, Color onSurfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracks',
          style: GoogleFonts.inter(
            color: onSurfaceColor.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _tracks.length,
            itemBuilder: (context, index) {
              final track = _tracks[index];
              final isCurrent = index == _currentTrackIndex;
              final trackName = _cleanTrackName(track);
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isCurrent ? accentColor.withOpacity(0.1) : Colors.transparent,
                leading: isCurrent && _isPlaying
                    ? _buildPlayingIndicator(accentColor)
                    : Icon(
                        Icons.music_note,
                        color: isCurrent ? accentColor : onSurfaceColor.withOpacity(0.3),
                      ),
                title: Text(
                  trackName.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isCurrent ? accentColor : onSurfaceColor,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  setState(() => _currentTrackIndex = index);
                  _playTrack();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayingIndicator(Color color) {
    return SizedBox(
      height: 16,
      width: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          3,
          (i) => _PlayingBar(color: color, delay: i * 200),
        ),
      ),
    );
  }
}

class _PlayingBar extends StatefulWidget {
  final Color color;
  final int delay;
  const _PlayingBar({required this.color, required this.delay});

  @override
  State<_PlayingBar> createState() => _PlayingBarState();
}

class _PlayingBarState extends State<_PlayingBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 3,
          height: 4 + (12 * _controller.value),
          decoration: BoxDecoration(
             color: widget.color,
             borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
