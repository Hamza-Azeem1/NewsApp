import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';
import '../services/news_engagement_service.dart';
import 'in_app_browser.dart';

class ArticleScreen extends StatefulWidget {
  final NewsArticle article;

  const ArticleScreen({super.key, required this.article});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final ScrollController _scrollController = ScrollController();

  double _scrollProgress = 0.0;
  bool _liked = false;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadEngagement();
  }

  Future<void> _loadEngagement() async {
    final id = widget.article.id;
    final liked = await NewsEngagementService.isLiked(id);
    final bookmarked = await NewsEngagementService.isBookmarked(id);
    if (!mounted) return;
    setState(() {
      _liked = liked;
      _bookmarked = bookmarked;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final value = max > 0 ? (offset / max).clamp(0.0, 1.0) : 0.0;
    setState(() => _scrollProgress = value);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final val = await NewsEngagementService.toggleLike(widget.article.id);
    if (!mounted) return;
    setState(() => _liked = val);
  }

  Future<void> _toggleBookmark() async {
    final val =
        await NewsEngagementService.toggleBookmark(widget.article.id);
    if (!mounted) return;
    setState(() => _bookmarked = val);
  }

  void _openFullNews() {
    final url = widget.article.newsUrl;
    if (url == null || url.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppBrowser(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasUrl =
        article.newsUrl != null && article.newsUrl!.trim().isNotEmpty;

    final dateStr =
        DateFormat('d MMM yyyy • HH:mm').format(article.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _scrollProgress,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header image
            if (article.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Colors.black26),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category,
                          style: textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    article.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  if (article.subtitle.isNotEmpty) ...[
                    Text(
                      article.subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Like + bookmark row
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _liked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _liked ? cs.error : cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _liked ? 'Liked' : 'Like',
                        style: textTheme.labelMedium,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: _toggleBookmark,
                        icon: Icon(
                          _bookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color:
                              _bookmarked ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _bookmarked ? 'Saved' : 'Bookmark',
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Body text
                  Text(
                    article.description,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Read full news button
                  if (hasUrl)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openFullNews,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Read full news'),
                      ),
                    )
                  else
                    Text(
                      'No external link available for this news.',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
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
