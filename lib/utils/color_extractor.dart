import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WallpaperColorExtractor {
  /// Known wallpaper signatures to guarantee instantaneous, 100% reliable matching.
  static final Map<String, Color> _presetWallpaperAccents = {
    // fyr Abstract (assets/wallpaper.png)
    'wallpaper.png': const Color(0xFF1E88E5), // Vibrant electric blue
    // Deep Space (assets/wallpaper.jpg or space.jpg)
    'wallpaper.jpg': const Color(0xFF7E57C2), // Rich cosmic deep purple
    'space.jpg': const Color(0xFF7E57C2),
    // Alpine Sunset (Unsplash photo-1477346611705)
    '1477346611705': const Color(0xFFFF6F00), // Blazing golden sunset amber
    // Cyber Grid (Unsplash photo-1518770660439)
    '1518770660439': const Color(0xFF00E5FF), // Glowing cyber electric cyan
    // Mountain Fog (Unsplash photo-1464822759023)
    '1464822759023': const Color(0xFF5C6BC0), // Misty mountain twilight indigo
  };

  /// Returns a signature accent color if the path matches a known preset wallpaper.
  static Color? getPresetAccentColor(String pathOrUrl) {
    for (final entry in _presetWallpaperAccents.entries) {
      if (pathOrUrl.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// High-level method to extract accent color from any wallpaper source:
  /// custom bytes, asset path, preset URL, or arbitrary remote network URL.
  static Future<Color?> extractColor({
    required String path,
    Uint8List? bytes,
  }) async {
    // 1. Check custom uploaded bytes first
    if (bytes != null && bytes.isNotEmpty) {
      final color = await extractAccentColorFromBytes(bytes);
      if (color != null) return color;
    }

    // 2. Check preset mapping for instant, reliable response
    final preset = getPresetAccentColor(path);
    if (preset != null) return preset;

    // 3. Local asset
    if (path.startsWith('assets/')) {
      try {
        final data = await rootBundle.load(path);
        final color =
            await extractAccentColorFromBytes(data.buffer.asUint8List());
        if (color != null) return color;
      } catch (e) {
        debugPrint('Error loading asset wallpaper for color extraction: $e');
      }
    }

    // 4. Remote web URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final color = await extractAccentColorFromUrl(path);
      if (color != null) return color;
    }

    return null;
  }

  /// Extracts dominant accent from remote image URL via NetworkImage.
  static Future<Color?> extractAccentColorFromUrl(String url) async {
    final preset = getPresetAccentColor(url);
    if (preset != null) return preset;

    // Try resolving through Flutter's ImageProvider cache
    try {
      final completer = Completer<ui.Image>();
      final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete(info.image);
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.completeError(error);
        },
      );
      stream.addListener(listener);
      final uiImage = await completer.future.timeout(const Duration(seconds: 4));
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData != null) {
        return extractDominantAccent(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('NetworkImage pixel extraction fallback: $e');
    }

    return null;
  }

  /// Extracts a dominant accent color from image bytes (PNG, JPEG, WebP, etc.).
  static Future<Color?> extractAccentColorFromBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 48,
        targetHeight: 48,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return null;
      return extractDominantAccent(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error extracting accent color from image: $e');
      return null;
    }
  }

  /// Analyzes RGBA pixel buffer to find the most vibrant, prominent hue.
  static Color extractDominantAccent(Uint8List rgbaBytes) {
    final Map<int, int> hueCounts = {};
    final Map<int, List<Color>> hueColors = {};

    // Sample pixels if the buffer is large
    final step = rgbaBytes.length > 8000 ? (rgbaBytes.length ~/ 2000) * 4 : 4;

    for (int i = 0; i < rgbaBytes.length; i += step) {
      final r = rgbaBytes[i];
      final g = rgbaBytes[i + 1];
      final b = rgbaBytes[i + 2];
      final a = rgbaBytes[i + 3];
      if (a < 128) continue;

      final color = Color.fromARGB(255, r, g, b);
      final hsv = HSVColor.fromColor(color);

      // Skip near black, near white, or grayscale noise
      if (hsv.value < 0.15 || (hsv.saturation < 0.15 && hsv.value > 0.85)) {
        continue;
      }

      // Group into 24 hue buckets (15 degrees each)
      final bucket = ((hsv.hue / 15).floor()) % 24;
      // Weight by saturation and value so vivid colors stand out as accents
      final weight = (hsv.saturation * 100 * (0.5 + hsv.value * 0.5)).round();

      hueCounts[bucket] = (hueCounts[bucket] ?? 0) + weight;
      hueColors.putIfAbsent(bucket, () => []).add(color);
    }

    if (hueCounts.isEmpty) {
      // Fallback: simple average if image is monochromatic / pure gray
      int rTot = 0, gTot = 0, bTot = 0, count = 0;
      for (int i = 0; i < rgbaBytes.length; i += step) {
        rTot += rgbaBytes[i];
        gTot += rgbaBytes[i + 1];
        bTot += rgbaBytes[i + 2];
        count++;
      }
      if (count == 0) return const Color(0xFF800080);
      return Color.fromARGB(
        255,
        (rTot / count).round().clamp(0, 255),
        (gTot / count).round().clamp(0, 255),
        (bTot / count).round().clamp(0, 255),
      );
    }

    final bestBucket =
        hueCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final colors = hueColors[bestBucket]!;
    int totalR = 0, totalG = 0, totalB = 0;
    for (var c in colors) {
      totalR += (c.r * 255).round();
      totalG += (c.g * 255).round();
      totalB += (c.b * 255).round();
    }
    final avgColor = Color.fromARGB(
      255,
      (totalR / colors.length).round().clamp(0, 255),
      (totalG / colors.length).round().clamp(0, 255),
      (totalB / colors.length).round().clamp(0, 255),
    );

    // Boost saturation and brightness slightly to create a punchy desktop accent
    final hsv = HSVColor.fromColor(avgColor);
    final boosted = hsv
        .withSaturation((hsv.saturation * 1.25).clamp(0.4, 0.95))
        .withValue((hsv.value * 1.1).clamp(0.5, 0.95));
    return boosted.toColor();
  }
}
