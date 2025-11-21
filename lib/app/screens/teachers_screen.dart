import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/teachers_repository.dart';
import '../widgets/teacher_card.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen>
    with SingleTickerProviderStateMixin {
  final repo = TeachersRepository();

  String _searchQuery = '';
  bool _showSearchBar = false;

  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;
  late TextEditingController _searchController;

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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchController.dispose();
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
          // 🔍 Animated search bar (appears when icon tapped)
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1.0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // List / Grid content
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
                          contains(e.key) ||
                          contains(e.value),
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

                    // Phones: list
                    if (isMobile) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            TeacherCard(t: list[i]),
                      );
                    }

                    // Tablet / Desktop: grid
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
