import 'dart:async';
import 'package:flutter/material.dart';

import '../services/ebooks_repository.dart';
import '../models/ebook.dart';
import '../models/app_category.dart';
import '../widgets/ebook_card.dart';
import '../widgets/category_bar.dart';

// 🔌 Connectivity
import '../services/connectivity_service.dart';
import '../widgets/offline_banner.dart';

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

  /// 🔹 'All' | 'Free' | 'Paid'
  String _priceFilter = 'All';

  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;
  late TextEditingController _searchController;

  // 🔌 Connectivity
  late StreamSubscription<AppConnectionStatus> _connSub;
  AppConnectionStatus _connStatus = AppConnectionStatus.online;

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

    // 🔌 Subscribe to connectivity
    _connStatus = ConnectivityService.instance.currentStatus;
    _connSub =
        ConnectivityService.instance.statusStream.listen((status) {
      if (!mounted) return;

      final wasOffline =
          _connStatus == AppConnectionStatus.offline;

      setState(() => _connStatus = status);

      if (status == AppConnectionStatus.online && wasOffline) {
        _onCameOnline();
      }
    });
  }

  void _onCameOnline() {
    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.surfaceContainerHigh,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(Icons.wifi_rounded, color: cs.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Back online • Updating content'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchController.dispose();
    _connSub.cancel(); // 🔌 IMPORTANT
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
    final isOffline = _connStatus == AppConnectionStatus.offline;

    // First row: Free / Paid (CategoryBar auto-includes “All”)
    final priceCategories = <AppCategory>[
      AppCategory(id: 'Free', name: 'Free'),
      AppCategory(id: 'Paid', name: 'Paid'),
    ];

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
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final ebooks = snapshot.data ?? [];

          // ---- Dynamic category list ----
          final uniqueNames = ebooks
              .map((e) => e.category.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final categories = uniqueNames
              .map((name) => AppCategory(id: name, name: name))
              .toList();

          // Start with all
          List<Ebook> filtered = List.of(ebooks);

          // ---- Price filter ----
          switch (_priceFilter.toLowerCase()) {
            case 'free':
              filtered = filtered.where((e) => !e.isPaid).toList();
              break;
            case 'paid':
              filtered = filtered.where((e) => e.isPaid).toList();
              break;
            default:
              break;
          }

          // ---- Category filter ----
          if (_selectedCategoryName != null &&
              _selectedCategoryName!.isNotEmpty) {
            filtered = filtered
                .where((e) => e.category == _selectedCategoryName)
                .toList();
          }

          // ---- Search filter ----
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
              // 🔌 Offline
              if (isOffline) const OfflineBanner(),

              // 🔍 Search Bar
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
                      fillColor:
                          theme.colorScheme.surfaceContainerHighest,
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

              // 🔹 PRICE BAR (All + Free + Paid)
              CategoryBar(
                categories: priceCategories,
                selected:
                    _priceFilter == 'All' ? null : _priceFilter,
                onSelect: (name) {
                  setState(() {
                    _priceFilter = name ?? 'All';
                  });
                },
              ),

              const SizedBox(height: 4),

              // 🔹 Dynamic categories
              if (categories.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected =
                          _selectedCategoryName == cat.name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryName =
                                  isSelected ? null : cat.name;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 8),

              // 🔹 E-BOOK LIST
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
