import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'game/gamepad.dart';
import 'game/mini_map.dart';
import 'game/models.dart';
import 'game/renderer.dart';
import 'game/world.dart';

bool get isDesktopPlatform {
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

class GrandTheftAntApp extends StatelessWidget {
  const GrandTheftAntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A140E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7FA650),
          secondary: Color(0xFFD9A74A),
          surface: Color(0xFF241C14),
        ),
      ),
      child: const CyberFpsGameScreen(),
    );
  }
}

class CyberFpsGameScreen extends StatefulWidget {
  const CyberFpsGameScreen({super.key});

  @override
  State<CyberFpsGameScreen> createState() => _CyberFpsGameScreenState();
}

class _CyberFpsGameScreenState extends State<CyberFpsGameScreen>
    with SingleTickerProviderStateMixin {
  late final CyberWorld world;
  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode();

  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Duration _lastTick = Duration.zero;

  bool _inMenu = true;
  bool _isPaused = false;
  bool _invertLookY = false;
  double _lookSensitivity = 1.0;
  late bool _showTouchJoysticks;
  NpcAnt? _talkingToNpc;
  bool _showMiniMap = true;
  bool _miniMapExpanded = false;

  // Gamepad / Controller integration
  final GamepadService _gamepadService = GamepadService();
  bool _lastGpJump = false;
  bool _lastGpAttack = false;
  bool _lastGpMount = false;
  bool _lastGpPause = false;
  GamepadSnapshot _currentGamepad = GamepadSnapshot.empty;

  // Virtual Touch Joystick state (-1.0 to +1.0)
  // Held values continuously drive movement (left stick) and camera yaw/pitch (right stick) every frame.
  Offset _leftJoystickVector = Offset.zero;
  Offset _rightJoystickVector = Offset.zero;

  @override
  void initState() {
    super.initState();
    world = CyberWorld(denseFoliage: isDesktopPlatform);
    _gamepadService.init();
    _showTouchJoysticks = !isDesktopPlatform;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startGame() {
    world.sound.init();
    setState(() {
      _inMenu = false;
      _isPaused = false;
      _talkingToNpc = null;
    });
    _focusNode.requestFocus();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    // Poll controller inputs every frame
    final gp = _gamepadService.poll();
    _currentGamepad = gp;

    if (_inMenu || _isPaused || _talkingToNpc != null) {
      // Allow unpausing / closing dialogue via controller Start button
      if (gp.isConnected && gp.pause && !_lastGpPause && !_inMenu) {
        if (_talkingToNpc != null) {
          setState(() => _talkingToNpc = null);
        } else {
          setState(() => _isPaused = false);
        }
      }
      _lastGpPause = gp.pause;
      return;
    }

    // Left Joystick + Controller Left Stick + Keyboard movement
    double moveForward = -_leftJoystickVector.dy;
    double moveStrafe = _leftJoystickVector.dx;

    if (gp.isConnected) {
      moveForward += gp.moveForward;
      moveStrafe += gp.moveStrafe;
    }

    // Right Joystick + Controller Right Stick continuous camera rotation and pitch look
    final pitchDirection = _invertLookY ? 1.0 : -1.0;
    double turnDelta = _rightJoystickVector.dx * 2.65 * _lookSensitivity * dt;
    double pitchDelta =
        pitchDirection * _rightJoystickVector.dy * 1.55 * _lookSensitivity * dt;

    if (gp.isConnected) {
      turnDelta += gp.lookX * 2.85 * _lookSensitivity * dt;
      pitchDelta += pitchDirection * gp.lookY * 1.85 * _lookSensitivity * dt;

      // Controller button triggers
      if (gp.jump && !_lastGpJump) {
        world.triggerJumpOrAscend();
      }
      if (gp.attack && !_lastGpAttack) {
        world.triggerSpeciesAbility();
      }
      if (gp.mount && !_lastGpMount) {
        final nearbyNpc = world.findNearbyNpcAnt();
        final nearbyBug = world.findNearbyMountableBug();
        if (nearbyNpc != null && nearbyBug == null && world.mountedVehicle == null) {
          setState(() => _talkingToNpc = nearbyNpc);
        } else {
          world.interactOrToggleMount();
        }
      }
      if (gp.pause && !_lastGpPause) {
        setState(() => _isPaused = true);
      }
      _lastGpJump = gp.jump;
      _lastGpAttack = gp.attack;
      _lastGpMount = gp.mount;
      _lastGpPause = gp.pause;
    }

    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      moveForward += 1.0;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      moveForward -= 1.0;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      moveStrafe -= 1.0;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      moveStrafe += 1.0;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyQ)) {
      turnDelta -= 2.4 * dt;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      turnDelta += 2.4 * dt;
    }

    moveForward = moveForward.clamp(-1.0, 1.0);
    moveStrafe = moveStrafe.clamp(-1.0, 1.0);

    final sprinting = _pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.shiftRight) ||
        _leftJoystickVector.distance > 0.78 ||
        (gp.isConnected && gp.sprint);

    world.update(
      dt,
      moveForward: moveForward,
      moveStrafe: moveStrafe,
      turnDelta: turnDelta,
      pitchDelta: pitchDelta,
      sprinting: sprinting,
      actionPressed: false,
    );

    if (mounted) {
      setState(() {});
    }
  }

  String _compassHeadingText(double angle) {
    final deg = ((angle * 180 / math.pi) % 360 + 360) % 360;
    if (deg >= 337.5 || deg < 22.5) return 'EAST (${deg.round()}°)';
    if (deg >= 22.5 && deg < 67.5) return 'SE (${deg.round()}°)';
    if (deg >= 67.5 && deg < 112.5) return 'SOUTH (${deg.round()}°)';
    if (deg >= 112.5 && deg < 157.5) return 'SW (${deg.round()}°)';
    if (deg >= 157.5 && deg < 202.5) return 'WEST (${deg.round()}°)';
    if (deg >= 202.5 && deg < 247.5) return 'NW (${deg.round()}°)';
    if (deg >= 247.5 && deg < 292.5) return 'NORTH (${deg.round()}°)';
    return 'NE (${deg.round()}°)';
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      _pressedKeys.add(key);

      if (key == LogicalKeyboardKey.keyM) {
        if (!_inMenu && !_isPaused) {
          setState(() => _miniMapExpanded = !_miniMapExpanded);
        }
      } else if (key == LogicalKeyboardKey.keyT) {
        if (_talkingToNpc != null) {
          setState(() => _talkingToNpc = null);
        } else {
          final nearbyNpc = world.findNearbyNpcAnt();
          if (nearbyNpc != null) {
            setState(() => _talkingToNpc = nearbyNpc);
          }
        }
      } else if (key == LogicalKeyboardKey.keyE) {
        final nearbyNpc = world.findNearbyNpcAnt();
        final nearbyBug = world.findNearbyMountableBug();
        if (nearbyNpc != null && nearbyBug == null && world.mountedVehicle == null) {
          setState(() => _talkingToNpc = nearbyNpc);
        } else {
          world.interactOrToggleMount();
        }
      } else if (key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.keyC) {
        world.triggerJumpOrAscend();
      } else if (key == LogicalKeyboardKey.keyF) {
        world.triggerSpeciesAbility();
      } else if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.keyP) {
        if (_miniMapExpanded) {
          setState(() => _miniMapExpanded = false);
        } else if (_talkingToNpc != null) {
          setState(() => _talkingToNpc = null);
        } else if (!_inMenu) {
          setState(() {
            _isPaused = !_isPaused;
          });
        }
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(key);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) {
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
          child: Stack(
            fit: StackFit.expand,
          children: [
            // 1. 3rd-Person Hyperrealistic "City of Grass" Viewport
            RepaintBoundary(
              child: CustomPaint(
                painter: CyberRenderer(world: world),
                size: Size.infinite,
              ),
            ),

            // 2. Minimal Uncluttered Portrait HUD (Top Status Pill + Dual Touch Joysticks + Proximity Mount Button)
            if (!_inMenu) _buildSimplifiedPortraitHud(context),

            // 3. Title, Pause Screens & NPC Dialogue Modal
            if (_inMenu) _buildTitleScreen(),
            if (_isPaused && !_inMenu) _buildPauseOverlay(),
            if (_talkingToNpc != null && !_inMenu)
              _buildDialogueModal(_talkingToNpc!),
            if (_miniMapExpanded && !_inMenu)
              FullMeadowTacticalMapModal(
                world: world,
                onClose: () => setState(() => _miniMapExpanded = false),
              ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSimplifiedPortraitHud(BuildContext context) {
    final vehicleSpec = world.currentVehicleSpec;
    final nearbyBug = world.findNearbyMountableBug();
    final nearbyNpc = world.findNearbyNpcAnt();
    final isMounted = world.mountedVehicle != null;
    final hasGamepad = _currentGamepad.isConnected;
    final activeMission = world.activeMission;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // COMPACT TOP SECTION: Biome Status Pill & Active Mission Tracker
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x5518140E),
                    border: Border.all(
                      color: const Color(0xFFD9C398).withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.grass,
                        size: 16,
                        color: Color(0xFF9AC962),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          vehicleSpec != null
                              ? 'Riding ${vehicleSpec.commonName} • ${world.currentBiomeName}'
                              : 'Red Wood Ant • ${world.currentBiomeName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF5EBD6),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasGamepad) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x448AB858),
                            border: Border.all(
                              color: const Color(0xFF8AB858).withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gamepad, size: 12, color: Color(0xFFDCE3B8)),
                              SizedBox(width: 4),
                              Text(
                                'PAD',
                                style: TextStyle(
                                  color: Color(0xFFDCE3B8),
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _compactIconBtn(
                        icon: world.sound.enabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        onTap: () => setState(() {
                          world.sound.enabled = !world.sound.enabled;
                        }),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        key: const ValueKey('pause_button'),
                        onTap: () => setState(() => _isPaused = true),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x442E2418),
                            border: Border.all(
                              color: const Color(0xFFD9C398).withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pause,
                                size: 14,
                                color: Color(0xFFD9C398),
                              ),
                              SizedBox(width: 3),
                              Text(
                                'PAUSE',
                                style: TextStyle(
                                  color: Color(0xFFD9C398),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Top row under pill: Navigation & Mission Tracker on left, Circular Radar on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Column: Mission tracker & coordinates
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeMission != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0x1F140E0A),
                                border: Border.all(
                                  color: activeMission.isFinished
                                      ? const Color(0xFFA8E07B).withValues(alpha: 0.55)
                                      : const Color(0xFFD9A74A).withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    activeMission.isFinished ? Icons.check_circle : Icons.assignment,
                                    size: 13,
                                    color: activeMission.isFinished
                                        ? const Color(0xFFA8E07B)
                                        : const Color(0xFFD9A74A),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '${activeMission.title}: ${activeMission.currentCount} / ${activeMission.targetCount}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: activeMission.isFinished
                                            ? const Color(0xFFE2F7CD)
                                            : const Color(0xFFF5EBD6),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  if (activeMission.isFinished) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(TALK: ${activeMission.giverName.toUpperCase()})',
                                      style: const TextStyle(
                                        color: Color(0xFFA8E07B),
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x1F140E0A),
                              border: Border.all(
                                color: const Color(0xFFD9C398).withValues(alpha: 0.22),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'POS: [${world.playerPos.x.toStringAsFixed(1)}, ${world.playerPos.y.toStringAsFixed(1)}] • ${_compassHeadingText(world.playerAngle)}',
                              style: const TextStyle(
                                color: Color(0xFFD9C398),
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: Mini-Map Radar (so you know where you're going!)
                    if (_showMiniMap) ...[
                      const SizedBox(width: 8),
                      MiniMapRadar(
                        world: world,
                        onToggleExpand: () => setState(() => _miniMapExpanded = true),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // BOTTOM CONTROLS: Transparent Action Badges + Optional Touch Joysticks (Hidden on Desktop)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Translucent Action Buttons: Species Attack, Mount/Dismount, Leap & NPC Dialogue
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      // Talk to Colony NPC Ant (when in proximity)
                      if (nearbyNpc != null)
                        _contextualActionButton(
                          buttonKey: const ValueKey('talk_npc_button'),
                          icon: Icons.chat_bubble_outline,
                          badge: hasGamepad ? 'Y' : (isDesktopPlatform ? 'T' : null),
                          label: nearbyNpc.hasClaimableMission
                              ? 'COMPLETE: ${nearbyNpc.name.toUpperCase()}'
                              : 'TALK: ${nearbyNpc.name.toUpperCase()}',
                          color: nearbyNpc.hasClaimableMission
                              ? const Color(0xFFA8E07B)
                              : const Color(0xFFFFD54F),
                          onTap: () => setState(() => _talkingToNpc = nearbyNpc),
                        ),
                      _contextualActionButton(
                        buttonKey: const ValueKey('attack_button'),
                        icon: Icons.flash_on,
                        badge: hasGamepad ? 'RT/Y' : (isDesktopPlatform ? 'F' : null),
                        label: world.currentAttackName,
                        color: const Color(0xFFFF8566),
                        onTap: world.triggerSpeciesAbility,
                      ),
                      if (nearbyBug != null && !isMounted)
                        _contextualActionButton(
                          buttonKey: const ValueKey('mount_button'),
                          icon: Icons.pest_control,
                          badge: hasGamepad ? 'X' : (isDesktopPlatform ? 'E' : null),
                          label: 'MOUNT ${nearbyBug.spec.commonName.toUpperCase()}',
                          color: const Color(0xFFF5D799),
                          onTap: world.interactOrToggleMount,
                        ),
                      if (isMounted) ...[
                        _contextualActionButton(
                          buttonKey: const ValueKey('jump_button'),
                          icon: Icons.flight_takeoff,
                          badge: hasGamepad ? 'A' : (isDesktopPlatform ? 'SPACE' : null),
                          label: world.mountedVehicle == BugVehicleType.hornet
                              ? 'FLY UP'
                              : 'LEAP',
                          color: const Color(0xFFA8E07B),
                          onTap: world.triggerJumpOrAscend,
                        ),
                        _contextualActionButton(
                          buttonKey: const ValueKey('dismount_button'),
                          icon: Icons.exit_to_app,
                          badge: hasGamepad ? 'X' : (isDesktopPlatform ? 'E' : null),
                          label: 'DISMOUNT',
                          color: const Color(0xFFF5D799),
                          onTap: world.interactOrToggleMount,
                        ),
                      ],
                    ],
                  ),
                ),

                // Touch Joysticks (Shown on touch screens, hidden when viewing on desktop)
                if (_showTouchJoysticks)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      VirtualJoystick(
                        key: const ValueKey('left_joystick'),
                        label: 'MOVE',
                        size: 104,
                        accentColor: const Color(0xFF8AB858),
                        onChanged: (vec) {
                          _leftJoystickVector = vec;
                        },
                      ),
                      VirtualJoystick(
                        key: const ValueKey('right_joystick'),
                        label: 'LOOK',
                        size: 104,
                        accentColor: const Color(0xFFD9C398),
                        onChanged: (vec) {
                          _rightJoystickVector = vec;
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactIconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFFD9C398),
        ),
      ),
    );
  }

  Widget _contextualActionButton({
    Key? buttonKey,
    required IconData icon,
    String? badge,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
          decoration: BoxDecoration(
            color: const Color(0x18140E0A), // Extremely transparent (~9% opacity)
            border: Border.all(color: color.withValues(alpha: 0.32), width: 1.0),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              Icon(icon, size: 13, color: color.withValues(alpha: 0.75)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.80),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogueModal(NpcAnt npc) {
    final mission = npc.currentMission;
    final hasClaimable = npc.hasClaimableMission;
    final hasAvailable = npc.hasAvailableMission;
    final hasActive = npc.hasActiveMission;

    String speechText;
    if (hasClaimable) {
      speechText = mission!.completionDialogue;
    } else if (hasActive) {
      speechText = mission!.inProgressDialogue;
    } else if (hasAvailable) {
      speechText = mission!.introDialogue;
    } else {
      speechText =
          'May the Colony thrive under your antennae, Scout. The meadow has never been safer.';
    }

    return Container(
      color: const Color(0xCC0D0A07),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xF21C160F),
            border: Border.all(
              color: npc.crestColor.withValues(alpha: 0.85),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 28,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Rank, Name, Crest Avatar & Dismiss
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: npc.chitinColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: npc.crestColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: npc.crestColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shield,
                        size: 22,
                        color: npc.crestColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${npc.rank.toUpperCase()} • ${npc.title.toUpperCase()}',
                          style: TextStyle(
                            color: npc.crestColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          npc.name,
                          style: const TextStyle(
                            color: Color(0xFFF5EBD6),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close_dialogue_button'),
                    icon: const Icon(Icons.close, color: Color(0xFFD9C398), size: 20),
                    onPressed: () => setState(() => _talkingToNpc = null),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Speech Bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF140F0A),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '“$speechText”',
                  style: const TextStyle(
                    color: Color(0xFFE8DFCE),
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),

              // Mission Details Card
              if (mission != null && !npc.allMissionsClaimed) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasClaimable
                        ? const Color(0x334E8532)
                        : (hasActive
                            ? const Color(0x22D9A74A)
                            : const Color(0x1A8AB858)),
                    border: Border.all(
                      color: hasClaimable
                          ? const Color(0xFFA8E07B)
                          : (hasActive
                              ? const Color(0xFFD9A74A)
                              : const Color(0xFF8AB858).withValues(alpha: 0.5)),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasClaimable
                                ? Icons.check_circle
                                : (hasActive ? Icons.assignment : Icons.assignment_outlined),
                            size: 15,
                            color: hasClaimable
                                ? const Color(0xFFA8E07B)
                                : const Color(0xFFD9A74A),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              mission.title,
                              style: const TextStyle(
                                color: Color(0xFFF5EBD6),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '+${mission.scoreReward} PTS',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          color: Color(0xFFD9C398),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                      if (hasActive || hasClaimable) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: mission.progressRatio,
                            backgroundColor: Colors.black38,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              hasClaimable
                                  ? const Color(0xFFA8E07B)
                                  : const Color(0xFFD9A74A),
                            ),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Progress: ${mission.currentCount} / ${mission.targetCount}',
                          style: TextStyle(
                            color: hasClaimable
                                ? const Color(0xFFA8E07B)
                                : const Color(0xFFD9A74A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons
              if (hasClaimable)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    key: const ValueKey('claim_reward_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E8532),
                      foregroundColor: const Color(0xFFFDFBF7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.star, size: 18),
                    label: Text(
                      'CLAIM REWARD (+${mission!.scoreReward} PTS)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        world.claimMissionReward(npc, mission);
                      });
                    },
                  ),
                )
              else if (hasAvailable)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    key: const ValueKey('accept_mission_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB57C24),
                      foregroundColor: const Color(0xFFFDFBF7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'ACCEPT COLONY ORDER',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        world.acceptMission(mission!);
                      });
                    },
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    key: const ValueKey('dismiss_dialogue_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD9C398),
                      side: const BorderSide(color: Color(0xFFD9C398)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => setState(() => _talkingToNpc = null),
                    child: Text(
                      hasActive ? 'CLOSE • RESUME PATROL' : 'DISMISS',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleScreen() {
    return Container(
      color: const Color(0xCC140F0A),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xF2211A12),
            border: Border.all(color: const Color(0xFFD9C398), width: 1.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 32),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E4F28).withValues(alpha: 0.45),
                  border: Border.all(color: const Color(0xFF8AB858)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PORTRAIT 3D MACRO OPEN WORLD',
                  style: TextStyle(
                    color: Color(0xFFDCE3B8),
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'CITY OF GRASS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF5EBD6),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const Text(
                '3rd-Person Ant & Insect Vehicle Simulation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFD9C398),
                  fontSize: 12.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF17120C),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    _ControlRow('LEFT STICK / WASD', 'Walk & Strafe Grass Floor'),
                    _ControlRow('RIGHT STICK / LOOK', 'Continuous Turn & Pitch Up/Down'),
                    _ControlRow('A / SPACE', 'Leap / Ascend Hornet Flight'),
                    _ControlRow('RT / F / TAP', 'Species Attack / Ability'),
                    _ControlRow('X / E', 'Mount / Dismount Nearby Insect'),
                    _ControlRow('T / TALK', 'Speak with Colony Ants & Accept Missions'),
                    _ControlRow('M / RADAR TAP', 'Toggle Full Meadow Tactical Map'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B8E3D),
                    foregroundColor: const Color(0xFFFDFBF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _startGame,
                  child: const Text(
                    'ENTER THE MEADOW',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    final gp = _gamepadService.poll();
    final isGpConnected = gp.isConnected || _currentGamepad.isConnected;
    final mapping = _gamepadService.mapping;

    return Container(
      color: const Color(0xCC140F0A),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xF2211A12),
            border: Border.all(color: const Color(0xFFD9C398), width: 1.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 28),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'PAUSE MENU',
                  style: TextStyle(
                    color: Color(0xFFF5EBD6),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // CONTROLLER STATUS & INPUT MAPPING SECTION
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF17120C),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isGpConnected
                              ? Icons.sports_esports
                              : Icons.sports_esports_outlined,
                          size: 16,
                          color: isGpConnected
                              ? const Color(0xFFA8E07B)
                              : Colors.white60,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isGpConnected
                                ? 'GAMEPAD: ${_currentGamepad.id.isNotEmpty ? _currentGamepad.id : "Connected"}'
                                : 'GAMEPAD: No Controller Detected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isGpConnected
                                  ? const Color(0xFFA8E07B)
                                  : Colors.white60,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'CONTROLLER PRESET MAPPING',
                      style: TextStyle(
                        color: Color(0xFFD9C398),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF221A12),
                        border: Border.all(
                          color: const Color(0xFFD9C398).withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ControllerPreset>(
                          key: const ValueKey('controller_preset_dropdown'),
                          value: mapping.preset,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF221A12),
                          style: const TextStyle(
                            color: Color(0xFFF5EBD6),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ControllerPreset.standard,
                              child: Text('Standard (A: Leap, RT: Attack, X: Mount)'),
                            ),
                            DropdownMenuItem(
                              value: ControllerPreset.bumperJumper,
                              child: Text('Bumper Jumper (LB: Leap, RB: Attack, X: Mount)'),
                            ),
                            DropdownMenuItem(
                              value: ControllerPreset.actionCombat,
                              child: Text('Action Combat (A: Leap, Y: Attack, RB: Sprint)'),
                            ),
                          ],
                          onChanged: (preset) {
                            if (preset != null) {
                              setState(() {
                                mapping.applyPreset(preset);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Deadzone slider
                    Row(
                      children: [
                        Text(
                          'STICK DEADZONE: ${(mapping.deadzone * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            key: const ValueKey('deadzone_slider'),
                            value: mapping.deadzone,
                            min: 0.05,
                            max: 0.35,
                            divisions: 6,
                            activeColor: const Color(0xFF8AB858),
                            onChanged: (v) => setState(() => mapping.deadzone = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // MINI-MAP / RADAR HUD TOGGLE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF17120C),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SHOW MINI-MAP / RADAR HUD',
                            style: TextStyle(
                              color: Color(0xFFF5EBD6),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Real-time navigation radar with compass and waypoint tracking',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      key: const ValueKey('toggle_mini_map'),
                      value: _showMiniMap,
                      activeThumbColor: const Color(0xFF8AB858),
                      onChanged: (val) => setState(() => _showMiniMap = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // DENSE FOLIAGE TOGGLE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF17120C),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HIGH DENSITY FOLIAGE (DESKTOP)',
                            style: TextStyle(
                              color: Color(0xFFF5EBD6),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Over 800+ towering grass stalks with adaptive LOD performance',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      key: const ValueKey('toggle_dense_foliage'),
                      value: world.denseFoliage,
                      activeThumbColor: const Color(0xFF8AB858),
                      onChanged: (val) => setState(() => world.setDenseFoliage(val)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // TOUCH JOYSTICKS TOGGLE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF17120C),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SHOW ON-SCREEN TOUCH JOYSTICKS',
                            style: TextStyle(
                              color: Color(0xFFF5EBD6),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Automatically hidden on desktop web/platforms',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      key: const ValueKey('toggle_touch_joysticks'),
                      value: _showTouchJoysticks,
                      activeThumbColor: const Color(0xFF8AB858),
                      onChanged: (val) => setState(() => _showTouchJoysticks = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // INVERT LOOK SWITCH
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF17120C),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'INVERT UP / DOWN LOOK',
                        style: TextStyle(
                          color: Color(0xFFF5EBD6),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch(
                      key: const ValueKey('invert_look_y_switch'),
                      value: _invertLookY,
                      activeThumbColor: const Color(0xFF8AB858),
                      onChanged: (val) => setState(() => _invertLookY = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // LOOK SPEED SLIDER
              Row(
                children: [
                  const Text(
                    'LOOK SPEED',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      key: const ValueKey('look_sensitivity_slider'),
                      value: _lookSensitivity,
                      min: 0.4,
                      max: 2.0,
                      activeColor: const Color(0xFF8AB858),
                      onChanged: (v) => setState(() => _lookSensitivity = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // RESUME BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8E3D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setState(() => _isPaused = false);
                  _focusNode.requestFocus();
                },
                child: const Text(
                  'RESUME EXPLORATION',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
                ),
              ),
              const SizedBox(height: 8),

              // RETURN TO ANTHILL BUTTON
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD9C398),
                  side: const BorderSide(color: Color(0xFFD9C398)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  world.resetGame();
                  setState(() => _isPaused = false);
                  _focusNode.requestFocus();
                },
                child: const Text(
                  'RETURN TO ANTHILL MOUND',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multi-touch friendly Virtual Thumbstick Joystick for Portrait Mode
class VirtualJoystick extends StatefulWidget {
  final String label;
  final double size;
  final Color accentColor;
  final ValueChanged<Offset> onChanged;

  const VirtualJoystick({
    super.key,
    required this.label,
    required this.size,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobOffset = Offset.zero;
  int? _activePointer;

  void _updateFromLocalPosition(Offset localPos) {
    final radius = widget.size * 0.5;
    final maxKnobDist = radius * 0.68;
    final center = Offset(radius, radius);
    final delta = localPos - center;
    final dist = delta.distance;
    final clampedDelta = dist > maxKnobDist
        ? Offset.fromDirection(delta.direction, maxKnobDist)
        : delta;

    setState(() {
      _knobOffset = clampedDelta;
    });

    final normalized = Offset(
      (clampedDelta.dx / maxKnobDist).clamp(-1.0, 1.0),
      (clampedDelta.dy / maxKnobDist).clamp(-1.0, 1.0),
    );
    widget.onChanged(normalized);
  }

  void _resetJoystick() {
    setState(() {
      _knobOffset = Offset.zero;
      _activePointer = null;
    });
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size * 0.5;
    final knobRadius = widget.size * 0.22;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            if (_activePointer == null) {
              _activePointer = e.pointer;
              _updateFromLocalPosition(e.localPosition);
            }
          },
          onPointerMove: (e) {
            if (e.pointer == _activePointer) {
              _updateFromLocalPosition(e.localPosition);
            }
          },
          onPointerUp: (e) {
            if (e.pointer == _activePointer) {
              _resetJoystick();
            }
          },
          onPointerCancel: (e) {
            if (e.pointer == _activePointer) {
              _resetJoystick();
            }
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _JoystickPainter(
                knobOffset: _knobOffset,
                knobRadius: knobRadius,
                baseRadius: radius,
                accentColor: widget.accentColor,
                isActive: _activePointer != null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.label,
          style: TextStyle(
            color: widget.accentColor.withValues(alpha: 0.35),
            fontSize: 9.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset knobOffset;
  final double knobRadius;
  final double baseRadius;
  final Color accentColor;
  final bool isActive;

  _JoystickPainter({
    required this.knobOffset,
    required this.knobRadius,
    required this.baseRadius,
    required this.accentColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(baseRadius, baseRadius);

    // Ultra-translucent outer base ring (~8% opacity) so character/dirt show through clearly
    canvas.drawCircle(
      center,
      baseRadius - 2,
      Paint()..color = const Color(0x1516110B),
    );
    canvas.drawCircle(
      center,
      baseRadius - 2,
      Paint()
        ..color = accentColor.withValues(alpha: isActive ? 0.35 : 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 1.8 : 1.2,
    );

    // Subtle directional crosshair ticks inside joystick well
    final tickPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(center.dx - baseRadius * 0.55, center.dy),
      Offset(center.dx + baseRadius * 0.55, center.dy),
      tickPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - baseRadius * 0.55),
      Offset(center.dx, center.dy + baseRadius * 0.55),
      tickPaint,
    );

    // Thumbstick knob with translucent tactile shading
    final knobCenter = center + knobOffset;
    final knobRect = Rect.fromCircle(center: knobCenter, radius: knobRadius);
    canvas.drawCircle(
      knobCenter + const Offset(0, 1.5),
      knobRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      knobCenter,
      knobRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            Colors.white.withValues(alpha: isActive ? 0.40 : 0.22),
            accentColor.withValues(alpha: isActive ? 0.35 : 0.18),
            Color.lerp(accentColor, Colors.black, 0.6)!
                .withValues(alpha: isActive ? 0.40 : 0.20),
          ],
        ).createShader(knobRect),
    );
    canvas.drawCircle(
      knobCenter,
      knobRadius,
      Paint()
        ..color = accentColor.withValues(alpha: isActive ? 0.45 : 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.knobOffset != knobOffset || oldDelegate.isActive != isActive;
}

class _ControlRow extends StatelessWidget {
  final String keys;
  final String desc;

  const _ControlRow(this.keys, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            keys,
            style: const TextStyle(
              color: Color(0xFFD9C398),
              fontWeight: FontWeight.w800,
              fontSize: 11.0,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              desc,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
