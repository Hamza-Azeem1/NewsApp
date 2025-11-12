import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/teachers_repository.dart';
import '../widgets/teacher_card.dart';

class TeachersSearchDelegate extends SearchDelegate<String?> {
  final _repo = TeachersRepository();

  @override
  String? get searchFieldLabel => 'Search teachers…';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

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
  final TeachersRepository repo;
  const _ResultsList({required this.query, required this.repo});

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    return StreamBuilder<List<Teacher>>(
      stream: repo.watchAll(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        final filtered = q.isEmpty
            ? items.take(12).toList()
            : items.where((t) {
                bool inText(String? s) => (s ?? '').toLowerCase().contains(q);
                bool inList(List<String> arr) => arr.any((x) => x.toLowerCase().contains(q));
                bool inMap(Map<String, String> m) =>
                    m.entries.any((e) => e.key.toLowerCase().contains(q) || e.value.toLowerCase().contains(q));

                return inText(t.name) ||
                    inText(t.intro) ||
                    inList(t.specializations) ||
                    inList(t.qualifications) ||
                    inMap(t.socials);
              }).toList();

        if (filtered.isEmpty) return const Center(child: Text('No teachers matched your search.'));

        // Use your existing TeacherCard for consistent look
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => TeacherCard(t: filtered[i]),
        );
      },
    );
  }
}
