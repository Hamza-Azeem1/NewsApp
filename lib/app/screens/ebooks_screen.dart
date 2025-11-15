import 'package:flutter/material.dart';
import '../services/ebooks_repository.dart';
import '../models/ebook.dart';
import '../models/app_category.dart';
import '../widgets/ebook_card.dart';
import '../widgets/category_bar.dart';

class EbooksScreen extends StatefulWidget {
  const EbooksScreen({super.key});

  @override
  State<EbooksScreen> createState() => _EbooksScreenState();
}

class _EbooksScreenState extends State<EbooksScreen> {
  final _ebooksRepository = EbooksRepository();

  /// null or empty = All
  String? _selectedCategoryName;

  /// text in the search bar
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Books'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Ebook>>(
        stream: _ebooksRepository.streamEbooks(), // get all ebooks
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ebooks = snapshot.data ?? [];

          // ---- Build unique category list from ebooks ----
          final uniqueNames = ebooks
              .map((e) => e.category.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final categories = uniqueNames
              .map(
                (name) => AppCategory(
                  id: name,
                  name: name,
                ),
              )
              .toList();

          // ---- Filter by category ----
          List<Ebook> filtered = (_selectedCategoryName == null ||
                  _selectedCategoryName!.isEmpty)
              ? ebooks
              : ebooks
                  .where((e) => e.category == _selectedCategoryName)
                  .toList();

          // ---- Filter by search text ----
          final q = _searchQuery.trim().toLowerCase();
          if (q.isNotEmpty) {
            filtered = filtered.where((e) {
              return e.title.toLowerCase().contains(q) ||
                  e.author.toLowerCase().contains(q) ||
                  e.category.toLowerCase().contains(q) ||
                  e.description.toLowerCase().contains(q);
            }).toList();
          }

          return Column(
            children: [
              const SizedBox(height: 8),

              // 🔍 SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search books...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// CATEGORY BAR
              CategoryBar(
                categories: categories,
                selected: _selectedCategoryName,
                onSelect: (name) {
                  setState(() {
                    _selectedCategoryName = name;
                  });
                },
              ),

              const SizedBox(height: 8),

              /// BOOK LIST
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No ebooks found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return EbookCard(ebook: filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
