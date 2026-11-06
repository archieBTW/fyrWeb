import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'macro_cache.dart';
import 'models.dart';
import 'world.dart';

class CyberRenderer extends CustomPainter {
  final CyberWorld world;
  final MacroVisualsCache visualsCache;
  static const double fov = math.pi / 2.75;
  static const int numColumns = 180;

  // Dark, humid earthy undergrowth fog color that hides the far clipping plane
  static const Color humidUndergrowthFog = Color(0xFF181512);

  CyberRenderer({required this.world}) : visualsCache = world.visualsCache;

  double _texHash(int a, int b) {
    int n = a * 374761393 + b * 668265263;
    n = (n ^ (n >> 13)) * 1274126177;
    return ((n ^ (n >> 16)) & 0x7FFFFFFF) / 2147483647.0;
  }

  /// Exponential distance fog factor (1.0 at camera, smoothly decays to 0.0 at far plane)
  double _computeExponentialFog(double depth) {
    const density = 0.058;
    return math.exp(-math.pow(depth * density, 1.42)).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();

    if (world.screenShake > 0.01) {
      final shakeAmt = world.screenShake * 7.0;
      final dx = math.sin(world.totalTime * 55.0) * shakeAmt;
      final dy = math.cos(world.totalTime * 68.0) * shakeAmt;
      canvas.translate(dx, dy);
    }

    final bobOffset = math.sin(world.walkBobPhase) * 3.5 * world.walkBobIntensity;
    final horizonY = (size.height * 0.44) +
        (world.playerPitch * size.height * 0.36) +
        bobOffset;

    // 1. Procedural Micro-Terrain & Grounded Dirt Floor, God Rays & Atmospheric Fog
    _drawRealisticSkyAndSoil(canvas, size, horizonY);

    // 2. Raycast Outer Perimeter Boundary Landmarks with Exponential Distance Fog
    final zBuffer = List<double>.filled(numColumns, 1000.0);
    final colWidth = size.width / numColumns;

    for (int col = 0; col < numColumns; col++) {
      final cameraX = (2.0 * col / numColumns) - 1.0;
      final rayAngle = world.playerAngle + math.atan(cameraX * math.tan(fov * 0.5));
      final hit = world.castRay(world.cameraPos, rayAngle);

      final perpDist = hit.distance * math.cos(rayAngle - world.playerAngle);
      zBuffer[col] = perpDist;

      final wallHeight = (size.height / math.max(0.08, perpDist)) * 0.92;
      final wallCenterY = horizonY + (world.cameraZ * wallHeight * 0.65);
      final wallTop = wallCenterY - wallHeight * 0.5;
      final wallBottom = wallCenterY + wallHeight * 0.5;

      _drawRealisticWallSlice(
        canvas,
        col * colWidth,
        colWidth + 0.75,
        wallTop,
        wallBottom,
        hit,
        perpDist,
      );
    }

    // 3. Draw Z-Sorted 3D Entities: Grass Stalks, Micro-Debris, Props, Bugs, Particles & 3rd-Person Player Bug
    _draw3DWorldEntities(canvas, size, horizonY, zBuffer, colWidth);

    // 4. Macro-Lens Optical Vignette, Chromatic Aberration & DoF Edge Softening
    _drawMacroLensVignette(canvas, size);

    canvas.restore();
  }

  void _drawRealisticSkyAndSoil(Canvas canvas, Size size, double horizonY) {
    final clampedHorizon = horizonY.clamp(0.0, size.height);

    // Natural Sunlit Meadow Sky Gradient blending smoothly into humid horizon haze
    final skyRect = Rect.fromLTWH(0, 0, size.width, clampedHorizon);
    if (skyRect.height > 0) {
      final skyPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1D4A6B),
            Color(0xFF457C9C),
            Color(0xFF6E8E84),
            humidUndergrowthFog,
          ],
        ).createShader(skyRect);
      canvas.drawRect(skyRect, skyPaint);

      // Soft Macro Bokeh Sunlight Orbs Filtering Through High Grass Canopy
      final bokehPaint = Paint()..color = const Color(0xFFFFF6D1).withValues(alpha: 0.12);
      for (int i = 0; i < 16; i++) {
        final bAngle = (i / 16.0) * math.pi * 2;
        double rel = (bAngle - world.playerAngle) % (math.pi * 2);
        if (rel > math.pi) rel -= math.pi * 2;
        if (rel < -math.pi) rel += math.pi * 2;
        final bx = size.width * 0.5 + (rel / fov) * size.width;
        final by = horizonY - (110.0 + (i % 5) * 65.0);
        if (by > -60 && by < clampedHorizon + 40) {
          final br = 22.0 + (i % 4) * 16.0;
          canvas.drawCircle(Offset(bx, by), br, bokehPaint);
        }
      }

      // Golden Sun with Warm Macro Halo
      double sunRelAngle = (-math.pi * 0.35 - world.playerAngle) % (math.pi * 2);
      if (sunRelAngle > math.pi) sunRelAngle -= math.pi * 2;
      if (sunRelAngle < -math.pi) sunRelAngle += math.pi * 2;
      final sunX = size.width * 0.5 + (sunRelAngle / fov) * size.width;
      final sunY = horizonY - size.height * 0.36;
      if (sunX > -220 && sunX < size.width + 220) {
        final sunHalo = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFFBEB).withValues(alpha: 0.90),
              const Color(0xFFDFF28D).withValues(alpha: 0.38),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 190));
        canvas.drawCircle(Offset(sunX, sunY), 190, sunHalo);
        canvas.drawCircle(Offset(sunX, sunY), 44, Paint()..color = const Color(0xFFFFFEF5));
      }

      // Multi-layered Distant Grass Skyline
      final farGrassPaint = Paint()..color = const Color(0xFF283B20).withValues(alpha: 0.65);
      final midGrassPaint = Paint()..color = const Color(0xFF1E2F17).withValues(alpha: 0.88);
      const numSkylineBlades = 72;
      for (int i = 0; i < numSkylineBlades; i++) {
        final bAngle = (i / numSkylineBlades) * math.pi * 2;
        double rel = (bAngle - world.playerAngle) % (math.pi * 2);
        if (rel > math.pi) rel -= math.pi * 2;
        if (rel < -math.pi) rel += math.pi * 2;

        final bx = size.width * 0.5 + (rel / fov) * size.width;
        if (bx < -90 || bx > size.width + 90) continue;

        final breeze = math.sin(world.totalTime * 1.3 + i * 0.65) * 18.0;
        final bWidth = 12.0 + (i % 4) * 6.0;
        final bHeight = 120.0 + ((i * 53) % 220);
        final path = Path()
          ..moveTo(bx - bWidth * 0.5, horizonY + 12)
          ..quadraticBezierTo(
            bx + breeze * 0.35,
            horizonY - bHeight * 0.55,
            bx + breeze,
            horizonY - bHeight,
          )
          ..lineTo(bx + bWidth * 0.5, horizonY + 12)
          ..close();
        canvas.drawPath(path, i.isEven ? farGrassPaint : midGrassPaint);
      }

      // Volumetric Canopy God Rays Streaming Downward through Grass Blades
      _drawCanopyGodRays(canvas, size, sunX, horizonY);
    }

    // PROCEDURAL MICRO-TERRAIN & GROUNDED DIRT FLOOR (Replacing flat striped ground)
    final floorRect = Rect.fromLTWH(0, clampedHorizon, size.width, size.height - clampedHorizon);
    if (floorRect.height > 0) {
      // 1. Base Soil Gradient: Humid undergrowth horizon -> Rich Loam Umber -> Dark Moist Peat
      final baseSoilPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            humidUndergrowthFog,
            Color(0xFF281C12),
            Color(0xFF1E140C),
            Color(0xFF120B06),
          ],
          stops: [0.0, 0.25, 0.65, 1.0],
        ).createShader(floorRect);
      canvas.drawRect(floorRect, baseSoilPaint);

      // 2. Procedural Multi-Octave Noise Perspective Ground Grid (Loamy Browns, Muted Umber, Moss)
      _drawProceduralPerspectiveDirt(canvas, size, horizonY, clampedHorizon);

      // 3. Dynamic Canopy Dappled Sunlight Decals Drifting on the Meadow Floor
      _drawGroundDappledSunlight(canvas, size, horizonY, clampedHorizon);
    }
  }

  /// Simulates angled volumetric sunlight shafts filtering through the tall grass canopy
  void _drawCanopyGodRays(Canvas canvas, Size size, double sunX, double horizonY) {
    const numRays = 6;
    final windDrift = math.sin(world.totalTime * 1.15) * 14.0;

    for (int r = 0; r < numRays; r++) {
      final rayFrac = (r - (numRays - 1) / 2.0);
      final rayOffset = rayFrac * (size.width * 0.18) + windDrift;
      final topX = (sunX * 0.45 + size.width * 0.5 * 0.55) + rayOffset * 0.65;
      final botX = topX + rayOffset * 1.5 + (r.isEven ? 45.0 : -35.0);

      final rayPath = Path()
        ..moveTo(topX - 18.0, -10.0)
        ..lineTo(topX + 26.0, -10.0)
        ..lineTo(botX + 85.0, size.height + 20)
        ..lineTo(botX - 45.0, size.height + 20)
        ..close();

      final rayPulse = 0.055 + 0.035 * math.sin(world.totalTime * 1.6 + r * 1.25);
      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFFBE8).withValues(alpha: rayPulse * 1.1),
            const Color(0xFFE8DEB2).withValues(alpha: rayPulse * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(rayPath, rayPaint);
    }
  }

  /// Procedural earthy soil texture mapped to the ground plane using multi-octave noise,
  /// blending dark loamy browns, muted umber, and subtle moss patches in 3D perspective.
  void _drawProceduralPerspectiveDirt(
    Canvas canvas,
    Size size,
    double horizonY,
    double clampedHorizon,
  ) {
    final floorHeight = size.height - clampedHorizon;
    if (floorHeight <= 0) return;

    const int numBands = 26;
    const int colsPerBand = 18;

    final camForwardX = math.cos(world.playerAngle);
    final camForwardY = math.sin(world.playerAngle);
    final camRightX = -camForwardY;
    final camRightY = camForwardX;

    for (int b = 0; b < numBands; b++) {
      final t0 = math.pow(b / numBands.toDouble(), 1.85).toDouble();
      final t1 = math.pow((b + 1) / numBands.toDouble(), 1.85).toDouble();

      final y0 = clampedHorizon + floorHeight * t0;
      final y1 = clampedHorizon + floorHeight * t1;
      final bandH = y1 - y0;
      if (bandH < 0.6) continue;

      final normY = ((y0 + y1) * 0.5 - horizonY) / size.height;
      final groundDepth = (0.78 / math.max(0.045, normY)).clamp(0.4, 26.0);
      final fogFactor = _computeExponentialFog(groundDepth);

      final lateralSpan = groundDepth * math.tan(fov * 0.5);

      for (int c = 0; c < colsPerBand; c++) {
        final cxFrac0 = c / colsPerBand.toDouble();
        final cxFrac1 = (c + 1) / colsPerBand.toDouble();

        final screenX0 = cxFrac0 * size.width;
        final screenX1 = cxFrac1 * size.width;
        final ndcX = (cxFrac0 + cxFrac1) - 1.0;

        final worldX = world.cameraPos.x +
            camForwardX * groundDepth +
            camRightX * ndcX * lateralSpan;
        final worldY = world.cameraPos.y +
            camForwardY * groundDepth +
            camRightY * ndcX * lateralSpan;

        // Sample cached multi-octave noise (0.0 to 1.0)
        final soilNoise = visualsCache.getSoilNoise(worldX, worldY);
        final mossNoise = visualsCache.getMossNoise(worldX, worldY);

        // Grounded earthy loam base
        final soilBase = Color.lerp(
          const Color(0xFF181008),
          const Color(0xFF302115),
          soilNoise,
        )!;

        // Granular umber highlights on soil ridges
        final umberColor = soilNoise > 0.60
            ? Color.lerp(soilBase, const Color(0xFF463220), (soilNoise - 0.60) / 0.40)!
            : soilBase;

        // Subtle, organic moss tinting (muted earthy olive-loam, never bright green!)
        Color patchColor;
        if (mossNoise > 0.70) {
          final mossT = ((mossNoise - 0.70) / 0.30).clamp(0.0, 1.0);
          patchColor = Color.lerp(
            umberColor,
            const Color(0xFF2B361B),
            mossT * 0.32,
          )!;
        } else {
          patchColor = umberColor;
        }

        // Blend with atmospheric distance fog
        final finalColor = Color.lerp(humidUndergrowthFog, patchColor, fogFactor)!;

        canvas.drawRect(
          Rect.fromLTRB(screenX0, y0, screenX1 + 0.5, y1 + 0.5),
          Paint()..color = finalColor,
        );
      }
    }
  }

  /// Procedural ground light-dapple decals drifting with grass sway
  void _drawGroundDappledSunlight(
    Canvas canvas,
    Size size,
    double horizonY,
    double clampedHorizon,
  ) {
    final floorH = size.height - clampedHorizon;
    if (floorH <= 0) return;

    final windSway = math.sin(world.totalTime * 1.2) * 12.0;

    for (int i = 0; i < 9; i++) {
      final dappleFrac = ((i * 37) % 100) / 100.0;
      final groundT = math.pow(0.25 + dappleFrac * 0.70, 1.6).toDouble();
      final dy = clampedHorizon + floorH * groundT;

      final dx = ((i * 83 + (world.totalTime * 6.0)) % size.width) + windSway;
      final dw = (32.0 + (i % 4) * 24.0) * groundT * 1.8;
      final dh = dw * 0.38;

      final dapplePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF6D8).withValues(alpha: 0.08 * groundT),
            const Color(0xFFEDE0A0).withValues(alpha: 0.03 * groundT),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCenter(center: Offset(dx, dy), width: dw, height: dh));

      canvas.drawOval(
        Rect.fromCenter(center: Offset(dx, dy), width: dw, height: dh),
        dapplePaint,
      );
    }
  }

  void _drawRealisticWallSlice(
    Canvas canvas,
    double x,
    double width,
    double top,
    double bottom,
    RayHit hit,
    double perpDist,
  ) {
    final height = bottom - top;
    if (height <= 0) return;

    final fogFactor = _computeExponentialFog(perpDist);
    final sunLightSide = hit.hitVertical ? 1.0 : 0.82;
    final cylinderShade = 0.76 + 0.24 * math.sin(hit.wallX * math.pi);

    final texCol = (hit.wallX * 16).floor();
    final grain = (_texHash(texCol + hit.mapX * 19, hit.mapY * 31) - 0.5) * 0.16;
    final lit = ((fogFactor * sunLightSide * cylinderShade) + grain).clamp(0.12, 1.0);

    // Render outer boundary as a dense wall of grass stems smoothly fading into humid fog
    final stemColor = Color.lerp(
      humidUndergrowthFog,
      Color.lerp(const Color(0xFF1B3614), const Color(0xFF568A35), lit)!,
      fogFactor,
    )!;
    canvas.drawRect(Rect.fromLTWH(x, top, width, height), Paint()..color = stemColor);

    if (texCol % 2 == 0) {
      final veinColor = Color.lerp(humidUndergrowthFog, const Color(0xFF84BA52), fogFactor)!
          .withValues(alpha: 0.42 * fogFactor);
      canvas.drawRect(
        Rect.fromLTWH(x, top + height * 0.04, width, height * 0.92),
        Paint()..color = veinColor,
      );
    }
  }

  void _draw3DWorldEntities(
    Canvas canvas,
    Size size,
    double horizonY,
    List<double> zBuffer,
    double colWidth,
  ) {
    final renderList = <_SortableRenderItem>[];
    final camX = world.cameraPos.x;
    final camY = world.cameraPos.y;
    final fwdX = math.cos(world.playerAngle);
    final fwdY = math.sin(world.playerAngle);

    // 1. Towering 3D "City of Grass" Stalks with Rapid Manhattan Distance Culling + Camera Frustum Dot Rejection
    for (final stalk in world.grassStalks) {
      final dx = stalk.pos.x - camX;
      final dy = stalk.pos.y - camY;
      if (dx.abs() > 22.0 || dy.abs() > 22.0) continue;

      // Reject stalks behind camera plane (sub-nanosecond dot product check)
      final dotFwd = dx * fwdX + dy * fwdY;
      if (dotFwd < -2.2) continue;

      final baseProj = _projectPoint(
        stalk.pos,
        -0.22,
        size,
        horizonY,
        maxNdcX: 1.8,
      );
      if (baseProj != null && baseProj.depth < 24.0) {
        if (baseProj.screenX < -180 || baseProj.screenX > size.width + 180) continue;
        renderList.add(_SortableRenderItem(
          depth: baseProj.depth,
          draw: () => _drawGrassStalk3D(
            canvas,
            stalk,
            baseProj,
            size,
            horizonY,
            zBuffer,
            colWidth,
          ),
        ));
      }
    }

    // 2. Procedural Micro-Debris Scattering with Fast Box Rejection
    for (final debris in visualsCache.microDebris) {
      if ((debris.pos.x - camX).abs() > 15.0 || (debris.pos.y - camY).abs() > 15.0) continue;
      final proj = _projectPoint(debris.pos, -0.22, size, horizonY);
      if (proj != null) {
        renderList.add(_SortableRenderItem(
          depth: proj.depth,
          draw: () => _drawMicroDebris3D(canvas, debris, proj, zBuffer, colWidth),
        ));
      }
    }

    // 3. Real-Life Backyard & Botanical 3D Props
    for (final prop in world.realLifeProps) {
      if ((prop.pos.x - camX).abs() > 28.0 || (prop.pos.y - camY).abs() > 28.0) continue;
      final zOff = prop.type == RealLifeObjectType.cloverBlossom ? -0.08 : -0.22;
      final proj = _projectPoint(prop.pos, zOff, size, horizonY);
      if (proj != null) {
        renderList.add(_SortableRenderItem(
          depth: proj.depth,
          draw: () => _drawRealLifeProp3D(canvas, prop, proj, zBuffer, colWidth),
        ));
      }
    }

    // 4. Roaming Mountable Insects in the Open World
    for (final mb in world.mountableBugs) {
      if ((mb.pos.x - camX).abs() > 28.0 || (mb.pos.y - camY).abs() > 28.0) continue;
      final zOff = mb.type == BugVehicleType.hornet ? 0.22 : -0.22;
      final proj = _projectPoint(mb.pos, zOff, size, horizonY);
      if (proj != null) {
        renderList.add(_SortableRenderItem(
          depth: proj.depth,
          draw: () => _drawWorldMountableBug(canvas, mb, proj, size, zBuffer, colWidth, horizonY),
        ));
      }
    }

    // 5. Friendly Colony NPC Ants (Mission Givers & Officers)
    for (final npc in world.npcAnts) {
      if ((npc.pos.x - camX).abs() > 28.0 || (npc.pos.y - camY).abs() > 28.0) continue;
      final proj = _projectPoint(npc.pos, -0.22, size, horizonY);
      if (proj != null) {
        renderList.add(_SortableRenderItem(
          depth: proj.depth,
          draw: () => _drawWorldNpcAnt(canvas, npc, proj, size, zBuffer, colWidth, horizonY),
        ));
      }
    }

    // 6. Natural Forage Items
    for (final item in world.forageItems) {
      if ((item.pos.x - camX).abs() > 24.0 || (item.pos.y - camY).abs() > 24.0) continue;
      final proj = _projectPoint(item.pos, -0.16, size, horizonY);
      if (proj != null) {
        renderList.add(_SortableRenderItem(
          depth: proj.depth,
          draw: () => _drawForageItem3D(canvas, item, proj, zBuffer, colWidth),
        ));
      }
    }

    // 7. Floating Sunlit Pollen & Spores with Near-Field Macro Bokeh
    for (final pt in world.particles) {
      final proj = _projectPoint(pt.pos, pt.z, size, horizonY);
      if (proj != null) {
        renderList.add(_SortableRenderItem(
          depth: proj.depth,
          draw: () => _drawPollenParticle3D(canvas, pt, proj, zBuffer, colWidth),
        ));
      }
    }

    // 8. Floating Field Notes
    for (final fn in world.floatingNotes) {
      final proj = _projectPoint(fn.pos, fn.z, size, horizonY);
      if (proj != null) {
        renderList.add(_SortableRenderItem(
          depth: proj.depth,
          draw: () => _drawFloatingNote3D(canvas, fn, proj, zBuffer, colWidth),
        ));
      }
    }

    // 9. 3rd-Person Player Character in Z-Sorted Queue (Properly occluded by foreground grass)
    final relPlayer = world.playerPos - world.cameraPos;
    final camForwardX = math.cos(world.playerAngle);
    final camForwardY = math.sin(world.playerAngle);
    final playerDepth = relPlayer.x * camForwardX + relPlayer.y * camForwardY;

    renderList.add(_SortableRenderItem(
      depth: playerDepth.clamp(0.15, 60.0),
      draw: () => _drawThirdPersonPlayerCharacter(canvas, size, horizonY),
    ));

    renderList.sort((a, b) => b.depth.compareTo(a.depth));
    for (final item in renderList) {
      item.draw();
    }
  }

  /// Procedurally renders micro-debris (pebbles, fallen twigs, dead leaf litter, dirt clods)
  /// with randomized rotation, scale, specular highlights, and contact drop shadows.
  void _drawMicroDebris3D(
    Canvas canvas,
    MicroDebrisItem item,
    _ProjectedPoint proj,
    List<double> zBuffer,
    double colWidth,
  ) {
    if (!_isVisibleAt(proj.screenX, proj.depth, zBuffer, colWidth)) return;

    final s = (proj.scale * 0.16 * item.scale).clamp(1.5, 42.0);
    if (s < 1.4) return;

    final fog = _computeExponentialFog(proj.depth);
    final cx = proj.screenX;
    final cy = proj.screenY;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(item.rotation);

    switch (item.type) {
      case MicroDebrisType.pebble:
        // Soft contact drop shadow
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.12, s * 0.22),
            width: s * 1.55,
            height: s * 0.78,
          ),
          Paint()..color = const Color(0xFF0C0704).withValues(alpha: 0.68 * fog),
        );
        // Pebble 3D rounded rock body with Blinn-Phong specular hotspot
        final pRect = Rect.fromCenter(center: Offset.zero, width: s * 1.35, height: s * 0.88);
        final pPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.38),
            colors: [
              Color.lerp(humidUndergrowthFog, item.highlightColor, fog)!,
              Color.lerp(humidUndergrowthFog, item.primaryColor, fog)!,
              Color.lerp(humidUndergrowthFog, item.secondaryColor, fog)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(pRect);
        canvas.drawOval(pRect, pPaint);
        // Micro specular glint
        if (s >= 5.0) {
          canvas.drawCircle(
            Offset(-s * 0.24, -s * 0.18),
            s * 0.14,
            Paint()..color = Colors.white.withValues(alpha: 0.75 * fog),
          );
        }
        break;

      case MicroDebrisType.twig:
        // Contact shadow along twig
        final shadowPaint = Paint()
          ..color = const Color(0xFF0C0704).withValues(alpha: 0.58 * fog)
          ..strokeWidth = (s * 0.32).clamp(1.2, 5.0)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(-s * 0.85, s * 0.18), Offset(s * 0.85, s * 0.25), shadowPaint);

        // Bark-textured slender twig with broken node
        final barkCol = Color.lerp(humidUndergrowthFog, item.primaryColor, fog)!;
        final twigPaint = Paint()
          ..color = barkCol
          ..strokeWidth = (s * 0.26).clamp(1.2, 4.5)
          ..strokeCap = StrokeCap.round;
        final midNode = Offset(s * 0.08, -s * 0.08);
        canvas.drawLine(Offset(-s * 0.85, 0), midNode, twigPaint);
        canvas.drawLine(midNode, Offset(s * 0.85, s * 0.06), twigPaint);

        // Exposed dry wood fibers at fractured end
        if (s >= 4.0) {
          canvas.drawCircle(
            Offset(s * 0.85, s * 0.06),
            s * 0.12,
            Paint()..color = Color.lerp(humidUndergrowthFog, item.highlightColor, fog)!,
          );
        }
        break;

      case MicroDebrisType.deadLeaf:
        // Curled dead leaf litter fragment
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.14, s * 0.18),
            width: s * 1.7,
            height: s * 0.72,
          ),
          Paint()..color = const Color(0xFF0C0704).withValues(alpha: 0.55 * fog),
        );

        final leafPath = Path()
          ..moveTo(-s * 0.9, 0)
          ..quadraticBezierTo(-s * 0.2, -s * 0.55, s * 0.7, -s * 0.15)
          ..quadraticBezierTo(s * 0.9, s * 0.1, s * 0.6, s * 0.42)
          ..quadraticBezierTo(0, s * 0.38, -s * 0.9, 0)
          ..close();

        final leafCol = Color.lerp(humidUndergrowthFog, item.primaryColor, fog)!;
        final underCol = Color.lerp(humidUndergrowthFog, item.secondaryColor, fog)!;
        final leafPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [leafCol, underCol],
          ).createShader(Rect.fromLTWH(-s, -s * 0.6, s * 2, s * 1.2));
        canvas.drawPath(leafPath, leafPaint);

        // Leaf central midrib vein
        if (s >= 5.0) {
          canvas.drawLine(
            Offset(-s * 0.75, 0),
            Offset(s * 0.65, 0),
            Paint()
              ..color = Color.lerp(humidUndergrowthFog, item.highlightColor, fog)!
                  .withValues(alpha: 0.65 * fog)
              ..strokeWidth = 1.0,
          );
        }
        break;

      case MicroDebrisType.dirtClod:
        // Rough loamy soil aggregate with granular specks
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.10, s * 0.16),
            width: s * 1.35,
            height: s * 0.75,
          ),
          Paint()..color = const Color(0xFF0C0704).withValues(alpha: 0.62 * fog),
        );

        final clodCol = Color.lerp(humidUndergrowthFog, item.primaryColor, fog)!;
        final deepCol = Color.lerp(humidUndergrowthFog, item.secondaryColor, fog)!;
        canvas.drawCircle(Offset(-s * 0.18, 0), s * 0.42, Paint()..color = clodCol);
        canvas.drawCircle(Offset(s * 0.18, -s * 0.08), s * 0.34, Paint()..color = deepCol);
        canvas.drawCircle(Offset(0, s * 0.12), s * 0.28, Paint()..color = clodCol);

        // Granular mineral specks
        if (s >= 5.5) {
          final speckCol = Color.lerp(humidUndergrowthFog, item.highlightColor, fog)!;
          canvas.drawCircle(Offset(-s * 0.12, -s * 0.14), s * 0.08, Paint()..color = speckCol);
          canvas.drawCircle(Offset(s * 0.10, s * 0.08), s * 0.06, Paint()..color = speckCol);
        }
        break;
    }

    canvas.restore();
  }

  void _drawGrassStalk3D(
    Canvas canvas,
    GrassStalk3D stalk,
    _ProjectedPoint baseProj,
    Size size,
    double horizonY,
    List<double> zBuffer,
    double colWidth,
  ) {
    final checkCol = (baseProj.screenX / colWidth).floor().clamp(0, numColumns - 1);
    if (baseProj.depth > zBuffer[checkCol] + 0.35) return;

    final fog = _computeExponentialFog(baseProj.depth);
    final windPhase = world.totalTime * 1.55 + stalk.swayPhase;
    final windSway = math.sin(windPhase) * 0.22;

    final archDirX = math.cos(stalk.archAngle + windSway * 0.4);
    final archDirY = math.sin(stalk.archAngle + windSway * 0.4);
    final archDist = stalk.archReach + math.sin(windPhase) * 0.16;

    final midWorldPos = Vec2(
      stalk.pos.x + archDirX * archDist * 0.38,
      stalk.pos.y + archDirY * archDist * 0.38,
    );
    final tipWorldPos = Vec2(
      stalk.pos.x + archDirX * archDist,
      stalk.pos.y + archDirY * archDist,
    );

    final midProj = _projectPoint(
      midWorldPos,
      stalk.height * 0.48,
      size,
      horizonY,
      maxNdcX: 3.5,
    );
    final tipProj = _projectPoint(
      tipWorldPos,
      stalk.height,
      size,
      horizonY,
      maxNdcX: 4.0,
    );

    final bx = baseProj.screenX;
    final by = baseProj.screenY;
    final stemBaseWidth = (baseProj.scale * stalk.baseWidth * 1.55).clamp(3.0, 72.0);

    // Multi-layer Soft Root-Crown Ambient Occlusion Shadow directly beneath grass base
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bx, by + stemBaseWidth * 0.16),
        width: stemBaseWidth * 3.4,
        height: stemBaseWidth * 1.1,
      ),
      Paint()..color = const Color(0xFF0C0804).withValues(alpha: 0.65 * fog),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bx, by + stemBaseWidth * 0.12),
        width: stemBaseWidth * 1.8,
        height: stemBaseWidth * 0.6,
      ),
      Paint()..color = const Color(0xFF060402).withValues(alpha: 0.85 * fog),
    );

    final baseCol = Color.lerp(humidUndergrowthFog, stalk.baseColor, fog)!;
    final midCol = Color.lerp(humidUndergrowthFog, stalk.midColor, fog)!;
    final tipCol = Color.lerp(humidUndergrowthFog, stalk.tipColor, fog)!;

    final mx = midProj?.screenX ?? (bx + math.sin(stalk.archAngle) * baseProj.scale * 0.45);
    final my = midProj?.screenY ?? (by - baseProj.scale * stalk.height * 0.52);
    final tx = tipProj?.screenX ?? (bx + math.sin(stalk.archAngle) * baseProj.scale * 1.05);
    final ty = tipProj?.screenY ?? (by - baseProj.scale * stalk.height);

    // Fast LOD for distant background grass stalks blending into atmospheric fog
    if (baseProj.depth > 12.0) {
      final distBladePath = Path()
        ..moveTo(bx, by)
        ..quadraticBezierTo(mx, my, tx, ty);
      canvas.drawPath(
        distBladePath,
        Paint()
          ..color = midCol
          ..style = PaintingStyle.stroke
          ..strokeWidth = (stemBaseWidth * 0.85).clamp(2.0, 15.0)
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // Fanning sub-blades of the grass clump
    final numBlades = stalk.subBlades;
    for (int b = 0; b < numBlades; b++) {
      final frac = numBlades == 1 ? 0.0 : (b / (numBlades - 1)) * 2.0 - 1.0;
      final bladeSpread = frac * baseProj.scale * 0.82;
      final bladeHeightScale = 0.70 + 0.30 * (1.0 - frac.abs() * 0.38);
      final bSway = math.sin(windPhase + b * 0.9) * baseProj.scale * 0.18;

      final bMidX = mx + bladeSpread * 0.48 + bSway * 0.4;
      final bMidY = by + (my - by) * bladeHeightScale;
      final bTipX = tx + bladeSpread * 1.15 + bSway;
      final bTipY = by + (ty - by) * bladeHeightScale + frac.abs() * baseProj.scale * 0.18;

      final bW = stemBaseWidth * (b == numBlades ~/ 2 ? 1.0 : 0.76);
      final bladePath = Path()
        ..moveTo(bx - bW * 0.5 + frac * bW * 0.35, by)
        ..quadraticBezierTo(bMidX - bW * 0.34, bMidY, bTipX, bTipY)
        ..quadraticBezierTo(bMidX + bW * 0.34, bMidY + bW * 0.08, bx + bW * 0.5 + frac * bW * 0.35, by)
        ..close();

      final topY = math.min(by, math.min(bMidY, bTipY));
      final botY = math.max(by, math.max(bMidY, bTipY));
      final shaderRect = Rect.fromLTRB(
        math.min(bx, bTipX) - bW,
        topY,
        math.max(bx, bTipX) + bW,
        math.max(topY + 4.0, botY),
      );

      final bladePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [baseCol, midCol, tipCol],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(shaderRect);

      canvas.drawPath(bladePath, bladePaint);

      // Sunlit vascular midrib vein
      if (bW >= 4.0) {
        final veinPath = Path()
          ..moveTo(bx + frac * bW * 0.35, by)
          ..quadraticBezierTo(bMidX, bMidY, bTipX, bTipY);
        canvas.drawPath(
          veinPath,
          Paint()
            ..color = const Color(0xFFD8F098).withValues(alpha: 0.45 * fog)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (bW * 0.14).clamp(1.0, 3.2),
        );
      }
    }

    // Culm node rings
    if (stemBaseWidth >= 4.5) {
      final nodeRingPaint = Paint()
        ..color = const Color(0xFF1E3612).withValues(alpha: 0.65 * fog)
        ..strokeWidth = (stemBaseWidth * 0.18).clamp(1.5, 4.5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(mx - stemBaseWidth * 0.38, my),
        Offset(mx + stemBaseWidth * 0.38, my),
        nodeRingPaint,
      );
    }

    // Botanical Crown
    final tipScale = (tipProj?.scale ?? baseProj.scale * 0.85) * 0.18;
    final crownRadius = tipScale.clamp(3.0, 55.0);

    switch (stalk.crownType) {
      case GrassCrownType.archingBlade:
        break;

      case GrassCrownType.seedPanicle:
        final panicleColor = Color.lerp(humidUndergrowthFog, const Color(0xFFD8B85B), fog)!;
        final glumeColor = Color.lerp(humidUndergrowthFog, const Color(0xFF9E7B2F), fog)!;
        for (int s = 0; s < 7; s++) {
          final t = s / 6.0;
          final sx = mx + (tx - mx) * (0.55 + t * 0.45);
          final sy = my + (ty - my) * (0.55 + t * 0.45);
          final side = s.isEven ? 1.0 : -1.0;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(sx + side * crownRadius * 0.32, sy),
              width: crownRadius * 0.68,
              height: crownRadius * 0.32,
            ),
            Paint()..color = s.isEven ? panicleColor : glumeColor,
          );
        }
        break;

      case GrassCrownType.cloverUmbrella:
        final leafCol = Color.lerp(humidUndergrowthFog, const Color(0xFF4C852E), fog)!;
        final veinCol = Color.lerp(humidUndergrowthFog, const Color(0xFFA5D678), fog)!;
        for (int lobe = -1; lobe <= 1; lobe++) {
          final lx = tx + lobe * crownRadius * 0.78;
          final ly = ty + (lobe == 0 ? -crownRadius * 0.28 : crownRadius * 0.12);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(lx, ly), width: crownRadius * 1.15, height: crownRadius * 0.62),
            Paint()..color = leafCol,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(lx, ly), width: crownRadius * 0.75, height: crownRadius * 0.35),
            Paint()
              ..color = veinCol.withValues(alpha: 0.55 * fog)
              ..style = PaintingStyle.stroke
              ..strokeWidth = (crownRadius * 0.08).clamp(1.0, 2.5),
          );
        }
        break;

      case GrassCrownType.dandelionTower:
        final pappusHalo = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.90 * fog),
              const Color(0xFFF2EED8).withValues(alpha: 0.55 * fog),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(tx, ty), radius: crownRadius * 1.55));
        canvas.drawCircle(Offset(tx, ty), crownRadius * 1.55, pappusHalo);
        canvas.drawCircle(
          Offset(tx, ty),
          crownRadius * 0.36,
          Paint()..color = Color.lerp(humidUndergrowthFog, const Color(0xFF786236), fog)!,
        );
        final spokePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.72 * fog)
          ..strokeWidth = 1.2;
        for (int k = 0; k < 10; k++) {
          final a = (k / 10.0) * math.pi * 2;
          canvas.drawLine(
            Offset(tx, ty),
            Offset(tx + math.cos(a) * crownRadius * 1.25, ty + math.sin(a) * crownRadius * 1.25),
            spokePaint,
          );
        }
        break;

      case GrassCrownType.dewdropBlade:
        final dropR = (crownRadius * 0.45).clamp(2.5, 22.0);
        final dropCenter = Offset(tx, ty + dropR * 0.75);
        final dropRect = Rect.fromCircle(center: dropCenter, radius: dropR);
        canvas.drawCircle(
          dropCenter,
          dropR,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.35),
              colors: [
                Colors.white.withValues(alpha: 0.95 * fog),
                const Color(0xFFA8E6CF).withValues(alpha: 0.80 * fog),
                const Color(0xFF2B6E52).withValues(alpha: 0.85 * fog),
              ],
            ).createShader(dropRect),
        );
        canvas.drawCircle(
          Offset(dropCenter.dx - dropR * 0.3, dropCenter.dy - dropR * 0.3),
          dropR * 0.28,
          Paint()..color = Colors.white.withValues(alpha: 0.95 * fog),
        );
        break;
    }
  }

  void _drawRealLifeProp3D(
    Canvas canvas,
    RealLifeProp3D prop,
    _ProjectedPoint proj,
    List<double> zBuffer,
    double colWidth,
  ) {
    if (!_isVisibleAt(proj.screenX, proj.depth, zBuffer, colWidth)) return;
    final s = (proj.scale * 0.24 * prop.scale).clamp(3.0, 160.0);
    if (s < 3.5) return;

    final fog = _computeExponentialFog(proj.depth);
    final cx = proj.screenX;
    final cy = proj.screenY;

    canvas.save();

    switch (prop.type) {
      case RealLifeObjectType.pennyCoin:
        final coinW = s * 1.45;
        final coinH = s * 0.58;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + coinH * 0.18), width: coinW * 1.15, height: coinH * 1.15),
          Paint()..color = const Color(0xFF0C0704).withValues(alpha: 0.70 * fog),
        );
        final coinRect = Rect.fromCenter(center: Offset(cx, cy), width: coinW, height: coinH);
        final copperPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(humidUndergrowthFog, const Color(0xFFE09563), fog)!,
              Color.lerp(humidUndergrowthFog, const Color(0xFFA85832), fog)!,
              Color.lerp(humidUndergrowthFog, const Color(0xFF5E2D16), fog)!,
              Color.lerp(humidUndergrowthFog, const Color(0xFFC97A4B), fog)!,
            ],
          ).createShader(coinRect);
        canvas.drawOval(coinRect, copperPaint);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: coinW * 0.88, height: coinH * 0.84),
          Paint()
            ..color = Color.lerp(humidUndergrowthFog, const Color(0xFF4A2210), fog)!
            ..style = PaintingStyle.stroke
            ..strokeWidth = (s * 0.04).clamp(1.0, 3.0),
        );
        break;

      case RealLifeObjectType.glassMarble:
        final r = s * 0.62;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + r * 0.35, cy + r * 0.78), width: r * 2.0, height: r * 0.75),
          Paint()..color = const Color(0xFF0C0704).withValues(alpha: 0.62 * fog),
        );
        final marbleRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
        final glassPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            colors: [
              Colors.white.withValues(alpha: 0.90 * fog),
              Color.lerp(humidUndergrowthFog, const Color(0xFF3B9E78), fog)!.withValues(alpha: 0.80),
              Color.lerp(humidUndergrowthFog, const Color(0xFF0E3D2F), fog)!.withValues(alpha: 0.90),
            ],
          ).createShader(marbleRect);
        canvas.drawCircle(Offset(cx, cy), r, glassPaint);
        break;

      case RealLifeObjectType.bottleCap:
        final capW = s * 1.3;
        final capH = s * 0.62;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + capH * 0.22), width: capW * 1.15, height: capH * 0.95),
          Paint()..color = const Color(0xFF0C0704).withValues(alpha: 0.70 * fog),
        );
        for (int i = -5; i <= 5; i++) {
          final tx = cx + (i / 5.5) * capW * 0.46;
          canvas.drawRect(
            Rect.fromCenter(center: Offset(tx, cy + capH * 0.14), width: capW * 0.07, height: capH * 0.45),
            Paint()..color = Color.lerp(humidUndergrowthFog, i.isEven ? const Color(0xFFB8BEC4) : const Color(0xFF686E75), fog)!,
          );
        }
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy - capH * 0.06), width: capW * 0.92, height: capH * 0.68),
          Paint()..color = Color.lerp(humidUndergrowthFog, const Color(0xFFB82925), fog)!,
        );
        break;

      case RealLifeObjectType.terracottaShard:
        final path = Path()
          ..moveTo(cx - s * 0.9, cy + s * 0.25)
          ..quadraticBezierTo(cx, cy - s * 0.55, cx + s * 0.85, cy + s * 0.15)
          ..lineTo(cx + s * 0.55, cy + s * 0.42)
          ..quadraticBezierTo(cx, cy - s * 0.1, cx - s * 0.65, cy + s * 0.42)
          ..close();
        canvas.drawPath(path, Paint()..color = Color.lerp(humidUndergrowthFog, const Color(0xFFB55A38), fog)!);
        break;

      case RealLifeObjectType.gardenKey:
        final brassPaint = Paint()
          ..color = Color.lerp(humidUndergrowthFog, const Color(0xFFB89644), fog)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = (s * 0.11).clamp(1.5, 5.0)
          ..strokeCap = StrokeCap.round;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - s * 0.55, cy), width: s * 0.65, height: s * 0.38),
          brassPaint,
        );
        canvas.drawLine(Offset(cx - s * 0.22, cy), Offset(cx + s * 0.75, cy), brassPaint);
        break;

      case RealLifeObjectType.fallenOakLeaf:
        final leafRect = Rect.fromCenter(center: Offset(cx, cy), width: s * 1.35, height: s * 0.52);
        final leafPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(humidUndergrowthFog, const Color(0xFF9E4B1E), fog)!,
              Color.lerp(humidUndergrowthFog, const Color(0xFFC47A2C), fog)!,
              Color.lerp(humidUndergrowthFog, const Color(0xFF6E3212), fog)!,
            ],
          ).createShader(leafRect);
        canvas.drawOval(leafRect, leafPaint);
        break;

      case RealLifeObjectType.riverPebble:
        final pRect = Rect.fromCenter(center: Offset(cx, cy), width: s * 0.95, height: s * 0.58);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + s * 0.14), width: s * 1.1, height: s * 0.6),
          Paint()..color = const Color(0xFF0C0704).withValues(alpha: 0.65 * fog),
        );
        canvas.drawOval(
          pRect,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.35),
              colors: [
                Color.lerp(humidUndergrowthFog, const Color(0xFFD9D4CA), fog)!,
                Color.lerp(humidUndergrowthFog, const Color(0xFF8C857B), fog)!,
                Color.lerp(humidUndergrowthFog, const Color(0xFF4A453E), fog)!,
              ],
            ).createShader(pRect),
        );
        break;

      case RealLifeObjectType.cloverBlossom:
        final stemPaint = Paint()
          ..color = Color.lerp(humidUndergrowthFog, const Color(0xFF46732D), fog)!
          ..strokeWidth = (s * 0.08).clamp(1.5, 4.0);
        canvas.drawLine(Offset(cx, cy + s * 0.45), Offset(cx, cy - s * 0.35), stemPaint);
        canvas.drawCircle(
          Offset(cx, cy - s * 0.42),
          s * 0.32,
          Paint()..color = Color.lerp(humidUndergrowthFog, const Color(0xFFF5EBF0), fog)!,
        );
        break;

      case RealLifeObjectType.pineCone:
        final coneW = s * 0.85;
        final coneH = s * 0.95;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: coneW, height: coneH),
          Paint()..color = Color.lerp(humidUndergrowthFog, const Color(0xFF422814), fog)!,
        );
        break;

      case RealLifeObjectType.rainPuddle:
        final puddleW = s * 2.6;
        final puddleH = s * 0.72;
        final puddleRect = Rect.fromCenter(center: Offset(cx, cy), width: puddleW, height: puddleH);
        canvas.drawOval(
          puddleRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF6B9EBD).withValues(alpha: 0.68 * fog),
                const Color(0xFFD9C79E).withValues(alpha: 0.58 * fog),
                const Color(0xFF2B424F).withValues(alpha: 0.72 * fog),
              ],
            ).createShader(puddleRect),
        );
        break;
    }

    canvas.restore();
  }

  _ProjectedPoint? _projectPoint(
    Vec2 worldPt,
    double zOffset,
    Size size,
    double horizonY, {
    double maxNdcX = 1.35,
  }) {
    final rel = worldPt - world.cameraPos;
    final forwardX = math.cos(world.playerAngle);
    final forwardY = math.sin(world.playerAngle);
    final rightX = -forwardY;
    final rightY = forwardX;

    final depth = rel.x * forwardX + rel.y * forwardY;
    if (depth <= 0.12) return null;

    final side = rel.x * rightX + rel.y * rightY;
    final halfFovTan = math.tan(fov * 0.5);
    final ndcX = side / (depth * halfFovTan);
    if (ndcX < -maxNdcX || ndcX > maxNdcX) return null;

    final screenX = (ndcX + 1.0) * 0.5 * size.width;
    final scale = (size.height / depth) * 0.92;
    final relativeZ = zOffset - world.cameraZ;
    final screenY = horizonY - relativeZ * scale;

    return _ProjectedPoint(
      screenX: screenX,
      screenY: screenY,
      depth: depth,
      scale: scale,
    );
  }

  bool _isVisibleAt(double screenX, double depth, List<double> zBuffer, double colWidth) {
    final col = (screenX / colWidth).floor();
    if (col < 0 || col >= numColumns) return false;
    return depth < zBuffer[col] + 0.18;
  }

  void _drawWorldMountableBug(
    Canvas canvas,
    MountableBug bug,
    _ProjectedPoint proj,
    Size size,
    List<double> zBuffer,
    double colWidth,
    double horizonY,
  ) {
    if (!_isVisibleAt(proj.screenX, proj.depth, zBuffer, colWidth)) {
      final leftVis = _isVisibleAt(proj.screenX - proj.scale * 0.25, proj.depth, zBuffer, colWidth);
      final rightVis = _isVisibleAt(proj.screenX + proj.scale * 0.25, proj.depth, zBuffer, colWidth);
      if (!leftVis && !rightVis) return;
    }

    final spriteScale = (proj.scale * 0.36 * bug.spec.sizeMultiplier).clamp(6.0, 260.0);
    if (spriteScale < 6.0) return;

    // Project ground position beneath wild bug for dynamic ambient occlusion shadow
    final groundProj = _projectPoint(bug.pos, -0.22, size, horizonY);
    final groundX = groundProj?.screenX ?? proj.screenX;
    final groundY = groundProj?.screenY ?? proj.screenY;
    final groundAnchor = Offset(groundX, groundY);

    // Full 3D camera-relative viewing azimuth
    final toBug = bug.pos - world.cameraPos;
    final camToBugAngle = math.atan2(toBug.y, toBug.x);
    var viewYaw = bug.angle - camToBugAngle;
    while (viewYaw > math.pi) {
      viewYaw -= math.pi * 2;
    }
    while (viewYaw < -math.pi) {
      viewYaw += math.pi * 2;
    }

    final pitchAngle = (0.42 - world.playerPitch * 0.35).clamp(0.15, 0.85);
    final altitude = bug.type == BugVehicleType.hornet ? 0.38 : 0.0;

    _drawRealisticInsectModel(
      canvas,
      groundAnchor: groundAnchor,
      bodyAnchor: Offset(proj.screenX, proj.screenY),
      scale: spriteScale,
      type: bug.type,
      walkPhase: bug.walkPhase,
      viewYaw: viewYaw,
      pitchAngle: pitchAngle,
      hasAntRider: false,
      attackAnim: bug.attackPhase,
      hitFlash: bug.hitFlashTimer > 0,
      altitude: altitude,
      worldDepth: proj.depth,
    );

    final distToPlayer = bug.pos.distanceTo(world.playerPos);
    if (distToPlayer < 8.5) {
      final isMountableNow = distToPlayer <= 2.6;
      final label = isMountableNow
          ? 'MOUNT / ATTACK ${bug.spec.commonName.toUpperCase()}'
          : bug.spec.commonName;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: bug.hitFlashTimer > 0
                ? const Color(0xFFFF8566)
                : (isMountableNow ? const Color(0xFFFFF3C4) : const Color(0xFFE6DEC8)),
            fontSize: (13.0 / math.max(0.7, proj.depth * 0.35)).clamp(9.5, 13.5),
            fontWeight: isMountableNow ? FontWeight.w800 : FontWeight.w600,
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelY = groundY - spriteScale * 0.88 - tp.height;
      tp.paint(
        canvas,
        Offset(groundX - tp.width * 0.5, labelY),
      );

      final barW = (spriteScale * 0.72).clamp(36.0, 96.0);
      const barH = 5.0;
      final barRect = Rect.fromCenter(
        center: Offset(groundX, labelY - 6.0),
        width: barW,
        height: barH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
        Paint()..color = const Color(0xCC140E08),
      );
      final hpRatio = (bug.health / bug.maxHealth).clamp(0.0, 1.0);
      final hpColor = hpRatio > 0.5
          ? const Color(0xFF8AB858)
          : (hpRatio > 0.25 ? const Color(0xFFE6A83E) : const Color(0xFFE05238));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barRect.left, barRect.top, barW * hpRatio, barH),
          const Radius.circular(3),
        ),
        Paint()..color = hpColor,
      );
    }
  }

  void _drawThirdPersonPlayerCharacter(Canvas canvas, Size size, double horizonY) {
    final bobY = math.sin(world.walkBobPhase) * 3.5 * world.walkBobIntensity;

    // Stable 3rd-person screen center framing: character is always comfortably centered in view
    final pitchShift = (world.playerPitch * size.height * 0.28);
    final charCenterX = size.width * 0.5;

    // Perspective scale calculation from camera distance
    final camDist = math.max(0.65, world.cameraOrbitDist);
    final baseProjScale = (size.height / camDist) * 0.92;

    // Project the terrain floor directly beneath the player to firmly ground the character on dirt
    final groundSoilProj = _projectPoint(
      world.playerPos,
      -0.22,
      size,
      horizonY,
      maxNdcX: 2.2,
    );
    final groundX = groundSoilProj?.screenX ?? charCenterX;
    final maxGroundY = size.height * 0.82;
    final groundY = (groundSoilProj?.screenY ?? (horizonY + size.height * 0.35))
        .clamp(size.height * 0.42, maxGroundY);
    final groundAnchor = Offset(groundX, groundY);

    var viewYaw = (world.bodyYaw - world.playerAngle);
    while (viewYaw > math.pi) {
      viewYaw -= math.pi * 2;
    }
    while (viewYaw < -math.pi) {
      viewYaw += math.pi * 2;
    }

    final pitchAngle = (0.42 - world.playerPitch * 0.35).clamp(0.15, 0.85);

    if (world.mountedVehicle != null) {
      final spec = world.currentVehicleSpec!;
      final bugScale = (baseProjScale * 0.36 * spec.sizeMultiplier).clamp(70.0, 240.0);
      final isFlying = spec.canFly;
      final altitude = isFlying
          ? math.max(0.35, world.playerZ - 0.42 + 0.35)
          : math.max(0.0, world.playerZ - spec.rideElevation);

      // Body anchor in 3rd-person view
      final Offset effectiveBodyAnchor;
      final Offset effectiveGroundAnchor;

      if (isFlying) {
        // Flying Hornet stays centered in 3rd-person view
        final flyingCenterY = ((size.height * 0.56) + pitchShift).clamp(size.height * 0.28, size.height * 0.72);
        effectiveBodyAnchor = Offset(charCenterX, flyingCenterY + bobY);
        // Ground shadow beneath the hornet scales with flight altitude
        final groundShadowY = groundSoilProj?.screenY ?? (flyingCenterY + altitude * bugScale * 1.5);
        effectiveGroundAnchor = Offset(charCenterX, groundShadowY);
      } else {
        // Ground insects (Rhino Beetle, Stag Beetle, Wolf Spider, Grasshopper)
        final leapPx = (altitude * baseProjScale * 0.70).clamp(0.0, size.height * 0.35);
        // Firmly planted on dirt at groundY; lifts upward during leaps!
        effectiveBodyAnchor = Offset(groundX, groundY - leapPx + bobY);
        effectiveGroundAnchor = groundAnchor;
      }

      _drawRealisticInsectModel(
        canvas,
        groundAnchor: effectiveGroundAnchor,
        bodyAnchor: effectiveBodyAnchor,
        scale: bugScale,
        type: world.mountedVehicle!,
        walkPhase: world.walkBobPhase,
        viewYaw: viewYaw,
        pitchAngle: pitchAngle,
        hasAntRider: true,
        attackAnim: world.attackAnim,
        hitFlash: false,
        altitude: altitude,
        worldDepth: camDist,
      );
    } else {
      final antScale = (baseProjScale * 0.125).clamp(36.0, 85.0);
      // When jumping on foot: lifts up smoothly on screen; when on ground: feet firmly planted on dirt at groundY
      final leapPx = (world.playerZ * baseProjScale * 0.70).clamp(0.0, size.height * 0.35);
      final antAnchor = Offset(groundX, groundY - leapPx + bobY);

      _drawRealisticAntModel(
        canvas,
        center: antAnchor,
        groundAnchor: groundAnchor,
        scale: antScale,
        walkPhase: world.walkBobPhase,
        walkIntensity: world.walkBobIntensity,
        relYaw: viewYaw,
        pitchAngle: pitchAngle,
        pinchAnim: world.mandiblePinchAnim,
        shadowDropPx: leapPx,
        groundY: groundY,
      );
    }
  }

  /// Renders a Colony NPC Ant in the 3D world with interactive quest status badges
  void _drawWorldNpcAnt(
    Canvas canvas,
    NpcAnt npc,
    _ProjectedPoint proj,
    Size size,
    List<double> zBuffer,
    double colWidth,
    double horizonY,
  ) {
    if (!_isVisibleAt(proj.screenX, proj.depth, zBuffer, colWidth)) return;

    final scale = (proj.scale * 0.40).clamp(5.0, 75.0);
    final cx = proj.screenX;
    final cy = proj.screenY;
    final fog = _computeExponentialFog(proj.depth);

    // Full 3D camera-relative viewing azimuth
    final toNpc = npc.pos - world.cameraPos;
    final camToNpcAngle = math.atan2(toNpc.y, toNpc.x);
    var viewYaw = npc.angle - camToNpcAngle;
    while (viewYaw > math.pi) {
      viewYaw -= math.pi * 2;
    }
    while (viewYaw < -math.pi) {
      viewYaw += math.pi * 2;
    }
    final pitchAngle = (0.42 - world.playerPitch * 0.35).clamp(0.15, 0.85);

    // Contact drop shadow on ground plane
    final groundProj = _projectPoint(npc.pos, -0.22, size, horizonY);
    final groundAnchor = Offset(groundProj?.screenX ?? cx, groundProj?.screenY ?? cy);

    // Draw realistic chitin ant body with NPC ranking colors
    _drawRealisticAntModel(
      canvas,
      center: Offset(cx, cy),
      groundAnchor: groundAnchor,
      scale: scale,
      walkPhase: npc.walkPhase,
      walkIntensity: 0.25,
      relYaw: viewYaw,
      pitchAngle: pitchAngle,
      pinchAnim: 0.0,
      customChitin: Color.lerp(humidUndergrowthFog, npc.chitinColor, fog)!,
      customCrest: Color.lerp(humidUndergrowthFog, npc.crestColor, fog)!,
      fog: fog,
    );

    // Floating Interactive 3D Dialogue Badge / Name Tag
    if (proj.depth < 18.0) {
      final badgeY = proj.screenY - scale * 0.75;
      final alpha = ((18.0 - proj.depth) / 10.0).clamp(0.0, 1.0) * fog;

      // Mission indicator icon:
      // Green checkmark if completed/claimable, Amber '!' if available, subtle '💬' if active/idle
      String iconText = '💬';
      Color badgeBg = const Color(0xD92E2114);
      Color badgeBorder = const Color(0xFFD9C398);

      if (npc.hasClaimableMission) {
        iconText = '✓';
        badgeBg = const Color(0xEB3B5C1C);
        badgeBorder = const Color(0xFFA8E07B);
      } else if (npc.hasAvailableMission) {
        iconText = '!';
        badgeBg = const Color(0xEB6E4716);
        badgeBorder = const Color(0xFFFFD54F);
      }

      // Draw floating badge circle
      final badgePaint = Paint()..color = badgeBg.withValues(alpha: alpha);
      final borderPaint = Paint()
        ..color = badgeBorder.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      canvas.drawCircle(Offset(proj.screenX, badgeY - 14), 11.0, badgePaint);
      canvas.drawCircle(Offset(proj.screenX, badgeY - 14), 11.0, borderPaint);

      final iconTp = TextPainter(
        text: TextSpan(
          text: iconText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: alpha),
            fontSize: 12.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconTp.paint(
        canvas,
        Offset(proj.screenX - iconTp.width * 0.5, badgeY - 14 - iconTp.height * 0.5),
      );

      // Name & Rank Tag
      final nameTp = TextPainter(
        text: TextSpan(
          text: npc.name,
          style: TextStyle(
            color: const Color(0xFFF5EBD6).withValues(alpha: alpha),
            fontSize: 11.0,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: alpha * 0.9),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      nameTp.paint(canvas, Offset(proj.screenX - nameTp.width * 0.5, badgeY + 1));
    }
  }

  /// Renders Red Wood Ant (Formica rufa) in true 3D using vector landmark projection,
  /// with Blinn-Phong chitin specularity, faux subsurface scattering (SSS) amber edge glow,
  /// articulated joints, 12-segmented waving antennae, scissor mandibles, and painter's depth sorting.
  void _drawRealisticAntModel(
    Canvas canvas, {
    required Offset center,
    Offset? groundAnchor,
    required double scale,
    required double walkPhase,
    required double walkIntensity,
    required double relYaw,
    double pitchAngle = 0.38,
    required double pinchAnim,
    double shadowDropPx = 0.0,
    double? groundY,
    Color? customChitin,
    Color? customCrest,
    double fog = 1.0,
    bool drawShadow = true,
  }) {
    if (drawShadow) {
      final effectiveGround = groundAnchor ??
          (groundY != null ? Offset(center.dx, groundY) : Offset(center.dx, center.dy + shadowDropPx));
      final heightRatio = (shadowDropPx / (scale * 1.8)).clamp(0.0, 3.5);
      final shadowRadiusExpansion = 1.0 + heightRatio * 0.45;
      final shadowOpacity = ((0.46 / (1.0 + heightRatio * 1.8)) * fog).clamp(0.06, 0.46);

      // 1. Soft Dynamic Drop Shadow Penumbra (Broad outer blur, feathered to 0 at perimeter)
      final penumbraWidth = scale * 2.20 * shadowRadiusExpansion;
      final penumbraHeight = scale * 0.90 * shadowRadiusExpansion;
      final penumbraRadius = penumbraWidth * 0.5;
      final penumbraYRatio = penumbraHeight / penumbraWidth;

      canvas.save();
      canvas.translate(effectiveGround.dx, effectiveGround.dy);
      canvas.scale(1.0, penumbraYRatio);

      final shadowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: shadowOpacity * 0.72),
            Colors.black.withValues(alpha: shadowOpacity * 0.38),
            Colors.black.withValues(alpha: shadowOpacity * 0.10),
            Colors.transparent,
          ],
          stops: const [0.0, 0.40, 0.75, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset.zero,
            radius: penumbraRadius,
          ),
        );
      canvas.drawCircle(Offset.zero, penumbraRadius, shadowPaint);
      canvas.restore();

      // 2. Soft Blurred Contact Occlusion Core Shadow (smooth radial falloff, zero hard edge)
      final contactAlpha = (1.0 - (heightRatio / 0.50)).clamp(0.0, 1.0) * 0.50 * fog;
      if (contactAlpha > 0.01) {
        final coreWidth = scale * 1.25 * (1.0 + heightRatio * 0.25);
        final coreHeight = scale * 0.50 * (1.0 + heightRatio * 0.25);
        final coreRadius = coreWidth * 0.5;
        final coreYRatio = coreHeight / coreWidth;

        canvas.save();
        canvas.translate(effectiveGround.dx, effectiveGround.dy);
        canvas.scale(1.0, coreYRatio);

        final coreShadowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: contactAlpha * 0.75),
              Colors.black.withValues(alpha: contactAlpha * 0.38),
              Colors.black.withValues(alpha: contactAlpha * 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.70, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset.zero,
              radius: coreRadius,
            ),
          );
        canvas.drawCircle(Offset.zero, coreRadius, coreShadowPaint);
        canvas.restore();
      }
    }

    // 2. 3D Landmark Projections
    final cosPsi = math.cos(relYaw);
    final sinPsi = math.sin(relYaw);
    final cosBeta = math.cos(pitchAngle);
    final sinBeta = math.sin(pitchAngle);

    final fwdScrX = sinPsi;
    final fwdScrY = -cosPsi * sinBeta;
    final bodyAngle = math.atan2(fwdScrY, fwdScrX);

    // Leg Paints
    final femurCoreColor = customChitin != null
        ? Color.lerp(customChitin, Colors.black, 0.60)!
        : const Color(0xFF38150B);
    final femurCorePaint = Paint()
      ..color = Color.lerp(humidUndergrowthFog, femurCoreColor, fog)!
      ..strokeWidth = (scale * 0.055).clamp(1.6, 6.0)
      ..strokeCap = StrokeCap.round;

    final femurSssPaint = Paint()
      ..color = const Color(0xFFFF6E24).withValues(alpha: 0.65 * fog)
      ..strokeWidth = (scale * 0.020).clamp(0.8, 2.4)
      ..strokeCap = StrokeCap.round;

    final tibiaCoreColor = customChitin != null
        ? Color.lerp(customChitin, Colors.black, 0.75)!
        : const Color(0xFF220C06);
    final tibiaCorePaint = Paint()
      ..color = Color.lerp(humidUndergrowthFog, tibiaCoreColor, fog)!
      ..strokeWidth = (scale * 0.042).clamp(1.2, 4.8)
      ..strokeCap = StrokeCap.round;

    final tibiaSssPaint = Paint()
      ..color = const Color(0xFFE85818).withValues(alpha: 0.55 * fog)
      ..strokeWidth = (scale * 0.016).clamp(0.7, 2.0)
      ..strokeCap = StrokeCap.round;

    final footContactShadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.36 * fog);

    void drawLegsForSide(int side) {
      for (int pair = -1; pair <= 1; pair++) {
        final tripodPhase = walkPhase + ((side * pair > 0) ? 0.0 : math.pi);
        final stride = math.sin(tripodPhase) * walkIntensity * scale * 0.12;
        final lift = math.max(0.0, math.cos(tripodPhase)) * walkIntensity * scale * 0.08;

        final xBase = pair == -1 ? 0.08 : (pair == 0 ? -0.01 : -0.10);
        final coxa = _projectBugLandmark(
          anchor: center,
          x: xBase,
          y: side * 0.08,
          z: 0.20,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        final knee = _projectBugLandmark(
          anchor: center,
          x: xBase + (pair == -1 ? 0.06 : (pair == 0 ? 0.01 : -0.05)),
          y: side * (0.24 + (pair == 1 ? 0.04 : 0.0)),
          z: 0.28 + (lift / scale),
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        final tarsus = _projectBugLandmark(
          anchor: center,
          x: xBase + (pair == -1 ? 0.14 : (pair == 0 ? 0.0 : -0.14)) + (stride / scale),
          y: side * (0.30 + (pair == 0 ? 0.04 : 0.0)),
          z: 0.02,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        // Foot contact shadow when walking on or near the ground
        if (drawShadow && lift < scale * 0.03 && shadowDropPx < 6.0) {
          canvas.drawOval(
            Rect.fromCenter(center: tarsus, width: scale * 0.12, height: scale * 0.05),
            footContactShadowPaint,
          );
        }

        // Femur: core chitin + backlit SSS translucent rim
        canvas.drawLine(coxa, knee, femurCorePaint);
        canvas.drawLine(coxa, knee, femurSssPaint);

        // Tibia: core chitin + amber rim glow
        canvas.drawLine(knee, tarsus, tibiaCorePaint);
        canvas.drawLine(knee, tarsus, tibiaSssPaint);

        // Hardened articular knee joint ring & crevice
        if (scale >= 20.0) {
          canvas.drawCircle(knee, (scale * 0.032).clamp(1.0, 3.5), Paint()..color = const Color(0xFF0F0603));
          canvas.drawCircle(knee, (scale * 0.020).clamp(0.7, 2.2), Paint()..color = const Color(0xFF9E5A3C));
        }
      }
    }

    void drawHeadAndMouthparts() {
      final headCenter = _projectBugLandmark(
        anchor: center,
        x: 0.28,
        y: 0.0,
        z: 0.22,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      // Powerful sclerotized mandibles with translucent razor cutting edges
      final pinchOffset = pinchAnim * 0.04;
      for (int side in [-1, 1]) {
        final mBase = _projectBugLandmark(
          anchor: center,
          x: 0.35,
          y: side * 0.06,
          z: 0.17,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final mTip = _projectBugLandmark(
          anchor: center,
          x: 0.44 + pinchOffset,
          y: side * (0.02 - pinchOffset * 0.6),
          z: 0.14,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawLine(
          mBase,
          mTip,
          Paint()
            ..color = const Color(0xFF2C0F06)
            ..strokeWidth = (scale * 0.038).clamp(1.4, 4.2)
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          mBase,
          mTip,
          Paint()
            ..color = const Color(0xFFFF9E3D).withValues(alpha: 0.75 * fog)
            ..strokeWidth = (scale * 0.016).clamp(0.8, 2.0)
            ..strokeCap = StrokeCap.round,
        );
      }

      // Cranial head capsule with Blinn-Phong specular hotspot
      canvas.save();
      canvas.translate(headCenter.dx, headCenter.dy);
      canvas.rotate(bodyAngle);

      final headRect = Rect.fromCenter(
        center: Offset.zero,
        width: scale * 0.34,
        height: scale * 0.30,
      );
      final headCol1 = customChitin ?? const Color(0xFF8E3C22);
      final headCol2 = customChitin != null
          ? Color.lerp(customChitin, Colors.black, 0.40)!
          : const Color(0xFF4A1A0D);
      final headCol3 = customChitin != null
          ? Color.lerp(customChitin, Colors.black, 0.75)!
          : const Color(0xFF160602);
      final headPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 0.85,
          colors: [headCol1, headCol2, headCol3],
        ).createShader(headRect);
      canvas.drawOval(headRect, headPaint);

      // High-contrast Blinn-Phong specular hotspot on cranial dome
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-scale * 0.05, -scale * 0.06),
          width: scale * 0.11,
          height: scale * 0.06,
        ),
        Paint()..color = const Color(0xFFFFFDEB).withValues(alpha: 0.90 * fog),
      );

      // Compound eyes with glossy corneal lens glint
      for (int side in [-1, 1]) {
        final eyeCenter = Offset(scale * 0.04, side * scale * 0.12);
        canvas.drawOval(
          Rect.fromCenter(center: eyeCenter, width: scale * 0.07, height: scale * 0.09),
          Paint()..color = const Color(0xFF0A0604),
        );
        canvas.drawCircle(
          Offset(eyeCenter.dx + scale * 0.012, eyeCenter.dy - scale * 0.015),
          scale * 0.015,
          Paint()..color = const Color(0xFFFFF7E6).withValues(alpha: 0.85 * fog),
        );
      }
      canvas.restore();

      // Articulated antennae with live swaying & SSS amber glow
      final antSway = math.sin(world.totalTime * 4.2) * 0.035;
      final antennaCorePaint = Paint()
        ..color = const Color(0xFF240B05)
        ..strokeWidth = (scale * 0.030).clamp(1.2, 3.2)
        ..strokeCap = StrokeCap.round;
      final antennaGlowPaint = Paint()
        ..color = const Color(0xFFFF8A36).withValues(alpha: 0.85 * fog)
        ..strokeWidth = (scale * 0.014).clamp(0.8, 1.8)
        ..strokeCap = StrokeCap.round;

      for (int side in [-1, 1]) {
        final aBase = _projectBugLandmark(
          anchor: center,
          x: 0.32,
          y: side * 0.05,
          z: 0.25,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final aElbow = _projectBugLandmark(
          anchor: center,
          x: 0.44,
          y: side * (0.16 + antSway),
          z: 0.32,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final aTip = _projectBugLandmark(
          anchor: center,
          x: 0.52,
          y: side * (0.11 - antSway),
          z: 0.26,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawLine(aBase, aElbow, antennaCorePaint);
        canvas.drawLine(aElbow, aTip, antennaCorePaint);
        canvas.drawLine(aBase, aElbow, antennaGlowPaint);
        canvas.drawLine(aElbow, aTip, antennaGlowPaint);
        canvas.drawCircle(aTip, (scale * 0.020).clamp(1.0, 2.4), Paint()..color = const Color(0xFFFFA24D));
      }
    }

    void drawPronotumAndPetiole() {
      // Sclerotized thoracic shield (pronotum) with specular ridge
      final thoraxCenter = _projectBugLandmark(
        anchor: center,
        x: 0.02,
        y: 0.0,
        z: 0.22,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(thoraxCenter.dx, thoraxCenter.dy);
      canvas.rotate(bodyAngle);

      final thoraxRect = Rect.fromCenter(
        center: Offset.zero,
        width: scale * 0.38,
        height: scale * 0.29,
      );
      final thoraxCol1 = customCrest ?? const Color(0xFFB85430);
      final thoraxCol2 = customCrest != null
          ? Color.lerp(customCrest, Colors.black, 0.35)!
          : const Color(0xFF782C15);
      final thoraxCol3 = customCrest != null
          ? Color.lerp(customCrest, Colors.black, 0.70)!
          : const Color(0xFF280B04);
      final thoraxPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: [thoraxCol1, thoraxCol2, thoraxCol3],
        ).createShader(thoraxRect);
      canvas.drawOval(thoraxRect, thoraxPaint);

      // Blinn-Phong specular hotspot on thoracic crest
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-scale * 0.04, -scale * 0.05),
          width: scale * 0.12,
          height: scale * 0.08,
        ),
        Paint()..color = const Color(0xFFFFF2DC).withValues(alpha: 0.85 * fog),
      );
      canvas.restore();

      // Articulated petiole node (distinct ant waist) with dark socket crevices
      final petioleCenter = _projectBugLandmark(
        anchor: center,
        x: -0.16,
        y: 0.0,
        z: 0.20,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      canvas.drawCircle(petioleCenter, scale * 0.08, Paint()..color = const Color(0xFF0A0402));
      canvas.drawCircle(petioleCenter, scale * 0.06, Paint()..color = const Color(0xFF5E210F));
    }

    void drawGaster() {
      // Glossy chitin gaster (abdomen) with raised tergites & Blinn-Phong specular hotspot
      final gasterCenter = _projectBugLandmark(
        anchor: center,
        x: -0.38,
        y: 0.0,
        z: 0.18,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(gasterCenter.dx, gasterCenter.dy);
      canvas.rotate(bodyAngle);

      final gasterRect = Rect.fromCenter(
        center: Offset.zero,
        width: scale * 0.54,
        height: scale * 0.42,
      );
      final gasterCol1 = customChitin ?? const Color(0xFF583626);
      final gasterCol2 = customChitin != null
          ? Color.lerp(customChitin, Colors.black, 0.45)!
          : const Color(0xFF25140D);
      final gasterCol3 = customChitin != null
          ? Color.lerp(customChitin, Colors.black, 0.80)!
          : const Color(0xFF0C0603);
      final gasterPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 0.85,
          colors: [gasterCol1, gasterCol2, gasterCol3],
        ).createShader(gasterRect);
      canvas.drawOval(gasterRect, gasterPaint);

      // Tergite intersegmental crevice lines
      final crevicePaint = Paint()
        ..color = const Color(0xFF070301)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (scale * 0.022).clamp(1.0, 3.0);

      final tergiteRimPaint = Paint()
        ..color = const Color(0xFF9E7455).withValues(alpha: 0.40 * fog)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (scale * 0.014).clamp(0.7, 2.0);

      for (double tx = -0.12; tx <= 0.14; tx += 0.09) {
        final arcRect = Rect.fromCenter(
          center: Offset(tx * scale, 0),
          width: scale * 0.18,
          height: scale * 0.38,
        );
        canvas.drawArc(arcRect, -math.pi * 0.4, math.pi * 0.8, false, crevicePaint);
        canvas.drawArc(arcRect, -math.pi * 0.4, math.pi * 0.8, false, tergiteRimPaint);
      }

      // High-contrast primary Blinn-Phong specular hotspot on the gaster dome
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-scale * 0.08, -scale * 0.08),
          width: scale * 0.16,
          height: scale * 0.10,
        ),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92 * fog),
      );

      // Broad secondary glossy highlight reflection arc
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-scale * 0.06, -scale * 0.06),
          width: scale * 0.24,
          height: scale * 0.18,
        ),
        Paint()..color = const Color(0xFFFFECD6).withValues(alpha: 0.28 * fog),
      );

      canvas.restore();
    }

    // Depth Sorting (Painter's Algorithm)
    final nearSide = sinPsi >= 0 ? 1 : -1;
    final farSide = -nearSide;

    // 1. Far-side articulated legs (behind body)
    drawLegsForSide(farSide);

    // 2. Body segments (order depends on cosPsi)
    if (cosPsi >= 0) {
      // Rear view: head is farthest, gaster is nearest
      drawHeadAndMouthparts();
      drawPronotumAndPetiole();
      drawGaster();
    } else {
      // Front view: gaster is farthest, head is nearest
      drawGaster();
      drawPronotumAndPetiole();
      drawHeadAndMouthparts();
    }

    // 3. Near-side articulated legs (in front of body)
    drawLegsForSide(nearSide);
  }

  /// Renders realistic 3D insect species with Blinn-Phong chitin specularity,
  /// faux subsurface scattering (SSS) on wings and legs, joint crevice ambient occlusion,
  /// and menacing micro-bumpiness/tactile spines on the Giant Wolf Spider.
  /// 3D Vector Landmark Projection Helper
  Offset _projectBugLandmark({
    required Offset anchor,
    required double x,
    required double y,
    required double z,
    required double cosPsi,
    required double sinPsi,
    required double cosBeta,
    required double sinBeta,
    required double scale,
    double lungeX = 0.0,
    double lungeY = 0.0,
  }) {
    final camFwd = x * cosPsi - y * sinPsi;
    final camRt = x * sinPsi + y * cosPsi;
    final sx = anchor.dx + camRt * scale + lungeX;
    final sy = anchor.dy - (z * cosBeta + camFwd * sinBeta) * scale + lungeY;
    return Offset(sx, sy);
  }

  /// Renders realistic 3D insect species with Blinn-Phong chitin specularity,
  /// faux subsurface scattering (SSS) on wings and legs, joint crevice ambient occlusion,
  /// full 360-degree viewing azimuth, and ground-anchored contact drop shadows.
  void _drawRealisticInsectModel(
    Canvas canvas, {
    required Offset groundAnchor,
    Offset? bodyAnchor,
    required double scale,
    required BugVehicleType type,
    required double walkPhase,
    required double viewYaw,
    required double pitchAngle,
    required bool hasAntRider,
    double attackAnim = 0.0,
    bool hitFlash = false,
    double altitude = 0.0,
    double worldDepth = 1.0,
  }) {
    final cosPsi = math.cos(viewYaw);
    final sinPsi = math.sin(viewYaw);
    final cosBeta = math.cos(pitchAngle);
    final sinBeta = math.sin(pitchAngle);
    final fog = _computeExponentialFog(worldDepth);

    // Airborne elevation offset for flying insects (hornet) or leaping grasshoppers
    final airborneDy = -altitude * scale * 1.5;
    final effectiveAnchor = bodyAnchor ?? Offset(groundAnchor.dx, groundAnchor.dy + airborneDy);

    // Dynamic ground contact drop shadow at ground plane
    final heightRatio = (altitude / 0.45).clamp(0.0, 3.5);
    final shadowRadiusExpansion = 1.0 + heightRatio * 0.42;
    final shadowOpacity = ((0.48 / (1.0 + heightRatio * 1.8)) * fog).clamp(0.06, 0.48);

    // 1. Soft Dynamic Drop Shadow Penumbra (Broad outer feathered blur)
    final penumbraWidth = scale * 2.35 * shadowRadiusExpansion;
    final penumbraHeight = scale * 1.02 * shadowRadiusExpansion;
    final penumbraRadius = penumbraWidth * 0.5;
    final penumbraYRatio = penumbraHeight / penumbraWidth;

    canvas.save();
    canvas.translate(groundAnchor.dx, groundAnchor.dy);
    canvas.scale(1.0, penumbraYRatio);

    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: shadowOpacity * 0.72),
          Colors.black.withValues(alpha: shadowOpacity * 0.38),
          Colors.black.withValues(alpha: shadowOpacity * 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 0.75, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: penumbraRadius,
        ),
      );
    canvas.drawCircle(Offset.zero, penumbraRadius, shadowPaint);
    canvas.restore();

    // 2. Soft Contact Occlusion Core Shadow (smooth radial gradient falloff to zero, perfectly feathered)
    final contactAlpha = (1.0 - (heightRatio / 0.50)).clamp(0.0, 1.0) * 0.52 * fog;
    if (contactAlpha > 0.01) {
      final coreWidth = scale * 1.40 * (1.0 + heightRatio * 0.25);
      final coreHeight = scale * 0.60 * (1.0 + heightRatio * 0.25);
      final coreRadius = coreWidth * 0.5;
      final coreYRatio = coreHeight / coreWidth;

      canvas.save();
      canvas.translate(groundAnchor.dx, groundAnchor.dy);
      canvas.scale(1.0, coreYRatio);

      final coreShadowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: contactAlpha * 0.75),
            Colors.black.withValues(alpha: contactAlpha * 0.38),
            Colors.black.withValues(alpha: contactAlpha * 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset.zero,
            radius: coreRadius,
          ),
        );
      canvas.drawCircle(Offset.zero, coreRadius, coreShadowPaint);
      canvas.restore();
    }

    // Visual Attack Strike Arc
    if (attackAnim > 0.05) {
      final headPoint = _projectBugLandmark(
        anchor: effectiveAnchor,
        x: 0.36,
        y: 0.0,
        z: 0.24,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final slashRadius = scale * (0.65 + (1.0 - attackAnim) * 0.35);
      final slashColor = type == BugVehicleType.wolfSpider
          ? const Color(0xFFB4F06E)
          : (type == BugVehicleType.hornet
              ? const Color(0xFFFFD84D)
              : const Color(0xFFFF9E5E));
      final slashAngle = math.atan2(-cosPsi * sinBeta, sinPsi);
      canvas.save();
      canvas.translate(headPoint.dx, headPoint.dy);
      canvas.rotate(slashAngle);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset.zero,
          width: slashRadius * 1.5,
          height: slashRadius * 0.9,
        ),
        -math.pi * 0.4,
        math.pi * 0.8,
        false,
        Paint()
          ..color = slashColor.withValues(alpha: attackAnim * 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (scale * 0.065).clamp(2.5, 9.0)
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    // Dispatch to dedicated 3D insect species renderer
    switch (type) {
      case BugVehicleType.hornet:
        _drawRealisticHornet(
          canvas,
          anchor: effectiveAnchor,
          scale: scale,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          walkPhase: walkPhase,
          attackAnim: attackAnim,
          hitFlash: hitFlash,
          fog: fog,
        );
        break;
      case BugVehicleType.grasshopper:
        _drawRealisticGrasshopper(
          canvas,
          anchor: effectiveAnchor,
          scale: scale,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          walkPhase: walkPhase,
          attackAnim: attackAnim,
          hitFlash: hitFlash,
          fog: fog,
        );
        break;
      case BugVehicleType.rhinoBeetle:
        _drawRealisticRhinoBeetle(
          canvas,
          anchor: effectiveAnchor,
          scale: scale,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          walkPhase: walkPhase,
          attackAnim: attackAnim,
          hitFlash: hitFlash,
          fog: fog,
        );
        break;
      case BugVehicleType.stagBeetle:
        _drawRealisticStagBeetle(
          canvas,
          anchor: effectiveAnchor,
          scale: scale,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          walkPhase: walkPhase,
          attackAnim: attackAnim,
          hitFlash: hitFlash,
          fog: fog,
        );
        break;
      case BugVehicleType.wolfSpider:
        _drawRealisticWolfSpider(
          canvas,
          anchor: effectiveAnchor,
          scale: scale,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          walkPhase: walkPhase,
          attackAnim: attackAnim,
          hitFlash: hitFlash,
          fog: fog,
        );
        break;
    }

    // Mounted Ant Rider seated on thorax top in true 3D
    if (hasAntRider) {
      final riderAnchor = _projectBugLandmark(
        anchor: effectiveAnchor,
        x: 0.04,
        y: 0.0,
        z: 0.32,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      _drawRealisticAntModel(
        canvas,
        center: riderAnchor,
        groundAnchor: riderAnchor,
        scale: scale * 0.32,
        walkPhase: walkPhase * 0.3,
        walkIntensity: 0.2,
        relYaw: viewYaw,
        pitchAngle: pitchAngle,
        pinchAnim: attackAnim,
        fog: fog,
        drawShadow: false,
      );
    }
  }

  /// Authentic European Hornet (Vespa crabro): heart-shaped head, yellow clypeus,
  /// deeply notched compound eyes, muscular mesosoma, slender wasp petiole waist,
  /// elongated spindle gaster with 6 black/yellow chevron tergites, lateral puncta dots,
  /// venom stinger with droplet, and 4 veined membranous fluttering wings with pterostigma.
  void _drawRealisticHornet(
    Canvas canvas, {
    required Offset anchor,
    required double scale,
    required double cosPsi,
    required double sinPsi,
    required double cosBeta,
    required double sinBeta,
    required double walkPhase,
    required double attackAnim,
    required bool hitFlash,
    required double fog,
  }) {
    // 3D Paints
    final legCorePaint = Paint()
      ..color = hitFlash ? const Color(0xFFFF9E70) : const Color(0xFF2E1A0F)
      ..strokeWidth = (scale * 0.046).clamp(1.5, 6.0)
      ..strokeCap = StrokeCap.round;
    final legSssPaint = Paint()
      ..color = const Color(0xFFFFB84D).withValues(alpha: 0.68)
      ..strokeWidth = (scale * 0.018).clamp(0.8, 2.4)
      ..strokeCap = StrokeCap.round;

    final wingFlutter = math.sin(world.totalTime * 46.0) * 0.22;
    final wingMembranePaint = Paint()
      ..color = const Color(0xFFFFF0B8).withValues(alpha: 0.46);
    final wingRimPaint = Paint()
      ..color = const Color(0xFFFFD066).withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (scale * 0.014).clamp(1.0, 2.2);
    final veinPaint = Paint()
      ..color = const Color(0xFF6E481F).withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (scale * 0.010).clamp(0.8, 1.8);
    final pterostigmaPaint = Paint()..color = const Color(0xFF422208);

    // Orientation vectors
    final fwdScrX = sinPsi;
    final fwdScrY = -cosPsi * sinBeta;
    final bodyAngle = math.atan2(fwdScrY, fwdScrX);

    // Side sorting: near vs far side
    final nearSide = sinPsi >= 0 ? 1 : -1;
    final farSide = -nearSide;

    void drawLegsForSide(int side) {
      for (int pair = -1; pair <= 1; pair++) {
        final phase = walkPhase + ((side * pair > 0) ? 0.0 : math.pi);
        final stride = math.sin(phase) * 0.06;
        final lift = math.max(0.0, math.cos(phase)) * 0.04;

        final xBase = pair == -1 ? 0.10 : (pair == 0 ? -0.02 : -0.14);
        final coxa = _projectBugLandmark(
          anchor: anchor,
          x: xBase,
          y: side * 0.12,
          z: 0.24,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final knee = _projectBugLandmark(
          anchor: anchor,
          x: xBase + 0.04,
          y: side * 0.28,
          z: 0.16 - lift,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final tarsus = _projectBugLandmark(
          anchor: anchor,
          x: xBase + 0.08,
          y: side * 0.32,
          z: 0.02 - stride,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawCircle(coxa, (scale * 0.028).clamp(1.2, 4.0), Paint()..color = const Color(0xFF140A05));
        canvas.drawLine(coxa, knee, legCorePaint);
        canvas.drawLine(knee, tarsus, legCorePaint);
        canvas.drawLine(coxa, knee, legSssPaint);

        if (scale >= 35.0) {
          canvas.drawCircle(knee, (scale * 0.022).clamp(1.0, 3.2), Paint()..color = const Color(0xFF1F1008));
        }
      }
    }

    void drawWingsForSide(int side) {
      // Forewing
      final foreRoot = _projectBugLandmark(
        anchor: anchor,
        x: 0.04,
        y: side * 0.10,
        z: 0.34,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final foreTip = _projectBugLandmark(
        anchor: anchor,
        x: -0.22,
        y: side * 0.72,
        z: 0.38 + side * wingFlutter,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      final foreCenter = Offset((foreRoot.dx + foreTip.dx) * 0.5, (foreRoot.dy + foreTip.dy) * 0.5);
      final foreAngle = math.atan2(foreTip.dy - foreRoot.dy, foreTip.dx - foreRoot.dx);
      final foreLength = (foreTip - foreRoot).distance;

      canvas.save();
      canvas.translate(foreCenter.dx, foreCenter.dy);
      canvas.rotate(foreAngle);
      final foreRect = Rect.fromCenter(center: Offset.zero, width: foreLength * 1.1, height: scale * 0.24);
      canvas.drawOval(foreRect, wingMembranePaint);
      canvas.drawOval(foreRect, wingRimPaint);
      canvas.drawLine(Offset(-foreLength * 0.45, 0), Offset(foreLength * 0.45, -scale * 0.02), veinPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(foreLength * 0.25, -scale * 0.06), width: scale * 0.10, height: scale * 0.035),
          const Radius.circular(1.5),
        ),
        pterostigmaPaint,
      );
      canvas.restore();

      // Hindwing (smaller)
      final hindRoot = _projectBugLandmark(
        anchor: anchor,
        x: -0.05,
        y: side * 0.08,
        z: 0.32,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final hindTip = _projectBugLandmark(
        anchor: anchor,
        x: -0.28,
        y: side * 0.54,
        z: 0.34 + side * wingFlutter * 0.7,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      final hindCenter = Offset((hindRoot.dx + hindTip.dx) * 0.5, (hindRoot.dy + hindTip.dy) * 0.5);
      final hindAngle = math.atan2(hindTip.dy - hindRoot.dy, hindTip.dx - hindRoot.dx);
      final hindLength = (hindTip - hindRoot).distance;

      canvas.save();
      canvas.translate(hindCenter.dx, hindCenter.dy);
      canvas.rotate(hindAngle);
      final hindRect = Rect.fromCenter(center: Offset.zero, width: hindLength * 1.08, height: scale * 0.18);
      canvas.drawOval(hindRect, wingMembranePaint);
      canvas.drawOval(hindRect, wingRimPaint);
      canvas.drawLine(Offset(-hindLength * 0.4, 0), Offset(hindLength * 0.4, 0), veinPaint);
      canvas.restore();
    }

    void drawHeadAndFace() {
      final headCenter = _projectBugLandmark(
        anchor: anchor,
        x: 0.28,
        y: 0.0,
        z: 0.28,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      // Chewing mandibles
      for (int side in [-1, 1]) {
        final mBase = _projectBugLandmark(
          anchor: anchor,
          x: 0.36,
          y: side * 0.05,
          z: 0.22,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final mTip = _projectBugLandmark(
          anchor: anchor,
          x: 0.42,
          y: side * 0.01,
          z: 0.18,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        canvas.drawLine(
          mBase,
          mTip,
          Paint()
            ..color = const Color(0xFF261006)
            ..strokeWidth = (scale * 0.035).clamp(1.4, 4.0)
            ..strokeCap = StrokeCap.round,
        );
      }

      // Heart-shaped cranial capsule
      canvas.save();
      canvas.translate(headCenter.dx, headCenter.dy);
      canvas.rotate(bodyAngle);
      final headRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.36, height: scale * 0.32);
      final headPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [
            hitFlash ? const Color(0xFFFFC0A8) : const Color(0xFF6B2412),
            hitFlash ? const Color(0xFFDE4E30) : const Color(0xFF2E1007),
            const Color(0xFF120603),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(headRect);
      canvas.drawOval(headRect, headPaint);

      // Yellow clypeus face shield
      final clypeusRect = Rect.fromCenter(center: Offset(scale * 0.06, 0), width: scale * 0.18, height: scale * 0.15);
      canvas.drawOval(clypeusRect, Paint()..color = const Color(0xFFF5BD26));

      // Kidney-shaped compound eyes on lateral margins
      for (int side in [-1, 1]) {
        final eyeCenter = Offset(scale * 0.04, side * scale * 0.11);
        final eyeRect = Rect.fromCenter(center: eyeCenter, width: scale * 0.14, height: scale * 0.09);
        canvas.drawOval(eyeRect, Paint()..color = const Color(0xFF0C0603));
        canvas.drawCircle(
          Offset(eyeCenter.dx + scale * 0.02, eyeCenter.dy - scale * 0.01),
          (scale * 0.018).clamp(1.0, 2.4),
          Paint()..color = const Color(0xFFFFFBE8).withValues(alpha: 0.90),
        );
      }
      canvas.restore();

      // Antennae with live waving
      final antSway = math.sin(world.totalTime * 5.0) * 0.04;
      final antPaint = Paint()
        ..color = const Color(0xFF261208)
        ..strokeWidth = (scale * 0.026).clamp(1.2, 3.2)
        ..strokeCap = StrokeCap.round;
      final antRim = Paint()
        ..color = const Color(0xFFFF8A36).withValues(alpha: 0.75)
        ..strokeWidth = (scale * 0.012).clamp(0.8, 1.8)
        ..strokeCap = StrokeCap.round;

      for (int side in [-1, 1]) {
        final aBase = _projectBugLandmark(
          anchor: anchor,
          x: 0.32,
          y: side * 0.05,
          z: 0.30,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final aElbow = _projectBugLandmark(
          anchor: anchor,
          x: 0.44,
          y: side * (0.16 + antSway),
          z: 0.36,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final aTip = _projectBugLandmark(
          anchor: anchor,
          x: 0.52,
          y: side * (0.12 - antSway),
          z: 0.32,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawLine(aBase, aElbow, antPaint);
        canvas.drawLine(aElbow, aTip, antPaint);
        canvas.drawLine(aBase, aElbow, antRim);
        canvas.drawLine(aElbow, aTip, antRim);
        canvas.drawCircle(aTip, (scale * 0.018).clamp(1.0, 2.2), Paint()..color = const Color(0xFFFFA64D));
      }
    }

    void drawMesosoma() {
      final thoraxCenter = _projectBugLandmark(
        anchor: anchor,
        x: 0.0,
        y: 0.0,
        z: 0.28,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(thoraxCenter.dx, thoraxCenter.dy);
      canvas.rotate(bodyAngle);

      final thoraxRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.52, height: scale * 0.44);
      final thoraxPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [
            hitFlash ? const Color(0xFFFFB296) : const Color(0xFF6B2B16),
            hitFlash ? const Color(0xFFD8482A) : const Color(0xFF2C1309),
            const Color(0xFF0F0703),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(thoraxRect);
      canvas.drawOval(thoraxRect, thoraxPaint);

      // Glossy chitin specular highlight
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-scale * 0.06, -scale * 0.05), width: scale * 0.16, height: scale * 0.09),
        Paint()..color = const Color(0xFFFFF7E6).withValues(alpha: 0.88),
      );

      // Amber tegulae shoulder pads
      for (int side in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(scale * 0.02, side * scale * 0.18), width: scale * 0.10, height: scale * 0.08),
          Paint()..color = const Color(0xFFE8A824),
        );
      }

      // Yellow crescent scutellum
      canvas.drawArc(
        Rect.fromCenter(center: Offset(-scale * 0.14, 0), width: scale * 0.22, height: scale * 0.16),
        -math.pi * 0.5,
        math.pi,
        true,
        Paint()..color = const Color(0xFFE29E20),
      );
      canvas.restore();

      // Slender petiole waist
      final p1 = _projectBugLandmark(
        anchor: anchor,
        x: -0.14,
        y: 0.0,
        z: 0.26,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final p2 = _projectBugLandmark(
        anchor: anchor,
        x: -0.22,
        y: 0.0,
        z: 0.24,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = const Color(0xFF140804)
          ..strokeWidth = (scale * 0.10).clamp(3.0, 14.0)
          ..strokeCap = StrokeCap.round,
      );
    }

    void drawGasterAndStinger() {
      final gasterCenter = _projectBugLandmark(
        anchor: anchor,
        x: -0.44,
        y: 0.0,
        z: 0.22,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(gasterCenter.dx, gasterCenter.dy);
      canvas.rotate(bodyAngle);

      final gasterRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.72, height: scale * 0.46);
      final gasterPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 0.9,
          colors: [
            hitFlash ? const Color(0xFFFFD4C2) : const Color(0xFFF7C83E),
            hitFlash ? const Color(0xFFE85434) : const Color(0xFFD49218),
            const Color(0xFF241006),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(gasterRect);
      canvas.drawOval(gasterRect, gasterPaint);

      // Tergite 1: Dark basal segment
      canvas.drawOval(
        Rect.fromCenter(center: Offset(scale * 0.24, 0), width: scale * 0.24, height: scale * 0.42),
        Paint()..color = const Color(0xFF281208),
      );

      // Tergites 2-5: Black chevron bands & lateral puncta dots
      final chevronPaint = Paint()..color = const Color(0xFF1A0A04);
      final dotPaint = Paint()..color = const Color(0xFF140803);
      final tOffsets = [0.12, -0.02, -0.14, -0.24];
      final tWidths = [0.44, 0.40, 0.32, 0.22];

      for (int t = 0; t < tOffsets.length; t++) {
        final tx = tOffsets[t] * scale;
        final tw = tWidths[t] * scale;
        final bandPath = Path()
          ..moveTo(tx, -tw * 0.5)
          ..lineTo(tx - scale * 0.04, 0)
          ..lineTo(tx, tw * 0.5)
          ..lineTo(tx - scale * 0.06, tw * 0.48)
          ..lineTo(tx - scale * 0.08, 0)
          ..lineTo(tx - scale * 0.06, -tw * 0.48)
          ..close();
        canvas.drawPath(bandPath, chevronPaint);

        if (t < 3) {
          canvas.drawCircle(Offset(tx, -tw * 0.36), (scale * 0.020).clamp(1.0, 2.8), dotPaint);
          canvas.drawCircle(Offset(tx, tw * 0.36), (scale * 0.020).clamp(1.0, 2.8), dotPaint);
        }
      }

      // Cylindrical chitin specular highlight streak
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, -scale * 0.08), width: scale * 0.44, height: scale * 0.10),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.82),
      );

      canvas.restore();

      // Articulated venom stinger with glowing chartreuse venom droplet
      final stingerBase = _projectBugLandmark(
        anchor: anchor,
        x: -0.70,
        y: 0.0,
        z: 0.18,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final stingerTip = _projectBugLandmark(
        anchor: anchor,
        x: -0.84 - attackAnim * 0.12,
        y: 0.0,
        z: 0.15,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      canvas.drawLine(
        stingerBase,
        stingerTip,
        Paint()
          ..color = const Color(0xFF0D0502)
          ..strokeWidth = (scale * 0.028).clamp(1.4, 3.4)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        stingerTip,
        (scale * 0.026).clamp(1.4, 4.0),
        Paint()..color = const Color(0xFFD6FF47).withValues(alpha: 0.92),
      );
    }

    // Depth Sorting (Painter's Algorithm)
    // 1. Far-side legs and wings (behind body)
    drawLegsForSide(farSide);
    drawWingsForSide(farSide);

    // 2. Body segments (order depends on cosPsi)
    if (cosPsi >= 0) {
      // Rear view: head is far, gaster is near
      drawHeadAndFace();
      drawMesosoma();
      drawGasterAndStinger();
    } else {
      // Front view: gaster is far, head is near
      drawGasterAndStinger();
      drawMesosoma();
      drawHeadAndFace();
    }

    // 3. Near-side legs and wings (in front of body)
    drawLegsForSide(nearSide);
    drawWingsForSide(nearSide);
  }

  /// Authentic Meadow Grasshopper (Chorthippus parallelus): vertical hypognathous head,
  /// protruding oval striped compound eyes, long filiform antennae, saddle-shaped pronotum
  /// with median carina keel, folded roof-like leathery tegmina with leaf veins,
  /// and massive jumping hind legs with herringbone chevron pinnate muscle striations.
  void _drawRealisticGrasshopper(
    Canvas canvas, {
    required Offset anchor,
    required double scale,
    required double cosPsi,
    required double sinPsi,
    required double cosBeta,
    required double sinBeta,
    required double walkPhase,
    required double attackAnim,
    required bool hitFlash,
    required double fog,
  }) {
    final legCorePaint = Paint()
      ..color = hitFlash ? const Color(0xFFFF9E70) : const Color(0xFF384A22)
      ..strokeWidth = (scale * 0.046).clamp(1.6, 6.0)
      ..strokeCap = StrokeCap.round;
    final legSssPaint = Paint()
      ..color = const Color(0xFFB4E04A).withValues(alpha: 0.65)
      ..strokeWidth = (scale * 0.018).clamp(0.8, 2.4)
      ..strokeCap = StrokeCap.round;

    final fwdScrX = sinPsi;
    final fwdScrY = -cosPsi * sinBeta;
    final bodyAngle = math.atan2(fwdScrY, fwdScrX);

    final nearSide = sinPsi >= 0 ? 1 : -1;
    final farSide = -nearSide;

    void drawLegsForSide(int side) {
      // 1. Front and mid walking legs
      for (int pair = -1; pair <= 0; pair++) {
        final phase = walkPhase + ((side * (pair == 0 ? -1 : 1) > 0) ? 0.0 : math.pi);
        final stride = math.sin(phase) * 0.07;
        final lift = math.max(0.0, math.cos(phase)) * 0.05;

        final xBase = pair == -1 ? 0.16 : 0.02;
        final coxa = _projectBugLandmark(
          anchor: anchor,
          x: xBase,
          y: side * 0.12,
          z: 0.22,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final knee = _projectBugLandmark(
          anchor: anchor,
          x: xBase + 0.04,
          y: side * 0.24,
          z: 0.16 - lift,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final tarsus = _projectBugLandmark(
          anchor: anchor,
          x: xBase + 0.08,
          y: side * 0.26,
          z: 0.0 - stride, // firmly touching dirt at Z=0
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawCircle(coxa, (scale * 0.030).clamp(1.2, 3.8), Paint()..color = const Color(0xFF141F0C));
        canvas.drawLine(coxa, knee, legCorePaint);
        canvas.drawLine(knee, tarsus, legCorePaint);
        canvas.drawLine(coxa, knee, legSssPaint);
      }

      // 2. Colossal Jumping Hind Leg
      final kickExtend = attackAnim * 0.35;
      final hindPhase = walkPhase + ((side > 0) ? 0.0 : math.pi);
      final hindStride = math.sin(hindPhase) * 0.05;
      final hindLift = math.max(0.0, math.cos(hindPhase)) * 0.05;

      final coxa = _projectBugLandmark(
        anchor: anchor,
        x: -0.12,
        y: side * 0.14,
        z: 0.24,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final knee = _projectBugLandmark(
        anchor: anchor,
        x: -0.26,
        y: side * (0.24 + kickExtend * 0.2),
        z: 0.54 - hindLift - kickExtend * 0.15, // Towering knee joint!
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final tarsus = _projectBugLandmark(
        anchor: anchor,
        x: -0.50 - kickExtend,
        y: side * (0.26 + kickExtend * 0.3),
        z: 0.0 - hindStride, // Firmly anchored to dirt at Z=0
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      // Muscular Femur Club
      final femurMid = Offset((coxa.dx + knee.dx) * 0.5 + (knee.dx - coxa.dx) * 0.1, (coxa.dy + knee.dy) * 0.5 - scale * 0.04);
      final femurPath = Path()
        ..moveTo(coxa.dx, coxa.dy)
        ..quadraticBezierTo(femurMid.dx - side * scale * 0.06, femurMid.dy, knee.dx, knee.dy)
        ..quadraticBezierTo(femurMid.dx + side * scale * 0.04, femurMid.dy + scale * 0.04, coxa.dx, coxa.dy)
        ..close();

      final femurPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hitFlash ? const Color(0xFFFFB296) : const Color(0xFF7FA83E),
            hitFlash ? const Color(0xFFDE5430) : const Color(0xFF4A6820),
            const Color(0xFF1E2E0A),
          ],
        ).createShader(Rect.fromPoints(coxa, knee));
      canvas.drawPath(femurPath, femurPaint);

      // Herringbone chevron pinnate muscle ridges on femur
      final chevronPaint = Paint()
        ..color = const Color(0xFF263A0F).withValues(alpha: 0.85)
        ..strokeWidth = (scale * 0.016).clamp(1.0, 2.4);
      for (double t = 0.25; t <= 0.80; t += 0.12) {
        final cx = coxa.dx + (knee.dx - coxa.dx) * t;
        final cy = coxa.dy + (knee.dy - coxa.dy) * t;
        canvas.drawLine(
          Offset(cx - side * scale * 0.035, cy - scale * 0.02),
          Offset(cx, cy),
          chevronPaint,
        );
        canvas.drawLine(
          Offset(cx, cy),
          Offset(cx + side * scale * 0.025, cy + scale * 0.02),
          chevronPaint,
        );
      }

      // Spined Tibia
      final tibiaPaint = Paint()
        ..color = hitFlash ? const Color(0xFFFF9E70) : const Color(0xFF384A22)
        ..strokeWidth = (scale * 0.040).clamp(1.5, 5.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(knee, tarsus, tibiaPaint);
      canvas.drawLine(knee, tarsus, legSssPaint);

      // Tibial spines along the shaft
      final spinePaint = Paint()
        ..color = const Color(0xFF1B2B0A)
        ..strokeWidth = 1.6;
      for (double t = 0.25; t <= 0.85; t += 0.15) {
        final sx = knee.dx + (tarsus.dx - knee.dx) * t;
        final sy = knee.dy + (tarsus.dy - knee.dy) * t;
        canvas.drawLine(Offset(sx, sy), Offset(sx + side * scale * 0.03, sy - scale * 0.015), spinePaint);
      }

      // Knee joint cap & tarsal claw on dirt
      canvas.drawCircle(knee, (scale * 0.042).clamp(1.8, 5.5), Paint()..color = const Color(0xFF1E2E0A));
      canvas.drawCircle(tarsus, (scale * 0.030).clamp(1.2, 4.0), Paint()..color = const Color(0xFF141F0C));
    }

    void drawHeadAndFace() {
      final headCenter = _projectBugLandmark(
        anchor: anchor,
        x: 0.28,
        y: 0.0,
        z: 0.28,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      // Vertical hypognathous head capsule
      canvas.save();
      canvas.translate(headCenter.dx, headCenter.dy);
      canvas.rotate(bodyAngle);

      final headRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.36, height: scale * 0.32);
      final headPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [
            hitFlash ? const Color(0xFFFFBCA4) : const Color(0xFF7FA83E),
            hitFlash ? const Color(0xFFDE4E30) : const Color(0xFF4A6820),
            const Color(0xFF1A290A),
          ],
        ).createShader(headRect);
      canvas.drawOval(headRect, headPaint);

      // Chewing mouthparts at front/bottom
      canvas.drawOval(
        Rect.fromCenter(center: Offset(scale * 0.14, 0), width: scale * 0.14, height: scale * 0.18),
        Paint()..color = const Color(0xFF283D12),
      );

      // Lateral striped compound eyes
      for (int side in [-1, 1]) {
        final eyeCenter = Offset(scale * 0.05, side * scale * 0.12);
        final eyeRect = Rect.fromCenter(center: eyeCenter, width: scale * 0.16, height: scale * 0.10);
        canvas.drawOval(eyeRect, Paint()..color = const Color(0xFF2D3814));
        canvas.drawOval(
          eyeRect,
          Paint()
            ..color = const Color(0xFFD6C865).withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        // Vertical eye stripe
        canvas.drawLine(
          Offset(eyeCenter.dx, eyeCenter.dy - scale * 0.04),
          Offset(eyeCenter.dx, eyeCenter.dy + scale * 0.04),
          Paint()
            ..color = const Color(0xFF0F1706)
            ..strokeWidth = 1.6,
        );
      }
      canvas.restore();

      // Long filiform antennae sweeping up and backward
      final antSway = math.sin(world.totalTime * 4.0) * 0.03;
      final antPaint = Paint()
        ..color = const Color(0xFF2E4016)
        ..strokeWidth = (scale * 0.024).clamp(1.2, 2.8)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int side in [-1, 1]) {
        final aRoot = _projectBugLandmark(
          anchor: anchor,
          x: 0.32,
          y: side * 0.04,
          z: 0.36,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final aMid = _projectBugLandmark(
          anchor: anchor,
          x: 0.24,
          y: side * (0.14 + antSway),
          z: 0.52,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final aTip = _projectBugLandmark(
          anchor: anchor,
          x: 0.12,
          y: side * (0.20 - antSway),
          z: 0.64,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        final aPath = Path()
          ..moveTo(aRoot.dx, aRoot.dy)
          ..quadraticBezierTo(aMid.dx, aMid.dy, aTip.dx, aTip.dy);
        canvas.drawPath(aPath, antPaint);
      }
    }

    void drawPronotum() {
      final center = _projectBugLandmark(
        anchor: anchor,
        x: 0.06,
        y: 0.0,
        z: 0.28,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bodyAngle);

      final pronRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.50, height: scale * 0.40);
      final pronPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [
            hitFlash ? const Color(0xFFFFB698) : const Color(0xFF6B942E),
            hitFlash ? const Color(0xFFD64426) : const Color(0xFF3E5A18),
            const Color(0xFF142106),
          ],
        ).createShader(pronRect);
      canvas.drawOval(pronRect, pronPaint);

      // Median dorsal carina keel line
      canvas.drawLine(
        Offset(-scale * 0.22, 0),
        Offset(scale * 0.22, 0),
        Paint()
          ..color = const Color(0xFFD4E882).withValues(alpha: 0.85)
          ..strokeWidth = (scale * 0.020).clamp(1.2, 2.5),
      );

      // Lateral cream flank stripes
      for (int side in [-1, 1]) {
        canvas.drawLine(
          Offset(-scale * 0.18, side * scale * 0.14),
          Offset(scale * 0.18, side * scale * 0.14),
          Paint()
            ..color = const Color(0xFFE8E29E).withValues(alpha: 0.75)
            ..strokeWidth = 1.5,
        );
      }
      canvas.restore();
    }

    void drawAbdomenAndTegmina() {
      final center = _projectBugLandmark(
        anchor: anchor,
        x: -0.32,
        y: 0.0,
        z: 0.24,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bodyAngle);

      // Elongated body cylinder
      final abdRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.78, height: scale * 0.38);
      final abdPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [
            hitFlash ? const Color(0xFFFFC2A8) : const Color(0xFF7A9C34),
            hitFlash ? const Color(0xFFDB4E2E) : const Color(0xFF456018),
            const Color(0xFF162407),
          ],
        ).createShader(abdRect);
      canvas.drawOval(abdRect, abdPaint);

      // Segment rings along abdomen
      final segPaint = Paint()
        ..color = const Color(0xFF1A2B08)
        ..strokeWidth = 1.4;
      for (double t = -0.30; t <= 0.25; t += 0.08) {
        final sx = t * scale;
        canvas.drawLine(Offset(sx, -scale * 0.16), Offset(sx, scale * 0.16), segPaint);
      }

      // Roof-like folded tegmina forewings along dorsum with leaf veins
      canvas.drawLine(
        Offset(-scale * 0.35, 0),
        Offset(scale * 0.35, 0),
        Paint()
          ..color = const Color(0xFF9CCC44).withValues(alpha: 0.85)
          ..strokeWidth = (scale * 0.026).clamp(1.4, 3.2),
      );

      canvas.restore();
    }

    // Depth Sorting
    // 1. Far-side legs (behind body)
    drawLegsForSide(farSide);

    // 2. Body segments
    if (cosPsi >= 0) {
      drawHeadAndFace();
      drawPronotum();
      drawAbdomenAndTegmina();
    } else {
      drawAbdomenAndTegmina();
      drawPronotum();
      drawHeadAndFace();
    }

    // 3. Near-side legs (in front of body)
    drawLegsForSide(nearSide);
  }

  /// Authentic Hercules Rhinoceros Beetle (Dynastes hercules): colossal downward-curving
  /// pronotal horn with rust velvet setae, upward-curving cephalic horn with forked tip,
  /// massive polished obsidian pronotum, voluminous domed olive elytra with punctate striae
  /// and camouflage spots, and heavy fossorial front legs with digging teeth.
  void _drawRealisticRhinoBeetle(
    Canvas canvas, {
    required Offset anchor,
    required double scale,
    required double cosPsi,
    required double sinPsi,
    required double cosBeta,
    required double sinBeta,
    required double walkPhase,
    required double attackAnim,
    required bool hitFlash,
    required double fog,
  }) {
    final legCorePaint = Paint()
      ..color = hitFlash ? const Color(0xFFFF9E70) : const Color(0xFF24160E)
      ..strokeWidth = (scale * 0.065).clamp(2.4, 8.5)
      ..strokeCap = StrokeCap.round;
    final legSssPaint = Paint()
      ..color = const Color(0xFFFF8A38).withValues(alpha: 0.65)
      ..strokeWidth = (scale * 0.022).clamp(1.0, 3.0)
      ..strokeCap = StrokeCap.round;

    final fwdScrX = sinPsi;
    final fwdScrY = -cosPsi * sinBeta;
    final bodyAngle = math.atan2(fwdScrY, fwdScrX);

    final nearSide = sinPsi >= 0 ? 1 : -1;
    final farSide = -nearSide;

    void drawLegsForSide(int side) {
      for (int pair = -1; pair <= 1; pair++) {
        final phase = walkPhase + ((side * pair > 0) ? 0.0 : math.pi);
        final stride = math.sin(phase) * 0.06;
        final lift = math.max(0.0, math.cos(phase)) * 0.04;

        final xBase = pair == -1 ? 0.18 : (pair == 0 ? 0.04 : -0.14);
        final coxa = _projectBugLandmark(
          anchor: anchor,
          x: xBase,
          y: side * 0.16,
          z: 0.20,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final knee = _projectBugLandmark(
          anchor: anchor,
          x: xBase + 0.04,
          y: side * 0.34,
          z: 0.15 - lift,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final tarsus = _projectBugLandmark(
          anchor: anchor,
          x: xBase + 0.08,
          y: side * 0.38,
          z: 0.0 - stride, // Firmly planted on dirt at Z=0
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawCircle(coxa, (scale * 0.040).clamp(1.8, 5.5), Paint()..color = const Color(0xFF100905));
        canvas.drawLine(coxa, knee, legCorePaint);
        canvas.drawLine(knee, tarsus, legCorePaint);
        canvas.drawLine(coxa, knee, legSssPaint);

        // Digging teeth along front tibia
        if (pair == -1 && scale >= 30.0) {
          final toothPaint = Paint()
            ..color = const Color(0xFF140B06)
            ..strokeWidth = 2.0;
          for (double dt = 0.35; dt <= 0.85; dt += 0.25) {
            final tx = knee.dx + (tarsus.dx - knee.dx) * dt;
            final ty = knee.dy + (tarsus.dy - knee.dy) * dt;
            canvas.drawLine(Offset(tx, ty), Offset(tx + side * scale * 0.04, ty - scale * 0.02), toothPaint);
          }
        }
      }
    }

    void drawHeadAndTwinHorns() {
      final hornLift = attackAnim * scale * 0.22;
      final headCenter = _projectBugLandmark(
        anchor: anchor,
        x: 0.28,
        y: 0.0,
        z: 0.20,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      // Head capsule
      canvas.save();
      canvas.translate(headCenter.dx, headCenter.dy);
      canvas.rotate(bodyAngle);
      final headRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.32, height: scale * 0.26);
      canvas.drawOval(headRect, Paint()..color = const Color(0xFF140C07));

      // Small shiny compound eyes
      for (int side in [-1, 1]) {
        canvas.drawCircle(
          Offset(scale * 0.04, side * scale * 0.11),
          (scale * 0.020).clamp(1.0, 2.4),
          Paint()..color = const Color(0xFFFFF2D0),
        );
      }
      canvas.restore();

      // 1. CEPHALIC HORN (Sweeps upward with bifurcated Y-forked tip)
      final cHornBase = _projectBugLandmark(
        anchor: anchor,
        x: 0.34,
        y: 0.0,
        z: 0.20,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final cHornMid = _projectBugLandmark(
        anchor: anchor,
        x: 0.46,
        y: 0.0,
        z: 0.38 + hornLift * 0.005,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final cHornTip = _projectBugLandmark(
        anchor: anchor,
        x: 0.56,
        y: 0.0,
        z: 0.54 + hornLift * 0.008,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      final cHornPaint = Paint()
        ..color = const Color(0xFF1C110A)
        ..strokeWidth = (scale * 0.050).clamp(2.0, 6.5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(cHornBase, cHornMid, cHornPaint);
      canvas.drawLine(cHornMid, cHornTip, cHornPaint);

      // Y-forked bifurcated tip
      final forkL = _projectBugLandmark(
        anchor: anchor,
        x: 0.60,
        y: -0.04,
        z: 0.58 + hornLift * 0.008,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final forkR = _projectBugLandmark(
        anchor: anchor,
        x: 0.60,
        y: 0.04,
        z: 0.58 + hornLift * 0.008,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final forkPaint = Paint()
        ..color = const Color(0xFF140A06)
        ..strokeWidth = (scale * 0.035).clamp(1.5, 4.5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(cHornTip, forkL, forkPaint);
      canvas.drawLine(cHornTip, forkR, forkPaint);

      // 2. PRONOTAL HORN (Arches forward & downward from top of thorax)
      final pHornBase = _projectBugLandmark(
        anchor: anchor,
        x: 0.18,
        y: 0.0,
        z: 0.38,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final pHornTip = _projectBugLandmark(
        anchor: anchor,
        x: 0.46,
        y: 0.0,
        z: 0.40 - hornLift * 0.004,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      final pHornPaint = Paint()
        ..color = const Color(0xFF26180E)
        ..strokeWidth = (scale * 0.055).clamp(2.2, 7.5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(pHornBase, pHornTip, pHornPaint);

      // Rust velvet setae along underside of pronotal horn
      final velvetPaint = Paint()
        ..color = const Color(0xFF9E4B18).withValues(alpha: 0.75)
        ..strokeWidth = 1.4;
      for (double vt = 0.25; vt <= 0.85; vt += 0.15) {
        final vx = pHornBase.dx + (pHornTip.dx - pHornBase.dx) * vt;
        final vy = pHornBase.dy + (pHornTip.dy - pHornBase.dy) * vt;
        canvas.drawLine(Offset(vx, vy), Offset(vx, vy + scale * 0.02), velvetPaint);
      }
    }

    void drawPronotum() {
      final center = _projectBugLandmark(
        anchor: anchor,
        x: 0.14,
        y: 0.0,
        z: 0.26,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bodyAngle);

      final pronRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.50, height: scale * 0.44);
      final pronPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [
            hitFlash ? const Color(0xFFFFB698) : const Color(0xFF382216),
            hitFlash ? const Color(0xFFD64426) : const Color(0xFF1E120B),
            const Color(0xFF0C0704),
          ],
        ).createShader(pronRect);
      canvas.drawOval(pronRect, pronPaint);

      // Glossy chitin highlight arc
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-scale * 0.06, -scale * 0.06), width: scale * 0.18, height: scale * 0.10),
        Paint()..color = const Color(0xFFFFF2D0).withValues(alpha: 0.85),
      );

      canvas.restore();
    }

    void drawElytra() {
      final center = _projectBugLandmark(
        anchor: anchor,
        x: -0.24,
        y: 0.0,
        z: 0.26,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bodyAngle);

      // Voluminous domed elytra oval
      final elytraRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.84, height: scale * 0.56);
      final elytraPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 0.9,
          colors: [
            hitFlash ? const Color(0xFFFFD4C2) : const Color(0xFF8A7A40),
            hitFlash ? const Color(0xFFDE4E30) : const Color(0xFF5A4D24),
            const Color(0xFF241C0A),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(elytraRect);
      canvas.drawOval(elytraRect, elytraPaint);

      // Central suture line
      canvas.drawLine(
        Offset(-scale * 0.40, 0),
        Offset(scale * 0.40, 0),
        Paint()
          ..color = const Color(0xFF120E04)
          ..strokeWidth = (scale * 0.020).clamp(1.2, 2.5),
      );

      // Camouflage punctate striae spots
      final spotPaint = Paint()..color = const Color(0xFF1A1406).withValues(alpha: 0.70);
      final spotOffsets = [
        Offset(-scale * 0.18, -scale * 0.14),
        Offset(-scale * 0.10, scale * 0.15),
        Offset(scale * 0.08, -scale * 0.12),
        Offset(scale * 0.16, scale * 0.14),
      ];
      for (final sp in spotOffsets) {
        canvas.drawCircle(sp, (scale * 0.024).clamp(1.2, 3.2), spotPaint);
      }

      // Broad glossy Blinn-Phong highlight arc
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-scale * 0.10, -scale * 0.10), width: scale * 0.38, height: scale * 0.14),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85),
      );

      canvas.restore();
    }

    // Depth Sorting
    // 1. Far-side legs (behind body)
    drawLegsForSide(farSide);

    // 2. Body segments
    if (cosPsi >= 0) {
      drawHeadAndTwinHorns();
      drawPronotum();
      drawElytra();
    } else {
      drawElytra();
      drawPronotum();
      drawHeadAndTwinHorns();
    }

    // 3. Near-side legs (in front of body)
    drawLegsForSide(nearSide);
  }

  /// Authentic Greater Stag Beetle (Lucanus cervus): colossal curved sickle mandibles
  /// with inner crushing teeth, broad transverse head with temporal ridges,
  /// rectangular pronotum shield, triangular scutellum, and lustrous wine-red/mahogany elytra.
  void _drawRealisticStagBeetle(
    Canvas canvas, {
    required Offset anchor,
    required double scale,
    required double cosPsi,
    required double sinPsi,
    required double cosBeta,
    required double sinBeta,
    required double walkPhase,
    required double attackAnim,
    required bool hitFlash,
    required double fog,
  }) {
    final legCorePaint = Paint()
      ..color = hitFlash ? const Color(0xFFFF9E70) : const Color(0xFF2B100B)
      ..strokeWidth = (scale * 0.060).clamp(2.2, 8.0)
      ..strokeCap = StrokeCap.round;
    final legSssPaint = Paint()
      ..color = const Color(0xFFFF6E2E).withValues(alpha: 0.65)
      ..strokeWidth = (scale * 0.020).clamp(1.0, 2.8)
      ..strokeCap = StrokeCap.round;

    final fwdScrX = sinPsi;
    final fwdScrY = -cosPsi * sinBeta;
    final bodyAngle = math.atan2(fwdScrY, fwdScrX);

    final nearSide = sinPsi >= 0 ? 1 : -1;
    final farSide = -nearSide;

    void drawLegsForSide(int side) {
      for (int pair = -1; pair <= 1; pair++) {
        final phase = walkPhase + ((side * pair > 0) ? 0.0 : math.pi);
        final stride = math.sin(phase) * 0.06;
        final lift = math.max(0.0, math.cos(phase)) * 0.04;

        final xBase = pair == -1 ? 0.16 : (pair == 0 ? 0.02 : -0.14);
        final coxa = _projectBugLandmark(
          anchor: anchor,
          x: xBase,
          y: side * 0.16,
          z: 0.20,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final knee = _projectBugLandmark(
          anchor: anchor,
          x: xBase + 0.04,
          y: side * 0.32,
          z: 0.15 - lift,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final tarsus = _projectBugLandmark(
          anchor: anchor,
          x: xBase + 0.08,
          y: side * 0.36,
          z: 0.0 - stride, // Firmly touching dirt at Z=0
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawCircle(coxa, (scale * 0.038).clamp(1.6, 5.0), Paint()..color = const Color(0xFF120604));
        canvas.drawLine(coxa, knee, legCorePaint);
        canvas.drawLine(knee, tarsus, legCorePaint);
        canvas.drawLine(coxa, knee, legSssPaint);
      }
    }

    void drawHeadAndAntlers() {
      final clampIn = attackAnim * 0.14;
      final headCenter = _projectBugLandmark(
        anchor: anchor,
        x: 0.28,
        y: 0.0,
        z: 0.22,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      // Broad transverse head capsule
      canvas.save();
      canvas.translate(headCenter.dx, headCenter.dy);
      canvas.rotate(bodyAngle);
      final headRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.36, height: scale * 0.44);
      canvas.drawRRect(
        RRect.fromRectAndRadius(headRect, Radius.circular(scale * 0.06)),
        Paint()..color = const Color(0xFF1E0804),
      );

      // Lateral eyes
      for (int side in [-1, 1]) {
        canvas.drawCircle(
          Offset(scale * 0.02, side * scale * 0.19),
          (scale * 0.026).clamp(1.2, 3.4),
          Paint()..color = const Color(0xFF080201),
        );
      }
      canvas.restore();

      // Colossal Sickle Antler Mandibles
      final antlerPaint = Paint()
        ..color = const Color(0xFF380C04)
        ..strokeWidth = (scale * 0.068).clamp(2.4, 8.5)
        ..strokeCap = StrokeCap.round;
      final antlerRim = Paint()
        ..color = const Color(0xFFFF7A28).withValues(alpha: 0.70)
        ..strokeWidth = (scale * 0.020).clamp(0.9, 2.6)
        ..strokeCap = StrokeCap.round;
      final toothPaint = Paint()
        ..color = const Color(0xFF200602)
        ..strokeWidth = (scale * 0.035).clamp(1.4, 4.0)
        ..strokeCap = StrokeCap.round;

      for (int side in [-1, 1]) {
        final aBase = _projectBugLandmark(
          anchor: anchor,
          x: 0.34,
          y: side * 0.08,
          z: 0.22,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final aMid = _projectBugLandmark(
          anchor: anchor,
          x: 0.54,
          y: side * (0.20 - clampIn * 0.4),
          z: 0.24,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final aTip = _projectBugLandmark(
          anchor: anchor,
          x: 0.72,
          y: side * (0.04 - clampIn * 0.8),
          z: 0.26,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawLine(aBase, aMid, antlerPaint);
        canvas.drawLine(aMid, aTip, antlerPaint);
        canvas.drawLine(aBase, aMid, antlerRim);
        canvas.drawLine(aMid, aTip, antlerRim);

        // Crushing teeth along inner edge
        final t1 = Offset(aBase.dx + (aMid.dx - aBase.dx) * 0.65, aBase.dy + (aMid.dy - aBase.dy) * 0.65);
        final t1Target = _projectBugLandmark(
          anchor: anchor,
          x: 0.46,
          y: side * (0.08 - clampIn * 0.3),
          z: 0.23,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        canvas.drawLine(t1, t1Target, toothPaint);

        final t2 = Offset(aMid.dx + (aTip.dx - aMid.dx) * 0.50, aMid.dy + (aTip.dy - aMid.dy) * 0.50);
        final t2Target = _projectBugLandmark(
          anchor: anchor,
          x: 0.62,
          y: side * (0.02 - clampIn * 0.6),
          z: 0.25,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        canvas.drawLine(t2, t2Target, toothPaint);
      }
    }

    void drawPronotum() {
      final center = _projectBugLandmark(
        anchor: anchor,
        x: 0.12,
        y: 0.0,
        z: 0.24,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bodyAngle);

      final pronRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.46, height: scale * 0.48);
      final pronPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [
            hitFlash ? const Color(0xFFFFB296) : const Color(0xFF5C1C10),
            hitFlash ? const Color(0xFFDE4E30) : const Color(0xFF2E0C06),
            const Color(0xFF0F0402),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(pronRect);
      canvas.drawRRect(RRect.fromRectAndRadius(pronRect, Radius.circular(scale * 0.07)), pronPaint);

      // Specular highlight
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-scale * 0.06, -scale * 0.06), width: scale * 0.16, height: scale * 0.08),
        Paint()..color = const Color(0xFFFFF4DE).withValues(alpha: 0.88),
      );

      canvas.restore();
    }

    void drawElytra() {
      final center = _projectBugLandmark(
        anchor: anchor,
        x: -0.24,
        y: 0.0,
        z: 0.24,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bodyAngle);

      // Wine-red/mahogany elytra dome
      final elytraRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.82, height: scale * 0.54);
      final elytraPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 0.9,
          colors: [
            hitFlash ? const Color(0xFFFFD4C2) : const Color(0xFF7E2A18),
            hitFlash ? const Color(0xFFDE4E30) : const Color(0xFF4A140B),
            const Color(0xFF220804),
            const Color(0xFF0C0302),
          ],
          stops: const [0.0, 0.50, 0.85, 1.0],
        ).createShader(elytraRect);
      canvas.drawOval(elytraRect, elytraPaint);

      // Triangular dark scutellum
      final scutellumPath = Path()
        ..moveTo(scale * 0.38, -scale * 0.06)
        ..lineTo(scale * 0.38, scale * 0.06)
        ..lineTo(scale * 0.26, 0)
        ..close();
      canvas.drawPath(scutellumPath, Paint()..color = const Color(0xFF140502));

      // Central suture line
      canvas.drawLine(
        Offset(-scale * 0.40, 0),
        Offset(scale * 0.40, 0),
        Paint()
          ..color = const Color(0xFF080201)
          ..strokeWidth = (scale * 0.022).clamp(1.2, 3.0),
      );

      // Specular reflection hotspot
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-scale * 0.10, -scale * 0.08), width: scale * 0.36, height: scale * 0.12),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.90),
      );

      canvas.restore();
    }

    // Depth Sorting
    // 1. Far-side legs
    drawLegsForSide(farSide);

    // 2. Body segments
    if (cosPsi >= 0) {
      drawHeadAndAntlers();
      drawPronotum();
      drawElytra();
    } else {
      drawElytra();
      drawPronotum();
      drawHeadAndAntlers();
    }

    // 3. Near-side legs
    drawLegsForSide(nearSide);
  }

  /// Authentic Giant Wolf Spider (Hogna carolinensis): high cephalothorax with radiating furrows
  /// and tan median band, Lycosidae 8-eye cluster with huge glistening anterior median eyes,
  /// bulky chelicerae fangs with venom glints, furry pedipalps, velvety abdomen with spear
  /// cardiac mark and sepia chevrons, micro-hair grain, and 8 long bristled legs.
  void _drawRealisticWolfSpider(
    Canvas canvas, {
    required Offset anchor,
    required double scale,
    required double cosPsi,
    required double sinPsi,
    required double cosBeta,
    required double sinBeta,
    required double walkPhase,
    required double attackAnim,
    required bool hitFlash,
    required double fog,
  }) {
    final legCorePaint = Paint()
      ..color = hitFlash ? const Color(0xFFFF9E70) : const Color(0xFF261C14)
      ..strokeWidth = (scale * 0.052).clamp(2.0, 7.5)
      ..strokeCap = StrokeCap.round;
    final legSssPaint = Paint()
      ..color = const Color(0xFFFF8A38).withValues(alpha: 0.65)
      ..strokeWidth = (scale * 0.018).clamp(0.8, 2.4)
      ..strokeCap = StrokeCap.round;

    final fwdScrX = sinPsi;
    final fwdScrY = -cosPsi * sinBeta;
    final bodyAngle = math.atan2(fwdScrY, fwdScrX);

    final nearSide = sinPsi >= 0 ? 1 : -1;
    final farSide = -nearSide;

    void drawLegsForSide(int side) {
      final xBases = [0.14, 0.05, -0.04, -0.14];
      final yKnees = [0.32, 0.38, 0.40, 0.36];
      final zKnees = [0.32, 0.34, 0.34, 0.32];
      final xFeet = [0.38, 0.20, -0.10, -0.36];
      final yFeet = [0.40, 0.46, 0.48, 0.42];

      for (int p = 0; p < 4; p++) {
        final phase = walkPhase + ((side * (p.isEven ? 1 : -1) > 0) ? 0.0 : math.pi);
        final stride = math.sin(phase) * 0.07;
        final lift = math.max(0.0, math.cos(phase)) * 0.06;

        final coxa = _projectBugLandmark(
          anchor: anchor,
          x: xBases[p],
          y: side * 0.14,
          z: 0.18,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final knee = _projectBugLandmark(
          anchor: anchor,
          x: xBases[p] + (p < 2 ? 0.06 : -0.06),
          y: side * yKnees[p],
          z: zKnees[p] - lift,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final foot = _projectBugLandmark(
          anchor: anchor,
          x: xFeet[p],
          y: side * yFeet[p],
          z: 0.0 - stride, // Firmly touching dirt at Z=0
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );

        canvas.drawCircle(coxa, (scale * 0.034).clamp(1.4, 4.4), Paint()..color = const Color(0xFF0F0B08));
        canvas.drawLine(coxa, knee, legCorePaint);
        canvas.drawLine(knee, foot, legCorePaint);
        canvas.drawLine(coxa, knee, legSssPaint);

        // Tactile spines along the leg
        if (scale >= 30.0) {
          final spinePaint = Paint()
            ..color = const Color(0xFF140D09)
            ..strokeWidth = (scale * 0.015).clamp(0.8, 2.0);
          for (double st = 0.35; st <= 0.85; st += 0.30) {
            final spX = coxa.dx + (knee.dx - coxa.dx) * st;
            final spY = coxa.dy + (knee.dy - coxa.dy) * st;
            canvas.drawLine(Offset(spX, spY), Offset(spX + side * scale * 0.03, spY - scale * 0.02), spinePaint);
          }
        }

        // Arched knee joint cap
        canvas.drawCircle(knee, (scale * 0.036).clamp(1.4, 4.5), Paint()..color = const Color(0xFF0A0503));
        canvas.drawCircle(knee, (scale * 0.022).clamp(0.9, 2.8), Paint()..color = const Color(0xFF9E8260));
      }
    }

    void drawHeadEyesFangs() {
      final fangSpread = attackAnim * 0.06;
      final headCenter = _projectBugLandmark(
        anchor: anchor,
        x: 0.22,
        y: 0.0,
        z: 0.22,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );
      // Ocular tubercle mound behind eye cluster
      canvas.drawOval(
        Rect.fromCenter(center: headCenter, width: scale * 0.22, height: scale * 0.16),
        Paint()..color = const Color(0xFF180F0A),
      );

      // Lycosidae 8-eye cluster
      for (int side in [-1, 1]) {
        // Large Anterior Median Eyes (AME)
        final amePos = _projectBugLandmark(
          anchor: anchor,
          x: 0.23,
          y: side * 0.04,
          z: 0.24,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        canvas.drawCircle(amePos, (scale * 0.038).clamp(1.5, 4.8), Paint()..color = const Color(0xFF060302));
        canvas.drawCircle(
          Offset(amePos.dx - scale * 0.01, amePos.dy - scale * 0.01),
          (scale * 0.016).clamp(0.8, 2.0),
          Paint()..color = const Color(0xFFFFFBE8).withValues(alpha: 0.95),
        );

        // Posterior Median Eyes (PME)
        final pmePos = _projectBugLandmark(
          anchor: anchor,
          x: 0.20,
          y: side * 0.08,
          z: 0.26,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        canvas.drawCircle(pmePos, (scale * 0.026).clamp(1.1, 3.4), Paint()..color = const Color(0xFF100A06));

        // Lower Anterior Lateral Eyes
        final ale1 = _projectBugLandmark(
          anchor: anchor,
          x: 0.24,
          y: side * 0.025,
          z: 0.20,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final ale2 = _projectBugLandmark(
          anchor: anchor,
          x: 0.24,
          y: side * 0.065,
          z: 0.20,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        canvas.drawCircle(ale1, (scale * 0.016).clamp(0.8, 2.0), Paint()..color = const Color(0xFF0C0704));
        canvas.drawCircle(ale2, (scale * 0.016).clamp(0.8, 2.0), Paint()..color = const Color(0xFF0C0704));
      }

      // Chelicerae & Fangs with venom glint
      final fangPaint = Paint()
        ..color = const Color(0xFF140A06)
        ..strokeWidth = (scale * 0.060).clamp(2.0, 7.0)
        ..strokeCap = StrokeCap.round;

      for (int side in [-1, 1]) {
        final fBase = _projectBugLandmark(
          anchor: anchor,
          x: 0.24,
          y: side * (0.05 + fangSpread),
          z: 0.16,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final fTip = _projectBugLandmark(
          anchor: anchor,
          x: 0.26 + attackAnim * 0.08,
          y: side * (0.02 - fangSpread * 0.5),
          z: 0.08,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        canvas.drawLine(fBase, fTip, fangPaint);
        canvas.drawCircle(
          fTip,
          (scale * 0.034).clamp(1.5, 4.2),
          Paint()..color = const Color(0xFFB4F06E).withValues(alpha: 0.90),
        );

        // Furry Pedipalps
        final pBase = _projectBugLandmark(
          anchor: anchor,
          x: 0.20,
          y: side * 0.08,
          z: 0.18,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final pKnee = _projectBugLandmark(
          anchor: anchor,
          x: 0.28,
          y: side * 0.11,
          z: 0.12,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final pTip = _projectBugLandmark(
          anchor: anchor,
          x: 0.34,
          y: side * 0.09,
          z: 0.05,
          cosPsi: cosPsi,
          sinPsi: sinPsi,
          cosBeta: cosBeta,
          sinBeta: sinBeta,
          scale: scale,
        );
        final palpPaint = Paint()
          ..color = const Color(0xFF4A3828)
          ..strokeWidth = (scale * 0.044).clamp(1.5, 5.5)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(pBase, pKnee, palpPaint);
        canvas.drawLine(pKnee, pTip, palpPaint);
      }
    }

    void drawProsoma() {
      final center = _projectBugLandmark(
        anchor: anchor,
        x: 0.06,
        y: 0.0,
        z: 0.20,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bodyAngle);

      final prosomaRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.54, height: scale * 0.46);
      final prosomaPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [
            hitFlash ? const Color(0xFFFFB296) : const Color(0xFF5E4836),
            hitFlash ? const Color(0xFFDE4E30) : const Color(0xFF342419),
            const Color(0xFF120B07),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(prosomaRect);
      canvas.drawOval(prosomaRect, prosomaPaint);

      // Radiating thoracic furrows
      final furrowPaint = Paint()
        ..color = const Color(0xFF140D08)
        ..strokeWidth = (scale * 0.020).clamp(1.0, 2.5);
      for (int side in [-1, 1]) {
        for (double ay = -0.14; ay <= 0.14; ay += 0.09) {
          canvas.drawLine(Offset.zero, Offset(side * scale * 0.22, ay * scale), furrowPaint);
        }
      }

      // Tan median dorsal band
      canvas.drawLine(
        Offset(-scale * 0.22, 0),
        Offset(scale * 0.22, 0),
        Paint()
          ..color = const Color(0xFFD4BE98).withValues(alpha: 0.78)
          ..strokeWidth = (scale * 0.07).clamp(2.5, 7.0)
          ..strokeCap = StrokeCap.round,
      );

      // Chitin highlight
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-scale * 0.06, -scale * 0.06), width: scale * 0.15, height: scale * 0.08),
        Paint()..color = const Color(0xFFFFF2DE).withValues(alpha: 0.85),
      );

      canvas.restore();
    }

    void drawOpisthosoma() {
      final center = _projectBugLandmark(
        anchor: anchor,
        x: -0.28,
        y: 0.0,
        z: 0.22,
        cosPsi: cosPsi,
        sinPsi: sinPsi,
        cosBeta: cosBeta,
        sinBeta: sinBeta,
        scale: scale,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bodyAngle);

      final abdomenRect = Rect.fromCenter(center: Offset.zero, width: scale * 0.72, height: scale * 0.54);
      final abdomenPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 0.85,
          colors: [
            hitFlash ? const Color(0xFFFFD4C2) : const Color(0xFF6E5642),
            hitFlash ? const Color(0xFFDE4E30) : const Color(0xFF3E2E22),
            const Color(0xFF1E150F),
          ],
          stops: const [0.0, 0.60, 1.0],
        ).createShader(abdomenRect);
      canvas.drawOval(abdomenRect, abdomenPaint);

      // Dark spear-shaped cardiac mark along dorsum
      final cardiacPath = Path()
        ..moveTo(scale * 0.25, 0)
        ..lineTo(scale * 0.12, -scale * 0.06)
        ..lineTo(-scale * 0.04, 0)
        ..lineTo(scale * 0.12, scale * 0.06)
        ..close();
      canvas.drawPath(cardiacPath, Paint()..color = const Color(0xFF160E0A));

      // Sepia chevrons behind cardiac mark
      final chevronPaint = Paint()
        ..color = const Color(0xFF22160E).withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (scale * 0.032).clamp(1.4, 4.0);
      for (double cx = -0.08; cx >= -0.24; cx -= 0.08) {
        final path = Path()
          ..moveTo(cx * scale, -scale * 0.14)
          ..lineTo((cx - 0.04) * scale, 0)
          ..lineTo(cx * scale, scale * 0.14);
        canvas.drawPath(path, chevronPaint);
      }

      // Tactile micro-hair grain dots
      if (scale >= 35.0) {
        final bumpPaint = Paint()..color = const Color(0xFFD4B892).withValues(alpha: 0.32);
        for (int k = 0; k < 12; k++) {
          final bx = -scale * 0.28 + (k / 12.0) * scale * 0.48;
          final by = math.sin(k * 2.3) * scale * 0.16;
          canvas.drawCircle(Offset(bx, by), (scale * 0.014).clamp(0.8, 2.0), bumpPaint);
        }
      }

      // Spinnerets at rear
      canvas.drawCircle(Offset(-scale * 0.34, -scale * 0.04), (scale * 0.024).clamp(1.0, 3.0), Paint()..color = const Color(0xFF1C130D));
      canvas.drawCircle(Offset(-scale * 0.34, scale * 0.04), (scale * 0.024).clamp(1.0, 3.0), Paint()..color = const Color(0xFF1C130D));

      canvas.restore();
    }

    // Depth Sorting
    // 1. Far-side 4 legs
    drawLegsForSide(farSide);

    // 2. Body segments
    if (cosPsi >= 0) {
      drawHeadEyesFangs();
      drawProsoma();
      drawOpisthosoma();
    } else {
      drawOpisthosoma();
      drawProsoma();
      drawHeadEyesFangs();
    }

    // 3. Near-side 4 legs
    drawLegsForSide(nearSide);
  }

  void _drawForageItem3D(
    Canvas canvas,
    ForageItem item,
    _ProjectedPoint proj,
    List<double> zBuffer,
    double colWidth,
  ) {
    if (!_isVisibleAt(proj.screenX, proj.depth, zBuffer, colWidth)) return;
    final radius = (proj.scale * 0.13).clamp(4.0, 48.0);
    final center = Offset(proj.screenX, proj.screenY);
    final fog = _computeExponentialFog(proj.depth);

    // Contact drop shadow on ground
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.85),
        width: radius * 1.8,
        height: radius * 0.6,
      ),
      Paint()..color = const Color(0xFF0C0704).withValues(alpha: 0.60 * fog),
    );

    final itemRect = Rect.fromCircle(center: center, radius: radius);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          Colors.white,
          Color.lerp(humidUndergrowthFog, item.color, fog)!,
          Color.lerp(humidUndergrowthFog, Colors.black, 0.65)!,
        ],
      ).createShader(itemRect);
    canvas.drawCircle(center, radius, bodyPaint);

    // Specular glint
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.88 * fog),
    );
  }

  void _drawPollenParticle3D(
    Canvas canvas,
    NatureParticle3D pt,
    _ProjectedPoint proj,
    List<double> zBuffer,
    double colWidth,
  ) {
    if (!_isVisibleAt(proj.screenX, proj.depth, zBuffer, colWidth)) return;
    final alpha = (pt.life / pt.maxLife).clamp(0.0, 1.0) * 0.65;
    final r = (proj.scale * pt.size).clamp(1.5, 18.0);

    // Near-Field Macro Bokeh on floating spores/dust motes very close to camera
    if (proj.depth < 0.85) {
      final bokehR = r * 2.2;
      final bokehPaint = Paint()
        ..color = pt.color.withValues(alpha: alpha * 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(proj.screenX, proj.screenY), bokehR, bokehPaint);
      canvas.drawCircle(
        Offset(proj.screenX, proj.screenY),
        bokehR,
        Paint()
          ..color = pt.color.withValues(alpha: alpha * 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    } else {
      canvas.drawCircle(
        Offset(proj.screenX, proj.screenY),
        r,
        Paint()..color = pt.color.withValues(alpha: alpha),
      );
    }
  }

  void _drawFloatingNote3D(
    Canvas canvas,
    FloatingNote3D fn,
    _ProjectedPoint proj,
    List<double> zBuffer,
    double colWidth,
  ) {
    if (!_isVisibleAt(proj.screenX, proj.depth, zBuffer, colWidth)) return;
    final alpha = (fn.life / fn.maxLife).clamp(0.0, 1.0);
    final fontSize = (16.0 / math.max(0.6, proj.depth * 0.35)).clamp(10.0, 16.0);
    final tp = TextPainter(
      text: TextSpan(
        text: fn.text,
        style: TextStyle(
          color: fn.color.withValues(alpha: alpha),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: alpha),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(proj.screenX - tp.width * 0.5, proj.screenY - tp.height * 0.5));
  }

  /// Subtle macro-lens optical vignette, edge blur / chromatic aberration,
  /// and shallow depth-of-field foreground softening.
  void _drawMacroLensVignette(Canvas canvas, Size size) {
    // 1. Natural Macro Lens Optical Vignette with Warm Loamy Corner Falloff
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        radius: 0.96,
        colors: [
          Colors.transparent,
          const Color(0xFF140D07).withValues(alpha: 0.22),
          const Color(0xFF0F0A05).withValues(alpha: 0.48),
        ],
        stops: const [0.55, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);

    // 2. Optical Edge Chromatic Aberration Fringe (warm amber vs cool emerald lens dispersion)
    final leftFringe = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0x18D9521E), Colors.transparent],
        stops: [0.0, 0.08],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), leftFringe);

    final rightFringe = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [Color(0x1838A86C), Colors.transparent],
        stops: [0.0, 0.08],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), rightFringe);

    // 3. Foreground Dirt-Level Edge Softening (Macro Camera Down in the Dirt)
    final foregroundBlur = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0x2E120A05),
          Colors.transparent,
        ],
        stops: [0.0, 0.07],
      ).createShader(Rect.fromLTWH(0, size.height * 0.90, size.width, size.height * 0.10));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.90, size.width, size.height * 0.10), foregroundBlur);
  }

  @override
  bool shouldRepaint(covariant CyberRenderer oldDelegate) => true;
}

class _ProjectedPoint {
  final double screenX;
  final double screenY;
  final double depth;
  final double scale;

  const _ProjectedPoint({
    required this.screenX,
    required this.screenY,
    required this.depth,
    required this.scale,
  });
}

class _SortableRenderItem {
  final double depth;
  final VoidCallback draw;

  const _SortableRenderItem({
    required this.depth,
    required this.draw,
  });
}
