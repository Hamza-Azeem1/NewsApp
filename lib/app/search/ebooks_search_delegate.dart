import 'package:flutter/material.dart';
import '../models/ebook.dart';
import '../services/ebooks_repository.dart';

class EbooksSearchDelegate extends SearchDelegate<String?> {
  final _repo = EbooksRepository();
  @override
  String? get searchFieldLabel => 'Search eBooks…';
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
  final EbooksRepository repo;
  const _ResultsList({required this.query, required this.repo});
  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    return StreamBuilder<List<Ebook>>(
      stream: repo.watchAll(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        final filtered = q.isEmpty
            ? items.take(20).toList()
            : items.where((e) {
                bool inText(String? s) => (s ?? '').toLowerCase().contains(q);
                bool inList(List<String> arr) => arr.any((x) => x.toLowerCase().contains(q));
                return inText(e.title) || inText(e.author) || inText(e.description) || inList(e.tags);
              }).toList();

        if (filtered.isEmpty) return const Center(child: Text('No eBooks matched your search.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final e = filtered[i];
            return ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [if (e.author != null) e.author!, if (e.description != null) e.description!].join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        );
      },
    );
  }
}
