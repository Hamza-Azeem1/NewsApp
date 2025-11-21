import 'package:flutter/material.dart';
import 'package:news_swipe/app/screens/courses_screen.dart';
import '../models/news_article.dart';
import '../models/app_category.dart';
import '../services/news_repository.dart';
import '../widgets/news_card.dart';
import '../widgets/category_bar.dart';
import '../widgets/side_drawer.dart';
import '../widgets/footer_nav.dart';
import 'teachers_screen.dart';
import 'ebooks_screen.dart';
import 'tools_screen.dart';

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

  bool _autoResetScheduled = false; // to avoid stacking multiple resets

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animCtrl.dispose();
    _searchController.dispose();
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

    // If parent didn't pass isDark, infer from current theme
    final bool isDark =
        widget.isDark ?? Theme.of(context).brightness == Brightness.dark;

    // If parent didn't pass onThemeChanged (e.g. web app), make it a no-op
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
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.menu_rounded),
                ),
              ),
            );
          },
        ),
        title: Row(
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

    return Column(
      children: [
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
        Expanded(
          child: StreamBuilder<List<NewsArticle>>(
            stream: _newsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final all = snapshot.data ?? [];
              final q = (_searchQuery ?? '').toLowerCase();

              final filtered = q.isEmpty
                  ? all
                  : all.where((a) {
                      bool contains(String s) =>
                          s.toLowerCase().contains(q);
                      return contains(a.title) ||
                          contains(a.subtitle) ||
                          contains(a.description) ||
                          contains(a.category);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    q.isEmpty
                        ? 'No news found for this category.'
                        : 'No news matched your search.',
                  ),
                );
              }

              _totalPages = filtered.length + 1;
              final endIndex = _totalPages - 1;

              final progress = _totalPages <= 1
                  ? 0.0
                  : (_currentStoryIndex.clamp(0, endIndex) / endIndex);

              return Column(
                children: [
                  // progress bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LinearProgressIndicator(value: progress),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) async {
                        setState(() {
                          _currentStoryIndex = i.clamp(0, endIndex);
                        });

                        // When user reaches end-of-feed page
                        if (i == endIndex && _pageController.hasClients) {
                          if (!_autoResetScheduled) {
                            _autoResetScheduled = true;

                            // Capture what we need BEFORE async gap
                            final messenger =
                                ScaffoldMessenger.of(context);
                            final cs2 =
                                Theme.of(context).colorScheme;

                            await Future.delayed(
                              const Duration(seconds: 2),
                            );

                            if (!mounted ||
                                !_pageController.hasClients) {
                              _autoResetScheduled = false;
                              return;
                            }

                            await _pageController.animateToPage(
                              0,
                              duration:
                                  const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            );

                            if (!mounted) return;

                            setState(() {
                              _currentStoryIndex = 0;
                              _autoResetScheduled = false;
                            });

                            // Modern floating snack (using captured messenger)
                            messenger.showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                backgroundColor:
                                    cs2.surfaceContainerHigh,
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      color: cs2.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Back to top • Latest stories',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: cs2.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                duration:
                                    const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      itemCount: _totalPages,
                      itemBuilder: (context, index) {
                        if (index < filtered.length) {
                          return _NewsPage(article: filtered[index]);
                        }
                        return _EndOfFeed(
                          label: _selectedCategory == null
                              ? 'No more news'
                              : 'No more $_selectedCategory news',
                        );
                      },
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
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
