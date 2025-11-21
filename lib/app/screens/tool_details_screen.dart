import 'package:flutter/material.dart';
import '../models/tool.dart';
import 'in_app_browser.dart'; 

class ToolDetailsScreen extends StatelessWidget {
  final Tool tool;

  const ToolDetailsScreen({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final priceLabel = tool.isFree
        ? 'Free'
        : (tool.price != null
            ? 'PKR ${tool.price!.toStringAsFixed(0)}'
            : 'Paid');

    final buttonText = tool.isFree ? 'Open tool' : 'Buy tool';

    return Scaffold(
      appBar: AppBar(
        title: Text(tool.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                color: cs.onSurface.withOpacity(0.7),
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
                Chip(
                  label: const Text('Tool'),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (tool.toolLink.isEmpty) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InAppBrowser(
                        url: tool.toolLink, // 👈 only url parameter
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
