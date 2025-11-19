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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = NewsRepository();

  int _tabIndex = 0;
  String? _selectedCategory; // null => ALL
  String? _searchQuery;      // inline search for News tab

  // 🔍 search UI state (for News tab only)
  bool _showSearchBar = false;
  late TextEditingController _searchController;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  // Persistent news stream
  late Stream<List<NewsArticle>> _newsStream;

  late PageController _pageController;
  int _totalPages = 1;
  int _currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _updateNewsStream();

    _searchController = TextEditingController();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
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
    final body = IndexedStack(
      index: _tabIndex,
      children: [
        _buildHomeFeed(),        // News
        const TeachersScreen(),  // has its own AppBar + search
        const CoursesScreen(),   // has its own AppBar + search
        const EbooksScreen(),    // has its own AppBar + search
      ],
    );

    return Scaffold(
      drawer: const SideDrawer(),
      appBar: AppBar(
        title: const Text('News Swipe'),
        centerTitle: true,
        // 👇 Only show this search icon on the News tab
        actions: _tabIndex == 0
            ? [
                IconButton(
                  icon: Icon(_showSearchBar ? Icons.close : Icons.search),
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

  Widget _buildHomeFeed() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 🔍 Animated Search Bar (News tab only, but stays in this widget)
        SizeTransition(
          sizeFactor: _expandAnim,
          axisAlignment: -1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_searchQuery != null && _searchQuery!.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchQuery = null;
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.35),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

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
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final all = snapshot.data ?? [];
              final q = (_searchQuery ?? '').toLowerCase();

              final filtered = q.isEmpty
                  ? all
                  : all.where((a) {
                      bool contains(String s) => s.toLowerCase().contains(q);
                      return contains(a.title) ||
                          contains(a.subtitle) ||
                          contains(a.description) ||
                          contains(a.category);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(q.isEmpty
                      ? 'No news found for this category.'
                      : 'No news matched your search.'),
                );
              }

              _totalPages = filtered.length + 1;
              final endIndex = _totalPages - 1;

              final progress = _totalPages <= 1
                  ? 0.0
                  : (_currentStoryIndex.clamp(0, endIndex) / endIndex);

              return Column(
                children: [
                  // 🔵 Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LinearProgressIndicator(
                      value: progress,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // The vertical PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      onPageChanged: (i) async {
                        setState(() {
                          _currentStoryIndex = i.clamp(0, endIndex);
                        });

                        // looping behavior
                        if (i == endIndex && _pageController.hasClients) {
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          if (!mounted) return;
                          await _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          );
                          if (mounted) {
                            setState(() => _currentStoryIndex = 0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Refreshed • Back to first story'),
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

  const _NewsPage({
    required this.article,
  });

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
    return Container(
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.surface.withOpacity(0.1), cs.surface],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 48),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'You’re all caught up',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
