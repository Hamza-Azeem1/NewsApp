import 'package:flutter/material.dart';
import '../models/tool.dart';
import 'in_app_browser.dart';

class ToolDetailsScreen extends StatelessWidget {
  final Tool tool;

  const ToolDetailsScreen({super.key, required this.tool});

  void _openToolLink(BuildContext context) {
    final url = tool.toolLink.trim();
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

    final priceLabel = tool.isFree
        ? 'Free'
        : (tool.price != null
            ? '\$${tool.price!.toStringAsFixed(2)}'
            : 'Paid');

    final buttonText = tool.isFree ? 'Open tool' : 'Buy tool';
    final hasLink = tool.toolLink.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(tool.name),
      ),

      // 🔹 Sticky CTA button
      bottomNavigationBar: hasLink
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => _openToolLink(context),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: Text(buttonText),
                  ),
                ),
              ),
            )
          : null,

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, hasLink ? 80 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  tool.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.build_outlined, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tool.name,
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              tool.shortDesc,
              style: t.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(priceLabel),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                const Chip(
                  label: Text('Tool'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Details',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              tool.description,
              style: t.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
