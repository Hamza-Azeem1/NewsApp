// lib/admin/screens/admin_ebooks_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../app/models/ebook.dart';
import '../../app/services/ebooks_repository.dart';
import '../widgets/ebook_form.dart';

class AdminEbooksScreen extends StatefulWidget {
  const AdminEbooksScreen({super.key});

  @override
  State<AdminEbooksScreen> createState() => _AdminEbooksScreenState();
}

class _AdminEbooksScreenState extends State<AdminEbooksScreen> {
  final _repo = EbooksRepository();

  List<String> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() => _loadingCategories = true);

    try {
      final snap =
          await FirebaseFirestore.instance.collection('ebooks').get();

      final setCats = <String>{};

      for (final doc in snap.docs) {
        final catString = (doc.data()['category'] ?? '').toString();

        for (final raw in catString.split(',')) {
          final c = raw.trim();
          if (c.isNotEmpty) setCats.add(c);
        }
      }

      if (!mounted) return;
      setState(() {
        _categories = setCats.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<void> _openForm({Ebook? initial}) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: EbookForm(
            initial: initial,
            categories: _categories,
          ),
        );
      },
    );

    if (!mounted) return;

    if (changed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initial == null
                ? "Ebook added successfully"
                : "Ebook updated successfully",
          ),
        ),
      );
      _loadCategories();
    }
  }

  Future<void> _delete(Ebook ebook) async {
    final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Ebook"),
            content: Text('Delete "${ebook.title}" permanently?'),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              FilledButton(
                child: const Text("Delete"),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ) ??
        false;

    if (!yes) return;

    try {
      await _repo.deleteEbook(ebook.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ebook deleted")),
      );

      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin – Ebooks'),
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
            icon: const Icon(Icons.add),
            tooltip: "Add Ebook",
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<Ebook>>(
        stream: _repo.streamEbooks(),
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

          if (ebooks.isEmpty) {
            return const Center(child: Text("No ebooks added yet."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ebooks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final e = ebooks[index];

              return ListTile(
                tileColor: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(
                  backgroundImage:
                      e.imageUrl.isNotEmpty ? NetworkImage(e.imageUrl) : null,
                  child: e.imageUrl.isEmpty
                      ? const Icon(Icons.book_outlined)
                      : null,
                ),
                title: Text(e.title),
                subtitle: Text(
                  '${e.author} • ${e.category} • ${e.isPaid ? "PKR ${e.pricePkr}" : "Free"}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openForm(initial: e),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(e),
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
