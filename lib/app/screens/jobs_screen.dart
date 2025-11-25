import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/jobs_repository.dart';
import '../widgets/job_card.dart';
import 'job_details_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = JobsRepository.instance;

  bool _showSearchBar = false;
  late AnimationController _searchAnimCtrl;
  late Animation<double> _searchExpandAnim;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode(); // 👈 NEW

  String _searchQuery = '';
  String _selectedCategory = 'All'; // category filter

  @override
  void initState() {
    super.initState();
    _searchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _searchExpandAnim =
        CurvedAnimation(parent: _searchAnimCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose(); // 👈 NEW
    _searchAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
    });

    if (_showSearchBar) {
      _searchAnimCtrl.forward();
      // 👇 Only now request focus so keyboard appears
      Future.microtask(() {
        _searchFocus.requestFocus();
      });
    } else {
      _searchAnimCtrl.reverse();
      _searchCtrl.clear();
      _searchQuery = '';
      // 👇 Remove focus so keyboard hides
      _searchFocus.unfocus();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline_rounded, size: 20),
            SizedBox(width: 8),
            Text('Jobs'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: StreamBuilder<List<Job>>(
        stream: _repo.watchJobs(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Failed to load jobs'));
          }

          final allJobs = snap.data ?? [];

          // Dynamic categories from jobs (no "all" etc.)
          final dynamicCats = allJobs
              .map((j) => j.category.trim())
              .where((c) {
                if (c.isEmpty) return false;
                final lc = c.toLowerCase();
                return lc != 'all';
              })
              .toSet()
              .toList()
            ..sort();

          // Apply filters & search
          final filtered = _applyFilters(allJobs);
          final t = Theme.of(context).textTheme;

          return Column(
            children: [
              // 🔍 Expandable Search Bar
              SizeTransition(
                sizeFactor: _searchExpandAnim,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus, // 👈 NEW
                    autofocus: false,        // 👈 IMPORTANT: was true before
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search jobs, companies, locations...',
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

              // 🏷️ Categories bar (All + dynamic categories)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // "All" chip
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
                    // Dynamic category chips
                    ...dynamicCats.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: cat,
                          isSelected: selected,
                          onTap: () {
                            setState(() {
                              // tap again to clear
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

              // Small header: count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    filtered.isEmpty
                        ? 'No jobs found'
                        : 'Jobs found: ${filtered.length}',
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
                              ? 'No jobs available for this filter.'
                              : 'No jobs match "$_searchQuery".',
                          style: t.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final job = filtered[index];
                          return JobCard(
                            job: job,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      JobDetailsScreen(job: job),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🧠 Filtering by category + search
  List<Job> _applyFilters(List<Job> list) {
    Iterable<Job> filtered = list;

    // Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where(
        (j) =>
            j.category.trim().toLowerCase() ==
            _selectedCategory.trim().toLowerCase(),
      );
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery;
      filtered = filtered.where((j) {
        bool contains(String s) => s.toLowerCase().contains(q);
        return contains(j.title) ||
            contains(j.companyName) ||
            contains(j.location) ||
            contains(j.shortDesc) ||
            contains(j.longDesc) ||
            contains(j.desc) ||
            contains(j.category);
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
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
