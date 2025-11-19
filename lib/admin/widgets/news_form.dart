import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

enum ImageSourceKind { url, upload }

class NewsForm extends StatefulWidget {
  final void Function({
    required String category,
    required String title,
    required String subtitle,
    required String description,
    required Uint8List? imageBytes,
    required String? imageExt,
    required String? imageUrl,
    required String? newsUrl, // 🔗 NEW
  }) onSubmit;

  /// Pass a Firestore document map when editing to prefill fields.
  final Map<String, dynamic>? initial;

  const NewsForm({
    super.key,
    required this.onSubmit,
    this.initial,
  });

  @override
  State<NewsForm> createState() => _NewsFormState();
}

class _NewsFormState extends State<NewsForm> {
  final _category = TextEditingController();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _desc = TextEditingController();
  final _imageUrl = TextEditingController();
  final _newsUrl = TextEditingController();

  ImageSourceKind _source = ImageSourceKind.url;
  Uint8List? _imageBytes;
  String? _imageExt;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      _category.text = (m['category'] ?? '').toString();
      _title.text = (m['title'] ?? '').toString();
      _subtitle.text = (m['subtitle'] ?? '').toString();
      _desc.text = (m['description'] ?? '').toString();
      _imageUrl.text = (m['imageUrl'] ?? '').toString();
      _newsUrl.text = (m['newsUrl'] ?? m['url'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _category.dispose();
    _title.dispose();
    _subtitle.dispose();
    _desc.dispose();
    _imageUrl.dispose();
    _newsUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res != null && res.files.single.bytes != null) {
      setState(() {
        _imageBytes = res.files.single.bytes!;
        _imageExt = res.files.single.extension;
      });
    }
  }

  void _submit() {
    if (_saving) return;

    final cat = _category.text.trim();
    final title = _title.text.trim();
    final subtitle = _subtitle.text.trim();
    final desc = _desc.text.trim();
    final imgUrl = _imageUrl.text.trim();
    final url = _newsUrl.text.trim();

    if (cat.isEmpty || title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category, title & description are required')),
      );
      return;
    }

    if (_source == ImageSourceKind.url && imgUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an image URL')),
      );
      return;
    }

    if (_source == ImageSourceKind.upload && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image')),
      );
      return;
    }

    setState(() => _saving = true);

    widget.onSubmit(
      category: cat,
      title: title,
      subtitle: subtitle,
      description: desc,
      imageBytes: _source == ImageSourceKind.upload ? _imageBytes : null,
      imageExt: _source == ImageSourceKind.upload ? _imageExt : null,
      imageUrl: _source == ImageSourceKind.url ? imgUrl : null,
      newsUrl: url.isEmpty ? null : url,
    );

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'News details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitle,
            decoration: const InputDecoration(
              labelText: 'Subtitle',
              prefixIcon: Icon(Icons.subtitles_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Short description',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // 🔗 News URL
          TextField(
            controller: _newsUrl,
            decoration: const InputDecoration(
              labelText: 'News URL (opens in browser)',
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),

          // image source toggle
          SegmentedButton<ImageSourceKind>(
            segments: const [
              ButtonSegment(
                value: ImageSourceKind.url,
                label: Text('Image URL'),
                icon: Icon(Icons.link),
              ),
              ButtonSegment(
                value: ImageSourceKind.upload,
                label: Text('Upload image'),
                icon: Icon(Icons.upload_file),
              ),
            ],
            selected: {_source},
            onSelectionChanged: (set) {
              setState(() => _source = set.first);
            },
          ),
          const SizedBox(height: 12),

          if (_source == ImageSourceKind.url) ...[
            TextField(
              controller: _imageUrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.folder_open),
                    label: Text(_imageBytes == null
                        ? 'Pick image'
                        : 'Change image (${(_imageBytes!.length / 1024).toStringAsFixed(0)} KB)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
