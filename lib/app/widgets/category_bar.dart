import 'package:flutter/material.dart';
import '../models/app_category.dart';

class CategoryBar extends StatelessWidget {
  final List<AppCategory> categories;
  final String? selected;
  final void Function(String? name) onSelect;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // === ALL CHIP ===
            final isSelected = selected == null || selected!.isEmpty;
            return _StyledChip(
              label: "All",
              isSelected: isSelected,
              onTap: () => onSelect(null),
            );
          }

          // === CATEGORY CHIPS ===
          final item = categories[index - 1];
          final isSelected = selected == item.name;

          return _StyledChip(
            label: item.name,
            isSelected: isSelected,
            onTap: () => onSelect(item.name),
          );
        },
      ),
    );
  }
}

///
/// 🔥 Custom reusable chip with smooth animations & polished UI
///
class _StyledChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyledChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withOpacity(0.18)
            : cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSelected
              ? cs.primary.withOpacity(0.8)
              : cs.outlineVariant.withOpacity(0.3),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
