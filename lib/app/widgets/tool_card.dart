import 'package:flutter/material.dart';
import '../models/tool.dart';

class ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback? onTap;

  const ToolCard({
    super.key,
    required this.tool,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final priceLabel = tool.isFree
        ? 'Free'
        : (tool.price != null
            ? 'PKR ${tool.price!.toStringAsFixed(0)}'
            : 'Paid');

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 110,
              height: 110,
              child: Ink.image(
                image: NetworkImage(tool.imageUrl),
                fit: BoxFit.cover,
                child: Container(),
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.shortDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tool.isFree
                                ? cs.primaryContainer
                                : cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            priceLabel,
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: cs.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
