import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/models/tool.dart';
import '../services/admin_tools_repository.dart';
import '../widgets/tool_form.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  final _repo = AdminToolsRepository();

  List<String> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Load distinct category tokens from `tools.category` (comma-separated)
  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() => _loadingCategories = true);

    try {
      final snap =
          await FirebaseFirestore.instance.collection('tools').get();

      final setCats = <String>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final catString = (data['category'] ?? '').toString();

        for (final raw in catString.split(',')) {
          final cat = raw.trim();
          if (cat.isEmpty) continue;
          setCats.add(cat);
        }
      }

      final list = setCats.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _categories = list;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      // ✅ Check mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tool categories: $e')),
        );
      }
    }
  }

  Future<void> _openForm({Tool? initial}) async {
    // ✅ Capture ScaffoldMessenger before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: ToolForm(
            initial: initial,
            categories: _categories,
          ),
        );
      },
    );

    if (!mounted) return;
    
    if (changed == true) {
      // ✅ Use captured ScaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            initial == null ? 'Tool added successfully' : 'Tool updated successfully',
          ),
        ),
      );
      _loadCategories();
    }
  }

  Future<void> _confirmDelete(Tool tool) async {
    // ✅ Capture context-dependent objects before async gap
    Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete tool'),
            content: Text('Are you sure you want to delete "${tool.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await _repo.deleteTool(tool.id);
      if (!mounted) return;
      
      // ✅ Use captured ScaffoldMessenger
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Tool deleted')),
      );
      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      
      // ✅ Use captured ScaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin – Tools'),
        actions: [
          if (_loadingCategories)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Add tool',
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<Tool>>(
        stream: _repo.watchTools(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Error loading tools'));
          }

          final tools = snap.data ?? [];
          if (tools.isEmpty) {
            return const Center(child: Text('No tools yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tool = tools[index];

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: cs.surfaceContainerHighest,
                title: Text(tool.name),
                subtitle: Text(
                  '${tool.category} • ${tool.shortDesc}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      tool.isFree
                          ? 'Free'
                          : (tool.price != null
                              ? 'PKR ${tool.price!.toStringAsFixed(0)}'
                              : 'Paid'),
                      style: t.labelMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openForm(initial: tool),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(tool),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}