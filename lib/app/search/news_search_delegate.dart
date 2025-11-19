import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../services/news_repository.dart';
import '../screens/article_screen.dart';

class NewsSearchDelegate extends SearchDelegate<String?> {
  final _repo = NewsRepository();

  @override
  String? get searchFieldLabel => 'Search news…';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _ResultsList(query: query, repo: _repo);

  @override
  Widget buildSuggestions(BuildContext context) => _ResultsList(query: query, repo: _repo);
}

class _ResultsList extends StatelessWidget {
  final String query;
  final NewsRepository repo;
  const _ResultsList({required this.query, required this.repo});

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    return StreamBuilder<List<NewsArticle>>(
      stream: repo.streamNews(), // your existing stream
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        // Data -> newest first
        final all = [...snap.data!]
          ..sort((a, b) => b.date.compareTo(a.date));

        // Filter: title, subtitle, description, category
        bool matches(NewsArticle a) {
          if (q.isEmpty) return true;
          bool inText(String s) => s.toLowerCase().contains(q);
          return inText(a.title) ||
              inText(a.subtitle) ||
              inText(a.description) ||
              inText(a.category);
        }

        final items = all.where(matches).toList();
        if (items.isEmpty) {
          return const Center(child: Text('No news matched your search.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final a = items[i];
            return _NewsTile(article: a);
          },
        );
      },
    );
  }
}

class _NewsTile extends StatelessWidget {
  final NewsArticle article;
  const _NewsTile({required this.article});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hasImage = article.imageUrl.trim().isNotEmpty;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArticleScreen(article: article)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 96,
                  height: 76,
                  child: hasImage
                      ? Image.network(
                          article.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackThumb(cs),
                        )
                      : _fallbackThumb(cs),
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),

                    // Subtitle / Description
                    if (article.subtitle.trim().isNotEmpty ||
                        article.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.subtitle.trim().isNotEmpty
                            ? article.subtitle
                            : article.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Meta (category • date)
                    _MetaLine(
                      category: article.category,
                      date: article.date,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackThumb(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.article_outlined, size: 28),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String category;
  final DateTime date;
  const _MetaLine({required this.category, required this.date});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (category.trim().isNotEmpty) parts.add(category.trim());

    // simple date (e.g., 2025-11-12) – switch to intl if you want localized
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    parts.add(dateStr);

    return Text(
      parts.join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
