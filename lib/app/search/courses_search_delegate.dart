import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/courses_repository.dart';
import '../widgets/course_card.dart';

class CoursesSearchDelegate extends SearchDelegate<void> {
  final CoursesRepository repository;

  CoursesSearchDelegate({required this.repository});

  @override
  String? get searchFieldLabel => 'Search courses';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildBody();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    return StreamBuilder<List<Course>>(
      stream: repository.searchCourses(query),
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
          return const Center(child: Text('No courses found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return CourseCard(course: courses[index]);
          },
        );
      },
    );
  }
}
