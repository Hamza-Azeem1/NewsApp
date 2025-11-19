import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../screens/article_screen.dart';
import '../services/news_engagement_service.dart';

class NewsCard extends StatefulWidget {
  final NewsArticle article;
  final int? index; // kept for compatibility, not shown

  const NewsCard({
    super.key,
    required this.article,
    this.index,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _liked = false;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
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

  void _openArticle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleScreen(article: widget.article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openArticle(context),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: widget.article.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const ColoredBox(color: Colors.black26),
              ),

              // Gradient at bottom for readability
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black54,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
              ),

              // Category chip (top-right)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.article.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              // Title + subtitle + actions (bottom)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.article.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Like + bookmark + tap to read
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleLike,
                          icon: Icon(
                            _liked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _liked
                                ? cs.error
                                : Colors.white.withOpacity(0.9),
                          ),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints.tightFor(width: 36),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _toggleBookmark,
                          icon: Icon(
                            _bookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: _bookmarked
                                ? cs.primary
                                : Colors.white.withOpacity(0.9),
                          ),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints.tightFor(width: 36),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tap to read',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: cs.primary,
                            ),
                          ],
                        ),
                      ],
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
}
