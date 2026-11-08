import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billyrigdon/models/config_model.dart';
import 'package:billyrigdon/app_data.dart';

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
}
