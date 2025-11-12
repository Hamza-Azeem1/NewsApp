import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/courses_repository.dart';

class CoursesSearchDelegate extends SearchDelegate<String?> {
  final _repo = CoursesRepository();
  @override
  String? get searchFieldLabel => 'Search courses…';
  @override
  List<Widget>? buildActions(BuildContext context) =>
      [if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => _ResultsList(query: query, repo: _repo);
  @override
  Widget buildSuggestions(BuildContext context) => _ResultsList(query: query, repo: _repo);
}

class _ResultsList extends StatelessWidget {
  final String query;
  final CoursesRepository repo;
  const _ResultsList({required this.query, required this.repo});
  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    return StreamBuilder<List<Course>>(
      stream: repo.watchAll(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        final filtered = q.isEmpty
            ? items.take(20).toList()
            : items.where((c) {
                bool inText(String? s) => (s ?? '').toLowerCase().contains(q);
                bool inList(List<String> arr) => arr.any((x) => x.toLowerCase().contains(q));
                return inText(c.title) || inText(c.intro) || inList(c.tags);
              }).toList();

        if (filtered.isEmpty) return const Center(child: Text('No courses matched your search.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = filtered[i];
            return ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: c.intro == null ? null : Text(c.intro!, maxLines: 2, overflow: TextOverflow.ellipsis),
            );
          },
        );
      },
    );
  }
}
