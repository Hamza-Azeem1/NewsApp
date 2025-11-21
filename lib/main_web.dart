import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/screens/home_screen.dart';
import 'admin/auth/admin_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WebApp());
}

class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _setTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6F6CFB);

    final baseLight = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: seed,
      scaffoldBackgroundColor: const Color(0xFFF5F5FB),
      appBarTheme:
          const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme:
          const InputDecorationTheme(border: OutlineInputBorder()),
    );

    final baseDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: seed,
      scaffoldBackgroundColor: const Color(0xFF0E1117),
      appBarTheme:
          const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme:
          const InputDecorationTheme(border: OutlineInputBorder()),
    );

    final isDark = _themeMode == ThemeMode.dark;

    return MaterialApp(
      title: 'News App',
      debugShowCheckedModeBanner: false,
      theme: baseLight,
      darkTheme: baseDark,
      themeMode: _themeMode,
      routes: {
        '/': (_) => HomeScreen(
              themeMode: _themeMode,
              isDark: isDark,
              onThemeChanged: _setTheme,
            ),
        '/admin': (_) => const AdminGate(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => HomeScreen(
          themeMode: _themeMode,
          isDark: isDark,
          onThemeChanged: _setTheme,
        ),
      ),
    );
  }
}
