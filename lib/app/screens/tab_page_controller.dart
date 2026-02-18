import 'package:flutter/material.dart';

class TabPageControllerManager {
  final int initialIndex;
  late PageController pageController;

  TabPageControllerManager({this.initialIndex = 0}) {
    pageController = PageController(initialPage: initialIndex);
  }

  void dispose() {
    pageController.dispose();
  }

  void animateToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}
