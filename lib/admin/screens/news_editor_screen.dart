import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/admin_news_repository.dart';
import '../services/storage_service.dart';
import '../widgets/news_form.dart';

class NewsEditorScreen extends StatefulWidget {
  final String? docId; // null => create
  final Map<String, dynamic>? initial; // when editing

  const NewsEditorScreen({super.key, this.docId, this.initial});

  @override
  State<NewsEditorScreen> createState() => _NewsEditorScreenState();
}

class _NewsEditorScreenState extends State<NewsEditorScreen> {
  final _repo = AdminNewsRepository();
  final _storage = StorageService();

  bool _busy = false;

  // 🔽 Category state
  List<String> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// 🔥 Load distinct category strings from the `news` collection.
  Future<void> _loadCategories() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('news').get();

      final names = snap.docs
          .map((d) => (d.data()['category'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final filtered = names
          .where((n) => n.toLowerCase() != 'all')
          .toList(); // avoid any "All" if present

      // Make sure existing category (when editing) is present even if
      // there are no other docs with that category.
      final initialCat = (widget.initial?['category'] ?? '').toString();
      if (initialCat.isNotEmpty && !filtered.contains(initialCat)) {
        filtered.insert(0, initialCat);
      }

      setState(() {
        _categories = filtered;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categories = [];
        _loadingCategories = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<void> _handleSubmit({
    required String category,
    required String title,
    required String subtitle,
    required String description,
    required Uint8List? imageBytes,
    required String? imageExt,
    required String? imageUrl, // from URL mode
    required String? newsUrl, // 🔗 external news link
  }) async {
    setState(() => _busy = true);
    try {
      // EDIT mode
      if (widget.docId != null) {
        final updates = <String, dynamic>{
          'category': category,
          'title': title,
          'subtitle': subtitle,
          'description': description,
          'newsUrl': newsUrl, // can be null/empty to clear
        };

        // If URL provided, prefer it
        if (imageUrl != null && imageUrl.isNotEmpty) {
          updates['imageUrl'] = imageUrl;
        }
        // Else if file selected and Storage is available
        else if (imageBytes != null && imageBytes.isNotEmpty) {
          try {
            final url = await _storage.uploadNewsImage(
              docId: widget.docId!,
              bytes: imageBytes,
              ext: (imageExt ?? 'jpg').toLowerCase(),
            );
            updates['imageUrl'] = url;
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image upload failed. You can paste an Image URL instead.\n$e',
                ),
              ),
            );
          }
        }

        await _repo.updateNews(widget.docId!, updates);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Updated')));
        Navigator.pop(context);
        return;
      }

      // CREATE mode
      final docId = await _repo.createNews(
        category: category,
        title: title,
        subtitle: subtitle,
        description: description,
        date: DateTime.now(),
        imageUrl: imageUrl ?? '', // use URL immediately if given
        newsUrl: newsUrl, // 🔗 pass through
      );

      if (imageUrl == null && imageBytes != null && imageBytes.isNotEmpty) {
        try {
          final url = await _storage.uploadNewsImage(
            docId: docId,
            bytes: imageBytes,
            ext: (imageExt ?? 'jpg').toLowerCase(),
          );
          await _repo.updateNews(docId, {'imageUrl': url});
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image upload failed. You can paste an Image URL instead.\n$e',
              ),
            ),
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Published')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.docId != null;

    Widget bodyChild;

    if (_busy) {
      bodyChild = const Center(child: CircularProgressIndicator());
    } else if (_loadingCategories) {
      bodyChild = const Center(child: CircularProgressIndicator());
    } else if (_categories.isEmpty) {
      bodyChild = const Center(
        child: Text(
          'No categories found.\nAdd at least one news document with a category first.',
          textAlign: TextAlign.center,
        ),
      );
    } else {
      bodyChild = SingleChildScrollView(
        child: NewsForm(
          onSubmit: _handleSubmit,
          initial: widget.initial,
          categories: _categories,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit News' : 'Create News')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: bodyChild,
      ),
    );
  }
}
