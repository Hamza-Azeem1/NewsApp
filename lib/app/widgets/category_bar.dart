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
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selected == null || selected!.isEmpty;
            return ChoiceChip(
              label: const Text('All'),
              selected: isSelected,
              onSelected: (_) => onSelect(null),
            );
          }
          final item = categories[index - 1];
          final isSelected = selected == item.name;
          return ChoiceChip(
            label: Text(item.name),
            selected: isSelected,
            onSelected: (_) => onSelect(item.name),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length + 1,
      ),
    );
  }
}
