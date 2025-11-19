import 'package:flutter/material.dart';
import '../models/course.dart';
import '../screens/in_app_browser.dart'; 

class CourseCard extends StatelessWidget {
  final Course course;

  const CourseCard({super.key, required this.course});

  void _openCourse(BuildContext context) {
    if (course.buyUrl.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppBrowser(url: course.buyUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCourse(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image header ---
            SizedBox(
              height: 150,
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
                        child: const Icon(Icons.school, size: 40),
                      ),
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.school, size: 40),
                    ),

                  // Gradient overlay for readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),

                  // Category + price chips
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            course.category,
                            style: textTheme.labelMedium?.copyWith(
                              color: cs.onSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: cs.secondary.withOpacity(0.9),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            course.isPaid
                                ? 'PKR ${course.pricePkr ?? '-'}'
                                : 'Free',
                            style: textTheme.labelMedium?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor:
                              course.isPaid ? cs.primary : cs.tertiary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Content area ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Topics covered (short)
                  if (course.topicsCovered.isNotEmpty) ...[
                    Text(
                      course.topicsCovered,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Short description
                  if (course.description.isNotEmpty) ...[
                    Text(
                      course.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // --- Bottom row: info + button ---
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course.isPaid ? 'Premium course' : 'Free course',
                        style: textTheme.labelMedium?.copyWith(
                          color: cs.primary,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed:
                            course.buyUrl.isEmpty ? null : () => _openCourse(context),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: const Text('Buy now'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          textStyle: textTheme.labelLarge,
                        ),
                      ),
                    ],
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
