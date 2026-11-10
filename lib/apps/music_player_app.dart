import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../system_settings.dart';
import '../services/music_audio/music_audio.dart';
import '../fyr_theme.dart';

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    final music = context.watch<MusicService>();
    final accentColor = settings.accentColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tracks = music.tracks;

    if (!music.isInitialized && tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'No music found in assets/music/',
          style: GoogleFonts.inter(
            color: onSurfaceColor.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Now Playing',
                style: GoogleFonts.outfit(
                  color: onSurfaceColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (music.isPlaying)
                _buildPlayingIndicator(accentColor),
            ],
          ),
          const SizedBox(height: 24),
          _buildPlayerControls(context, music, accentColor, onSurfaceColor),
          const SizedBox(height: 32),
          Expanded(
            child: _buildTracklist(context, music, accentColor, onSurfaceColor, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(
    BuildContext context,
    MusicService music,
    Color accentColor,
    Color onSurfaceColor,
  ) {
    final trackName = music.currentTrackTitle.isNotEmpty
        ? music.currentTrackTitle
        : 'Unknown Track';

    final position = music.position;
    final duration = music.duration;
    final isPlaying = music.isPlaying;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: onSurfaceColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onSurfaceColor.withValues(alpha: 0.1),
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
                MusicService.formatDuration(position),
                style: GoogleFonts.jetBrainsMono(
                  color: onSurfaceColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    activeTrackColor: accentColor,
                    inactiveTrackColor: onSurfaceColor.withValues(alpha: 0.1),
                    thumbColor: accentColor,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: position.inMilliseconds
                        .toDouble()
                        .clamp(0.0, (duration.inMilliseconds > 0 ? duration.inMilliseconds : 1).toDouble()),
                    max: duration.inMilliseconds.toDouble() > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (value) {
                      music.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                MusicService.formatDuration(duration),
                style: GoogleFonts.jetBrainsMono(
                  color: onSurfaceColor.withValues(alpha: 0.5),
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
                onPressed: () => music.previous(),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  color: FyrTheme.onColor(accentColor),
                  iconSize: 40,
                  onPressed: () => music.playPause(),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next),
                color: onSurfaceColor,
                iconSize: 32,
                onPressed: () => music.next(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTracklist(
    BuildContext context,
    MusicService music,
    Color accentColor,
    Color onSurfaceColor,
    bool isDark,
  ) {
    final tracks = music.tracks;
    final currentIndex = music.currentTrackIndex;
    final isPlaying = music.isPlaying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracks',
          style: GoogleFonts.inter(
            color: onSurfaceColor.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final isCurrent = index == currentIndex;
              final trackName = MusicService.cleanTrackName(track);

              final Color activeTitleColor;
              if (isCurrent) {
                if (!isDark && accentColor.computeLuminance() > 0.55) {
                  activeTitleColor = Colors.black87;
                } else {
                  activeTitleColor = accentColor;
                }
              } else {
                activeTitleColor = onSurfaceColor;
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isCurrent ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
                leading: isCurrent && isPlaying
                    ? _buildPlayingIndicator(accentColor)
                    : Icon(
                        Icons.music_note,
                        color: isCurrent ? accentColor : onSurfaceColor.withValues(alpha: 0.3),
                      ),
                title: Text(
                  trackName.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: activeTitleColor,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  music.playTrackAtIndex(index);
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

class _PlayingBarState extends State<_PlayingBar>
    with SingleTickerProviderStateMixin {
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
