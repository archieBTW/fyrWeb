import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../fyr_theme.dart';
import '../../models/fyr_notification.dart';
import '../../services/music_audio/music_audio.dart';

class CalendarMenuPopup extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onOpenCalendar;

  const CalendarMenuPopup({
    super.key,
    required this.onClose,
    required this.onOpenCalendar,
  });

  @override
  State<CalendarMenuPopup> createState() => _CalendarMenuPopupState();
}

class _CalendarMenuPopupState extends State<CalendarMenuPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  DateTime _selectedDate = DateTime.now();
  String _location = 'Oklahoma City';
  final TextEditingController _locController = TextEditingController();

  final List<Map<String, dynamic>> _sampleEvents = [
    {
      'title': 'Team Sync & Product Review',
      'time': '10:00 AM',
      'date': DateTime.now(),
    },
    {
      'title': 'Deploy fyrWeb v2.0 to Production',
      'time': '2:30 PM',
      'date': DateTime.now(),
    },
    {
      'title': 'Open Source Community Hangout',
      'time': '5:00 PM',
      'date': DateTime.now(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _locController.text = _location;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _locController.dispose();
    super.dispose();
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FyrTheme.bgColor,
        title: Text('Set Location', style: TextStyle(color: FyrTheme.textColor)),
        content: TextField(
          controller: _locController,
          style: TextStyle(color: FyrTheme.textColor),
          decoration: InputDecoration(
            hintText: 'City Name',
            hintStyle: TextStyle(color: FyrTheme.textColorMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: FyrTheme.cardColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: FyrTheme.accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: FyrTheme.textColorMuted)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _location = _locController.text.trim().isEmpty ? 'Oklahoma City' : _locController.text.trim();
              });
              Navigator.pop(context);
            },
            child: Text('Save', style: TextStyle(color: FyrTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationCenter.instance.notifications;
    final screenHeight = MediaQuery.of(context).size.height;

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          constraints: BoxConstraints(
            maxHeight: (screenHeight - 76).clamp(300.0, 720.0),
          ),
          decoration: BoxDecoration(
            color: FyrTheme.bgColor.withValues(alpha: 0.35),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border(
              left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Calendar Section - Catppuccin / Dark theme
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: FyrTheme.accentColor,
                          onPrimary: Colors.white,
                          surface: FyrTheme.bgColor,
                          onSurface: FyrTheme.textColor,
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      ),
                    ),
                  ),

                  // 2. Events Section
                  if (_sampleEvents.any((e) =>
                      (e['date'] as DateTime).year == _selectedDate.year &&
                      (e['date'] as DateTime).month == _selectedDate.month &&
                      (e['date'] as DateTime).day == _selectedDate.day)) ...[
                    Divider(height: 1, color: FyrTheme.cardColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EVENTS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: FyrTheme.textColorMuted,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._sampleEvents
                              .where((e) =>
                                  (e['date'] as DateTime).year == _selectedDate.year &&
                                  (e['date'] as DateTime).month == _selectedDate.month &&
                                  (e['date'] as DateTime).day == _selectedDate.day)
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: FyrTheme.accentColor,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e['title'],
                                            style: TextStyle(
                                              color: FyrTheme.textColor,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          e['time'],
                                          style: TextStyle(
                                            color: FyrTheme.textColorMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                        ],
                      ),
                    ),
                  ],

                  // Open Calendar button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: TextButton(
                      onPressed: () {
                        widget.onOpenCalendar();
                        widget.onClose();
                      },
                      child: Text(
                        'Open Calendar',
                        style: TextStyle(color: FyrTheme.accentColor, fontSize: 12),
                      ),
                    ),
                  ),

                  Divider(height: 1, color: FyrTheme.cardColor),

                  // 3. Weather Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          size: 44,
                          color: FyrTheme.textColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _location,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: FyrTheme.textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _showLocationDialog,
                                    child: Icon(
                                      Icons.edit,
                                      size: 13,
                                      color: FyrTheme.textColorMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '58°F • Clear sky',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: FyrTheme.textColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: FyrTheme.cardColor),

                  // 4. Phone Section (KDE Connect replica from fyrDE)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.smartphone,
                          size: 24,
                          color: FyrTheme.accentColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pixel 9',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: FyrTheme.textColor,
                                ),
                              ),
                              Text(
                                'Connected • 38% Battery',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: FyrTheme.textColorMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ringing Pixel 9...',
                                  style: TextStyle(color: FyrTheme.onAccentColor),
                                ),
                                backgroundColor: FyrTheme.accentColor,
                                duration: const Duration(milliseconds: 1400),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.notifications_active_outlined,
                            size: 20,
                            color: FyrTheme.accentColor,
                          ),
                          tooltip: 'Find my phone',
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: FyrTheme.cardColor),

                  // 5. Now Playing Section (Media Controls in notifications dropdown)
                  _buildNowPlayingSection(context, context.watch<MusicService>()),

                  Divider(height: 1, color: FyrTheme.cardColor),

                  // 6. Notifications Section - Exact 1:1 replica of fyrDE notification card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NOTIFICATIONS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: FyrTheme.textColorMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              NotificationCenter.instance.clearAll();
                            });
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              fontSize: 12,
                              color: FyrTheme.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No notifications',
                          style: TextStyle(
                            color: FyrTheme.textColorMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: notifications.map((n) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: NotificationCard(
                              notification: n,
                              onDismiss: () {
                                setState(() {
                                  NotificationCenter.instance.dismissNotification(n.id);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlayingSection(BuildContext context, MusicService music) {
    if (music.tracks.isEmpty) return const SizedBox.shrink();

    final accentColor = FyrTheme.accentColor;
    final trackName = music.currentTrackTitle.isNotEmpty
        ? music.currentTrackTitle
        : 'Unknown Track';
    final isPlaying = music.isPlaying;
    final position = music.position;
    final duration = music.duration;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FyrTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying
                ? accentColor.withValues(alpha: 0.35)
                : FyrTheme.dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPlaying
                        ? Icons.music_note_rounded
                        : Icons.pause_circle_outline_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trackName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: FyrTheme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Archer Woods • Beats by Arch',
                        style: TextStyle(
                          fontSize: 10,
                          color: FyrTheme.textColorMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 20),
                  color: FyrTheme.textColor,
                  onPressed: () => music.previous(),
                  tooltip: 'Previous Track',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
                const SizedBox(width: 2),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 18,
                      color: FyrTheme.onColor(accentColor),
                    ),
                    onPressed: () => music.playPause(),
                    tooltip: isPlaying ? 'Pause' : 'Play',
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 20),
                  color: FyrTheme.textColor,
                  onPressed: () => music.next(),
                  tooltip: 'Next Track',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  MusicService.formatDuration(position),
                  style: TextStyle(
                    fontSize: 10,
                    color: FyrTheme.textColorMuted,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      activeTrackColor: accentColor,
                      inactiveTrackColor: FyrTheme.dividerColor,
                      thumbColor: accentColor,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble().clamp(
                            0.0,
                            (duration.inMilliseconds > 0
                                    ? duration.inMilliseconds
                                    : 1)
                                .toDouble(),
                          ),
                      max: duration.inMilliseconds.toDouble() > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (val) {
                        music.seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                ),
                Text(
                  MusicService.formatDuration(duration),
                  style: TextStyle(
                    fontSize: 10,
                    color: FyrTheme.textColorMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final FyrNotification notification;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FyrTheme.bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.appName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: FyrTheme.accentColor,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(notification.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: FyrTheme.textColorMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: FyrTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: FyrTheme.textColor.withValues(alpha: 0.8),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: notification.actions
                              .asMap()
                              .entries
                              .where((entry) => entry.key % 2 == 0 && entry.value != 'default')
                              .map((entry) {
                            final label = notification.actions.length > entry.key + 1
                                ? notification.actions[entry.key + 1]
                                : entry.value;
                            return TextButton(
                              onPressed: onDismiss,
                              style: TextButton.styleFrom(
                                backgroundColor: FyrTheme.accentColor.withValues(alpha: 0.1),
                                foregroundColor: FyrTheme.accentColor,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close, size: 16, color: FyrTheme.textColorMuted),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (notification.icon == 'phone') {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: FyrTheme.accentColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.smartphone, color: FyrTheme.accentColor, size: 24),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: FyrTheme.accentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.notifications, color: FyrTheme.accentColor, size: 24),
    );
  }
}
