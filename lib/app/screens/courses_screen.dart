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

  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Categories Area
          StreamBuilder<List<Course>>(
            stream: _repo.watchAll(),
            builder: (context, snapshot) {
              final allCourses = snapshot.data ?? [];

              // 1. Static categories row
              final staticCats = ['All', 'Free', 'Paid'];

              // 2. Dynamic categories (excluding static ones)
              final dynamicCats = allCourses
                  .map((c) => c.category.trim())
                  .where(
                    (c) =>
                        c.isNotEmpty &&
                        !staticCats.contains(c), // no All / Free / Paid
                  )
                  .toSet()
                  .toList()
                ..sort();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Line 1: Static Categories (All / Free / Paid) ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: staticCats.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _StyledChip(
                            label: cat,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // --- Line 2: Dynamic Categories (subjects) ---
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
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _StyledChip(
                              label: cat,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() => _selectedCategory = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            },
          ),

          const Divider(height: 1),

          // Course List
          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: _selectedCategory == 'All'
                  ? _repo.watchAll()
                  : _repo.watchByCategory(_selectedCategory),
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

                final courses = snapshot.data ?? [];
                if (courses.isEmpty) {
                  return const Center(
                    child: Text('No courses found for this filter.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return CourseCard(course: courses[index]);
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), // Bigger padding
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withOpacity(0.22)
            : cs.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(30), // Slightly bigger radius
        border: Border.all(
          width: 1.4, // Thicker border
          color: isSelected
              ? cs.primary.withOpacity(0.9)
              : cs.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.28),
                  blurRadius: 10,      // Stronger glow
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
              fontSize: 15.5, // Bigger font
              color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.85),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
