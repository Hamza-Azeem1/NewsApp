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

class _EbooksScreenState extends State<EbooksScreen>
    with SingleTickerProviderStateMixin {
  final _ebooksRepository = EbooksRepository();

  bool _showSearchBar = false;
  String? _selectedCategoryName;
  String _searchQuery = '';

  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;

      if (_showSearchBar) {
        _animCtrl.forward();
      } else {
        _searchQuery = '';
        _searchController.clear();
        _animCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Books'),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
          ),
        ],
      ),

      body: StreamBuilder<List<Ebook>>(
        stream: _ebooksRepository.streamEbooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ebooks = snapshot.data ?? [];

          // ---- Build category list ----
          final uniqueNames = ebooks
              .map((e) => e.category.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final categories = uniqueNames
              .map((name) => AppCategory(id: name, name: name))
              .toList();

          // ---- Filter by category ----
          List<Ebook> filtered = (_selectedCategoryName == null ||
                  _selectedCategoryName!.isEmpty)
              ? ebooks
              : ebooks.where((e) => e.category == _selectedCategoryName).toList();

          // ---- Filter by search ----
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
              // 🔍 Animated Search Bar
              SizeTransition(
                sizeFactor: _expandAnim,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search books...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// Category Bar
              CategoryBar(
                categories: categories,
                selected: _selectedCategoryName,
                onSelect: (name) {
                  setState(() => _selectedCategoryName = name);
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
