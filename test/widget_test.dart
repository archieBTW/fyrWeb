import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billyrigdon/models/config_model.dart';
import 'package:billyrigdon/app_data.dart';
import 'package:billyrigdon/system_settings.dart';
import 'package:billyrigdon/fyr_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Config contains beats_by_arch and loads apps properly', () async {
    final String configString = await rootBundle.loadString('assets/config.json');
    final configJson = jsonDecode(configString);
    final config = AppConfig.fromJson(configJson);

    expect(config.profile.name, isNotEmpty);
    expect(config.apps.any((a) => a.id == 'beats_by_arch'), isTrue);

    final apps = getApps(config);
    final beatsApp = apps.firstWhere((a) => a.id == 'beats_by_arch');
    expect(beatsApp.title, equals('Beats by Arch'));
    expect(beatsApp.url, equals('https://beats.archerwoods.dev'));
  });

  test('SystemSettings.setDarkMode synchronizes with FyrTheme and notifies listeners', () async {
    final settings = SystemSettings();
    bool notified = false;
    settings.addListener(() {
      notified = true;
    });

    settings.setDarkMode(false);
    expect(settings.isDarkMode, isFalse);
    expect(FyrTheme.isDark, isFalse);
    expect(notified, isTrue);

    notified = false;
    settings.setDarkMode(true);
    expect(settings.isDarkMode, isTrue);
    expect(FyrTheme.isDark, isTrue);
    expect(notified, isTrue);
  });
}
