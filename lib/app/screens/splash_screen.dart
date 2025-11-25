import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final bool isDark;
  final void Function(bool) onThemeChanged;

  const SplashScreen({
    super.key,
    required this.themeMode,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Main intro animation (scale + fade + slight slide)
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: Curves.easeOutBack,
    );

    _opacityAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _mainCtrl.forward();

    // Let splash stay a bit, then go directly to HomeScreen (no blank frame)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          pageBuilder: (_, __, ___) => HomeScreen(
            themeMode: widget.themeMode,
            isDark: widget.isDark,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: AnimatedBuilder(
              animation: _opacityAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnim.value,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 Hero for logo/title -> flies into AppBar title
                  Hero(
                    tag: 'app-title-hero',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'News',
                              style: t.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              ' Swipe',
                              style: t.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tagline
                  Text(
                    'News, jobs & more in one swipe.',
                    style: t.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
