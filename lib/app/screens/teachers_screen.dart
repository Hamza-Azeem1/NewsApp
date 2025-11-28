import 'dart:async';

import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../services/teachers_repository.dart';
import '../widgets/teacher_card.dart';

// 🔌 Connectivity
import '../services/connectivity_service.dart';
import '../widgets/offline_banner.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen>
    with SingleTickerProviderStateMixin {
  final _repo = TeachersRepository.instance;

  bool _showSearchBar = false;
  late AnimationController _searchAnimCtrl;
  late Animation<double> _searchExpandAnim;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  // 🔌 Connectivity
  late StreamSubscription<AppConnectionStatus> _connSub;
  AppConnectionStatus _connStatus = AppConnectionStatus.online;

  @override
  void initState() {
    super.initState();

    _searchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _searchExpandAnim =
        CurvedAnimation(parent: _searchAnimCtrl, curve: Curves.easeInOut);

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
    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
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
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _searchAnimCtrl.dispose();
    _connSub.cancel();
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
        centerTitle: false, // This is the key change
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 8),
            Text('Teachers'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: StreamBuilder<List<Teacher>>(
        stream: _repo.watchAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Failed to load teachers: ${snap.error}'));
          }

          final allTeachers = snap.data ?? [];

          // Dynamic categories from teacher.categories (List<String>)
          final dynamicCats = allTeachers
              .expand((t) => t.categories)
              .map((c) => c.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          // Apply category + search filters
          final filtered = _applyFilters(allTeachers);

          return Column(
            children: [
              if (isOffline) const OfflineBanner(),

              // 🔍 Expandable search bar
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
                      hintText: 'Search teachers, specializations...',
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

              const SizedBox(height: 4),

              // 🔹 Category chips bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: 'All',
                        isSelected: _selectedCategory == 'All',
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'All';
                          });
                        },
                      ),
                    ),
                    ...dynamicCats.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: cat,
                          isSelected: selected,
                          onTap: () {
                            setState(() {
                              if (_selectedCategory == cat) {
                                _selectedCategory = 'All';
                              } else {
                                _selectedCategory = cat;
                              }
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Small header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    filtered.isEmpty
                        ? 'No teachers found'
                        : 'Teachers found: ${filtered.length}',
                    style: t.labelMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No teachers available for this filter.'
                              : 'No teachers match "$_searchQuery".',
                          style: t.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final teacher = filtered[index];
                          return TeacherCard(t: teacher);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Teacher> _applyFilters(List<Teacher> list) {
    Iterable<Teacher> filtered = list;

    // Category filter
    if (_selectedCategory != 'All') {
      final selected = _selectedCategory.trim().toLowerCase();
      filtered = filtered.where((t) {
        return t.categories
            .map((c) => c.trim().toLowerCase())
            .contains(selected);
      });
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery;
      filtered = filtered.where((t) {
        bool inText(String? s) => (s ?? '').toLowerCase().contains(q);
        bool inList(List<String> arr) =>
            arr.any((x) => x.toLowerCase().contains(q));
        bool inMap(Map<String, String> m) => m.entries.any(
              (e) =>
                  e.key.toLowerCase().contains(q) ||
                  e.value.toLowerCase().contains(q),
            );

        return inText(t.name) ||
            inText(t.intro) ||
            inList(t.categories) ||
            inList(t.specializations) ||
            inList(t.qualifications) ||
            inMap(t.socials);
      });
    }

    return filtered.toList();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.16)
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          width: 1.3,
          color: isSelected
              ? cs.primary.withValues(alpha: 0.9)
              : cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14.5,
              color: isSelected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
