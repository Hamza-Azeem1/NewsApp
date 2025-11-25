import 'dart:async';
import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../services/teachers_repository.dart';

// 🔌 Connectivity
import '../services/connectivity_service.dart';
import '../widgets/offline_banner.dart';

import '../widgets/teacher_card.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen>
    with SingleTickerProviderStateMixin {
  final TeachersRepository repo = TeachersRepository();

  String _searchQuery = '';
  bool _showSearchBar = false;

  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;
  late TextEditingController _searchController;

  // 🔌 Connectivity fields
  late StreamSubscription<AppConnectionStatus> _connSub;
  AppConnectionStatus _connStatus = AppConnectionStatus.online;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );

    // 🔌 Start monitoring connectivity
    _connStatus = ConnectivityService.instance.currentStatus;
    _connSub =
        ConnectivityService.instance.statusStream.listen((status) {
      if (!mounted) return;

      final wasOffline =
          _connStatus == AppConnectionStatus.offline;

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
            const Expanded(child: Text('Back online • Updating content')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchController.dispose();
    _connSub.cancel(); // 🔌 IMPORTANT
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _animCtrl.forward();
      } else {
        _searchQuery = '';
        _searchController.clear();
        _animCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isOffline = _connStatus == AppConnectionStatus.offline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Teachers'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔌 Offline message
          if (isOffline) const OfflineBanner(),

          // 🔍 Animated search bar
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search teachers...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor:
                      cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(
                  () => _searchQuery = v.trim().toLowerCase(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 🔥 Teachers list / grid
          Expanded(
            child: StreamBuilder<List<Teacher>>(
              stream: repo.watchAll(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Error: ${snap.error}'),
                  );
                }

                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final all = snap.data!;
                final q = _searchQuery;

                bool contains(String s) =>
                    s.toLowerCase().contains(q);

                bool inList(List<String> l) =>
                    l.any((x) => contains(x));

                bool inMap(Map<String, String> m) =>
                    m.entries.any(
                  (e) =>
                      contains(e.key) || contains(e.value),
                );

                final list = q.isEmpty
                    ? all
                    : all.where((t) {
                        return contains(t.name) ||
                            contains(t.intro ?? '') ||
                            inList(t.specializations) ||
                            inList(t.qualifications) ||
                            inMap(t.socials);
                      }).toList();

                if (list.isEmpty) {
                  return const Center(
                    child: Text('No teachers matched your search.'),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final isMobile = w < 600;
                    final isDesktop = w >= 1100;

                    if (isMobile) {
                      // Phones → List view
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            TeacherCard(t: list[i]),
                      );
                    }

                    // Tablet / Desktop → Grid view
                    final crossAxisCount = isDesktop ? 3 : 2;
                    const tileHeight = 420.0;

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: tileHeight,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) =>
                          TeacherCard(t: list[i]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
