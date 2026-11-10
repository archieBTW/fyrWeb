import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billyrigdon/models/config_model.dart';
import 'package:billyrigdon/app_data.dart';
import 'package:billyrigdon/system_settings.dart';
import 'package:billyrigdon/fyr_theme.dart';
import 'package:billyrigdon/widgets/portfolio_app_icon.dart';
import 'package:billyrigdon/window_manager.dart';
import 'package:billyrigdon/system_controller.dart';
import 'package:billyrigdon/desktop_screen.dart';
import 'package:billyrigdon/services/music_audio/music_audio.dart';
import 'package:billyrigdon/widgets/taskbar/start_menu_popup.dart';
import 'package:billyrigdon/widgets/dock/fyrdock.dart';
import 'package:provider/provider.dart';

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

  test('Config contains welledumacated and verifies title, url, and case study', () async {
    final String configString = await rootBundle.loadString('assets/config.json');
    final configJson = jsonDecode(configString);
    final config = AppConfig.fromJson(configJson);

    expect(config.apps.any((a) => a.id == 'welledumacated'), isTrue);

    final apps = getApps(config);
    final wellApp = apps.firstWhere((a) => a.id == 'welledumacated');
    expect(wellApp.title, equals('well edumacated'));
    expect(wellApp.url, equals('https://welledumacated.dev'));
    expect(wellApp.caseStudy, isNotNull);
    expect(wellApp.caseStudy, isNotEmpty);
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

  testWidgets('PortfolioAppIcon renders custom logos for archbtw, libretrac, pycontui without waffles', (tester) async {
    // Test archbtw
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PortfolioAppIcon(appId: 'archbtw', size: 48),
        ),
      ),
    );
    expect(find.byIcon(Icons.album_rounded), findsOneWidget);
    expect(find.byIcon(Icons.apps), findsNothing);

    // Test libretrac
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PortfolioAppIcon(appId: 'libretrac', size: 48),
        ),
      ),
    );
    expect(find.byIcon(Icons.monitor_heart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.apps), findsNothing);

    // Test pycontui
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PortfolioAppIcon(appId: 'pycontui', size: 48),
        ),
      ),
    );
    expect(find.byIcon(Icons.terminal_rounded), findsOneWidget);
    expect(find.byIcon(Icons.apps), findsNothing);
  });

  testWidgets('PortfolioAppIcon with solidBackground wraps asset apps in solid containers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PortfolioAppIcon(appId: 'browser', size: 48, solidBackground: true),
        ),
      ),
    );
    // Finds Container with solid background color
    final containerFinder = find.byType(Container);
    expect(containerFinder, findsWidgets);

    final container = tester.widget<Container>(containerFinder.first);
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration?.color, isNotNull);
    expect(decoration?.color?.a, equals(1.0)); // fully opaque, not transparent
  });

  testWidgets('Start menu appears in front of FyrDock on desktop', (tester) async {
    final String configString = await rootBundle.loadString('assets/config.json');
    final configJson = jsonDecode(configString);
    final config = AppConfig.fromJson(configJson);

    final windowManager = WindowManager();
    final settings = SystemSettings();
    final systemController = SystemController(windowManager: windowManager);

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppConfig>.value(value: config),
          ChangeNotifierProvider<SystemSettings>.value(value: settings),
          ChangeNotifierProvider<WindowManager>.value(value: windowManager),
          ChangeNotifierProvider<SystemController>.value(value: systemController),
          ChangeNotifierProvider<MusicService>.value(value: MusicService.instance),
        ],
        child: const MaterialApp(
          home: DesktopScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap start button on FyrTaskbar
    final startButton = find.byTooltip('Start Menu (fyr)');
    expect(startButton, findsOneWidget);
    await tester.tap(startButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify StartMenuPopup and FyrDock are both present
    expect(find.byType(StartMenuPopup), findsOneWidget);
    expect(find.byType(FyrDock), findsOneWidget);

    // Verify in the stack children that StartMenuPopup is rendered after FyrDock
    final stackFinder = find.ancestor(
      of: find.byType(StartMenuPopup),
      matching: find.byType(Stack),
    );
    expect(stackFinder, findsWidgets);

    final stack = tester.widget<Stack>(stackFinder.first);
    int dockIndex = -1;
    int startMenuIndex = -1;

    for (int i = 0; i < stack.children.length; i++) {
      final child = stack.children[i];
      // FyrDock is inside AnimatedPositioned
      if (child is AnimatedPositioned) {
        dockIndex = i;
      }
      // StartMenuPopup is inside Positioned with top: 56, left: 0
      if (child is Positioned && child.left == 0 && child.top == 56 && child.bottom == 0) {
        startMenuIndex = i;
      }
    }

    expect(dockIndex, isNonNegative);
    expect(startMenuIndex, isNonNegative);
    // startMenuIndex > dockIndex guarantees StartMenuPopup paints in front of FyrDock
    expect(startMenuIndex, greaterThan(dockIndex));

    await tester.pumpWidget(const SizedBox());
  });
}
