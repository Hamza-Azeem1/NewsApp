import 'package:flutter/material.dart';

class UserSubmissionScreen extends StatelessWidget {
  const UserSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Submission'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🖼️ Modern Icon Container
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 68,
                  color: cs.primary,
                ),
              ),

              const SizedBox(height: 32),

              // 📝 Heading
              Text(
                "Coming Soon",
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // 📄 Description
              Text(
                "A new, dedicated space where users will be able to submit "
                "their own content, resources, and suggestions.\n\n"
                "We're building something great — stay tuned!",
                style: t.bodyMedium?.copyWith(
                  height: 1.55,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // 🎨 Decorative subtle divider
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
