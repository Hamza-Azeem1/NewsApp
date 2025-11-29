import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/admin_news_repository.dart';

class VideoEditorScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initial;

  const VideoEditorScreen({
    super.key,
    this.docId,
    this.initial,
  });

  bool get isEditing => docId != null;

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _thumbCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  late final AdminVideosRepository _repo;

  /// All category options (from news + videos)
  List<String> _allCategories = [];

  /// Selected categories for this video
  final Set<String> _selectedCategories = {};

  bool _loadingCats = true;

  @override
  void initState() {
    super.initState();
    _repo = AdminVideosRepository();

    final initial = widget.initial;
    if (initial != null) {
      _titleCtrl.text = initial['title'] as String? ?? '';
      _descriptionCtrl.text = initial['description'] as String? ?? '';
      _thumbCtrl.text = initial['thumbnailUrl'] as String? ?? '';
      _videoUrlCtrl.text = initial['videoUrl'] as String? ?? '';

      final rawCats = initial['categories'];
      if (rawCats is Iterable) {
        _selectedCategories.addAll(
          rawCats.map((e) => e.toString()).where((e) => e.isNotEmpty),
        );
      } else if (initial['primaryCategory'] != null) {
        _selectedCategories.add(initial['primaryCategory'].toString());
      } else if (initial['category'] != null) {
        _selectedCategories.add(initial['category'].toString());
      }
    }

    _loadCategoriesFromNewsAndVideos();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _thumbCtrl.dispose();
    _videoUrlCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  /// 🔥 Load distinct categories from both `news` and `videos`
  Future<void> _loadCategoriesFromNewsAndVideos() async {
    try {
      final fs = FirebaseFirestore.instance;
      final newsSnap = await fs.collection('news').get();
      final videoSnap = await fs.collection('videos').get();

      final set = <String>{};

      // from news.category
      for (final d in newsSnap.docs) {
        final cat = (d.data()['category'] ?? '').toString().trim();
        if (cat.isNotEmpty && cat.toLowerCase() != 'all') set.add(cat);
      }

      // from videos.categories / category
      for (final d in videoSnap.docs) {
        final data = d.data();
        final cats = data['categories'];
        if (cats is Iterable) {
          for (final c in cats) {
            final s = c.toString().trim();
            if (s.isNotEmpty && s.toLowerCase() != 'all') set.add(s);
          }
        } else if (data['category'] != null) {
          final s = data['category'].toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'all') set.add(s);
        }
      }

      // make sure already-selected categories are present
      set.addAll(_selectedCategories);

      final names = set.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _allCategories = names;
        _loadingCats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allCategories = [];
        _loadingCats = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  /// Custom category is ONLY stored in this video.
  void _addCustomCategory() {
    final text = _customCategoryCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _selectedCategories.add(text);
      if (!_allCategories.contains(text)) {
        _allCategories.add(text);
        _allCategories
            .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }
      _customCategoryCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final thumbnailUrl = _thumbCtrl.text.trim();
    final videoUrl = _videoUrlCtrl.text.trim();

    final categories = _selectedCategories.isEmpty
        ? <String>['General']
        : _selectedCategories.toList();

    try {
      if (widget.isEditing) {
        await _repo.updateVideo(widget.docId!, {
          'title': title,
          'description': description,
          'categories': categories,
          'primaryCategory':
              categories.isNotEmpty ? categories.first : 'General',
          'thumbnailUrl': thumbnailUrl,
          'videoUrl': videoUrl,
        });
      } else {
        await _repo.createVideo(
          title: title,
          description: description,
          categories: categories,
          thumbnailUrl: thumbnailUrl,
          videoUrl: videoUrl,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Video updated' : 'Video created',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit video' : 'Add video'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Categories section
            Text(
              'Categories',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            if (_loadingCats)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else ...[
              if (_allCategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select category',
                    border: OutlineInputBorder(),
                  ),
                  items: _allCategories
                      .map(
                        (name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCategories.add(value));
                  },
                )
              else
                Text(
                  'No categories found yet. You can add your own below.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              const SizedBox(height: 8),

              // Selected categories as chips
              if (_selectedCategories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedCategories.map((name) {
                    return Chip(
                      label: Text(name),
                      onDeleted: () {
                        setState(() {
                          _selectedCategories.remove(name);
                        });
                      },
                    );
                  }).toList(),
                ),
            ],

            const SizedBox(height: 10),

            // Custom category
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCategoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add custom category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _addCustomCategory,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Add',
                ),
              ],
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _thumbCtrl,
              decoration: const InputDecoration(
                labelText: 'Thumbnail URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _videoUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Video URL (YouTube or .mp4)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: Text(widget.isEditing ? 'Save changes' : 'Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
