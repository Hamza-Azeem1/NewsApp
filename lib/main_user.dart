import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NewsSwipeApp());
}

class NewsSwipeApp extends StatefulWidget {
  const NewsSwipeApp({super.key});

  @override
  State<NewsSwipeApp> createState() => _NewsSwipeAppState();
}

class _NewsSwipeAppState extends State<NewsSwipeApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _setTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7C5CFF);

    // LIGHT THEME
    final baseLight = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: Brightness.light,
    );

    final light = baseLight.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F5FB),
      appBarTheme: baseLight.appBarTheme.copyWith(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: baseLight.colorScheme.onSurface,
        titleTextStyle: baseLight.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: baseLight.navigationBarTheme.copyWith(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor:
            baseLight.colorScheme.primary.withOpacity(0.12),
        labelTextStyle: WidgetStatePropertyAll(
          baseLight.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: baseLight.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
      ),
    );

    // DARK THEME
    const darkBg = Color(0xFF0F1115);
    final baseDark = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
    );

    final dark = baseDark.copyWith(
      appBarTheme: baseDark.appBarTheme.copyWith(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        titleTextStyle: baseDark.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: baseDark.navigationBarTheme.copyWith(
        elevation: 0,
        backgroundColor: darkBg,
        indicatorColor:
            baseDark.colorScheme.secondaryContainer.withOpacity(.25),
        labelTextStyle: WidgetStatePropertyAll(
          baseDark.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: baseDark.chipTheme.copyWith(
        side: const BorderSide(color: Colors.white10),
        selectedColor:
            baseDark.colorScheme.secondaryContainer.withOpacity(.25),
        labelStyle: baseDark.textTheme.labelLarge,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      textTheme: baseDark.textTheme.copyWith(
        titleLarge: baseDark.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: baseDark.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: baseDark.textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: baseDark.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      snackBarTheme: baseDark.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1D24),
        contentTextStyle:
            const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    final isDark = _themeMode == ThemeMode.dark;

    return MaterialApp(
      title: 'News Swipe',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: light,
      darkTheme: dark,
      home: HomeScreen(
        themeMode: _themeMode,
        isDark: isDark,
        onThemeChanged: _setTheme,
      ),
    );
  }
}
