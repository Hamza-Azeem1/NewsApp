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
            const SizedBox(height: 6),

            // Category + location
            Row(
              children: [
                if (job.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      job.category,
                      style: t.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (job.location.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        job.location,
                        style: t.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
}
