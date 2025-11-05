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

class NewsSwipeApp extends StatelessWidget {
  const NewsSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF7C5CFF); // modern purple/indigo
    final baseDark = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1115),
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
        backgroundColor: const Color(0xFF0F1115),
        indicatorColor: baseDark.colorScheme.secondaryContainer.withOpacity(.25),
        labelTextStyle: WidgetStatePropertyAll(
          baseDark.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: baseDark.chipTheme.copyWith(
        side: const BorderSide(color: Colors.white10),
        selectedColor: baseDark.colorScheme.secondaryContainer.withOpacity(.25),
        labelStyle: baseDark.textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      textTheme: baseDark.textTheme.copyWith(
        titleLarge: baseDark.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: baseDark.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: baseDark.textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: baseDark.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      snackBarTheme: baseDark.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1D24),
        contentTextStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    return MaterialApp(
      title: 'News Swipe',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: dark,
      theme: dark, // keep consistent
      home: const HomeScreen(),
    );
  }
}
