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
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Category chips bar: All, Free, Paid + dynamic categories from data
          StreamBuilder<List<Course>>(
            stream: _repo.watchAll(),
            builder: (context, snapshot) {
              final allCourses = snapshot.data ?? [];
              final dynamicCats = allCourses
                  .map((c) => c.category)
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              final categories = <String>[
                'All',
                'Free',
                'Paid',
                ...dynamicCats.where(
                  (c) => c != 'Free' && c != 'Paid',
                ),
              ];

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    for (final cat in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
