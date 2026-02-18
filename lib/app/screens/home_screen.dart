import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../models/news_video.dart';
import '../models/app_category.dart';
import '../services/news_repository.dart';
import '../services/connectivity_service.dart';
import '../widgets/news_card.dart';
import '../widgets/video_card.dart';
import '../widgets/category_bar.dart';
import '../widgets/side_drawer.dart';
import '../widgets/footer_nav.dart';
import '../widgets/offline_banner.dart';
import 'teachers_screen.dart';
import 'courses_screen.dart';
import 'ebooks_screen.dart';
import 'tools_screen.dart';
import 'tab_page_controller.dart';

// =======================
// Feed item class
// =======================
class FeedItem {
  final NewsArticle? article;
  final NewsVideo? video;
  final bool isVideo;

  FeedItem.article(this.article)
      : video = null,
        isVideo = false;

  FeedItem.video(this.video)
      : article = null,
        isVideo = true;

  DateTime get date => isVideo
      ? (video?.createdAt ?? DateTime(1970))
      : (article?.date ?? DateTime(1970));
}

// =====================================================================
// fetchCategoriesFromFirestore — top-level so splash can call it too
// =====================================================================
Future<List<AppCategory>> fetchCategoriesFromFirestore() async {
  try {
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('news').get(),
      FirebaseFirestore.instance.collection('videos').get(),
    ]);

    final nameSet = <String>{};

    for (final doc in results[0].docs) {
      final data = doc.data();
      final cats = data['categories'];
      if (cats is List) {
        for (final c in cats) {
          final s = c.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'all') nameSet.add(s);
        }
      }
      final primary = (data['primaryCategory'] ?? '').toString().trim();
      if (primary.isNotEmpty && primary.toLowerCase() != 'all') nameSet.add(primary);
      final single = (data['category'] ?? '').toString().trim();
      if (single.isNotEmpty && single.toLowerCase() != 'all') nameSet.add(single);
    }

    for (final doc in results[1].docs) {
      final data = doc.data();
      final cats = data['categories'];
      if (cats is List) {
        for (final c in cats) {
          final s = c.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'all') nameSet.add(s);
        }
      }
      final single = (data['category'] ?? '').toString().trim();
      if (single.isNotEmpty && single.toLowerCase() != 'all') nameSet.add(single);
    }

    final sorted = nameSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return sorted
        .map((n) => AppCategory(id: n.toLowerCase(), name: n))
        .toList();
  } catch (e) {
    debugPrint('❌ fetchCategoriesFromFirestore: $e');
    return [];
  }
}

// =====================
// HomeScreen
// Accepts optional preloaded data from SplashScreen so the feed
// renders immediately with content instead of "No content found".
// =====================
class HomeScreen extends StatefulWidget {
  final ThemeMode? themeMode;
  final bool? isDark;
  final void Function(bool isDark)? onThemeChanged;

  // Pre-loaded by SplashScreen while it was showing
  final List<NewsArticle> preloadedArticles;
  final List<NewsVideo> preloadedVideos;
  final List<AppCategory> preloadedCategories;

  const HomeScreen({
    super.key,
    this.themeMode,
    this.isDark,
    this.onThemeChanged,
    this.preloadedArticles = const [],
    this.preloadedVideos = const [],
    this.preloadedCategories = const [],
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = NewsRepository();

  int _tabIndex = 0;
  late TabPageControllerManager _tabManager;

  // Categories
  late Future<List<AppCategory>> _categoryFuture;
  List<AppCategory> _categories = [];

  // Feed
  String? _selectedCategory;
  String? _pendingCategory;
  bool _isSwitchingCategory = false;
  String? _searchQuery;
  int _currentStoryIndex = 0;
  List<NewsArticle> _articles = [];
  List<NewsVideo> _videos = [];

  StreamSubscription<List<NewsArticle>>? _newsSub;
  StreamSubscription<List<NewsVideo>>? _videoSub;
  StreamSubscription<AppConnectionStatus>? _connSub;

  bool _showSearchBar = false;
  late TextEditingController _searchController;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  AppConnectionStatus _connStatus = AppConnectionStatus.online;

  @override
  void initState() {
    super.initState();

    _tabManager = TabPageControllerManager(initialIndex: 0);
    _searchController = TextEditingController();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);

    // ── Seed state with preloaded data immediately ───────────────────────
    // This means on the very first frame, _articles and _videos are already
    // populated — no "No content found" flash ever appears.
    _articles = List.of(widget.preloadedArticles);
    _videos = List.of(widget.preloadedVideos);
    _categories = List.of(widget.preloadedCategories);

    // Category future resolves instantly if we already have data,
    // otherwise fetches from Firestore.
    if (_categories.isNotEmpty) {
      _categoryFuture = Future.value(_categories);
    } else {
      _startCategoryFetch();
    }

    _repo.cleanupOldContent();

    // Subscribe to live streams — first emission will refresh the preloaded
    // data with the latest from Firestore (seamless, no flash)
    _subscribeToFeed(category: null, isInitial: true);

    _connStatus = ConnectivityService.instance.currentStatus;
    _connSub = ConnectivityService.instance.statusStream.listen((status) {
      if (!mounted) return;
      final wasOffline = _connStatus == AppConnectionStatus.offline;
      setState(() => _connStatus = status);
      if (status == AppConnectionStatus.online && wasOffline) _onCameOnline();
    });
  }

  void _startCategoryFetch() {
    _categoryFuture = fetchCategoriesFromFirestore().then((cats) {
      if (mounted) setState(() => _categories = cats);
      return cats;
    });
  }

  void _subscribeToFeed({required String? category, bool isInitial = false}) {
    _newsSub?.cancel();
    _videoSub?.cancel();

    _pendingCategory = category;
    if (!isInitial) setState(() => _isSwitchingCategory = true);

    bool newsArrived = false;
    bool videosArrived = false;
    List<NewsArticle>? pendingArticles;
    List<NewsVideo>? pendingVideos;

    void tryCommit() {
      if (newsArrived && videosArrived) {
        if (mounted) {
          setState(() {
            _selectedCategory = _pendingCategory;
            _articles = pendingArticles!;
            _videos = pendingVideos!;
            _isSwitchingCategory = false;
            _currentStoryIndex = 0;
          });
        }
      }
    }

    _newsSub = _repo.streamNews(category: category).listen((articles) {
      if (!newsArrived) {
        newsArrived = true;
        pendingArticles = articles;
        tryCommit();
      } else if (_selectedCategory == category && mounted) {
        setState(() => _articles = articles);
      }
    });

    _videoSub = _repo.streamVideos(category: category).listen((videos) {
      if (!videosArrived) {
        videosArrived = true;
        pendingVideos = videos;
        tryCommit();
      } else if (_selectedCategory == category && mounted) {
        setState(() => _videos = videos);
      }
    });
  }

  @override
  void dispose() {
    _newsSub?.cancel();
    _videoSub?.cancel();
    _connSub?.cancel();
    _tabManager.dispose();
    _animCtrl.dispose();
    _searchController.dispose();
    _repo.dispose();
    super.dispose();
  }

  void _onCategorySelected(String? name) {
    if (_selectedCategory == name && !_isSwitchingCategory) return;
    _subscribeToFeed(category: name);
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _animCtrl.forward();
      } else {
        _searchQuery = null;
        _searchController.clear();
        _animCtrl.reverse();
      }
    });
  }

  void _onCameOnline() {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: cs.surfaceContainerHigh,
      content: Row(children: [
        Icon(Icons.wifi_rounded, color: cs.primary),
        const SizedBox(width: 12),
        const Expanded(child: Text('Back online • Updating feed')),
      ]),
      duration: const Duration(seconds: 2),
    ));
    _startCategoryFetch();
    _subscribeToFeed(category: _selectedCategory);
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _repo.refreshNews(category: _selectedCategory),
      _repo.refreshVideos(category: _selectedCategory),
    ]);
    _startCategoryFetch();
    if (mounted) setState(() => _currentStoryIndex = 0);
  }

  List<FeedItem> get _filteredItems {
    final items = [
      ..._articles.map((a) => FeedItem.article(a)),
      ..._videos.map((v) => FeedItem.video(v)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final q = (_searchQuery ?? '').toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      if (item.isVideo) return item.video!.title.toLowerCase().contains(q);
      return item.article!.title.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isDark =
        widget.isDark ?? Theme.of(context).brightness == Brightness.dark;
    final onThemeChanged = widget.onThemeChanged ?? (_) {};

    return Scaffold(
      drawer: SideDrawer(isDark: isDark, onThemeChanged: onThemeChanged),
      appBar: AppBar(
        leadingWidth: 72,
        leading: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                decoration: BoxDecoration(
                  //color: cs.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.menu_rounded),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('News',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('Swipe',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w400)),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            ),
          ],
        ),
        centerTitle: true,
        actions: _tabIndex == 0
            ? [
                IconButton(
                  icon: Icon(_showSearchBar
                      ? Icons.close_rounded
                      : Icons.search_rounded),
                  onPressed: _toggleSearchBar,
                ),
              ]
            : null,
      ),
      body: PageView(
        controller: _tabManager.pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => _tabIndex = i),
        children: [
          _buildHomeFeed(),
          const TeachersScreen(),
          const CoursesScreen(),
          const EbooksScreen(),
          const ToolsScreen(),
        ],
      ),
      bottomNavigationBar: FooterNav(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          _tabManager.animateToPage(i);
        },
      ),
    );
  }

  Widget _buildHomeFeed() {
    final cs = Theme.of(context).colorScheme;
    final bool isOffline = _connStatus == AppConnectionStatus.offline;
    final filtered = _filteredItems;
    final total = filtered.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOffline) const OfflineBanner(),

        // Search bar
        SizeTransition(
          sizeFactor: _expandAnim,
          axisAlignment: -1.0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search news...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withAlpha(90),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
        ),

        // Category bar with gap
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: FutureBuilder<List<AppCategory>>(
            future: _categoryFuture,
            builder: (context, snapshot) {
              final cats = _categories.isNotEmpty
                  ? _categories
                  : (snapshot.data ?? []);
              return CategoryBar(
                categories: cats,
                selected: _isSwitchingCategory
                    ? _pendingCategory
                    : _selectedCategory,
                onSelect: _onCategorySelected,
              );
            },
          ),
        ),

        // Switching indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isSwitchingCategory ? 2 : 0,
          child: _isSwitchingCategory
              ? LinearProgressIndicator(
                  minHeight: 2,
                  color: cs.primary,
                  backgroundColor: Colors.transparent,
                )
              : const SizedBox.shrink(),
        ),

        // Progress bar
        if (total > 0) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _StoryProgressBar(
              current: _currentStoryIndex,
              total: total,
            ),
          ),
          const SizedBox(height: 6),
        ] else
          const SizedBox(height: 6),

        // Feed
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemHeight = constraints.maxHeight;

              if (filtered.isEmpty && !_isSwitchingCategory) {
                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: itemHeight * 0.35),
                      const Center(child: Text('No content found')),
                    ],
                  ),
                );
              }

              if (filtered.isEmpty && _isSwitchingCategory) {
                return const SizedBox.expand();
              }

              return SnappingFeedList(
                key: ValueKey('${_selectedCategory}_${filtered.length}'),
                items: filtered,
                itemHeight: itemHeight,
                selectedCategory: _selectedCategory,
                onRefresh: _handleRefresh,
                onPageChanged: (i) =>
                    setState(() => _currentStoryIndex = i),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// _StoryProgressBar
// =====================================================================
class _StoryProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _StoryProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final double progress =
        total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final int displayCurrent = current.clamp(0, total);

    return Row(
      children: [
        Text(
          'Top Stories',
          style: t.labelSmall?.copyWith(
            color: cs.onSurface.withAlpha(160),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor:
                      cs.surfaceContainerHighest.withAlpha(180),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$displayCurrent / $total',
          style: t.labelSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// SnappingFeedList
// =====================================================================
class SnappingFeedList extends StatefulWidget {
  final List<FeedItem> items;
  final double itemHeight;
  final String? selectedCategory;
  final Future<void> Function() onRefresh;
  final void Function(int) onPageChanged;

  const SnappingFeedList({
    super.key,
    required this.items,
    required this.itemHeight,
    required this.selectedCategory,
    required this.onRefresh,
    required this.onPageChanged,
  });

  @override
  State<SnappingFeedList> createState() => _SnappingFeedListState();
}

class _SnappingFeedListState extends State<SnappingFeedList> {
  late final ScrollController _ctrl;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_ctrl.hasClients) return;
    final h = widget.itemHeight;
    if (h <= 0) return;
    final idx = (_ctrl.offset / h).round().clamp(0, widget.items.length);
    if (idx != _currentIndex) {
      _currentIndex = idx;
      widget.onPageChanged(idx);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _ctrl,
        physics: const PageScrollPhysics(),
        itemCount: widget.items.length + 1,
        itemBuilder: (context, index) {
          return SizedBox(
            height: widget.itemHeight,
            child: index < widget.items.length
                ? _buildItem(widget.items[index])
                : EndOfFeed(
                    label: widget.selectedCategory == null
                        ? 'No more stories'
                        : 'No more ${widget.selectedCategory} stories',
                  ),
          );
        },
      ),
    );
  }

  Widget _buildItem(FeedItem item) => item.isVideo
      ? VideoPage(video: item.video!)
      : NewsPage(article: item.article!);
}

// ====================
// Page widgets
// ====================
class NewsPage extends StatelessWidget {
  final NewsArticle article;
  const NewsPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: NewsCard(article: article));
}

class VideoPage extends StatelessWidget {
  final NewsVideo video;
  const VideoPage({super.key, required this.video});

  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: VideoCard(video: video));
}

class EndOfFeed extends StatelessWidget {
  final String label;
  const EndOfFeed({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.surface.withAlpha(13), cs.surface],
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('End of feed',
                  style: t.labelMedium?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withAlpha(242),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: cs.shadow.withAlpha(46),
                      blurRadius: 24,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 42, color: cs.primary),
                  const SizedBox(height: 8),
                  Text("You're all caught up",
                      style: t.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: t.bodySmall
                          ?.copyWith(color: cs.onSurface.withAlpha(179)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('New stories will appear here when available.',
                      style: t.bodySmall
                          ?.copyWith(color: cs.onSurface.withAlpha(153)),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}