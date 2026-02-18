import 'package:flutter/material.dart';
import '../../app/screens/ebook_details_screen.dart';
import '../models/ebook.dart';

class EbookCard extends StatelessWidget {
  final Ebook ebook;

  const EbookCard({
    super.key,
    required this.ebook,
  });

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EbookDetailsScreen(ebook: ebook),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final priceLabel = ebook.isPaid
        ? (ebook.priceUsd != null
            ? '\$${ebook.priceUsd!.toStringAsFixed(2)}'
            : 'Paid')
        : 'Free';

    final categoryTags = ebook.category
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 BOOK IMAGE LEFT
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: Image.network(
                    ebook.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.book_outlined, size: 40),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 🔹 TEXT DETAILS RIGHT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      ebook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      'by ${ebook.author}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Short description preview
                    Text(
                      ebook.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: .8),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Categories
                    if (categoryTags.isNotEmpty)
                      SizedBox(
                        height: 24,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categoryTags.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final cat = categoryTags[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .55),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                cat,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Price row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ebook.isPaid
                                ? cs.errorContainer.withValues(alpha: .4)
                                : cs.primaryContainer.withValues(alpha: .5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            ebook.isPaid ? 'Paid' : 'Free',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ebook.isPaid ? cs.error : cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priceLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // View Details button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openDetails(context),
                        icon: Icon(
                          ebook.isPaid
                              ? Icons.info_outline
                              : Icons.menu_book_outlined,
                        ),
                        label: const Text('View Details'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
