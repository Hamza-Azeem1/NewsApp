import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/admin_courses_screen.dart';
import '../screens/news_list_screen.dart';
import '../screens/teachers_list_screen.dart';
import '../screens/admin_ebooks_screen.dart';
import '../screens/admin_tools_screen.dart';
import '../screens/admin_jobs_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  /// Whether the sidebar is expanded or collapsed
  bool _isExpanded = true;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const NewsListScreen(),
      const TeachersListScreen(),
      const AdminCoursesScreen(),
      const AdminEbooksScreen(),
      const AdminToolsScreen(),
      const AdminJobsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // ====== COLLAPSIBLE SIDEBAR ======
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _isExpanded ? 230 : 72,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.98),
              border: Border(
                right: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Column(
              children: [
                // --- Header with toggle icon ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() => _isExpanded = !_isExpanded);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isExpanded
                                ? Icons.menu_open_rounded
                                : Icons.menu_rounded,
                            size: 22,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ===== Navigation Buttons =====
                Expanded(
                  child: ListView(
                    children: [
                      _navItem(
                        icon: Icons.article_rounded,
                        selected: _index == 0,
                        label: 'News',
                        expanded: _isExpanded,
                        onTap: () => setState(() => _index = 0),
                      ),
                      _navItem(
                        icon: Icons.people_alt_rounded,
                        selected: _index == 1,
                        label: 'Teachers',
                        expanded: _isExpanded,
                        onTap: () => setState(() => _index = 1),
                      ),
                      _navItem(
                        icon: Icons.school_rounded,
                        selected: _index == 2,
                        label: 'Courses',
                        expanded: _isExpanded,
                        onTap: () => setState(() => _index = 2),
                      ),
                      _navItem(
                        icon: Icons.menu_book_rounded,
                        selected: _index == 3,
                        label: 'eBooks',
                        expanded: _isExpanded,
                        onTap: () => setState(() => _index = 3),
                      ),
                      _navItem(
                        icon: Icons.apps_rounded,
                        selected: _index == 4,
                        label: 'Tools',
                        expanded: _isExpanded,
                        onTap: () => setState(() => _index = 4),
                      ),
                      _navItem(
                        icon: Icons.work_rounded,
                        selected: _index == 5,
                        label: 'Jobs',
                        expanded: _isExpanded,
                        onTap: () => setState(() => _index = 5),
                      ),
                    ],
                  ),
                ),

                // Sign out button
                Padding(
  padding: const EdgeInsets.only(bottom: 20),
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => FirebaseAuth.instance.signOut(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment:
            _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Icon(
            Icons.logout_rounded,
            color: cs.error,
          ),

          // Show label ONLY when expanded
          if (_isExpanded) ...[
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                color: cs.error,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ),
  ),
),

              ],
            ),
          ),

          // Divider Line
          const VerticalDivider(width: 1),

          // ===== Main Content =====
          Expanded(
            child: _pages[_index],
          ),
        ],
      ),
    );
  }

  /// Reusable Navigation Item
  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? 16 : 0,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              selected ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            if (expanded) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
