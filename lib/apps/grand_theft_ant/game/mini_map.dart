import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'world.dart';

/// Compact Circular In-Game Radar / Mini-Map HUD
class MiniMapRadar extends StatelessWidget {
  final CyberWorld world;
  final VoidCallback onToggleExpand;
  final double size;

  const MiniMapRadar({
    super.key,
    required this.world,
    required this.onToggleExpand,
    this.size = 104.0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('mini_map_radar'),
      onTap: onToggleExpand,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xE616110B),
          border: Border.all(
            color: const Color(0xFFD9C398).withValues(alpha: 0.50),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Radar Canvas
            Positioned.fill(
              child: CustomPaint(
                painter: MiniMapRadarPainter(world: world),
              ),
            ),
            // Tap hint badge in lower right corner
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0x992B1D12),
                  border: Border.all(
                    color: const Color(0xFFD9C398).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MAP',
                  style: TextStyle(
                    color: Color(0xFFD9C398),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Canvas Painter for the Circular Local Radar
class MiniMapRadarPainter extends CustomPainter {
  final CyberWorld world;
  static const double radarRange = 28.0; // 28 units local radius

  MiniMapRadarPainter({required this.world});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 3.5;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // 1. Subtle Earthen Radar Background with Biome Tint
    final bgPaint = Paint()..color = const Color(0xF2140F09);
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // 2. Concentric Range Rings (10m and 20m) & Crosshairs
    final ringPaint = Paint()
      ..color = const Color(0xFFD9C398).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, cy), r * (10.0 / radarRange), ringPaint);
    canvas.drawCircle(Offset(cx, cy), r * (20.0 / radarRange), ringPaint);

    final crosshairPaint = Paint()
      ..color = const Color(0xFFD9C398).withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), crosshairPaint);
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), crosshairPaint);

    final playerPos = world.playerPos;

    // 3. Render Real-Life Props / Human Relics
    for (final prop in world.realLifeProps) {
      final dx = prop.pos.x - playerPos.x;
      final dy = prop.pos.y - playerPos.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= radarRange) {
        final px = cx + (dx / radarRange) * r;
        final py = cy + (dy / radarRange) * r;
        _drawDiamond(canvas, px, py, 3.2, const Color(0xFFE5A93C));
      }
    }

    // 4. Render Mountable Bugs
    for (final bug in world.mountableBugs) {
      final dx = bug.pos.x - playerPos.x;
      final dy = bug.pos.y - playerPos.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= radarRange) {
        final px = cx + (dx / radarRange) * r;
        final py = cy + (dy / radarRange) * r;
        Color bugColor;
        switch (bug.type) {
          case BugVehicleType.wolfSpider:
            bugColor = const Color(0xFFE54B4B);
            break;
          case BugVehicleType.hornet:
            bugColor = const Color(0xFFFFD152);
            break;
          case BugVehicleType.grasshopper:
            bugColor = const Color(0xFF8CE04F);
            break;
          case BugVehicleType.rhinoBeetle:
          case BugVehicleType.stagBeetle:
            bugColor = const Color(0xFFD49E5E);
            break;
        }
        canvas.drawCircle(Offset(px, py), 2.2, Paint()..color = bugColor);
      }
    }

    // 5. Render Colony NPC Ants (Shield / Heraldry pips + Quest Status)
    for (final npc in world.npcAnts) {
      final dx = npc.pos.x - playerPos.x;
      final dy = npc.pos.y - playerPos.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= radarRange) {
        final px = cx + (dx / radarRange) * r;
        final py = cy + (dy / radarRange) * r;

        // Base crest circle
        canvas.drawCircle(Offset(px, py), 3.8, Paint()..color = npc.crestColor);
        canvas.drawCircle(
          Offset(px, py),
          3.8,
          Paint()
            ..color = Colors.white70
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );

        // Status badge overhead
        if (npc.hasClaimableMission) {
          canvas.drawCircle(Offset(px, py - 4.5), 2.4, Paint()..color = const Color(0xFFA8E07B));
        } else if (npc.hasAvailableMission) {
          canvas.drawCircle(Offset(px, py - 4.5), 2.4, Paint()..color = const Color(0xFFFFD54F));
        }
      }
    }

    // 6. Active Mission Waypoint Beacon
    final active = world.activeMission;
    if (active != null) {
      Vec2? targetPos = active.targetLocation;
      // If completed, waypoint points to the mission giver NPC
      if (active.status == MissionStatus.completed) {
        final giver = world.npcAnts.where((n) => n.name == active.giverName).firstOrNull;
        if (giver != null) {
          targetPos = giver.pos;
        }
      }

      if (targetPos != null) {
        final tx = targetPos.x - playerPos.x;
        final ty = targetPos.y - playerPos.y;
        final tDist = math.sqrt(tx * tx + ty * ty);

        if (tDist <= radarRange) {
          final px = cx + (tx / radarRange) * r;
          final py = cy + (ty / radarRange) * r;
          // Pulsing waypoint beacon
          final pulse = (math.sin(world.totalTime * 4.0) * 0.5 + 0.5);
          canvas.drawCircle(
            Offset(px, py),
            4.0 + pulse * 3.0,
            Paint()
              ..color = const Color(0xFFFFD54F).withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
          canvas.drawCircle(Offset(px, py), 3.5, Paint()..color = const Color(0xFFFFD54F));
        } else {
          // Beyond radar: Draw directional arrow indicator clamped to circumference
          final angle = math.atan2(ty, tx);
          final edgeX = cx + math.cos(angle) * (r - 7.0);
          final edgeY = cy + math.sin(angle) * (r - 7.0);

          final arrowPath = Path();
          final tip = Offset(edgeX, edgeY);
          final left = Offset(
            edgeX - math.cos(angle - 0.45) * 6.5,
            edgeY - math.sin(angle - 0.45) * 6.5,
          );
          final right = Offset(
            edgeX - math.cos(angle + 0.45) * 6.5,
            edgeY - math.sin(angle + 0.45) * 6.5,
          );
          arrowPath.moveTo(tip.dx, tip.dy);
          arrowPath.lineTo(left.dx, left.dy);
          arrowPath.lineTo(right.dx, right.dy);
          arrowPath.close();

          canvas.drawPath(
            arrowPath,
            Paint()..color = active.isFinished ? const Color(0xFFA8E07B) : const Color(0xFFFFD54F),
          );
        }
      }
    }

    // 7. Player Ant Field-of-View Cone & Directional Chevron (Centered)
    final camAngle = world.playerAngle;
    final fovArc = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        camAngle - 0.42,
        0.84,
        false,
      )
      ..close();
    canvas.drawPath(
      fovArc,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF9AC94B).withValues(alpha: 0.28),
            const Color(0xFF9AC94B).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72)),
    );

    // Player Directional Chevron
    final heading = world.playerAngle;
    final pTip = Offset(cx + math.cos(heading) * 6.5, cy + math.sin(heading) * 6.5);
    final pLeft = Offset(
      cx + math.cos(heading + 2.45) * 5.0,
      cy + math.sin(heading + 2.45) * 5.0,
    );
    final pRight = Offset(
      cx + math.cos(heading - 2.45) * 5.0,
      cy + math.sin(heading - 2.45) * 5.0,
    );
    final playerChevron = Path()
      ..moveTo(pTip.dx, pTip.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..lineTo(cx, cy)
      ..lineTo(pRight.dx, pRight.dy)
      ..close();

    canvas.drawPath(playerChevron, Paint()..color = const Color(0xFFB4E64D));
    canvas.drawPath(
      playerChevron,
      Paint()
        ..color = const Color(0xFF140F08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.restore(); // Restore clip

    // 8. Outer Metallic Rim & Cardinal Letters
    final rimPaint = Paint()
      ..color = const Color(0xFFD9C398).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(Offset(cx, cy), r, rimPaint);

    // Cardinal 'N' indicator at top
    _drawText(
      canvas,
      'N',
      Offset(cx, cy - r + 6.0),
      const TextStyle(
        color: Color(0xFFFFD54F),
        fontSize: 9.0,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }

  void _drawDiamond(Canvas canvas, double x, double y, double size, Color color) {
    final path = Path()
      ..moveTo(x, y - size)
      ..lineTo(x + size, y)
      ..lineTo(x, y + size)
      ..lineTo(x - size, y)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant MiniMapRadarPainter oldDelegate) => true;
}

/// Full Meadow Tactical Map Modal Overlay (Expanded View: 112x112 Meadow Map)
class FullMeadowTacticalMapModal extends StatelessWidget {
  final CyberWorld world;
  final VoidCallback onClose;

  const FullMeadowTacticalMapModal({
    super.key,
    required this.world,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC0D0A07),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xF21C160F),
            border: Border.all(
              color: const Color(0xFFD9C398).withValues(alpha: 0.85),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 32,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF382312),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD9C398), width: 1.2),
                    ),
                    child: const Icon(Icons.map, size: 20, color: Color(0xFFD9C398)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MEADOW TACTICAL MAP',
                          style: TextStyle(
                            color: Color(0xFFF5EBD6),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '112×112 Units • ${world.currentBiomeName}',
                          style: const TextStyle(
                            color: Color(0xFFD9A74A),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close_map_button'),
                    icon: const Icon(Icons.close, color: Color(0xFFD9C398), size: 22),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tactical Canvas Map (112x112 Full Meadow View)
              Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF140F09),
                      border: Border.all(
                        color: const Color(0xFFD9C398).withValues(alpha: 0.40),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: CustomPaint(
                        painter: FullMeadowMapPainter(world: world),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Map Legend
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF140F0A),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _LegendChip(icon: Icons.navigation, color: Color(0xFFB4E64D), label: 'You'),
                    _LegendChip(icon: Icons.shield, color: Color(0xFFE88A2D), label: 'Officers'),
                    _LegendChip(icon: Icons.star, color: Color(0xFFFFD54F), label: 'Objective'),
                    _LegendChip(icon: Icons.diamond, color: Color(0xFFE5A93C), label: 'Relics'),
                    _LegendChip(icon: Icons.circle, color: Color(0xFF8CE04F), label: 'Insects'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Dismiss / Close Button
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD9C398),
                    side: const BorderSide(color: Color(0xFFD9C398)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onClose,
                  child: const Text(
                    'CLOSE MAP [M]',
                    style: TextStyle(
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
}

class _LegendChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD9C398),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Canvas Painter for the Full 112x112 Meadow Map Overview
class FullMeadowMapPainter extends CustomPainter {
  final CyberWorld world;

  FullMeadowMapPainter({required this.world});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / CyberWorld.mapWidth; // 112 units mapped to size

    // 1. Biome Shaded Zones
    // (A) Southern Emerald Avenue & Anthill Outpost (y: 74..112)
    canvas.drawRect(
      Rect.fromLTRB(0, 74.0 * scale, size.width, size.height),
      Paint()..color = const Color(0xFF1B2E15),
    );
    // (B) Clover Canopy Plaza (Southwest: x: 0..48, y: 32..74)
    canvas.drawRect(
      Rect.fromLTRB(0, 32.0 * scale, 48.0 * scale, 74.0 * scale),
      Paint()..color = const Color(0xFF1E381C),
    );
    // (C) Tall Fescue Cathedral (East: x: 72..112, y: 32..74)
    canvas.drawRect(
      Rect.fromLTRB(72.0 * scale, 32.0 * scale, size.width, 74.0 * scale),
      Paint()..color = const Color(0xFF132B1A),
    );
    // (D) Dandelion Crown District (North: y: 0..32)
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, 32.0 * scale),
      Paint()..color = const Color(0xFF2B3315),
    );
    // (E) Meadow Crossroads & Relic Glade (Center: x: 48..72, y: 32..74)
    canvas.drawRect(
      Rect.fromLTRB(48.0 * scale, 32.0 * scale, 72.0 * scale, 74.0 * scale),
      Paint()..color = const Color(0xFF261D14),
    );

    // 2. Faint Grid Lines (16 units per block)
    final gridPaint = Paint()
      ..color = const Color(0xFFD9C398).withValues(alpha: 0.10)
      ..strokeWidth = 0.8;
    for (double g = 16.0; g < CyberWorld.mapWidth; g += 16.0) {
      canvas.drawLine(Offset(g * scale, 0), Offset(g * scale, size.height), gridPaint);
      canvas.drawLine(Offset(0, g * scale), Offset(size.width, g * scale), gridPaint);
    }

    // 3. Biome Text Labels
    _drawBiomeLabel(canvas, 'DANDELION CROWN', Offset(size.width * 0.5, 16.0 * scale));
    _drawBiomeLabel(canvas, 'CLOVER PLAZA', Offset(24.0 * scale, 53.0 * scale));
    _drawBiomeLabel(canvas, 'CROSSROADS', Offset(60.0 * scale, 53.0 * scale));
    _drawBiomeLabel(canvas, 'TALL FESCUE', Offset(92.0 * scale, 53.0 * scale));
    _drawBiomeLabel(canvas, 'ANTHILL OUTPOST', Offset(size.width * 0.5, 93.0 * scale));

    // 4. Real-Life Human Relics & Landmarks
    for (final prop in world.realLifeProps) {
      final px = prop.pos.x * scale;
      final py = prop.pos.y * scale;
      final diamond = Path()
        ..moveTo(px, py - 3.5)
        ..lineTo(px + 3.5, py)
        ..lineTo(px, py + 3.5)
        ..lineTo(px - 3.5, py)
        ..close();
      canvas.drawPath(diamond, Paint()..color = const Color(0xFFE5A93C));
    }

    // 5. Mountable Bugs (Small colored pips)
    for (final bug in world.mountableBugs) {
      final px = bug.pos.x * scale;
      final py = bug.pos.y * scale;
      Color bugColor;
      switch (bug.type) {
        case BugVehicleType.wolfSpider:
          bugColor = const Color(0xFFE54B4B);
          break;
        case BugVehicleType.hornet:
          bugColor = const Color(0xFFFFD152);
          break;
        case BugVehicleType.grasshopper:
          bugColor = const Color(0xFF8CE04F);
          break;
        case BugVehicleType.rhinoBeetle:
        case BugVehicleType.stagBeetle:
          bugColor = const Color(0xFFD49E5E);
          break;
      }
      canvas.drawCircle(Offset(px, py), 2.0, Paint()..color = bugColor);
    }

    // 6. Colony NPC Ants (Heraldry circles + status badges)
    for (final npc in world.npcAnts) {
      final px = npc.pos.x * scale;
      final py = npc.pos.y * scale;

      canvas.drawCircle(Offset(px, py), 4.5, Paint()..color = npc.crestColor);
      canvas.drawCircle(
        Offset(px, py),
        4.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      if (npc.hasClaimableMission) {
        canvas.drawCircle(Offset(px, py - 5.0), 3.0, Paint()..color = const Color(0xFFA8E07B));
      } else if (npc.hasAvailableMission) {
        canvas.drawCircle(Offset(px, py - 5.0), 3.0, Paint()..color = const Color(0xFFFFD54F));
      }
    }

    // 7. Active Mission Waypoint Marker
    final active = world.activeMission;
    if (active != null) {
      Vec2? target = active.targetLocation;
      if (active.status == MissionStatus.completed) {
        final giver = world.npcAnts.where((n) => n.name == active.giverName).firstOrNull;
        if (giver != null) target = giver.pos;
      }

      if (target != null) {
        final px = target.x * scale;
        final py = target.y * scale;
        final pulse = math.sin(world.totalTime * 4.0) * 0.5 + 0.5;

        canvas.drawCircle(
          Offset(px, py),
          6.0 + pulse * 4.0,
          Paint()
            ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.drawCircle(Offset(px, py), 4.0, Paint()..color = const Color(0xFFFFD54F));
      }
    }

    // 8. Player Ant Position & Facing Chevron
    final px = world.playerPos.x * scale;
    final py = world.playerPos.y * scale;
    final heading = world.playerAngle;

    // Pulsing player ring
    canvas.drawCircle(
      Offset(px, py),
      6.0,
      Paint()
        ..color = const Color(0xFFB4E64D).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final tip = Offset(px + math.cos(heading) * 7.5, py + math.sin(heading) * 7.5);
    final left = Offset(px + math.cos(heading + 2.5) * 5.5, py + math.sin(heading + 2.5) * 5.5);
    final right = Offset(px + math.cos(heading - 2.5) * 5.5, py + math.sin(heading - 2.5) * 5.5);
    final playerPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(px, py)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(playerPath, Paint()..color = const Color(0xFFB4E64D));
    canvas.drawPath(
      playerPath,
      Paint()
        ..color = const Color(0xFF140F08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawBiomeLabel(Canvas canvas, String label, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFFD9C398).withValues(alpha: 0.35),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant FullMeadowMapPainter oldDelegate) => true;
}
