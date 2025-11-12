import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../models/app_category.dart';
import '../services/news_repository.dart';
import '../widgets/news_card.dart';
import '../widgets/category_bar.dart';
import '../widgets/side_drawer.dart';
import '../widgets/footer_nav.dart';
import 'article_screen.dart';
import 'teachers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = NewsRepository();

  int _tabIndex = 0;
  String? _selectedCategory; // null => ALL
  String? _searchQuery;      // inline search for News tab
  late PageController _pageController;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // stable per category
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String? name) {
    setState(() {
      _selectedCategory = name; // null => ALL
      _pageController.dispose();
      _pageController = PageController(initialPage: 0, keepPage: true);
    });
  }

  int _currentPageSafe() {
    if (!_pageController.hasClients) return 0;
    final p = _pageController.page;
    return p == null ? _pageController.initialPage : p.round().clamp(0, (_totalPages - 1));
  }

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _tabIndex,
      children: [
        _buildHomeFeed(),          // News (with inline search bar)
        TeachersScreen(),          // Teachers screen (has its own layout)
        const _PlaceholderScreen(title: 'Courses'),
        const _PlaceholderScreen(title: 'eBooks'),
      ],
    );

    return Scaffold(
      drawer: const SideDrawer(),
      appBar: AppBar(
        title: const Text('News Swipe'),
        centerTitle: true,
      ),
      body: body,
      bottomNavigationBar: FooterNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
    );
  }

  Widget _buildHomeFeed() {
    return Column(
      children: [
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

        const SizedBox(height: 8),

        // 🔍 Inline search bar (centered, above the cards)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search news...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
        ),

        const SizedBox(height: 6),

        // News feed (vertical pager)
        Expanded(
          child: StreamBuilder<List<NewsArticle>>(
            stream: _repo.streamNews(category: _selectedCategory), // null => ALL
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // All items (optionally category-filtered by repo)
              final all = snapshot.data ?? [];

              // Inline search filter
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
                  child: Text(
                    q.isEmpty ? 'No news found for this category.' : 'No news matched your search.',
                  ),
                );
              }

              // Pager math uses the filtered list
              _totalPages = filtered.length + 1; // +1 end-of-feed
              final endIndex = _totalPages - 1;

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) async {
                  if (i == endIndex && _pageController.hasClients) {
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (!mounted) return;
                    await _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Refreshed • Back to first story')),
                      );
                    }
                  }
                },
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  if (index < filtered.length) {
                    final article = filtered[index];
                    return _NewsPage(
                      article: article,
                      pageLabel: '${_currentPageSafe() + 1}/$_totalPages',
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ArticleScreen(article: article)),
                      ),
                    );
                  }
                  return _EndOfFeed(
                    label: _selectedCategory == null
                        ? 'No more news'
                        : 'No more $_selectedCategory news',
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
  final String pageLabel;
  final VoidCallback onOpen;

  const _NewsPage({
    required this.article,
    required this.pageLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen, // tap anywhere opens the article
      child: Stack(
        children: [
          Positioned.fill(child: NewsCard(article: article)),

          // Page counter
          Positioned(
            top: 12,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  pageLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
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
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('You’re all caught up', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title tab', style: const TextStyle(fontSize: 18)));
  }
}
