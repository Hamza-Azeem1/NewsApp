import 'dart:async';
import 'package:flutter/material.dart';
import 'package:news_swipe/app/screens/courses_screen.dart';
import '../models/news_article.dart';
import '../models/app_category.dart';
import '../services/news_repository.dart';
import '../services/connectivity_service.dart';
import '../widgets/news_card.dart';
import '../widgets/category_bar.dart';
import '../widgets/side_drawer.dart';
import '../widgets/footer_nav.dart';
import '../widgets/offline_banner.dart';
import 'teachers_screen.dart';
import 'ebooks_screen.dart';
import 'tools_screen.dart';
import '../models/news_video.dart';
import '../widgets/video_card.dart';


class HomeScreen extends StatefulWidget {
  /// These are optional so web can still use `const HomeScreen()`.
  final ThemeMode? themeMode;
  final bool? isDark;
  final void Function(bool isDark)? onThemeChanged;

  const HomeScreen({
    super.key,
    this.themeMode,
    this.isDark,
    this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = NewsRepository();

  int _tabIndex = 0;
  String? _selectedCategory; // null => ALL
  String? _searchQuery;

  bool _showSearchBar = false;
  late TextEditingController _searchController;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  late Stream<List<NewsArticle>> _newsStream;
  late PageController _pageController;
  int _totalPages = 1;
  int _currentStoryIndex = 0;

  //bool _autoResetScheduled = false; // to avoid stacking multiple resets

  // 🔌 connectivity
  late StreamSubscription<AppConnectionStatus> _connSub;
  AppConnectionStatus _connStatus = AppConnectionStatus.online;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _updateNewsStream();

    _searchController = TextEditingController();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );

    // connectivity subscription
    _connStatus = ConnectivityService.instance.currentStatus;
    _connSub =
        ConnectivityService.instance.statusStream.listen((status) {
      if (!mounted) return;
      final wasOffline =
          _connStatus == AppConnectionStatus.offline;
      setState(() => _connStatus = status);

      if (status == AppConnectionStatus.online && wasOffline) {
        _onCameOnline();
      }
    });
  }

  void _onCameOnline() {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: cs.surfaceContainerHigh,
        content: Row(
          children: [
            Icon(Icons.wifi_rounded, color: cs.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Back online • Updating feed'),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Firestore streams will auto-refresh; just ensure we’re still using the right stream.
    _updateNewsStream();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animCtrl.dispose();
    _searchController.dispose();
    _connSub.cancel();
    super.dispose();
  }

  void _updateNewsStream() {
    _newsStream = _repo.streamNews(category: _selectedCategory);
  }

  void _onCategorySelected(String? name) {
    setState(() {
      _selectedCategory = name;
      _currentStoryIndex = 0;
      _updateNewsStream();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bool isDark =
        widget.isDark ?? Theme.of(context).brightness == Brightness.dark;

    final void Function(bool) onThemeChanged =
        widget.onThemeChanged ?? (_) {};

    // Decide which tab body to show
    Widget body;
    if (_tabIndex == 0) {
      body = _buildHomeFeed();
    } else {
      body = _buildOtherTab();
    }

    return Scaffold(
      drawer: SideDrawer(
        isDark: isDark,
        onThemeChanged: onThemeChanged,
      ),
      appBar: AppBar(
        leadingWidth: 72,
        leading: Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.only(left: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.menu_rounded),
                ),
              ),
            );
          },
        ),
        // 🔥 Hero title to match splash screen logo animation
        title: Hero(
          tag: 'app-title-hero',
          flightShuttleBuilder: (flightContext, animation,
              flightDirection, fromHeroContext, toHeroContext) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: toHeroContext.widget,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'News',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Swipe',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                ),
                const SizedBox(width: 6),
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
        centerTitle: true,
        actions: _tabIndex == 0
            ? [
                IconButton(
                  icon: Icon(
                    _showSearchBar
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                  ),
                  onPressed: _toggleSearchBar,
                ),
              ]
            : null,
      ),
      body: body,
      bottomNavigationBar: FooterNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
    );
  }

  Widget _buildOtherTab() {
    switch (_tabIndex) {
      case 1:
        return const TeachersScreen();
      case 2:
        return const CoursesScreen();
      case 3:
        return const EbooksScreen();
      case 4:
        return const ToolsScreen();
      default:
        return _buildHomeFeed();
    }
  }

  Widget _buildHomeFeed() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isOffline = _connStatus == AppConnectionStatus.offline;

    return Column(
      children: [
        if (isOffline) const OfflineBanner(),

        // 🔍 Animated Search Bar
        SizeTransition(
          sizeFactor: _expandAnim,
          axisAlignment: -1.0,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search news...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: (_searchQuery != null &&
                        _searchQuery!.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          setState(() {
                            _searchQuery = null;
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor:
                    cs.surfaceContainerHighest.withValues(alpha: 0.35),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Categories row
        StreamBuilder<List<AppCategory>>(
          stream: _repo.streamCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];
            return CategoryBar(
              categories: categories,
              selected: _selectedCategory,
              onSelect: _onCategorySelected,
            );
          },
        ),

        const SizedBox(height: 6),

        // News feed (vertical pager)
                // News + Videos feed (vertical pager)
        Expanded(
          child: StreamBuilder<List<NewsArticle>>(
            stream: _newsStream,
            builder: (context, newsSnap) {
              if (newsSnap.hasError) {
                return Center(
                  child: Text('Error: ${newsSnap.error}'),
                );
              }
              if (newsSnap.connectionState == ConnectionState.waiting &&
                  !newsSnap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final allArticles = newsSnap.data ?? [];
              final q = (_searchQuery ?? '').toLowerCase();

              final filteredArticles = q.isEmpty
                  ? allArticles
                  : allArticles.where((a) {
                      bool contains(String s) =>
                          s.toLowerCase().contains(q);
                      return contains(a.title) ||
                          contains(a.subtitle) ||
                          contains(a.description) ||
                          contains(a.category);
                    }).toList();

              // Now load videos and combine them with articles
              return StreamBuilder<List<NewsVideo>>(
                stream: _repo.streamVideos(
                  category: _selectedCategory,
                ),
                builder: (context, videoSnap) {
                  if (videoSnap.hasError) {
                    return Center(
                      child: Text('Error: ${videoSnap.error}'),
                    );
                  }

                  final videos = videoSnap.data ?? [];

                  // Interleave: after every 3 articles, insert 1 video (if any left)
                  final List<_FeedItem> items = [];
                  int videoIndex = 0;

                  for (int i = 0; i < filteredArticles.length; i++) {
                    items.add(_FeedItem.article(filteredArticles[i]));
                    final bool shouldInsertVideo =
                        ((i + 1) % 3 == 0) && videoIndex < videos.length;
                    if (shouldInsertVideo) {
                      items.add(_FeedItem.video(videos[videoIndex++]));
                    }
                  }
                  // Append any leftover videos
                  while (videoIndex < videos.length) {
                    items.add(_FeedItem.video(videos[videoIndex++]));
                  }

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        q.isEmpty
                            ? 'No items found for this category.'
                            : 'No results for "$q".',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  _totalPages = items.length + 1; // +1 for end-of-feed page
                  final endIndex = _totalPages - 1;

                  final progress = _totalPages <= 1
                      ? 0.0
                      : (_currentStoryIndex.clamp(0, endIndex) / endIndex);

                  return Column(
                    children: [
                      // Progress header
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Top stories',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.75),
                                      ),
                                ),
                                Text(
                                  '${(_currentStoryIndex >= items.length ? items.length : _currentStoryIndex + 1)} / ${items.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.primary
                                            .withValues(alpha: 0.9),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                  begin: 0, end: progress),
                              duration:
                                  const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    color: cs.surfaceContainerHigh
                                        .withValues(alpha: 0.8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Align(
                                    alignment:
                                        Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: value,
                                      child: Container(
                                        decoration:
                                            BoxDecoration(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(999),
                                          gradient:
                                              LinearGradient(
                                            colors: [
                                              cs.primary,
                                              cs.primary
                                                  .withValues(
                                                      alpha:
                                                          0.4),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Vertical story pager
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          physics:
                              const BouncingScrollPhysics(),
                          itemCount: _totalPages,
                          onPageChanged: (i) async {
                            setState(() {
                              _currentStoryIndex =
                                  i.clamp(0, endIndex);
                            });

                            // If you had special auto-reset logic,
                            // you can keep it here (omitted for brevity).
                          },
                          itemBuilder: (context, index) {
                            if (index < items.length) {
                              final item = items[index];
                              if (item.isVideo) {
                                return _VideoPage(
                                  video: item.video!,
                                );
                              } else {
                                return _NewsPage(
                                  article: item.article!,
                                );
                              }
                            } else {
                              return _EndOfFeed(
                                label: _selectedCategory ==
                                        null
                                    ? 'No more stories'
                                    : 'No more $_selectedCategory stories',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),

      ],
    );
  }
}

class _NewsPage extends StatelessWidget {
  final NewsArticle article;

  const _NewsPage({required this.article});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: NewsCard(article: article),
    );
  }
}

class _EndOfFeed extends StatelessWidget {
  final String label;
  const _EndOfFeed({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.surface.withValues(alpha: 0.05),
            cs.surface,
          ],
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding:
            const EdgeInsets.only(bottom: 96, left: 16, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'End of feed',
                style: t.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 42,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You’re all caught up',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New stories will appear here when available.',
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItem {
  final NewsArticle? article;
  final NewsVideo? video;
  final bool isVideo;

  _FeedItem.article(this.article)
      : video = null,
        isVideo = false;

  _FeedItem.video(this.video)
      : article = null,
        isVideo = true;
}

class _VideoPage extends StatelessWidget {
  final NewsVideo video;

  const _VideoPage({required this.video});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: VideoCard(video: video),
    );
  }
}

