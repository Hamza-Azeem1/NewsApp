import 'package:flutter/material.dart';
import '../models/course.dart';
import 'in_app_browser.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  void _openCourseLink(BuildContext context) {
    final url = course.buyUrl.trim();
    if (url.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppBrowser(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // Split into separate category tags
    final categories = course.category
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final priceLabel = course.isPaid
        ? (course.pricePkr != null ? 'PKR ${course.pricePkr}' : 'Paid')
        : 'Free';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image with overlay + price
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (course.imageUrl.isNotEmpty)
                    Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.school, size: 48),
                      ),
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.school, size: 48),
                    ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),

                  // Title & price on image
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
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
                            color: course.isPaid
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

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories chips
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
                    const SizedBox(height: 12),
                  ],

                  // Free / premium label
                  Row(
                    children: [
                      Icon(
                        course.isPaid
                            ? Icons.workspace_premium_outlined
                            : Icons.check_circle_outline,
                        size: 18,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        course.isPaid ? 'Premium course' : 'Free course',
                        style: t.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Topics covered
                  if (course.topicsCovered.isNotEmpty) ...[
                    Text(
                      'What you’ll learn',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _topicsBlock(context, course.topicsCovered),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (course.description.isNotEmpty) ...[
                    Text(
                      'Course overview',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.description,
                      style: t.bodyMedium?.copyWith(
                        height: 1.5,
                        color: cs.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: course.buyUrl.trim().isEmpty
                          ? null
                          : () => _openCourseLink(context),
                      icon: Icon(
                        course.isPaid
                            ? Icons.shopping_cart_outlined
                            : Icons.play_circle_outline,
                      ),
                      label: Text(
                        course.isPaid ? 'Buy / Enroll now' : 'Start course',
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

  /// Turn topics string into bullet-style lines.
  /// - If the admin wrote comma-separated: "X, Y, Z"
  /// - Or multi-line text
  Widget _topicsBlock(BuildContext context, String raw) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    // Split by newlines first, then commas as backup
    final lines = raw
        .split(RegExp(r'[\n\r]'))
        .expand((line) => line.split(','))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return Text(
        raw,
        style: t.bodyMedium,
      );
    }

    return Column(
      children: [
        for (final item in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: t.bodyMedium?.copyWith(
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
