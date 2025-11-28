import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../screens/teacher_details_screen.dart';

class TeacherCard extends StatelessWidget {
  final Teacher t;

  const TeacherCard({super.key, required this.t});

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherDetailsScreen(teacher: t),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categories = t.categories
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final primarySpec =
        t.specializations.isNotEmpty ? t.specializations.first : null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Single banner image only
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if ((t.imageUrl ?? '').trim().isNotEmpty)
                    Image.network(
                      t.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, size: 40),
                      ),
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.person, size: 40),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.60),
                        ],
                      ),
                    ),
                  ),

                  // Categories chips
                  if (categories.isNotEmpty)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 10,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                cat,
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  // Name at bottom
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            shadows: const [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                        if (primarySpec != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            primarySpec,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Content
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((t.intro ?? '').isNotEmpty)
                    Text(
                      t.intro!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color:
                            cs.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  if ((t.intro ?? '').isNotEmpty) const SizedBox(height: 8),

                  // One small row with “View profile”
                  Row(
                    children: [
                      Icon(Icons.school_outlined,
                          size: 16, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        t.qualifications.isNotEmpty ? t.qualifications.first : 'Expert instructor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          color:
                              cs.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View profile',
                        style: textTheme.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: cs.primary,
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
