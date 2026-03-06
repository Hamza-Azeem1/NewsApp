import 'dart:async';
import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../models/news_video.dart';
import '../models/app_category.dart';
import '../services/news_repository.dart';
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

  List<NewsArticle> _preloadedArticles = [];
  List<NewsVideo> _preloadedVideos = [];
  List<AppCategory> _preloadedCategories = [];
  bool _dataReady = false;
  bool _animDone = false;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: Curves.easeOutBack,
    );

    _opacityAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: Curves.easeIn,
    );

    _mainCtrl.forward();

    // Shorter splash delay to make icon disappear faster
    Future.delayed(const Duration(milliseconds: 600), () {
      _animDone = true;
      _tryNavigate();
    });

    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      final repo = NewsRepository();

      final results = await Future.wait([
        fetchCategoriesFromFirestore(),
        repo.refreshNews().then((_) => repo.streamNews().first),
        repo.refreshVideos().then((_) => repo.streamVideos().first),
      ]);

      if (!mounted) return;

      _preloadedCategories = results[0] as List<AppCategory>;
      _preloadedArticles = results[1] as List<NewsArticle>;
      _preloadedVideos = results[2] as List<NewsVideo>;

      repo.dispose();
    } catch (e) {
      debugPrint('⚠️ Splash preload error: $e');
    }

    _dataReady = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!_animDone || !_dataReady) return;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: HomeScreen(
            themeMode: widget.themeMode,
            isDark: widget.isDark,
            onThemeChanged: widget.onThemeChanged,
            preloadedArticles: _preloadedArticles,
            preloadedVideos: _preloadedVideos,
            preloadedCategories: _preloadedCategories,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Animated Logo ---
            ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _opacityAnim,
                child: Image.asset(
                  'assets/images/app_logo_dark.png',
                  width: 180, // bigger logo
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Optional tagline
            Text(
              'News, jobs & more in one swipe.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Small loading indicator
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
