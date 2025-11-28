import 'dart:async';

import 'package:flutter/material.dart';
import '../services/courses_repository.dart';
import '../models/course.dart';
import '../widgets/course_card.dart';

// 🔌 Connectivity
import '../services/connectivity_service.dart';
import '../widgets/offline_banner.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  final _repo = CoursesRepository();

  /// Top row: price filter -> 'All' | 'Free' | 'Paid'
  String _priceFilter = 'All';

  /// Bottom row: dynamic category filter (subject) -> 'All' = no category filter
  String _categoryFilter = 'All';

  // 🔍 Search
  bool _showSearchBar = false;
  late AnimationController _searchAnimCtrl;
  late Animation<double> _searchExpandAnim;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  // 🔌 Connectivity
  late StreamSubscription<AppConnectionStatus> _connSub;
  AppConnectionStatus _connStatus = AppConnectionStatus.online;

  @override
  void initState() {
    super.initState();

    // Search animation
    _searchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _searchExpandAnim =
        CurvedAnimation(parent: _searchAnimCtrl, curve: Curves.easeInOut);

    // Connectivity
    _connStatus = ConnectivityService.instance.currentStatus;
    _connSub = ConnectivityService.instance.statusStream.listen((status) {
      if (!mounted) return;

      final wasOffline = _connStatus == AppConnectionStatus.offline;

      setState(() => _connStatus = status);

      if (status == AppConnectionStatus.online && wasOffline) {
        _onCameOnline();
      }
    });
  }

  void _onCameOnline() {
    // ✅ Capture context-dependent objects before any potential async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: cs.surfaceContainerHigh,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(Icons.wifi_rounded, color: cs.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Back online • Updating content'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connSub.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _searchAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
    });

    if (_showSearchBar) {
      _searchAnimCtrl.forward();
      Future.microtask(() {
        _searchFocus.requestFocus();
      });
    } else {
      _searchAnimCtrl.reverse();
      _searchCtrl.clear();
      _searchQuery = '';
      _searchFocus.unfocus();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isOffline = _connStatus == AppConnectionStatus.offline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: StreamBuilder<List<Course>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final allCourses = snapshot.data ?? [];

          // Static categories for top row
          final staticCats = ['All', 'Free', 'Paid'];

          // 🔹 Build dynamic categories from data
          //    - each course can have "Marketing, SEO"
          //    - we split by comma and add them individually
          //    - ignore FREE / PAID here
          final dynamicCatSet = <String>{};
          for (final c in allCourses) {
            final catString = c.category;
            for (final raw in catString.split(',')) {
              final cat = raw.trim();
              if (cat.isEmpty) continue;

              final lower = cat.toLowerCase();
              if (lower == 'free' || lower == 'paid') continue;

              dynamicCatSet.add(cat);
            }
          }

          final dynamicCats = ['All', ...dynamicCatSet.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))];

          // Apply filters + search
          final filteredCourses = _applyFilters(allCourses);

          return Column(
            children: [
              // 🔌 Offline banner
              if (isOffline) const OfflineBanner(),

              // 🔍 Expandable Search Bar
              SizeTransition(
                sizeFactor: _searchExpandAnim,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    autofocus: false,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search courses, topics, categories...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      filled: true,
                      fillColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: cs.outline.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 🔹 Top row: All / Free / Paid
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: staticCats.map((cat) {
                    final isSelected = _priceFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _StyledChip(
                        label: cat,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            // ✅ Clicking All in upper row only resets price filter
                            _priceFilter = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 🔹 Bottom row: All + dynamic categories
              if (dynamicCats.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 4,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: dynamicCats.map((cat) {
                      final isSelected = _categoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _StyledChip(
                          label: cat,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (cat == 'All') {
                                // ✅ Clicking All in bottom row only resets category filter
                                _categoryFilter = 'All';
                              } else {
                                // tap same category again -> clear category filter
                                if (_categoryFilter == cat) {
                                  _categoryFilter = 'All';
                                } else {
                                  _categoryFilter = cat;
                                }
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const Divider(height: 1),

              // 🔹 Courses list
              Expanded(
                child: filteredCourses.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No courses found for this filter.'
                              : 'No courses match "$_searchQuery".',
                          style: t.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        itemCount: filteredCourses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return CourseCard(course: filteredCourses[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🧠 Apply price + category + search
  List<Course> _applyFilters(List<Course> list) {
    Iterable<Course> filtered = list;

    // 1) Price filter
    switch (_priceFilter) {
      case 'Free':
        filtered = filtered.where((c) => c.isPaid == false).toList();
        break;

      case 'Paid':
        filtered = filtered.where((c) => c.isPaid == true).toList();
        break;

      default:
        break; // 'All'
    }

    // 2) Category filter
    if (_categoryFilter != 'All') {
      final selected = _categoryFilter.trim().toLowerCase();
      filtered = filtered.where((c) {
        final tokens = c.category
            .split(',')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty);
        return tokens.contains(selected);
      }).toList();
    }

    // 3) Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery;
      filtered = filtered.where((c) {
        bool contains(String? s) =>
            (s ?? '').toLowerCase().contains(q);

        final catText = c.category.toLowerCase();

        return contains(c.title) ||
            contains(c.description) ||
            contains(c.topicsCovered) ||
            catText.contains(q);
      }).toList();
    }

    return filtered.toList();
  }
}

///
/// 🔥 Reusable styled chip (same look as your CategoryBar)
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.22)
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          width: 1.4,
          color: isSelected
              ? cs.primary.withValues(alpha: 0.9)
              : cs.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15.5,
              color: isSelected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.85),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}