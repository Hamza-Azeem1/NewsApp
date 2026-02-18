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
  late Animation<Offset> _slideAnim;

  // Pre-loaded data passed to HomeScreen so it renders instantly
  List<NewsArticle> _preloadedArticles = [];
  List<NewsVideo> _preloadedVideos = [];
  List<AppCategory> _preloadedCategories = [];
  bool _dataReady = false;
  bool _animDone = false;

  @override
  void initState() {
    super.initState();

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
    ).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: Curves.easeOutCubic,
    ));

    _mainCtrl.forward();

    // Minimum splash display time
    Future.delayed(const Duration(milliseconds: 2000), () {
      _animDone = true;
      _tryNavigate();
    });

    // Load all data in parallel while splash is showing
    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      final repo = NewsRepository();

      // Fetch categories + first page of articles & videos in parallel
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
      debugPrint('⚠️ Splash preload error (non-fatal): $e');
      // Silently continue — HomeScreen will load its own data
    }

    _dataReady = true;
    _tryNavigate();
  }

  // Navigate only when BOTH the minimum time has passed AND data is ready.
  // This prevents the "No content found" flash by ensuring content exists
  // before HomeScreen is shown.
  void _tryNavigate() {
    if (!_animDone || !_dataReady) return;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
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
              builder: (context, child) => Opacity(
                opacity: _opacityAnim.value,
                child: child,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 14),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('News',
                            style: t.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        Text(' Swipe',
                            style: t.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w400)),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: cs.primary, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'News, jobs & more in one swipe.',
                    style: t.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Small loading indicator so user knows something is happening
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
          ),
        ),
      ),
    );
  }
}