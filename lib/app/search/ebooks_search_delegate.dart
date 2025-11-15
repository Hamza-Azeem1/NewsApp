import 'package:flutter/material.dart';
import '../../app/models/ebook.dart';
import '../services/ebooks_repository.dart';
import '../widgets/ebook_card.dart';

class EbooksSearchDelegate extends SearchDelegate<Ebook?> {
  final EbooksRepository _repository;

  EbooksSearchDelegate({EbooksRepository? repository})
      : _repository = repository ?? EbooksRepository();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Search ebooks by title, author, or category'),
      );
    }
    return _buildResultsList();
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Type something to search ebooks'),
      );
    }
    return _buildResultsList();
  }

  Widget _buildResultsList() {
    return FutureBuilder<List<Ebook>>(
      future: _repository.fetchOnce(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final all = snapshot.data ?? [];
        final q = query.toLowerCase();

        final results = all.where((ebook) {
          return ebook.title.toLowerCase().contains(q) ||
              ebook.author.toLowerCase().contains(q) ||
              ebook.category.toLowerCase().contains(q);
        }).toList();

        if (results.isEmpty) {
          return const Center(child: Text('No matching ebooks found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final ebook = results[index];
            return EbookCard(ebook: ebook);
          },
        );
      },
    );
  }
}
