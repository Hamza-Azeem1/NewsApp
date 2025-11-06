import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/admin_news_repository.dart';
import '../services/storage_service.dart';
import '../widgets/news_form.dart';

class NewsEditorScreen extends StatefulWidget {
  final String? docId;                         // null => create
  final Map<String, dynamic>? initial;         // when editing

  const NewsEditorScreen({super.key, this.docId, this.initial});

  @override
  State<NewsEditorScreen> createState() => _NewsEditorScreenState();
}

class _NewsEditorScreenState extends State<NewsEditorScreen> {
  final _repo = AdminNewsRepository();
  final _storage = StorageService();
  bool _busy = false;

  Future<void> _handleSubmit({
    required String category,
    required String title,
    required String subtitle,
    required String description,
    required Uint8List? imageBytes,
    required String? imageExt,
    required String? imageUrl, // from URL mode
  }) async {
    setState(() => _busy = true);
    try {
      // EDIT mode
      if (widget.docId != null) {
        final updates = {
          'category': category,
          'title': title,
          'subtitle': subtitle,
          'description': description,
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
              SnackBar(content: Text('Image upload failed. You can paste an Image URL instead.\n$e')),
            );
          }
        }

        await _repo.updateNews(widget.docId!, updates);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated')));
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
            SnackBar(content: Text('Image upload failed. You can paste an Image URL instead.\n$e')),
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: NewsForm(
                  onSubmit: _handleSubmit,
                  // pass initial values to prefill form when editing
                  initial: widget.initial,
                ),
              ),
      ),
    );
  }
}
