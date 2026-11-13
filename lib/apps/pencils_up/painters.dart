import 'dart:math' as math;

import 'package:flutter/material.dart' hide Colors;

import 'data.dart';
import 'draw.dart';
import 'game.dart';
import 'sketch.dart';

const _green = Color(0xFF5E9E5E);
const _water = Color(0xFF7FB2E5);

void _paperLines(Canvas c, Rect view, double gap, {double marginX = double.nan}) {
  c.drawRect(view, Sketch.fill(Sketch.paper));
  final p = Paint()
    ..color = Sketch.blueLine
    ..strokeWidth = math.max(1, gap * 0.03);
  final startY = (view.top / gap).floor() * gap;
  for (var y = startY; y < view.bottom; y += gap) {
    c.drawLine(Offset(view.left, y), Offset(view.right, y), p);
  }
  if (!marginX.isNaN) {
    c.drawLine(Offset(marginX, view.top), Offset(marginX, view.bottom),
        Paint()
          ..color = Sketch.redLine
          ..strokeWidth = math.max(1.5, gap * 0.05));
  }
}

class WorldPainter extends CustomPainter {
  final Game g;
  WorldPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    final t = math.min(size.width, size.height) / 9.5;
    final mw = g.mapW * t, mh = g.mapH * t;
    double cam(double p, double view, double world) {
      if (world <= view) return (world - view) / 2;
      return (p - view / 2).clamp(0, world - view);
    }

    final camX = cam((g.posX + 0.5) * t, size.width, mw);
    final camY = cam((g.posY + 0.5) * t, size.height, mh);
    canvas.drawRect(Offset.zero & size, Sketch.fill(const Color(0xFFE9E4D6)));
    canvas.save();
    canvas.translate(-camX, -camY);
    final view = Rect.fromLTWH(camX, camY, size.width, size.height);
    final pageRect = Rect.fromLTWH(0, 0, mw, mh);
    canvas.drawRect(pageRect.shift(Offset(t * 0.08, t * 0.1)), Sketch.fill(const Color(0x33000000)));
    canvas.save();
    canvas.clipRect(pageRect);
    _paperLines(canvas, view.intersect(pageRect), t * 0.5, marginX: t * 0.75);
    canvas.restore();

    final x0 = math.max(0, (camX / t).floor() - 1);
    final x1 = math.min(g.mapW - 1, ((camX + size.width) / t).ceil() + 1);
    final y0 = math.max(0, (camY / t).floor() - 1);
    final y1 = math.min(g.mapH - 1, ((camY + size.height) / t).ceil() + 2);

    // ground layer
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        _ground(canvas, g.tile(x, y), x, y, t);
      }
    }
    // objects, row by row so taller things overlap correctly
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        _object(canvas, g.tile(x, y), x, y, t);
      }
      if (y == math.max(g.py, g.fromY)) {
        _player(canvas, t);
      }
    }
    canvas.restore();
  }

  void _player(Canvas canvas, double t) {
    final c = Offset((g.posX + 0.5) * t, (g.posY + 0.5) * t - t * 0.12);
    drawDoodle(canvas, c, t * 0.95, g.facing, g.walk, g.player.equipped, seed: 1);
    // tall grass overlays your feet
    final tx = g.posX.round(), ty = g.posY.round();
    if (g.tile(tx, ty) == '"' && (!g.moving || g.moveT > 0.5)) {
      final base = Offset((tx + 0.5) * t, (ty + 1) * t - t * 0.08);
      for (var i = -2; i <= 2; i++) {
        final b = base + Offset(i * t * 0.14, 0);
        Sketch.line(canvas, b, b + Offset(-t * 0.05, -t * 0.25), tx * 7 + i, w: t * 0.03, color: _green);
        Sketch.line(canvas, b, b + Offset(t * 0.06, -t * 0.22), tx * 9 + i, w: t * 0.03, color: _green);
      }
    }
  }

  int _seed(int x, int y) => x * 7919 + y * 104729;

  void _ground(Canvas c, String tile, int x, int y, double t) {
    final r = Rect.fromLTWH(x * t, y * t, t, t);
    final s = _seed(x, y);
    final w = t * 0.025;
    switch (tile) {
      case '=':
        for (var i = 0; i < 4; i++) {
          final p = r.topLeft + Offset(Sketch.rnd(s + i) * t, Sketch.rnd(s + i + 50) * t);
          Sketch.circle(c, p, t * 0.04, s + i, w: w * 0.8, color: Sketch.lightGraphite);
        }
        void edge(int dx, int dy, Offset a, Offset b) {
          final n = g.tile(x + dx, y + dy);
          if (n != '=' && n != 'P') {
            Sketch.line(c, a, b, s + dx * 3 + dy * 5, w: w, color: Sketch.lightGraphite);
          }
        }
        final i = t * 0.08;
        edge(0, -1, r.topLeft + Offset(0, i), r.topRight + Offset(0, i));
        edge(0, 1, r.bottomLeft - Offset(0, i), r.bottomRight - Offset(0, i));
        edge(-1, 0, r.topLeft + Offset(i, 0), r.bottomLeft + Offset(i, 0));
        edge(1, 0, r.topRight - Offset(i, 0), r.bottomRight - Offset(i, 0));
      case '~':
        c.drawRect(r.inflate(0.5), Sketch.fill(const Color(0xFFDDEBF8)));
        Sketch.scribbleFill(c, Path()..addRect(r), r, _water, s, gap: t * 0.1);
        for (var k = 0; k < 2; k++) {
          final y0 = r.top + t * (0.35 + k * 0.35);
          final p = Path()..moveTo(r.left + t * 0.15, y0);
          p.quadraticBezierTo(r.left + t * 0.3, y0 - t * 0.04, r.left + t * 0.45, y0);
          p.quadraticBezierTo(r.left + t * 0.6, y0 + t * 0.04, r.left + t * 0.75, y0);
          c.drawPath(p, Sketch.pen(w, Sketch.bluePencil));
        }
        void edge(int dx, int dy, Offset a, Offset b) {
          if (g.tile(x + dx, y + dy) != '~') Sketch.line(c, a, b, s + dx * 3 + dy * 5, w: w * 1.5, color: Sketch.bluePencil);
        }
        edge(0, -1, r.topLeft, r.topRight);
        edge(0, 1, r.bottomLeft, r.bottomRight);
        edge(-1, 0, r.topLeft, r.bottomLeft);
        edge(1, 0, r.topRight, r.bottomRight);
      case '"':
        for (var i = 0; i < 3; i++) {
          for (var k = 0; k < 2; k++) {
            final b = r.topLeft + Offset(t * (0.2 + i * 0.3), t * (0.45 + k * 0.45));
            Sketch.line(c, b, b + Offset(-t * 0.06, -t * 0.22), s + i * 3 + k, w: w, color: _green);
            Sketch.line(c, b, b + Offset(t * 0.02, -t * 0.28), s + i * 5 + k, w: w, color: _green);
            Sketch.line(c, b, b + Offset(t * 0.08, -t * 0.2), s + i * 7 + k, w: w, color: _green);
          }
        }
      case 'F':
        const colors = [Sketch.redPencil, Sketch.yellowPencil, Color(0xFF9B59B6)];
        for (var i = 0; i < 3; i++) {
          final p = r.topLeft + Offset(t * (0.2 + Sketch.rnd(s + i) * 0.6), t * (0.25 + Sketch.rnd(s + i + 9) * 0.55));
          Sketch.line(c, p, p + Offset(0, t * 0.15), s + i, w: w, color: _green);
          for (var k = 0; k < 5; k++) {
            final a = k / 5 * math.pi * 2;
            c.drawCircle(p + Offset(math.cos(a), math.sin(a)) * t * 0.05, t * 0.035,
                Sketch.fill(colors[i % 3].withValues(alpha: 0.7)));
          }
          c.drawCircle(p, t * 0.025, Sketch.fill(Sketch.yellowPencil));
        }
      case '.':
        if (Sketch.rnd(s) < 0.18) {
          final b = r.topLeft + Offset(Sketch.rnd(s + 1) * t * 0.7 + t * 0.15, Sketch.rnd(s + 2) * t * 0.6 + t * 0.3);
          Sketch.line(c, b, b + Offset(-t * 0.05, -t * 0.1), s, w: w * 0.8, color: Sketch.lightGraphite);
          Sketch.line(c, b, b + Offset(t * 0.05, -t * 0.12), s + 1, w: w * 0.8, color: Sketch.lightGraphite);
        }
    }
  }

  void _object(Canvas c, String tile, int x, int y, double t) {
    final r = Rect.fromLTWH(x * t, y * t, t, t);
    final s = _seed(x, y);
    final w = t * 0.03;
    switch (tile) {
      case '#':
        final trunkB = r.bottomCenter - Offset(0, t * 0.1);
        final trunkT = r.center + Offset(0, -t * 0.05);
        Sketch.line(c, trunkB + Offset(-t * 0.08, 0), trunkT + Offset(-t * 0.06, 0), s, w: w);
        Sketch.line(c, trunkB + Offset(t * 0.08, 0), trunkT + Offset(t * 0.06, 0), s + 1, w: w);
        final cc = r.center + Offset(0, -t * 0.3);
        final cr = t * 0.52;
        final rect = Rect.fromCenter(center: cc, width: cr * 2, height: cr * 1.8);
        final path = Path()..addOval(rect);
        c.drawOval(rect, Sketch.fill(Sketch.paper));
        Sketch.scribbleFill(c, path, rect, _green, s, gap: t * 0.08);
        c.drawOval(rect, Sketch.pen(w * 1.2));
        for (var i = 0; i < 3; i++) {
          final p = cc + Offset(Sketch.j(s + i, cr * 0.4), Sketch.j(s + i + 4, cr * 0.3));
          final arc = Path()..addArc(Rect.fromCircle(center: p, radius: t * 0.08), 0.3, 2.2);
          c.drawPath(arc, Sketch.pen(w * 0.6));
        }
      case 'R':
        final pts = [
          for (var i = 0; i < 7; i++)
            r.center + Offset(0, t * 0.1) +
                Offset(math.cos(i / 7 * math.pi * 2), math.sin(i / 7 * math.pi * 2) * 0.7) *
                    t * (0.36 + Sketch.rnd(s + i) * 0.08)
        ];
        final p = Path()..addPolygon(pts, true);
        c.drawPath(p, Sketch.fill(const Color(0xFFE6E3DA)));
        Sketch.hatch(c, p, p.getBounds(), s, gap: t * 0.07);
        Sketch.poly(c, pts, s, w: w);
      case 'H':
        final base = Rect.fromLTWH(r.left - t * 0.4, r.top - t * 0.2, t * 1.8, t * 1.1);
        c.drawRect(base, Sketch.fill(Sketch.paper));
        Sketch.rect(c, base, s, w: w * 1.2);
        final roof = [base.topLeft + Offset(-t * 0.2, 0), Offset(base.center.dx, base.top - t * 0.8), base.topRight + Offset(t * 0.2, 0)];
        final rp = Path()..addPolygon(roof, true);
        c.drawPath(rp, Sketch.fill(Sketch.paper));
        Sketch.scribbleFill(c, rp, rp.getBounds(), Sketch.redPencil, s, gap: t * 0.07);
        Sketch.poly(c, roof, s + 3, w: w * 1.2);
        final door = Rect.fromLTWH(base.center.dx - t * 0.15, base.bottom - t * 0.5, t * 0.3, t * 0.5);
        Sketch.rect(c, door, s + 5, w: w, fillColor: const Color(0xFFD9B98A));
        c.drawCircle(door.centerRight - Offset(t * 0.06, 0), t * 0.025, Sketch.fill(Sketch.graphite));
        for (final dx in [-0.55, 0.55]) {
          final win = Rect.fromCenter(center: base.center + Offset(dx * t, -t * 0.1), width: t * 0.3, height: t * 0.3);
          Sketch.rect(c, win, s + 7, w: w, fillColor: const Color(0xFFDDEBF8));
          Sketch.line(c, win.topCenter, win.bottomCenter, s + 8, w: w * 0.6);
          Sketch.line(c, win.centerLeft, win.centerRight, s + 9, w: w * 0.6);
        }
      case 'x':
        final post = Rect.fromCenter(center: r.center + Offset(0, t * 0.05), width: t * 0.12, height: t * 0.6);
        Sketch.rect(c, post, s, w: w, fillColor: const Color(0xFFE8D5B5));
        if (g.tile(x + 1, y) == 'x') {
          for (final yy in [-0.1, 0.15]) {
            Sketch.line(c, r.center + Offset(0, yy * t), r.center + Offset(t, yy * t), s + 3, w: w, color: const Color(0xFF8B6B3D));
          }
        }
        if (g.tile(x, y + 1) == 'x') {
          Sketch.line(c, r.center + Offset(-t * 0.03, 0), r.center + Offset(-t * 0.03, t), s + 4, w: w, color: const Color(0xFF8B6B3D));
          Sketch.line(c, r.center + Offset(t * 0.03, 0), r.center + Offset(t * 0.03, t), s + 5, w: w, color: const Color(0xFF8B6B3D));
        }
      case 'C':
        final open = g.opened.contains('$x,$y');
        final box = Rect.fromLTWH(r.left + t * 0.15, r.top + t * 0.4, t * 0.7, t * 0.45);
        c.drawRect(box, Sketch.fill(const Color(0xFFE2C38F)));
        Sketch.hatch(c, Path()..addRect(box), box, s, gap: t * 0.08, color: const Color(0xFFA0763D));
        Sketch.rect(c, box, s, w: w);
        if (open) {
          final lid = [box.topLeft, box.topRight, box.topRight + Offset(-t * 0.05, -t * 0.25), box.topLeft + Offset(t * 0.05, -t * 0.25)];
          Sketch.poly(c, lid, s + 1, w: w);
        } else {
          final lid = Rect.fromLTWH(box.left - t * 0.03, box.top - t * 0.15, box.width + t * 0.06, t * 0.17);
          Sketch.rect(c, lid, s + 1, w: w, fillColor: const Color(0xFFD9B47A));
          c.drawRect(Rect.fromCenter(center: lid.bottomCenter, width: t * 0.1, height: t * 0.12),
              Sketch.fill(Sketch.yellowPencil));
          // sparkle
          if (((g.time * 2).floor() % 2) == 0) {
            final sp = box.topRight + Offset(t * 0.05, -t * 0.25);
            Sketch.line(c, sp - Offset(t * 0.06, 0), sp + Offset(t * 0.06, 0), s + 2, w: w * 0.7, color: Sketch.yellowPencil);
            Sketch.line(c, sp - Offset(0, t * 0.06), sp + Offset(0, t * 0.06), s + 3, w: w * 0.7, color: Sketch.yellowPencil);
          }
        }
      case 'S':
        Sketch.line(c, r.bottomCenter - Offset(0, t * 0.1), r.center, s, w: w * 1.3);
        final board = Rect.fromCenter(center: r.center + Offset(0, -t * 0.1), width: t * 0.7, height: t * 0.4);
        Sketch.rect(c, board, s + 1, w: w, fillColor: const Color(0xFFF0DFC0));
        for (var i = 0; i < 2; i++) {
          final yy = board.top + board.height * (0.35 + i * 0.3);
          Sketch.line(c, Offset(board.left + t * 0.08, yy), Offset(board.right - t * 0.1 - i * t * 0.1, yy), s + 2 + i,
              w: w * 0.6);
        }
      case 'N':
        _sharpener(c, r.center + Offset(0, -t * 0.05), t, s);
      case 'B':
        drawEnemy(c, r.center + Offset(0, -t * 0.15), t * 1.3, 'knight', g.time, seed: s);
        if (((g.time * 2).floor() % 2) == 0) {
          final tp = TextPainter(
              text: TextSpan(text: '!', style: TextStyle(fontSize: t * 0.4, color: Sketch.redPencil, fontWeight: FontWeight.bold)),
              textDirection: TextDirection.ltr)
            ..layout();
          tp.paint(c, r.topCenter + Offset(-tp.width / 2, -t * 1.0));
        }
    }
  }

  void _sharpener(Canvas c, Offset ctr, double t, int s) {
    final w = t * 0.03;
    final body = Rect.fromCenter(center: ctr, width: t * 0.6, height: t * 0.55);
    c.drawRect(body, Sketch.fill(const Color(0xFF8FB8DE)));
    Sketch.scribbleFill(c, Path()..addRect(body), body, Sketch.bluePencil, s, gap: t * 0.06);
    Sketch.rect(c, body, s, w: w);
    Sketch.circle(c, body.centerRight + Offset(-t * 0.12, t * 0.08), t * 0.08, s + 1, w: w, fillColor: Sketch.graphite);
    for (final k in [-1, 1]) {
      c.drawCircle(body.center + Offset(k * t * 0.1 - t * 0.05, -t * 0.08), t * 0.035, Sketch.fill(Sketch.graphite));
    }
    final m = Path()
      ..moveTo(body.center.dx - t * 0.15, body.center.dy + t * 0.03)
      ..quadraticBezierTo(body.center.dx - t * 0.05, body.center.dy + t * 0.12, body.center.dx + t * 0.05, body.center.dy + t * 0.03);
    c.drawPath(m, Sketch.pen(w));
    Sketch.line(c, body.bottomLeft + Offset(t * 0.12, 0), body.bottomLeft + Offset(t * 0.1, t * 0.15), s + 2, w: w);
    Sketch.line(c, body.bottomRight - Offset(t * 0.12, 0), body.bottomRight + Offset(-t * 0.1, t * 0.15), s + 3, w: w);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BattlePainter extends CustomPainter {
  final Game g;
  final double u;
  final String? font;
  final double panelH;
  BattlePainter(this.g, this.u, this.font, this.panelH);

  void _text(Canvas c, String s, Offset p, double size, {Color color = Sketch.graphite, bool center = false, bool bold = false}) {
    final tp = TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(fontFamily: font, fontSize: size, color: color, fontWeight: bold ? FontWeight.bold : null)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, center ? p - Offset(tp.width / 2, tp.height / 2) : p);
  }

  void _statBox(Canvas c, Rect r, String name, int lvl, int hp, int maxHp, int seed, {bool showNums = true}) {
    c.drawRect(r, Sketch.fill(Sketch.paper));
    Sketch.rect(c, r, seed, w: 2 * u);
    _text(c, '$name  Lv$lvl', r.topLeft + Offset(8 * u, 4 * u), 15 * u, bold: true);
    final bar = Rect.fromLTWH(r.left + 8 * u, r.top + 26 * u, r.width - 16 * u, 9 * u);
    BarPainter(hp / maxHp, seed).paint(c, bar.size, offset: bar.topLeft);
    if (showNums) _text(c, 'HP $hp/$maxHp', Offset(r.left + 8 * u, bar.bottom + 1 * u), 12 * u);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final b = g.battle!;
    final e = b.enemy;
    final sceneH = size.height - panelH;
    final portrait = size.height > size.width;
    _paperLines(canvas, Offset.zero & size, 18 * u, marginX: 26 * u);

    final unit = math.min(size.width / (portrait ? 1.6 : 2.4), sceneH);
    final eSize = unit * (b.boss ? 0.62 : 0.5);
    final pSize = unit * 0.5;
    final ease = Curves.easeOutBack.transform(b.intro);
    var ePos = Offset(size.width * (portrait ? 0.7 : 0.68), sceneH * 0.36);
    var pPos = Offset(size.width * (portrait ? 0.3 : 0.32), sceneH * 0.7);
    ePos += Offset((1 - ease) * size.width * 0.5, 0);
    pPos -= Offset((1 - ease) * size.width * 0.5, 0);

    // ground scribbles
    for (final (pos, s, seed) in [(ePos, eSize, 3), (pPos, pSize, 4)]) {
      final o = pos + Offset(0, s * 0.42);
      final path = Sketch.wobblyCirclePath(o, s * 0.65, s * 0.15, seed, overshoot: 0);
      Sketch.scribbleFill(canvas, path, path.getBounds(), _green, seed, gap: 5 * u);
      canvas.drawPath(Sketch.wobblyCirclePath(o, s * 0.65, s * 0.15, seed), Sketch.pen(1.5 * u, _green));
    }

    // enemy
    final eShake = math.sin(g.time * 50) * b.enemyShake * eSize * 0.06;
    final eL = math.sin(math.pi * (1 - b.enemyLunge)) * (b.enemyLunge > 0 ? 1 : 0);
    final ep = ePos + Offset(eShake, 0) + (pPos - ePos) * 0.15 * eL;
    canvas.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, 1 - b.enemyFade));
    final flash = b.enemyShake > 0.5 && ((g.time * 16).floor() % 2 == 0);
    if (!flash) {
      drawEnemy(canvas, ep, eSize, e.type.id, g.time, seed: 11);
    }
    // eraser crumbs when fading
    if (b.enemyDead) {
      for (var i = 0; i < 10; i++) {
        final a = i / 10 * math.pi * 2;
        canvas.drawCircle(ep + Offset(math.cos(a), math.sin(a)) * eSize * (0.3 + b.enemyFade * 0.4), 3 * u,
            Sketch.fill(const Color(0xFFE88AA0)));
      }
    }
    canvas.restore();

    // player (side view)
    final pShake = math.sin(g.time * 50) * b.playerShake * pSize * 0.06;
    final pL = math.sin(math.pi * (1 - b.lunge)) * (b.lunge > 0 ? 1 : 0);
    final pp = pPos + Offset(pShake, 0) + (ePos - pPos) * 0.2 * pL;
    final pFlash = b.playerShake > 0.5 && ((g.time * 16).floor() % 2 == 0);
    if (!pFlash) {
      drawDoodle(canvas, pp, pSize, Facing.right, g.time * 0.4, g.player.equipped, seed: 1);
    }

    // stat boxes
    final boxW = math.min(200 * u, size.width * 0.46);
    final eBox = Rect.fromLTWH(10 * u, 10 * u, boxW, 52 * u);
    final pBox = Rect.fromLTWH(size.width - boxW - 10 * u, sceneH - 66 * u, boxW, 56 * u);
    _statBox(canvas, eBox, e.type.name, e.level, e.hp, e.maxHp, 21, showNums: false);
    _statBox(canvas, pBox, 'Doodle', g.player.level, g.player.hp, g.player.maxHp, 22);

    // floating numbers
    for (final f in b.floats) {
      final base = f.onEnemy ? ep - Offset(0, eSize * 0.4) : pp - Offset(0, pSize * 0.5);
      final pos = base - Offset(0, f.t * 40 * u);
      _text(canvas, f.text, pos, 26 * u,
          color: (f.heal ? Sketch.greenPencil : Sketch.redPencil).withValues(alpha: (1.2 - f.t).clamp(0, 1)),
          center: true,
          bold: true);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarPainter extends CustomPainter {
  final double frac;
  final int seed;
  BarPainter(this.frac, this.seed);

  @override
  void paint(Canvas canvas, Size size, {Offset offset = Offset.zero}) {
    final r = offset & size;
    final f = frac.clamp(0.0, 1.0);
    final color = f > 0.5 ? Sketch.greenPencil : f > 0.2 ? Sketch.yellowPencil : Sketch.redPencil;
    if (f > 0) {
      final fr = Rect.fromLTWH(r.left, r.top, r.width * f, r.height);
      canvas.drawRect(fr, Sketch.fill(color.withValues(alpha: 0.35)));
      Sketch.scribbleFill(canvas, Path()..addRect(fr), fr, color, seed, gap: math.max(2, size.height * 0.35));
    }
    Sketch.rect(canvas, r, seed, w: math.max(1.2, size.height * 0.15));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PaperBoxPainter extends CustomPainter {
  final int seed;
  final double u;
  PaperBoxPainter(this.seed, this.u);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r.shift(Offset(3 * u, 4 * u)), Sketch.fill(const Color(0x22000000)));
    canvas.drawRect(r, Sketch.fill(Sketch.paper));
    // faint ruled lines inside boxes for notebook feel
    final p = Paint()
      ..color = Sketch.blueLine.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var y = 22 * u; y < size.height; y += 22 * u) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    Sketch.rect(canvas, r, seed, w: 2.2 * u);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HighlightPainter extends CustomPainter {
  final int seed;
  HighlightPainter(this.seed);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(size.height * 0.4, size.height * 0.12, size.width - size.height * 0.4, size.height * 0.76);
    Sketch.scribbleFill(canvas, Path()..addRect(r), r, Sketch.yellowPencil, seed, gap: math.max(3, size.height * 0.12));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class IconPainter extends CustomPainter {
  final String id;
  IconPainter(this.id);
  @override
  void paint(Canvas canvas, Size size) => drawItemIcon(canvas, size.center(Offset.zero), size.shortestSide, id);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PreviewPainter extends CustomPainter {
  final Map<Slot, Item?> eq;
  final double time;
  PreviewPainter(this.eq, this.time);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero) + Offset(0, size.height * 0.05);
    final ground = Sketch.wobblyCirclePath(c + Offset(0, size.height * 0.32), size.width * 0.35, size.height * 0.07, 4);
    canvas.drawPath(ground, Sketch.pen(1.5, _green));
    drawDoodle(canvas, c, size.shortestSide * 0.8, Facing.down, time * 0.5, eq, seed: 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class JoystickPainter extends CustomPainter {
  final Offset knob;
  final double radius;
  JoystickPainter(this.knob, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, radius, Sketch.fill(Sketch.paper.withValues(alpha: 0.6)));
    Sketch.circle(canvas, c, radius, 300, w: radius * 0.05);
    // direction arrows
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a));
      final tip = c + d * radius * 0.82;
      final perp = Offset(-d.dy, d.dx);
      Sketch.poly(canvas, [tip, tip - d * radius * 0.14 + perp * radius * 0.1, tip - d * radius * 0.14 - perp * radius * 0.1], 310 + i,
          w: radius * 0.035);
    }
    final k = c + knob;
    final kr = radius * 0.42;
    final path = Sketch.wobblyCirclePath(k, kr, kr, 320, overshoot: 0);
    canvas.drawPath(path, Sketch.fill(Sketch.paper));
    Sketch.hatch(canvas, path, path.getBounds(), 321, gap: kr * 0.22, color: Sketch.graphite);
    Sketch.circle(canvas, k, kr, 322, w: radius * 0.05);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ButtonPainter extends CustomPainter {
  final bool down;
  final bool wide;
  final int seed;
  ButtonPainter(this.down, this.wide, this.seed);
  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(2);
    final w = size.height * 0.05;
    if (wide) {
      canvas.drawRect(r, Sketch.fill(down ? const Color(0xFFF3E3A0) : Sketch.paper.withValues(alpha: 0.85)));
      Sketch.rect(canvas, r, seed, w: w);
    } else {
      final c = r.center + (down ? Offset(0, size.height * 0.03) : Offset.zero);
      final rad = r.shortestSide / 2;
      if (!down) canvas.drawCircle(c + Offset(0, rad * 0.1), rad, Sketch.fill(const Color(0x22000000)));
      final path = Sketch.wobblyCirclePath(c, rad, rad, seed, overshoot: 0);
      canvas.drawPath(path, Sketch.fill(down ? const Color(0xFFF3E3A0) : Sketch.paper.withValues(alpha: 0.9)));
      if (down) Sketch.scribbleFill(canvas, path, path.getBounds(), Sketch.yellowPencil, seed, gap: rad * 0.15);
      Sketch.circle(canvas, c, rad, seed, w: w);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
