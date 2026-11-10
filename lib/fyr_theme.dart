import 'package:flutter/material.dart';

class FyrTheme {
  static const Color defaultAccent = Colors.purpleAccent;

  static final ValueNotifier<Color> accentColorNotifier = ValueNotifier<Color>(
    defaultAccent,
  );
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static Color get accentColor => accentColorNotifier.value;
  static ThemeMode get themeMode => themeModeNotifier.value;

  static Color get onAccentColor =>
      accentColor.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

  static Color onColor(Color color) =>
      color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

  static Color get onAccentColorMuted =>
      accentColor.computeLuminance() > 0.55 ? Colors.black54 : Colors.white70;

  static bool get isDark => themeMode == ThemeMode.dark;
  static Color get textColor => isDark ? Colors.white : Colors.black87;
  static Color get textColorMuted => isDark ? Colors.white70 : Colors.black54;
  static Color get bgColor =>
      isDark ? const Color(0xFF000000) : Colors.white.withValues(alpha: 0.9);
  static Color get cardColor =>
      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
  static Color get hoverColor =>
      isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
  static Color get dividerColor =>
      isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
  static Color get surfaceColor =>
      isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get sidebarColor =>
      isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  static void setAccentColor(Color color) {
    accentColorNotifier.value = color;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  static String get iconThemeName {
    final currentColor = accentColorNotifier.value;
    final int val = currentColor.value;
    String baseIconTheme = 'purple';
    if (val == Colors.purpleAccent.value ||
        val == Colors.purple.value ||
        val == Colors.deepPurpleAccent.value) {
      baseIconTheme = 'purple';
    } else if (val == Colors.indigoAccent.value ||
        val == Colors.blueAccent.value ||
        val == Colors.lightBlueAccent.value) {
      baseIconTheme = 'blue';
    } else if (val == Colors.cyanAccent.value || val == Colors.tealAccent.value) {
      baseIconTheme = 'standard';
    } else if (val == Colors.greenAccent.value ||
        val == Colors.lightGreenAccent.value ||
        val == Colors.limeAccent.value) {
      baseIconTheme = 'green';
    } else if (val == Colors.yellowAccent.value || val == Colors.amberAccent.value) {
      baseIconTheme = 'yellow';
    } else if (val == Colors.orangeAccent.value ||
        val == Colors.deepOrangeAccent.value) {
      baseIconTheme = 'orange';
    } else if (val == Colors.redAccent.value) {
      baseIconTheme = 'red';
    } else if (val == Colors.pinkAccent.value) {
      baseIconTheme = 'pink';
    }
    return 'Tela-$baseIconTheme-dark';
  }

  static const List<Color> customColors = [
    Colors.purpleAccent,
    Colors.purple,
    Colors.deepPurpleAccent,
    Colors.indigoAccent,
    Colors.blueAccent,
    Colors.lightBlueAccent,
    Colors.cyanAccent,
    Colors.tealAccent,
    Colors.greenAccent,
    Colors.lightGreenAccent,
    Colors.limeAccent,
    Colors.yellowAccent,
    Colors.amberAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
    Colors.redAccent,
    Colors.pinkAccent,
  ];
}

