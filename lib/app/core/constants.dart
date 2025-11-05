import 'package:flutter/material.dart';

const categoriesCollection = 'categories'; // each doc: { name: string }
const newsCollection = 'news'; // fields: category, date, description, imageUrl, subtitle, title

const kHorizontalPadding = 16.0;

final chipStyle = OutlinedButton.styleFrom(
  side: const BorderSide(color: Colors.black12),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
);

const bottomItems = [
  _NavItem('Home', Icons.home_outlined),
  _NavItem('Teachers', Icons.people_outline),
  _NavItem('Courses', Icons.school_outlined),
  _NavItem('eBooks', Icons.menu_book_outlined),
];

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
