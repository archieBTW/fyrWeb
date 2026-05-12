import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'desktop_screen.dart';
import 'package:provider/provider.dart';
import 'system_settings.dart';
import 'window_manager.dart';
import 'system_controller.dart';

void main() {
  final windowManager = WindowManager();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SystemSettings()),
        ChangeNotifierProvider.value(value: windowManager),
        ChangeNotifierProvider(create: (_) => SystemController(windowManager: windowManager)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettings>();
    
    return MaterialApp(
      title: 'fyrWeb',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.accentColor,
          brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
          surface: settings.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0F0),
          onSurface: settings.isDarkMode ? Colors.white : Colors.black87,
        ),
        scaffoldBackgroundColor: settings.isDarkMode ? Colors.black : Colors.white,
        textTheme: GoogleFonts.interTextTheme(
          settings.isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        ).apply(
          bodyColor: settings.isDarkMode ? Colors.white : Colors.black87,
          displayColor: settings.isDarkMode ? Colors.white : Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const DesktopScreen(),
    );
  }
}
