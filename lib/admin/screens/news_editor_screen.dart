import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/admin_news_repository.dart';
import '../services/storage_service.dart';
import '../widgets/news_form.dart';

class NewsEditorScreen extends StatefulWidget {
  const NewsEditorScreen({super.key});

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
    required String? imageUrl, // <-- new
  }) async {
    setState(() => _busy = true);
    try {
      // 1) Create the doc without image first; we’ll patch image field next
      final docId = await _repo.createNews(
        category: category,
        title: title,
        subtitle: subtitle,
        description: description,
        date: DateTime.now(),
        imageUrl: imageUrl ?? '', // use URL immediately if provided
      );

      // 2) If user selected upload (bytes present), try uploading to Storage
      if (imageBytes != null && imageBytes.isNotEmpty) {
        try {
          final url = await _storage.uploadNewsImage(
            docId: docId,
            bytes: imageBytes,
            ext: (imageExt ?? 'jpg').toLowerCase(),
          );
          await _repo.updateNews(docId, {'imageUrl': url});
        } catch (e) {
          // If Storage is disabled or blocked, we still keep the doc and just show one clear error.
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed (using Storage). You can paste an Image URL instead.\n$e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create News')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: NewsForm(onSubmit: _handleSubmit),
              ),
      ),
    );
  }
}
