import 'package:flutter/material.dart';

class FooterNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const FooterNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'Teachers'),
        NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Courses'),
        NavigationDestination(icon: Icon(Icons.menu_book_rounded), label: 'eBooks'),
      ],
    );
  }
}
