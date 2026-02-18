import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';
import 'in_app_browser.dart';

class ArticleScreen extends StatefulWidget {
  final NewsArticle article;

  const ArticleScreen({super.key, required this.article});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final ScrollController _scroll = ScrollController();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final max = _scroll.position.maxScrollExtent;
      _progress = max == 0 ? 0 : (_scroll.offset / max).clamp(0, 1);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openFull() {
    final url = widget.article.newsUrl;
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InAppBrowser(url: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final dateStr = DateFormat('d MMM yyyy • HH:mm').format(a.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("News"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child:
              LinearProgressIndicator(value: _progress, backgroundColor: cs.surfaceContainerHighest),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            if (a.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(a.imageUrl, fit: BoxFit.cover),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CATEGORY CHIPS
                  Wrap(
                    spacing: 8,
                    children: a.categories.map((cat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: t.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // DATE
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: t.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // TITLE
                  Text(
                    a.title,
                    style:
                        t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 8),

                  if (a.subtitle.isNotEmpty)
                    Text(
                      a.subtitle,
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: .8),
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text(
                    a.description,
                    style: t.bodyLarge?.copyWith(height: 1.55),
                  ),

                  const SizedBox(height: 28),

                  if (a.newsUrl != null && a.newsUrl!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openFull,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("Read full article"),
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
