import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

/// Micro-debris categories procedurally scattered across the terrain floor
enum MicroDebrisType {
  pebble,
  twig,
  deadLeaf,
  dirtClod,
}

/// An individual piece of static micro-debris providing tactile macro visual reference points
class MicroDebrisItem {
  final Vec2 pos;
  final MicroDebrisType type;
  final double rotation;
  final double scale;
  final int variant;
  final Color primaryColor;
  final Color secondaryColor;
  final Color highlightColor;

  const MicroDebrisItem({
    required this.pos,
    required this.type,
    required this.rotation,
    required this.scale,
    required this.variant,
    required this.primaryColor,
    required this.secondaryColor,
    required this.highlightColor,
  });
}

/// High-performance procedural cache for multi-octave noise, static micro-debris,
/// volumetric light rays, and macro soil decals. Initialized once on startup to
/// guarantee a locked 60 FPS.
class MacroVisualsCache {
  static const int noiseGridSize = 256;
  late final List<double> soilNoiseGrid;
  late final List<double> mossNoiseGrid;
  final List<MicroDebrisItem> microDebris = [];

  // Seeded Simplex-style 2D gradient noise table
  static final List<int> _perm = _buildPermutation(1859);
  static const List<List<double>> _grad2 = [
    [1.0, 1.0], [-1.0, 1.0], [1.0, -1.0], [-1.0, -1.0],
    [1.0, 0.0], [-1.0, 0.0], [0.0, 1.0], [0.0, -1.0],
  ];

  MacroVisualsCache() {
    _initNoiseGrids();
    _generateMicroDebris();
  }

  static List<int> _buildPermutation(int seed) {
    final rng = math.Random(seed);
    final p = List<int>.generate(256, (i) => i)..shuffle(rng);
    final out = List<int>.filled(512, 0);
    for (int i = 0; i < 256; i++) {
      out[i] = p[i];
      out[256 + i] = p[i];
    }
    return out;
  }

  /// 2D Gradient noise function
  static double _rawNoise(double x, double y) {
    final X = x.floor() & 255;
    final Y = y.floor() & 255;
    final xf = x - x.floor();
    final yf = y - y.floor();

    // Fade curves (smoothstep quintic)
    final u = xf * xf * xf * (xf * (xf * 6.0 - 15.0) + 10.0);
    final v = yf * yf * yf * (yf * (yf * 6.0 - 15.0) + 10.0);

    final a = _perm[X] + Y;
    final b = _perm[X + 1] + Y;

    final g00 = _grad2[_perm[a] & 7];
    final g10 = _grad2[_perm[b] & 7];
    final g01 = _grad2[_perm[a + 1] & 7];
    final g11 = _grad2[_perm[b + 1] & 7];

    final d00 = g00[0] * xf + g00[1] * yf;
    final d10 = g10[0] * (xf - 1.0) + g10[1] * yf;
    final d01 = g01[0] * xf + g01[1] * (yf - 1.0);
    final d11 = g11[0] * (xf - 1.0) + g11[1] * (yf - 1.0);

    final x1 = d00 + u * (d10 - d00);
    final x2 = d01 + u * (d11 - d01);
    return (x1 + v * (x2 - x1)).clamp(-1.0, 1.0);
  }

  /// Multi-octave fractal brownian motion (fBm) noise
  static double sampleFbm(
    double x,
    double y, {
    int octaves = 3,
    double lacunarity = 2.05,
    double gain = 0.5,
  }) {
    double total = 0.0;
    double freq = 1.0;
    double amp = 1.0;
    double maxAmp = 0.0;

    for (int i = 0; i < octaves; i++) {
      total += _rawNoise(x * freq, y * freq) * amp;
      maxAmp += amp;
      freq *= lacunarity;
      amp *= gain;
    }
    return (total / maxAmp + 1.0) * 0.5; // Normalized to 0.0 .. 1.0
  }

  void _initNoiseGrids() {
    soilNoiseGrid = List<double>.filled(noiseGridSize * noiseGridSize, 0.0);
    mossNoiseGrid = List<double>.filled(noiseGridSize * noiseGridSize, 0.0);

    for (int y = 0; y < noiseGridSize; y++) {
      final ny = y / noiseGridSize;
      for (int x = 0; x < noiseGridSize; x++) {
        final nx = x / noiseGridSize;
        final idx = y * noiseGridSize + x;

        // Multi-octave soil loam noise (3 octaves)
        soilNoiseGrid[idx] = sampleFbm(nx * 10.0, ny * 10.0, octaves: 3);

        // High-frequency subtle moss distribution (3 octaves, fine organic texture)
        mossNoiseGrid[idx] = sampleFbm((nx + 7.3) * 18.0, (ny + 11.8) * 18.0, octaves: 3);
      }
    }
  }

  /// Samples cached soil noise with bilinear interpolation in world space
  double getSoilNoise(double worldX, double worldY) {
    final u = (worldX * 4.0) % noiseGridSize;
    final v = (worldY * 4.0) % noiseGridSize;
    final su = u < 0 ? u + noiseGridSize : u;
    final sv = v < 0 ? v + noiseGridSize : v;

    final x0 = su.floor();
    final y0 = sv.floor();
    final x1 = (x0 + 1) % noiseGridSize;
    final y1 = (y0 + 1) % noiseGridSize;
    final fx = su - x0;
    final fy = sv - y0;

    final n00 = soilNoiseGrid[y0 * noiseGridSize + x0];
    final n10 = soilNoiseGrid[y0 * noiseGridSize + x1];
    final n01 = soilNoiseGrid[y1 * noiseGridSize + x0];
    final n11 = soilNoiseGrid[y1 * noiseGridSize + x1];

    final top = n00 + fx * (n10 - n00);
    final bot = n01 + fx * (n11 - n01);
    return top + fy * (bot - top);
  }

  /// Samples cached moss patch noise with bilinear interpolation in world space
  double getMossNoise(double worldX, double worldY) {
    final u = (worldX * 4.0) % noiseGridSize;
    final v = (worldY * 4.0) % noiseGridSize;
    final su = u < 0 ? u + noiseGridSize : u;
    final sv = v < 0 ? v + noiseGridSize : v;

    final x0 = su.floor();
    final y0 = sv.floor();
    final x1 = (x0 + 1) % noiseGridSize;
    final y1 = (y0 + 1) % noiseGridSize;
    final fx = su - x0;
    final fy = sv - y0;

    final n00 = mossNoiseGrid[y0 * noiseGridSize + x0];
    final n10 = mossNoiseGrid[y0 * noiseGridSize + x1];
    final n01 = mossNoiseGrid[y1 * noiseGridSize + x0];
    final n11 = mossNoiseGrid[y1 * noiseGridSize + x1];

    final top = n00 + fx * (n10 - n00);
    final bot = n01 + fx * (n11 - n01);
    return top + fy * (bot - top);
  }

  void _generateMicroDebris() {
    microDebris.clear();
    final rng = math.Random(1907);

    const pebblePalettes = [
      (Color(0xFF5A524A), Color(0xFF2C2723), Color(0xFF8E847A)), // River granite
      (Color(0xFF423C36), Color(0xFF1E1B18), Color(0xFF6B6259)), // Basalt slate
      (Color(0xFF6E5642), Color(0xFF38291D), Color(0xFF9E8166)), // Terracotta / Sandstone
      (Color(0xFF4A4438), Color(0xFF242018), Color(0xFF7A705E)), // Loamy limestone
    ];

    const leafPalettes = [
      (Color(0xFF6B361B), Color(0xFF38190B), Color(0xFF9E542C)), // Curled oak leaf flake
      (Color(0xFF542814), Color(0xFF281107), Color(0xFF7C3E20)), // Decayed russet fragment
      (Color(0xFF46301A), Color(0xFF201509), Color(0xFF6E4F2E)), // Dried brown litter
      (Color(0xFF75451D), Color(0xFF3E220D), Color(0xFFAA6B34)), // Warm autumn mulch
    ];

    const clodPalettes = [
      (Color(0xFF2E2014), Color(0xFF160E08), Color(0xFF483524)), // Dark rich humus clod
      (Color(0xFF3D2C1E), Color(0xFF1F150D), Color(0xFF5E4632)), // Muted umber earth clod
      (Color(0xFF261D12), Color(0xFF120C06), Color(0xFF3E2F20)), // Wet peat crumb
    ];

    // Distribute 750 micro-debris items across the expanded 112x112 meadow
    const int count = 750;
    for (int i = 0; i < count; i++) {
      // Keep clear of outer walls across the expanded 112x112 meadow
      final wx = 2.5 + rng.nextDouble() * 107.0;
      final wy = 2.5 + rng.nextDouble() * 107.0;

      // Keep starting spawn points clear
      if (math.sqrt(math.pow(wx - 28.0, 2) + math.pow(wy - 46.0, 2)) < 1.4) continue;
      if (math.sqrt(math.pow(wx - 56.0, 2) + math.pow(wy - 92.0, 2)) < 1.4) continue;

      final typeRoll = rng.nextDouble();
      MicroDebrisType type;
      Color pCol;
      Color sCol;
      Color hCol;
      double scale;

      if (typeRoll < 0.32) {
        // Pebbles
        type = MicroDebrisType.pebble;
        final pal = pebblePalettes[rng.nextInt(pebblePalettes.length)];
        pCol = pal.$1;
        sCol = pal.$2;
        hCol = pal.$3;
        scale = 0.08 + rng.nextDouble() * 0.16;
      } else if (typeRoll < 0.58) {
        // Twigs
        type = MicroDebrisType.twig;
        pCol = const Color(0xFF3A2416);
        sCol = const Color(0xFF1D1109);
        hCol = const Color(0xFF785236);
        scale = 0.14 + rng.nextDouble() * 0.22;
      } else if (typeRoll < 0.82) {
        // Dead leaf litter
        type = MicroDebrisType.deadLeaf;
        final pal = leafPalettes[rng.nextInt(leafPalettes.length)];
        pCol = pal.$1;
        sCol = pal.$2;
        hCol = pal.$3;
        scale = 0.12 + rng.nextDouble() * 0.18;
      } else {
        // Dirt clods
        type = MicroDebrisType.dirtClod;
        final pal = clodPalettes[rng.nextInt(clodPalettes.length)];
        pCol = pal.$1;
        sCol = pal.$2;
        hCol = pal.$3;
        scale = 0.10 + rng.nextDouble() * 0.15;
      }

      microDebris.add(MicroDebrisItem(
        pos: Vec2(wx, wy),
        type: type,
        rotation: rng.nextDouble() * math.pi * 2,
        scale: scale,
        variant: rng.nextInt(6),
        primaryColor: pCol,
        secondaryColor: sCol,
        highlightColor: hCol,
      ));
    }
  }
}

