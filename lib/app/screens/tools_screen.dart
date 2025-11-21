import 'package:flutter/material.dart';
import '../models/tool.dart';
import '../services/tools_repository.dart';
import '../widgets/tool_card.dart';
import 'tool_details_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ToolsRepository.instance;

  String _priceFilter = 'All';    // All | Free | Paid (top row)
  String _categoryFilter = 'All'; // dynamic category (bottom row)
  bool _showSearchBar = false;

  late AnimationController _searchAnimCtrl;
  late Animation<double> _searchExpandAnim;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _searchExpandAnim =
        CurvedAnimation(parent: _searchAnimCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
    });

    if (_showSearchBar) {
      _searchAnimCtrl.forward();
    } else {
      _searchAnimCtrl.reverse();
      _searchCtrl.clear();
      setState(() => _searchQuery = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

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

          // Dynamic categories from tools (excluding any variation of All/Free/Paid)
          final dynamicCats = allTools
              .map((t) => t.category.trim())
              .where((c) {
                if (c.isEmpty) return false;
                final lc = c.toLowerCase();
                return lc != 'all' && lc != 'free' && lc != 'paid';
              })
              .toSet()
              .toList()
            ..sort();

          // Apply filters + search
          final filtered = _applyFilters(allTools);

          return Column(
            children: [
              // 🔍 Expandable Search Bar
              SizeTransition(
                sizeFactor: _searchExpandAnim,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
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
                          color:
                              cs.outline.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Top row: All / Free / Paid
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
                            if (cat == 'All') {
                              // ✅ Reset all filters when All is tapped
                              _priceFilter = 'All';
                              _categoryFilter = 'All';
                            } else {
                              _priceFilter = cat;
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Bottom row: dynamic categories
              if (dynamicCats.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Row(
                    children: dynamicCats.map((cat) {
                      final isSelected = _categoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: cat,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              // tap again to clear only category filter
                              if (_categoryFilter == cat) {
                                _categoryFilter = 'All';
                              } else {
                                _categoryFilter = cat;
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 4),

              // List
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

  // 🧠 Apply price + category + search
  List<Tool> _applyFilters(List<Tool> list) {
    Iterable<Tool> filtered = list;

    // 1) Price filter
    switch (_priceFilter) {
      case 'Free':
        filtered = filtered.where((t) => t.isFree);
        break;
      case 'Paid':
        filtered = filtered.where((t) => !t.isFree);
        break;
      default:
        break; // All -> no price filter
    }

    // 2) Category filter
    if (_categoryFilter != 'All') {
      filtered = filtered.where(
        (t) =>
            t.category.trim().toLowerCase() ==
            _categoryFilter.trim().toLowerCase(),
      );
    }

    // 3) Search text
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
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
