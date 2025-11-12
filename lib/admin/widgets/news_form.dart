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
  }) onSubmit;

  /// Pass a Firestore document map when editing to prefill fields.
  final Map<String, dynamic>? initial;

  const NewsForm({super.key, required this.onSubmit, this.initial});

  @override
  State<NewsForm> createState() => _NewsFormState();
}

class _NewsFormState extends State<NewsForm> {
  final _formKey = GlobalKey<FormState>();
  final _category = TextEditingController();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _desc = TextEditingController();
  final _imageUrl = TextEditingController();

  ImageSourceKind _source = ImageSourceKind.url;
  Uint8List? _imageBytes;
  String? _imageExt;

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
      if (_imageUrl.text.isNotEmpty) {
        _source = ImageSourceKind.url;
      }
    }
  }

  @override
  void dispose() {
    _category.dispose();
    _title.dispose();
    _subtitle.dispose();
    _desc.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res != null && res.files.isNotEmpty) {
      final f = res.files.first;
      setState(() {
        _imageBytes = f.bytes;
        _imageExt = (f.extension ?? 'jpg').toLowerCase();
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_source == ImageSourceKind.url && _imageUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste an Image URL or switch to Upload')),
      );
      return;
    }
    if (_source == ImageSourceKind.upload && (_imageBytes == null || _imageBytes!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image file')),
      );
      return;
    }

    widget.onSubmit(
      category: _category.text.trim(),
      title: _title.text.trim(),
      subtitle: _subtitle.text.trim(),
      description: _desc.text.trim(),
      imageBytes: _source == ImageSourceKind.upload ? _imageBytes : null,
      imageExt: _source == ImageSourceKind.upload ? _imageExt : null,
      imageUrl: _source == ImageSourceKind.url ? _imageUrl.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxW = 900.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(labelText: 'Category (e.g., Economy, History)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitle,
                decoration: const InputDecoration(labelText: 'Subtitle'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 8,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Image source selector
              Row(
                children: [
                  const Text('Image source:'),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('URL'),
                    selected: _source == ImageSourceKind.url,
                    onSelected: (_) => setState(() => _source = ImageSourceKind.url),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Upload file'),
                    selected: _source == ImageSourceKind.upload,
                    onSelected: (_) => setState(() => _source = ImageSourceKind.upload),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_source == ImageSourceKind.url)
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (e.g., https://images.unsplash.com/photo-...)',
                  ),
                  validator: (v) {
                    if (_source != ImageSourceKind.url) return null;
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final ok = v.startsWith('http://') || v.startsWith('https://');
                    return ok ? null : 'Must start with http(s)://';
                  },
                )
              else
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('Select Image'),
                    ),
                    const SizedBox(width: 12),
                    Text(_imageBytes == null ? 'No file selected' : 'Image selected',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),

              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
