import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../screens/article_screen.dart';
import '../services/news_engagement_service.dart';

class NewsCard extends StatefulWidget {
  final NewsArticle article;

  const NewsCard({
    super.key,
    required this.article,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _liked = false;
  bool _bookmarked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final id = widget.article.id;
    final liked = await NewsEngagementService.isLiked(id);
    final bookmarked = await NewsEngagementService.isBookmarked(id);
    final count = await NewsEngagementService.getLikeCount(id);

    if (!mounted) return;
    setState(() {
      _liked = liked;
      _bookmarked = bookmarked;
      _likeCount = count;
    });
  }

  Future<void> _toggleLike() async {
    final newCount =
        await NewsEngagementService.toggleLikeAndGetCount(widget.article.id);

    if (!mounted) return;
    setState(() {
      _liked = !_liked;
      _likeCount = newCount;
    });
  }

  Future<void> _toggleBookmark() async {
    final val =
        await NewsEngagementService.toggleBookmark(widget.article.id);
    if (!mounted) return;
    setState(() => _bookmarked = val);
  }

  void _openArticle() {
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
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openArticle,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // IMAGE
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: widget.article.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Colors.black26),
                ),
              ),

              // GRADIENT
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black45,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
              ),

              // CATEGORY TAG
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
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

              // TITLE, SUBTITLE, ACTIONS
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      widget.article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // SUBTITLE
                    Text(
                      widget.article.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ACTION BAR
                    Row(
                      children: [
                        // ❤️ LIKE + COUNT
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                _liked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _liked ? cs.error : Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_likeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),

                        // 🔖 BOOKMARK
                        GestureDetector(
                          onTap: _toggleBookmark,
                          child: Icon(
                            _bookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 22,
                            color:
                                _bookmarked ? cs.primary : Colors.white,
                          ),
                        ),

                        const Spacer(),

                        // TAP TO READ
                        Row(
                          children: [
                            Text(
                              "Read",
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 13, color: cs.primary),
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
