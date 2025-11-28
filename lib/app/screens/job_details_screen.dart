import 'package:flutter/material.dart';
import '../models/job.dart';
import 'in_app_browser.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  void _openApply(BuildContext context) {
    final url = job.applyLink.trim();
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

    // 🔹 Split comma-separated categories into a clean list
    final categories = job.category
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              job.title,
              style: t.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),

            // Company
            Text(
              job.companyName,
              style: t.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Categories + location as separate pills
            if (categories.isNotEmpty || job.location.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  // Category pills
                  ...categories.map(
                    (cat) => _pill(
                      context,
                      icon: Icons.work_outline_rounded,
                      label: cat,
                    ),
                  ),
                  // Location pill
                  if (job.location.isNotEmpty)
                    _pill(
                      context,
                      icon: Icons.place_outlined,
                      label: job.location,
                    ),
                ],
              ),

            const SizedBox(height: 16),

            if (job.desc.isNotEmpty) ...[
              Text(
                job.desc,
                style: t.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              job.longDesc,
              style: t.bodyLarge?.copyWith(height: 1.5),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openApply(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Apply now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable pill-style chip (same vibe as JobCard)
  Widget _pill(BuildContext context,
      {required IconData icon, required String label}) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
