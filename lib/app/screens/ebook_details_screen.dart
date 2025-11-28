import 'package:flutter/material.dart';
import '../models/ebook.dart';
import 'in_app_browser.dart';

class EbookDetailsScreen extends StatelessWidget {
  final Ebook ebook;

  const EbookDetailsScreen({super.key, required this.ebook});

  void _openBuyLink(BuildContext context) {
    final url = ebook.buyUrl.trim();
    if (url.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppBrowser(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // Split multi-categories into separate chips
    final categories = ebook.category
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final priceLabel = ebook.isPaid
        ? (ebook.pricePkr != null ? 'PKR ${ebook.pricePkr}' : 'Paid')
        : 'Free';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ebook.imageUrl.isNotEmpty)
                    Image.network(
                      ebook.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.book_outlined, size: 48),
                      ),
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.book_outlined, size: 48),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            ebook.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              shadows: const [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ebook.isPaid
                                ? cs.primary.withValues(alpha: 0.95)
                                : cs.tertiary.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            priceLabel,
                            style: t.labelMedium?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  Text(
                    'by ${ebook.author}',
                    style: t.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Categories
                  if (categories.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: categories
                          .map(
                            (cat) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_offer_outlined,
                                    size: 14,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cat,
                                    style: t.labelSmall?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Free / premium label
                  Row(
                    children: [
                      Icon(
                        ebook.isPaid
                            ? Icons.workspace_premium_outlined
                            : Icons.check_circle_outline,
                        size: 18,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ebook.isPaid ? 'Paid ebook' : 'Free ebook',
                        style: t.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'About this book',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ebook.description,
                    style: t.bodyLarge?.copyWith(
                      height: 1.5,
                      color: cs.onSurface.withValues(alpha: 0.9),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: ebook.buyUrl.trim().isEmpty
                          ? null
                          : () => _openBuyLink(context),
                      icon: Icon(
                        ebook.isPaid
                            ? Icons.shopping_bag_outlined
                            : Icons.menu_book_outlined,
                      ),
                      label: Text(
                        ebook.isPaid ? 'Buy / Download' : 'Open / Read',
                      ),
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
