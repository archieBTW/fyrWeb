import 'dart:math' as math;
import 'dart:ui';

import 'data.dart';
import 'sketch.dart';

enum Facing { down, up, left, right }

/// Draws the player doodle (and its equipment) centered at [c]; [s] is the
/// approximate height of the character.
void drawDoodle(Canvas canvas, Offset c, double s, Facing f, double walk,
    Map<Slot, Item?> eq, {int seed = 1, bool bob = true}) {
  final w = math.max(1.2, s * 0.045);
  final step = math.sin(walk * math.pi * 2);
  final bodyC = c + Offset(0, -s * 0.12 + (bob ? -step.abs() * s * 0.03 : 0));
  final r = s * 0.28;
  final side = f == Facing.left ? -1.0 : 1.0;
  final head = eq[Slot.head]?.id;
  final body = eq[Slot.body]?.id;
  final weapon = eq[Slot.weapon]?.id;
  final shield = eq[Slot.shield]?.id;

  // shadow
  canvas.drawOval(Rect.fromCenter(center: c + Offset(0, s * 0.38), width: s * 0.5, height: s * 0.1),
      Sketch.fill(const Color(0x22000000)));

  // cape behind
  if (body == 'cape') {
    final flap = math.sin(walk * math.pi * 2 + 1) * s * 0.04;
    final path = Path()
      ..moveTo(bodyC.dx - r * 0.7, bodyC.dy - r * 0.6)
      ..lineTo(bodyC.dx + r * 0.7, bodyC.dy - r * 0.6)
      ..lineTo(bodyC.dx + r * 1.0 + flap, bodyC.dy + r * 1.35)
      ..lineTo(bodyC.dx - r * 1.0 + flap, bodyC.dy + r * 1.35)
      ..close();
    if (f == Facing.up) {
      // cape drawn later on top for back view
    } else {
      Sketch.scribbleFill(canvas, path, path.getBounds(), Sketch.bluePencil, seed + 5);
      canvas.drawPath(path, Sketch.pen(w, Sketch.bluePencil));
    }
  }

  // legs
  final hip = bodyC + Offset(0, r * 0.8);
  final footY = c.dy + s * 0.36;
  for (final k in [-1, 1]) {
    final swing = (f == Facing.left || f == Facing.right) ? step * k * s * 0.12 : 0.0;
    final lift = (f == Facing.down || f == Facing.up) ? math.max(0.0, step * k) * s * 0.05 : 0.0;
    final foot = Offset(hip.dx + k * r * 0.45 + swing, footY - lift);
    Sketch.line(canvas, hip + Offset(k * r * 0.35, 0), foot, seed + 40 + k, w: w);
    Sketch.line(canvas, foot, foot + Offset((f == Facing.left ? -1 : 1) * s * 0.07, 0), seed + 50 + k, w: w);
  }

  // arms
  final shoulderY = bodyC.dy + r * 0.1;
  final armSwing = step * s * 0.06;
  final handR = Offset(bodyC.dx + r * 1.45, shoulderY + r * 0.55 + armSwing);
  final handL = Offset(bodyC.dx - r * 1.45, shoulderY + r * 0.55 - armSwing);
  Sketch.line(canvas, Offset(bodyC.dx + r * 0.9, shoulderY), handR, seed + 60, w: w);
  Sketch.line(canvas, Offset(bodyC.dx - r * 0.9, shoulderY), handL, seed + 61, w: w);

  // Weapon / shield: behind body when facing up, else in front.
  void drawGear() {
    final wHand = f == Facing.left ? handL : handR;
    final sHand = f == Facing.left ? handR : handL;
    if (weapon != null) _drawWeapon(canvas, wHand, s, weapon, seed, side);
    if (shield != null) _drawShield(canvas, sHand, s, shield, seed);
  }

  if (f == Facing.up) drawGear();

  // body blob
  final bodyPath = Sketch.wobblyCirclePath(bodyC, r, r * 1.05, seed + 2, overshoot: 0);
  canvas.drawPath(bodyPath, Sketch.fill(Sketch.paper));
  if (body == 'cardboard') {
    final box = Rect.fromCenter(center: bodyC + Offset(0, r * 0.25), width: r * 2.1, height: r * 1.4);
    canvas.drawRect(box, Sketch.fill(const Color(0xFFD9B98A)));
    Sketch.hatch(canvas, Path()..addRect(box), box, seed + 7, gap: s * 0.05, color: const Color(0xFF8B6B3D));
    Sketch.rect(canvas, box, seed + 8, w: w, color: const Color(0xFF6B4E2A));
    Sketch.line(canvas, box.topCenter, box.bottomCenter, seed + 9, w: w * 0.6, color: const Color(0xFF6B4E2A));
  }
  canvas.drawPath(Sketch.wobblyCirclePath(bodyC, r, r * 1.05, seed + 2), Sketch.pen(w * 1.1));

  // face
  if (f != Facing.up) {
    final lookX = f == Facing.left ? -r * 0.35 : f == Facing.right ? r * 0.35 : 0.0;
    final eyeY = bodyC.dy - r * 0.25;
    for (final k in [-1, 1]) {
      if (f != Facing.down && k == -side) continue;
      final ex = bodyC.dx + lookX + k * r * 0.32;
      canvas.drawOval(Rect.fromCenter(center: Offset(ex, eyeY), width: r * 0.16, height: r * 0.26),
          Sketch.fill(Sketch.graphite));
    }
    final mouth = Path()
      ..moveTo(bodyC.dx + lookX - r * 0.18, bodyC.dy + r * 0.1)
      ..quadraticBezierTo(bodyC.dx + lookX, bodyC.dy + r * 0.3, bodyC.dx + lookX + r * 0.18, bodyC.dy + r * 0.1);
    canvas.drawPath(mouth, Sketch.pen(w * 0.8));
    // cheeks
    canvas.drawCircle(Offset(bodyC.dx + lookX - r * 0.5, bodyC.dy + r * 0.05), r * 0.1,
        Sketch.fill(const Color(0x44E57373)));
    canvas.drawCircle(Offset(bodyC.dx + lookX + r * 0.5, bodyC.dy + r * 0.05), r * 0.1,
        Sketch.fill(const Color(0x44E57373)));
  }

  // scarf
  if (body == 'scarf') {
    final y = bodyC.dy + r * 0.45;
    final band = Path()
      ..moveTo(bodyC.dx - r * 0.95, y - r * 0.12)
      ..quadraticBezierTo(bodyC.dx, y + r * 0.2, bodyC.dx + r * 0.95, y - r * 0.12)
      ..lineTo(bodyC.dx + r * 0.9, y + r * 0.15)
      ..quadraticBezierTo(bodyC.dx, y + r * 0.45, bodyC.dx - r * 0.9, y + r * 0.15)
      ..close();
    Sketch.scribbleFill(canvas, band, band.getBounds(), Sketch.redPencil, seed + 11, gap: 3);
    canvas.drawPath(band, Sketch.pen(w * 0.8, Sketch.redPencil));
    final flap = math.sin(walk * math.pi * 4) * r * 0.2;
    final tx = bodyC.dx - side * r * 0.6;
    Sketch.line(canvas, Offset(tx, y + r * 0.2), Offset(tx - side * r * 0.5, y + r * 0.9 + flap), seed + 12,
        w: w * 2, color: Sketch.redPencil);
  }
  if (body == 'cape' && f == Facing.up) {
    final path = Path()
      ..moveTo(bodyC.dx - r * 0.8, bodyC.dy - r * 0.5)
      ..lineTo(bodyC.dx + r * 0.8, bodyC.dy - r * 0.5)
      ..lineTo(bodyC.dx + r * 1.0, bodyC.dy + r * 1.3)
      ..lineTo(bodyC.dx - r * 1.0, bodyC.dy + r * 1.3)
      ..close();
    Sketch.scribbleFill(canvas, path, path.getBounds(), Sketch.bluePencil, seed + 5);
    canvas.drawPath(path, Sketch.pen(w, Sketch.bluePencil));
  }

  // headgear
  final top = Offset(bodyC.dx, bodyC.dy - r * 0.95);
  if (head == 'paperhat') {
    final pts = [top + Offset(-r * 0.85, r * 0.1), top + Offset(0, -r * 0.9), top + Offset(r * 0.85, r * 0.1)];
    final p = Path()..addPolygon(pts, true);
    canvas.drawPath(p, Sketch.fill(const Color(0xFFF2EEE2)));
    Sketch.hatch(canvas, p, p.getBounds(), seed + 13, gap: s * 0.03, color: const Color(0xFFBBBBBB));
    Sketch.poly(canvas, pts, seed + 14, w: w);
    Sketch.line(canvas, top + Offset(-r * 0.5, -r * 0.2), top + Offset(r * 0.4, -r * 0.3), seed + 15, w: w * 0.5);
  } else if (head == 'helmet') {
    final rect = Rect.fromCenter(center: top + Offset(0, r * 0.05), width: r * 1.6, height: r * 1.2);
    final p = Path()..addArc(rect, math.pi, math.pi);
    canvas.drawPath(p, Sketch.fill(const Color(0xFFC9CCD3)));
    Sketch.hatch(canvas, p, rect, seed + 16, gap: s * 0.025, color: Sketch.graphite);
    canvas.drawPath(p, Sketch.pen(w));
    Sketch.line(canvas, top + Offset(-r * 0.95, r * 0.05), top + Offset(r * 0.95, r * 0.05), seed + 17, w: w * 1.4);
    for (var i = -2; i <= 2; i++) {
      canvas.drawCircle(top + Offset(i * r * 0.25, -r * 0.25 + (i.abs() * r * 0.06)), r * 0.04,
          Sketch.fill(Sketch.graphite));
    }
  } else if (head == 'crown') {
    final b = top + Offset(0, r * 0.1);
    final pts = [
      b + Offset(-r * 0.7, 0),
      b + Offset(-r * 0.75, -r * 0.7),
      b + Offset(-r * 0.35, -r * 0.35),
      b + Offset(0, -r * 0.85),
      b + Offset(r * 0.35, -r * 0.35),
      b + Offset(r * 0.75, -r * 0.7),
      b + Offset(r * 0.7, 0),
    ];
    final p = Path()..addPolygon(pts, true);
    Sketch.scribbleFill(canvas, p, p.getBounds(), Sketch.yellowPencil, seed + 18, gap: 3);
    Sketch.poly(canvas, pts, seed + 19, w: w, color: const Color(0xFF9A7400));
    canvas.drawCircle(b + Offset(0, -r * 0.25), r * 0.09, Sketch.fill(Sketch.redPencil));
  }

  if (f != Facing.up) drawGear();
}

void _drawWeapon(Canvas canvas, Offset hand, double s, String id, int seed, double side) {
  final w = math.max(1.0, s * 0.035);
  final dir = Offset(side * 0.35, -1);
  final n = dir / dir.distance;
  final perp = Offset(-n.dy, n.dx);
  switch (id) {
    case 'pencil':
      final len = s * 0.55;
      final tip = hand + n * len;
      final base = hand - n * s * 0.08;
      final hw = s * 0.035;
      final body = [base + perp * hw, tip - n * s * 0.1 + perp * hw, tip - n * s * 0.1 - perp * hw, base - perp * hw];
      final p = Path()..addPolygon(body, true);
      canvas.drawPath(p, Sketch.fill(const Color(0xFFF4C430)));
      Sketch.poly(canvas, body, seed + 80, w: w);
      final cone = [tip - n * s * 0.1 + perp * hw, tip, tip - n * s * 0.1 - perp * hw];
      canvas.drawPath(Path()..addPolygon(cone, true), Sketch.fill(const Color(0xFFE8C9A0)));
      Sketch.poly(canvas, cone, seed + 81, w: w);
      canvas.drawCircle(tip - n * s * 0.02, w * 1.2, Sketch.fill(Sketch.graphite));
      final er = [base + perp * hw, base - perp * hw, base - perp * hw - n * s * 0.06, base + perp * hw - n * s * 0.06];
      canvas.drawPath(Path()..addPolygon(er, true), Sketch.fill(const Color(0xFFF2A0B0)));
      Sketch.poly(canvas, er, seed + 82, w: w);
    case 'ruler':
      final len = s * 0.7;
      final hw = s * 0.05;
      final a = hand - n * s * 0.05, b = hand + n * len;
      final pts = [a + perp * hw, b + perp * hw, b - perp * hw, a - perp * hw];
      canvas.drawPath(Path()..addPolygon(pts, true), Sketch.fill(const Color(0xFFE9E1C8)));
      Sketch.poly(canvas, pts, seed + 83, w: w);
      for (var i = 1; i < 12; i++) {
        final p = Offset.lerp(a, b, i / 12)!;
        final l = i % 4 == 0 ? hw * 1.2 : hw * 0.6;
        canvas.drawLine(p + perp * hw, p + perp * (hw - l), Sketch.pen(w * 0.5));
      }
    case 'compass':
      final top = hand + n * s * 0.15;
      final l1 = hand + n * s * 0.75 + perp * s * 0.08;
      final l2 = hand + n * s * 0.75 - perp * s * 0.08;
      Sketch.line(canvas, hand - n * s * 0.1, top, seed + 84, w: w * 1.5);
      Sketch.line(canvas, top, l1, seed + 85, w: w * 1.3, color: const Color(0xFF55606E));
      Sketch.line(canvas, top, l2, seed + 86, w: w * 1.3, color: const Color(0xFF55606E));
      canvas.drawCircle(top, w * 2, Sketch.fill(Sketch.graphite));
      canvas.drawCircle(l1, w * 1.1, Sketch.fill(Sketch.redPencil));
  }
}

void _drawShield(Canvas canvas, Offset hand, double s, String id, int seed) {
  final w = math.max(1.0, s * 0.035);
  if (id == 'cap') {
    final r = s * 0.15;
    canvas.drawCircle(hand, r, Sketch.fill(const Color(0xFFD8DEE6)));
    Sketch.circle(canvas, hand, r, seed + 90, w: w, color: Sketch.redPencil);
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      canvas.drawLine(hand + Offset(math.cos(a), math.sin(a)) * r * 0.75,
          hand + Offset(math.cos(a), math.sin(a)) * r, Sketch.pen(w * 0.6, Sketch.redPencil));
    }
    Sketch.circle(canvas, hand, r * 0.45, seed + 91, w: w * 0.6);
  } else if (id == 'eraser') {
    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: hand, width: s * 0.3, height: s * 0.4), Radius.circular(s * 0.06));
    canvas.drawRRect(rect, Sketch.fill(const Color(0xFFF2A0B0)));
    final p = Path()..addRRect(rect);
    Sketch.hatch(canvas, p, rect.outerRect, seed + 92, gap: s * 0.04, color: const Color(0xFFC96A80));
    canvas.drawRRect(rect, Sketch.pen(w));
    final band = Rect.fromLTWH(rect.left, rect.top + rect.height * 0.55, rect.width, rect.height * 0.25);
    canvas.drawRect(band, Sketch.fill(const Color(0xFF6C8EBF)));
    Sketch.rect(canvas, band, seed + 93, w: w * 0.7);
  }
}

/// Enemies, centered at [c] with size [s].
void drawEnemy(Canvas canvas, Offset c, double s, String id, double t, {int seed = 7}) {
  final w = math.max(1.4, s * 0.03);
  final bob = math.sin(t * 3) * s * 0.03;
  canvas.drawOval(Rect.fromCenter(center: c + Offset(0, s * 0.42), width: s * 0.7, height: s * 0.12),
      Sketch.fill(const Color(0x22000000)));
  switch (id) {
    case 'blob':
      final ctr = c + Offset(0, s * 0.1 + bob);
      final p = Path()
        ..moveTo(ctr.dx - s * 0.38, ctr.dy + s * 0.3)
        ..quadraticBezierTo(ctr.dx - s * 0.45, ctr.dy - s * 0.35, ctr.dx, ctr.dy - s * 0.32)
        ..quadraticBezierTo(ctr.dx + s * 0.45, ctr.dy - s * 0.35, ctr.dx + s * 0.38, ctr.dy + s * 0.3)
        ..close();
      canvas.drawPath(p, Sketch.fill(const Color(0xFFF7C5CF)));
      Sketch.scribbleFill(canvas, p, p.getBounds(), const Color(0xFFE88AA0), seed);
      canvas.drawPath(p, Sketch.pen(w));
      _angryEyes(canvas, ctr + Offset(0, -s * 0.08), s * 0.6, w, seed);
      // smudges
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(ctr + Offset(-s * 0.5 - i * s * 0.08, s * 0.25 - i * s * 0.03), s * 0.02,
            Sketch.fill(Sketch.lightGraphite));
      }
    case 'spider':
      final ctr = c + Offset(0, bob);
      for (var i = 0; i < 4; i++) {
        for (final k in [-1, 1]) {
          final a = (i - 1.5) * 0.45;
          final knee = ctr + Offset(k * s * 0.32, -s * 0.15 + a * s * 0.3 + math.sin(t * 8 + i) * s * 0.02);
          final foot = ctr + Offset(k * s * 0.48, s * 0.12 + a * s * 0.3);
          Sketch.line(canvas, ctr, knee, seed + i * 3 + k, w: w);
          Sketch.line(canvas, knee, foot, seed + i * 5 + k, w: w);
        }
      }
      final p = Sketch.wobblyCirclePath(ctr, s * 0.22, s * 0.2, seed, overshoot: 0);
      canvas.drawPath(p, Sketch.fill(const Color(0xFF2B2B40)));
      canvas.drawPath(Sketch.wobblyCirclePath(ctr, s * 0.22, s * 0.2, seed), Sketch.pen(w));
      for (final k in [-1, 1]) {
        canvas.drawCircle(ctr + Offset(k * s * 0.07, -s * 0.04), s * 0.045, Sketch.fill(Colors.white));
        canvas.drawCircle(ctr + Offset(k * s * 0.07, -s * 0.03), s * 0.02, Sketch.fill(Sketch.redPencil));
      }
      // ink drips
      canvas.drawCircle(ctr + Offset(0, s * 0.3), s * 0.025, Sketch.fill(const Color(0xFF2B2B40)));
    case 'snake':
      final ctr = c + Offset(0, s * 0.05);
      final p = Path();
      final pts = <Offset>[];
      for (var i = 0; i <= 40; i++) {
        final u = i / 40;
        final x = (u - 0.5) * s * 0.85;
        final y = math.sin(u * math.pi * 3 + t * 4) * s * 0.12 + bob;
        pts.add(ctr + Offset(x, y + s * 0.1));
      }
      p.addPolygon(pts, false);
      canvas.drawPath(p, Sketch.pen(s * 0.06, const Color(0xFF9AA4B0)));
      canvas.drawPath(p, Sketch.pen(w, Sketch.graphite));
      final head = pts.last + Offset(s * 0.05, -s * 0.04);
      Sketch.circle(canvas, head, s * 0.1, seed, w: w, fillColor: const Color(0xFFB8C0CA), ry: s * 0.08);
      canvas.drawCircle(head + Offset(s * 0.03, -s * 0.02), s * 0.02, Sketch.fill(Sketch.graphite));
      Sketch.line(canvas, head + Offset(s * 0.1, s * 0.01), head + Offset(s * 0.17, s * 0.03), seed + 3,
          w: w * 0.8, color: Sketch.redPencil);
    case 'knight':
      final ctr = c + Offset(0, bob * 0.5);
      // crayon body
      final body = Rect.fromCenter(center: ctr + Offset(0, s * 0.08), width: s * 0.36, height: s * 0.55);
      canvas.drawRect(body, Sketch.fill(const Color(0xFFE57373)));
      Sketch.scribbleFill(canvas, Path()..addRect(body), body, Sketch.redPencil, seed);
      Sketch.rect(canvas, body, seed + 1, w: w);
      final label = Rect.fromLTWH(body.left, body.top + body.height * 0.35, body.width, body.height * 0.3);
      canvas.drawRect(label, Sketch.fill(Sketch.paper));
      Sketch.rect(canvas, label, seed + 2, w: w * 0.7);
      // crayon tip helmet
      final tip = [body.topLeft, Offset(ctr.dx, body.top - s * 0.25), body.topRight];
      canvas.drawPath(Path()..addPolygon(tip, true), Sketch.fill(const Color(0xFFC0392B)));
      Sketch.poly(canvas, tip, seed + 3, w: w);
      _angryEyes(canvas, Offset(ctr.dx, body.top + body.height * 0.18), s * 0.4, w, seed);
      // sword
      final hand = body.centerRight + Offset(s * 0.08, s * 0.05);
      Sketch.line(canvas, body.centerRight, hand, seed + 4, w: w);
      final swing = math.sin(t * 2) * 0.15;
      final blade = hand + Offset(math.sin(0.4 + swing), -math.cos(0.4 + swing)) * s * 0.45;
      Sketch.line(canvas, hand, blade, seed + 5, w: w * 2.5, color: const Color(0xFF8899AA));
      Sketch.line(canvas, hand + Offset(-s * 0.06, 0), hand + Offset(s * 0.06, 0), seed + 6, w: w * 1.5);
      // legs
      Sketch.line(canvas, body.bottomLeft + Offset(s * 0.06, 0), body.bottomLeft + Offset(s * 0.02, s * 0.12),
          seed + 7, w: w);
      Sketch.line(canvas, body.bottomRight - Offset(s * 0.06, 0), body.bottomRight + Offset(-s * 0.02, s * 0.12),
          seed + 8, w: w);
  }
}

void _angryEyes(Canvas canvas, Offset c, double s, double w, int seed) {
  for (final k in [-1, 1]) {
    final e = c + Offset(k * s * 0.18, 0);
    canvas.drawCircle(e, s * 0.08, Sketch.fill(Colors.white));
    canvas.drawCircle(e, s * 0.08, Sketch.pen(w * 0.7));
    canvas.drawCircle(e + Offset(-k * s * 0.02, s * 0.02), s * 0.035, Sketch.fill(Sketch.graphite));
    Sketch.line(canvas, e + Offset(-k * s * 0.12, -s * 0.16), e + Offset(k * s * 0.06, -s * 0.08), seed + k,
        w: w);
  }
}

class Colors {
  static const white = Color(0xFFFFFFFF);
}

/// Small item icon for menus.
void drawItemIcon(Canvas canvas, Offset c, double s, String id, {int seed = 3}) {
  final w = math.max(1.0, s * 0.06);
  switch (id) {
    case 'apple':
      Sketch.circle(canvas, c + Offset(0, s * 0.05), s * 0.32, seed, w: w, fillColor: const Color(0xFFF08080));
      Sketch.line(canvas, c + Offset(0, -s * 0.25), c + Offset(s * 0.05, -s * 0.42), seed + 1, w: w);
      Sketch.circle(canvas, c + Offset(s * 0.15, -s * 0.35), s * 0.08, seed + 2,
          w: w * 0.6, fillColor: const Color(0xFF8FD18F), ry: s * 0.05);
    case 'cookie':
      Sketch.circle(canvas, c, s * 0.35, seed, w: w, fillColor: const Color(0xFFDDB27A));
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(c + Offset(Sketch.j(seed + i, s * 0.2), Sketch.j(seed + i + 9, s * 0.2)), s * 0.05,
            Sketch.fill(Sketch.graphite));
      }
    case 'juice':
      final r = Rect.fromCenter(center: c + Offset(0, s * 0.05), width: s * 0.45, height: s * 0.6);
      canvas.drawRect(r, Sketch.fill(const Color(0xFFFFCC80)));
      Sketch.rect(canvas, r, seed, w: w);
      Sketch.line(canvas, r.topCenter + Offset(s * 0.1, 0), r.topCenter + Offset(s * 0.18, -s * 0.25), seed + 1,
          w: w, color: Sketch.redPencil);
    case 'tack':
      Sketch.circle(canvas, c + Offset(0, -s * 0.1), s * 0.25, seed, w: w, fillColor: const Color(0xFFE57373), ry: s * 0.12);
      Sketch.line(canvas, c + Offset(0, s * 0.02), c + Offset(0, s * 0.4), seed + 1, w: w);
    default:
      final it = items[id];
      if (it?.slot == Slot.weapon) {
        _drawWeapon(canvas, c + Offset(-s * 0.15, s * 0.3), s * 0.9, id, seed, 1);
      } else if (it?.slot == Slot.shield) {
        _drawShield(canvas, c, s * 1.4, id, seed);
      } else if (it != null) {
        // head/body: draw mini doodle wearing it
        drawDoodle(canvas, c + Offset(0, s * 0.05), s * 0.9, Facing.down, 0, {it.slot!: it},
            seed: seed, bob: false);
      }
  }
}

