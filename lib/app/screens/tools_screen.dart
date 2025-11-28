import 'dart:async';
import 'package:flutter/material.dart';

import '../models/tool.dart';
import '../services/tools_repository.dart';
import '../widgets/tool_card.dart';
import 'tool_details_screen.dart';

// 🔌 Connectivity
import '../services/connectivity_service.dart';
import '../widgets/offline_banner.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ToolsRepository.instance;

  String _priceFilter = 'All'; // All | Free | Paid
  String _categoryFilter = 'All';
  bool _showSearchBar = false;

  late AnimationController _searchAnimCtrl;
  late Animation<double> _searchExpandAnim;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _searchQuery = '';

  // 🔌 Connectivity
  late StreamSubscription<AppConnectionStatus> _connSub;
  AppConnectionStatus _connStatus = AppConnectionStatus.online;

  @override
  void initState() {
    super.initState();

    _searchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _searchExpandAnim =
        CurvedAnimation(parent: _searchAnimCtrl, curve: Curves.easeInOut);

    // 🔌 Connectivity initialization
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
    // ✅ Capture context-dependent objects before any potential async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: cs.surfaceContainerHigh,
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
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _searchAnimCtrl.dispose();
    _connSub.cancel(); // 🔌 VERY IMPORTANT
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
    });

    if (_showSearchBar) {
      _searchAnimCtrl.forward();
      Future.microtask(() {
        _searchFocus.requestFocus();
      });
    } else {
      _searchAnimCtrl.reverse();
      _searchCtrl.clear();
      _searchQuery = '';
      _searchFocus.unfocus();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isOffline = _connStatus == AppConnectionStatus.offline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: StreamBuilder<List<Tool>>(
        stream: _repo.watchTools(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load tools'));
          }

          final allTools = snapshot.data ?? [];

          // Dynamic categories – split comma-separated tokens
          final dynamicCats = <String>{};
          for (final tool in allTools) {
            final catString = tool.category;
            for (final raw in catString.split(',')) {
              final cat = raw.trim();
              if (cat.isEmpty) continue;
              final lc = cat.toLowerCase();
              if (lc == 'all' || lc == 'free' || lc == 'paid') continue;
              dynamicCats.add(cat);
            }
          }
          final dynamicCatList = ['All', ...dynamicCats.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))];

          final filtered = _applyFilters(allTools);

          return Column(
            children: [
              if (isOffline) const OfflineBanner(),

              // 🔍 Expandable Search Bar
              SizeTransition(
                sizeFactor: _searchExpandAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    autofocus: false,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search tools...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: cs.outline.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // 🔹 Top row: Price filter chips (All | Free | Paid)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: ['All', 'Free', 'Paid'].map((cat) {
                    final selected = _priceFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: cat,
                        isSelected: selected,
                        onTap: () {
                          setState(() {
                            // ✅ Clicking All in upper row only resets price filter
                            _priceFilter = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 🔹 Bottom row: Category chips (All + dynamic categories)
              if (dynamicCatList.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Row(
                    children: dynamicCatList.map((cat) {
                      final isSelected = _categoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: cat,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (cat == 'All') {
                                // ✅ Clicking All in bottom row only resets category filter
                                _categoryFilter = 'All';
                              } else {
                                // tap same category again -> clear category filter
                                if (_categoryFilter == cat) {
                                  _categoryFilter = 'All';
                                } else {
                                  _categoryFilter = cat;
                                }
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 4),

              // List of tools
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No tools found for this filter.'
                              : 'No tools found for "$_searchQuery".',
                          style: t.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tool = filtered[index];
                          return ToolCard(
                            tool: tool,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ToolDetailsScreen(tool: tool),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _toolHasCategory(Tool t, String cat) {
    final want = cat.trim().toLowerCase();
    return t.category
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .any((c) => c == want);
  }

  // Apply filters
  List<Tool> _applyFilters(List<Tool> list) {
    Iterable<Tool> filtered = list;

    // Price filter
    switch (_priceFilter) {
      case 'Free':
        filtered = filtered.where((t) => t.isFree);
        break;
      case 'Paid':
        filtered = filtered.where((t) => !t.isFree);
        break;
      default:
        break;
    }

    // Category
    if (_categoryFilter != 'All') {
      filtered = filtered.where((t) => _toolHasCategory(t, _categoryFilter));
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final q = _searchQuery;
        return t.name.toLowerCase().contains(q) ||
            t.shortDesc.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q);
      });
    }

    return filtered.toList();
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.16)
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.9)
              : cs.outlineVariant.withValues(alpha: 0.35),
          width: 1.3,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}