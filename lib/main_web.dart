import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/screens/home_screen.dart';
import 'admin/auth/admin_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WebApp());
}

class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF6F6CFB),
      scaffoldBackgroundColor: const Color(0xFF0E1117),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme:
          const InputDecorationTheme(border: OutlineInputBorder()),
    );

    return MaterialApp(
      title: 'News App',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routes: {
        '/': (_) => const HomeScreen(),
        '/admin': (_) => const AdminGate(),
      },
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
