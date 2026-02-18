// ignore_for_file: use_build_context_synchronously

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

  // MULTI CATEGORY
  List<String> _allCategories = [];
  List<String> _selectedCategories = [];

  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Load all category options + merge with categories from initial doc
  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('news').get();

      final setCats = <String>{};

      for (final doc in snap.docs) {
        final c = doc.data()['categories']; // new structure (list)
        final oldSingle = doc.data()['category']; // old structure (string)

        if (c is List) {
          for (final x in c) {
            if (x.toString().trim().isNotEmpty) {
              setCats.add(x.toString().trim());
            }
          }
        }

        if (oldSingle != null && oldSingle is String) {
          if (oldSingle.trim().isNotEmpty) setCats.add(oldSingle.trim());
        }
      }

      final list = setCats.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      // Pre-fill selected categories when editing
      if (widget.initial != null) {
        final initCats = widget.initial!['categories'];
        final oldSingle = widget.initial!['category'];

        if (initCats is List) {
          _selectedCategories = initCats.map((e) => e.toString()).toList();
        } else if (oldSingle is String && oldSingle.trim().isNotEmpty) {
          _selectedCategories = [oldSingle.trim()];
        }
      }

      setState(() {
        _allCategories = list;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  /// SUBMIT FORM
  Future<void> _handleSubmit({
    required List<String> categories,
    required String title,
    required String subtitle,
    required String description,
    required Uint8List? imageBytes,
    required String? imageExt,
    required String? imageUrl,
    required String? newsUrl,
  }) async {
    setState(() => _busy = true);

    try {
      // --- EDIT MODE ---
      if (widget.docId != null) {
        final updates = <String, dynamic>{
          'categories': categories,
          'title': title,
          'subtitle': subtitle,
          'description': description,
          'newsUrl': newsUrl,
        };

        if (imageUrl != null && imageUrl.isNotEmpty) {
          updates['imageUrl'] = imageUrl;
        } else if (imageBytes != null && imageBytes.isNotEmpty) {
          try {
            final url = await _storage.uploadNewsImage(
              docId: widget.docId!,
              bytes: imageBytes,
              ext: (imageExt ?? 'jpg').toLowerCase(),
            );
            updates['imageUrl'] = url;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: $e')),
            );
          }
        }

        await _repo.updateNews(widget.docId!, updates);

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Updated')));
          Navigator.pop(context);
        }

        return;
      }

      // --- CREATE MODE ---
      final docId = await _repo.createNews(
        categories: categories,
        title: title,
        subtitle: subtitle,
        description: description,
        date: DateTime.now(),
        imageUrl: imageUrl ?? '',
        newsUrl: newsUrl,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: $e')),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Published')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.docId != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit News' : 'Create News')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _busy || _loadingCategories
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: NewsForm(
                  onSubmit: _handleSubmit,
                  initial: widget.initial,
                  allCategories: _allCategories,
                  initialSelectedCategories: _selectedCategories,
                ),
              ),
      ),
    );
  }
}
