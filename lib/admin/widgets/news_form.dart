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
    required String? newsUrl, // 🔗 external link
  }) onSubmit;

  /// Firestore document map when editing to prefill fields.
  final Map<String, dynamic>? initial;

  /// All available categories (names) for dropdown
  /// (coming from existing `news` docs).
  final List<String> categories;

  const NewsForm({
    super.key,
    required this.onSubmit,
    this.initial,
    required this.categories,
  });

  @override
  State<NewsForm> createState() => _NewsFormState();
}

class _NewsFormState extends State<NewsForm> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _desc = TextEditingController();
  final _imageUrl = TextEditingController();
  final _newsUrl = TextEditingController();

  ImageSourceKind _source = ImageSourceKind.url;
  Uint8List? _imageBytes;
  String? _imageExt;

  bool _saving = false;

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      final existingCat = (m['category'] ?? '').toString();
      if (existingCat.isNotEmpty) {
        _selectedCategory = existingCat;
      }

      _title.text = (m['title'] ?? '').toString();
      _subtitle.text = (m['subtitle'] ?? '').toString();
      _desc.text = (m['description'] ?? '').toString();
      _imageUrl.text = (m['imageUrl'] ?? '').toString();
      _newsUrl.text = (m['newsUrl'] ?? m['url'] ?? '').toString();
    }

    // If nothing selected yet, fall back to first category.
    if (_selectedCategory == null && widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
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

    final cat = _selectedCategory?.trim() ?? '';
    final title = _title.text.trim();
    final subtitle = _subtitle.text.trim();
    final desc = _desc.text.trim();
    final imgUrl = _imageUrl.text.trim();
    final url = _newsUrl.text.trim();

    if (cat.isEmpty || title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category, title & description are required'),
        ),
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

  /// Centered, nicely styled dialog:
  /// - top: "Add new category" text field
  /// - list of existing categories as cards
  /// Tap one or submit text → dialog closes → category applied.
  Future<void> _openCategoryDialog() async {
    final options = <String>{
      ...widget.categories,
      if (_selectedCategory != null && _selectedCategory!.trim().isNotEmpty)
        _selectedCategory!,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final newCatController = TextEditingController();

    final selectedOrNew = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Dialog(
              backgroundColor: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---- Title ----
                    Text(
                      "Select Category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---- Add New Category ----
                    TextField(
                      controller: newCatController,
                      decoration: InputDecoration(
                        hintText: "Add new category",
                        prefixIcon: const Icon(Icons.add),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (v) {
                        final t = v.trim();
                        if (t.isEmpty) return;
                        Navigator.of(ctx).pop(t);
                      },
                    ),

                    const SizedBox(height: 10),
                    Divider(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                      height: 1,
                    ),
                    const SizedBox(height: 8),

                    // ---- Existing Categories ----
                    if (options.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "No existing categories.\nAdd your first one above.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (ctx, i) {
                            final cat = options[i];
                            final isSelected = _selectedCategory == cat;

                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.of(ctx).pop(cat),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? cs.primary.withValues(alpha: 0.12)
                                      : cs.surfaceContainerHighest.withValues(alpha: 0.28),
                                  border: Border.all(
                                    color: isSelected
                                        ? cs.primary
                                        : cs.outlineVariant.withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 8),

                    // ---- Close ----
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selectedOrNew != null && selectedOrNew.trim().isNotEmpty) {
      setState(() {
        _selectedCategory = selectedOrNew.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final catLabel = _selectedCategory == null || _selectedCategory!.isEmpty
        ? 'Tap the arrow to select or add category'
        : _selectedCategory!;

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

          /// 🔽 Category selector (dropdown-style + manual add)
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: const Icon(Icons.category_outlined),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: _openCategoryDialog,
              ),
            ),
            isEmpty: _selectedCategory == null || _selectedCategory!.isEmpty,
            child: GestureDetector(
              onTap: _openCategoryDialog,
              behavior: HitTestBehavior.opaque,
              child: Text(
                catLabel,
                style: (_selectedCategory == null ||
                        _selectedCategory!.isEmpty)
                    ? Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey)
                    : null,
              ),
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
                    label: Text(
                      _imageBytes == null
                          ? 'Pick image'
                          : 'Change image (${(_imageBytes!.length / 1024).toStringAsFixed(0)} KB)',
                    ),
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
