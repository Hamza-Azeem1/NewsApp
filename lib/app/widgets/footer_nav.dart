import 'package:flutter/material.dart';

class FooterNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FooterNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NavigationBar(
      height: 65,
      elevation: 3,
      backgroundColor: cs.surface,
      indicatorColor: cs.primary.withOpacity(0.16),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_rounded),
          label: 'Teachers',
        ),
        NavigationDestination(
          icon: Icon(Icons.cast_for_education_outlined),
          selectedIcon: Icon(Icons.cast_for_education_rounded),
          label: 'Courses',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'eBooks',
        ),
        NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps_rounded),
          label: 'Tools',
        ),
      ],
    );
  }
}
