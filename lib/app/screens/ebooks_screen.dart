import 'dart:async';
import 'package:flutter/material.dart';

import '../services/ebooks_repository.dart';
import '../models/ebook.dart';
import '../widgets/ebook_card.dart';

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
    final cs = theme.colorScheme;
    final isOffline = _connStatus == AppConnectionStatus.offline;

    // Price filter labels
    const priceLabels = ['All', 'Free', 'Paid'];

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

          // ---- Dynamic category list (split multi-categories, ignore "free"/"paid") ----
          final dynamicCatSet = <String>{};
          for (final e in ebooks) {
            final raw = e.category;
            for (final part in raw.split(',')) {
              final name = part.trim();
              if (name.isEmpty) continue;

              final lower = name.toLowerCase();
              if (lower == 'free' || lower == 'paid') continue;

              dynamicCatSet.add(name);
            }
          }

          final categories = dynamicCatSet.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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

          // ---- Category filter (multi-category aware) ----
          if (_selectedCategoryName != null &&
              _selectedCategoryName!.isNotEmpty) {
            final selected = _selectedCategoryName!.trim().toLowerCase();
            filtered = filtered.where((e) {
              final tokens = e.category
                  .split(',')
                  .map((s) => s.trim().toLowerCase())
                  .where((s) => s.isNotEmpty);
              return tokens.contains(selected);
            }).toList();
          }

          // ---- Search filter ----
          final q = _searchQuery.trim().toLowerCase();
          if (q.isNotEmpty) {
            filtered = filtered.where((e) {
              final catText = e.category.toLowerCase();
              return e.title.toLowerCase().contains(q) ||
                  e.author.toLowerCase().contains(q) ||
                  catText.contains(q) ||
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

              // 🔹 PRICE BAR (All + Free + Paid) with styled chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: priceLabels.map((label) {
                    final selected = _priceFilter == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: label,
                        isSelected: selected,
                        onTap: () {
                          setState(() {
                            if (label == 'All') {
                              // ✅ Only reset price filter (upper row)
                              _priceFilter = 'All';
                            } else {
                              _priceFilter = label;
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 🔹 Dynamic categories row with its own "All"
              if (categories.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      // Bottom "All" for categories
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: 'All',
                          isSelected: _selectedCategoryName == null,
                          onTap: () {
                            setState(() {
                              // ✅ Only clear category filter (lower row)
                              _selectedCategoryName = null;
                            });
                          },
                        ),
                      ),
                      // Dynamic category chips
                      ...categories.map((cat) {
                        final selected = _selectedCategoryName == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: cat,
                            isSelected: selected,
                            onTap: () {
                              setState(() {
                                // Tap same category again → clear category filter
                                if (_selectedCategoryName == cat) {
                                  _selectedCategoryName = null;
                                } else {
                                  _selectedCategoryName = cat;
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // 🔹 E-BOOK LIST
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No ebooks found for this filter.'
                              : 'No ebooks match "$_searchQuery".',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      )
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.16)
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          width: 1.3,
          color: isSelected
              ? cs.primary.withValues(alpha: 0.9)
              : cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14.5,
              color: isSelected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
