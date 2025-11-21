import 'package:flutter/material.dart';
import '../services/courses_repository.dart';
import '../models/course.dart';
import '../widgets/course_card.dart';
import '../search/courses_search_delegate.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _repo = CoursesRepository();

  /// Top row: price filter -> 'All' | 'Free' | 'Paid'
  String _priceFilter = 'All';

  /// Bottom row: dynamic category filter (subject) -> 'All' = no category filter
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CoursesSearchDelegate(repository: _repo),
              );
            },
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

          // Build dynamic categories from data (except All/Free/Paid)
          final dynamicCats = allCourses
              .map((c) => c.category.trim())
              .where((c) => c.isNotEmpty && !staticCats.contains(c))
              .toSet()
              .toList()
            ..sort();

          // Apply both filters to the full list
          final filteredCourses = _applyFilters(allCourses);

          return Column(
            children: [
              const SizedBox(height: 8),

              // 🔹 Top row: All / Free / Paid
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                            if (cat == 'All') {
                              // ✅ Reset everything when All is tapped
                              _priceFilter = 'All';
                              _categoryFilter = 'All';
                            } else {
                              _priceFilter = cat;
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 🔹 Bottom row: dynamic categories
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
                              // tap same category again -> clear category filter
                              if (_categoryFilter == cat) {
                                _categoryFilter = 'All';
                              } else {
                                _categoryFilter = cat;
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
                    ? const Center(
                        child: Text('No courses found for this filter.'),
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

  /// 🧠 Apply BOTH filters: price (top row) + category (bottom row)
  List<Course> _applyFilters(List<Course> list) {
    Iterable<Course> filtered = list;

    // 1) Price filter
    switch (_priceFilter) {
      case 'Free':
        filtered = filtered.where((c) => c.isPaid == true);
        break;
      case 'Paid':
        filtered = filtered.where((c) => c.isPaid == false);
        break;
      default:
        // 'All' -> no price filter
        break;
    }

    // 2) Category filter
    if (_categoryFilter != 'All') {
      filtered = filtered.where(
        (c) =>
            c.category.trim().toLowerCase() ==
            _categoryFilter.trim().toLowerCase(),
      );
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
            ? cs.primary.withOpacity(0.22)
            : cs.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          width: 1.4,
          color: isSelected
              ? cs.primary.withOpacity(0.9)
              : cs.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.28),
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
              color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.85),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
