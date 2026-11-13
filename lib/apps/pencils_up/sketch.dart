import 'dart:math' as math;
import 'dart:ui';

/// Hand-drawn pencil rendering helpers.
/// Drawings are completely stable and clean without jitter or boiling wiggles.
class Sketch {
  static int boil = 0;

  static const graphite = Color(0xFF3A3A3F);
  static const lightGraphite = Color(0xFF8A8A92);
  static const paper = Color(0xFFFBF8EF);
  static const blueLine = Color(0xFFB9D3EA);
  static const redLine = Color(0xFFE8A3A3);
  static const redPencil = Color(0xFFC0392B);
  static const bluePencil = Color(0xFF2E5FA8);
  static const greenPencil = Color(0xFF3D8B4F);
  static const yellowPencil = Color(0xFFE0B020);

  static double rnd(int seed) {
    var x = (seed * 374761393 + 668265263) & 0x7fffffff;
    x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
    return (x & 0xffff) / 0xffff;
  }

  static double j(int seed, double amt) => (rnd(seed) - 0.5) * 2 * amt;

  static Paint pen(double w, [Color c = graphite]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Paint fill(Color c) => Paint()..color = c;

  /// Clean, stable pencil line with no random wiggling.
  static void line(Canvas c, Offset a, Offset b, int seed,
      {double w = 2, Color color = graphite, double wob = 0.0, bool boils = false}) {
    if (wob <= 0.01) {
      c.drawLine(a, b, pen(w, color.withValues(alpha: 0.9)));
      return;
    }
    final len = (b - a).distance;
    final amt = math.min(len * 0.02, 1.0) * wob;
    final p = Path();
    final mid = Offset.lerp(a, b, 0.5)! + Offset(j(seed + 23, amt), j(seed + 29, amt));
    p.moveTo(a.dx, a.dy);
    p.quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    c.drawPath(p, pen(w, color.withValues(alpha: 0.9)));
  }

  static void poly(Canvas c, List<Offset> pts, int seed,
      {double w = 2, Color color = graphite, bool close = true, double wob = 0.0}) {
    for (var i = 0; i < pts.length - (close ? 0 : 1); i++) {
      line(c, pts[i], pts[(i + 1) % pts.length], seed + i * 31, w: w, color: color, wob: wob);
    }
  }

  static void rect(Canvas c, Rect r, int seed,
      {double w = 2, Color color = graphite, Color? fillColor, double wob = 0.0}) {
    if (fillColor != null) {
      c.drawRect(r, fill(fillColor));
    }
    c.drawRect(r, pen(w, color.withValues(alpha: 0.9)));
  }

  static Path wobblyCirclePath(Offset ctr, double rx, double ry, int seed,
      {double wob = 0.0, double overshoot = 0.0}) {
    if (wob <= 0.01) {
      return Path()..addOval(Rect.fromCenter(center: ctr, width: rx * 2, height: ry * 2));
    }
    final p = Path();
    const n = 16;
    for (var i = 0; i <= n; i++) {
      final t = i / n * math.pi * 2;
      final k = 1 + j(seed + i * 7, 0.02 * wob);
      final pt = ctr + Offset(math.cos(t) * rx * k, math.sin(t) * ry * k);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p;
  }

  static void circle(Canvas c, Offset ctr, double r, int seed,
      {double w = 2, Color color = graphite, Color? fillColor, double ry = -1}) {
    final yr = ry < 0 ? r : ry;
    final rect = Rect.fromCenter(center: ctr, width: r * 2, height: yr * 2);
    if (fillColor != null) {
      c.drawOval(rect, fill(fillColor));
    }
    c.drawOval(rect, pen(w, color.withValues(alpha: 0.9)));
  }

  /// Diagonal pencil hatching clipped to [clip] - stable and clean.
  static void hatch(Canvas c, Path clip, Rect bounds, int seed,
      {double gap = 6, double w = 1, Color color = lightGraphite, double angle = 1}) {
    c.save();
    c.clipPath(clip);
    final paint = pen(w, color.withValues(alpha: 0.7));
    final h = bounds.height;
    for (var x = bounds.left - h; x < bounds.right; x += gap) {
      c.drawLine(Offset(x, bounds.bottom), Offset(x + h * angle, bounds.top), paint);
    }
    c.restore();
  }

  /// Crayon-ish colored scribble fill - stable and clean.
  static void scribbleFill(Canvas c, Path clip, Rect b, Color color, int seed,
      {double gap = 4}) {
    c.save();
    c.clipPath(clip);
    final p = Path();
    var up = true;
    p.moveTo(b.left - 4, b.bottom);
    for (var x = b.left - 4; x < b.right + 8; x += gap) {
      p.lineTo(x, up ? b.top - 2 : b.bottom + 2);
      up = !up;
    }
    c.drawPath(p, pen(gap * 0.9, color.withValues(alpha: 0.45)));
    c.restore();
  }
}
