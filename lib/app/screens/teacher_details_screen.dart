import 'package:flutter/material.dart';

import '../models/teacher.dart';
import 'in_app_browser.dart';

class TeacherDetailsScreen extends StatelessWidget {
  final Teacher teacher;

  const TeacherDetailsScreen({
    super.key,
    required this.teacher,
  });

  void _openLink(BuildContext context, String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppBrowser(url: trimmed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final tags = teacher.categories.isNotEmpty
        ? teacher.categories
        : teacher.specializations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage: (teacher.imageUrl ?? '').isNotEmpty
                      ? NetworkImage(teacher.imageUrl!)
                      : null,
                  child: (teacher.imageUrl ?? '').isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if ((teacher.intro ?? '').isNotEmpty)
                        Text(
                          teacher.intro!,
                          style: t.bodyMedium?.copyWith(
                            color:
                                cs.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final tag in tags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tag,
                                  style: t.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Specializations
            if (teacher.specializations.isNotEmpty) ...[
              Text(
                'Specializations',
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in teacher.specializations)
                    Chip(
                      label: Text(s),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Qualifications
            if (teacher.qualifications.isNotEmpty) ...[
              Text(
                'Qualifications',
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: teacher.qualifications.map((q) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: t.bodyMedium,
                        ),
                        Expanded(
                          child: Text(
                            q,
                            style: t.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Social links
            if (teacher.socials.isNotEmpty) ...[
              Text(
                'Connect',
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: teacher.socials.entries.map((entry) {
                  final label = entry.key;
                  final url = entry.value;
                  return OutlinedButton.icon(
                    onPressed: () => _openLink(context, url),
                    icon: Icon(_iconForLabel(label),
                        size: 18, color: cs.primary),
                    label: Text(label),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('linkedin')) return Icons.business_center_outlined;
    if (lower.contains('twitter') || lower.contains('x')) {
      return Icons.alternate_email;
    }
    if (lower.contains('facebook')) return Icons.facebook_outlined;
    if (lower.contains('instagram')) return Icons.camera_alt_outlined;
    if (lower.contains('youtube')) return Icons.ondemand_video_outlined;
    if (lower.contains('whatsapp')) return Icons.chat_bubble_outline;
    if (lower.contains('github')) return Icons.code;
    return Icons.link;
  }
}
