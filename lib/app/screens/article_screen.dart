import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';

class ArticleScreen extends StatelessWidget {
  final NewsArticle article;
  const ArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('d MMMM yyyy • HH:mm').format(article.date);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black26),
                    loadingBuilder: (c, child, p) =>
                        p == null ? child : const Center(child: CircularProgressIndicator()),
                  ),
                  // vignette gradient for readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black26, Colors.black87],
                      ),
                    ),
                  ),
                  // category chip on top-right
                  Positioned(
                    right: 12,
                    top: MediaQuery.of(context).padding.top + 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        article.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 16, right: 72, bottom: 14),
              title: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // subtitle + date row
                  Text(
                    article.subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withOpacity(.82),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 24),
                  const SizedBox(height: 4),
                  // body
                  Text(
                    article.description,
                    style: const TextStyle(fontSize: 16, height: 1.6, letterSpacing: .1),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
