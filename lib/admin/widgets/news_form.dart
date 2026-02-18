import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

enum ImageSourceKind { url, upload }

class NewsForm extends StatefulWidget {
  final void Function({
    required List<String> categories,
    required String title,
    required String subtitle,
    required String description,
    required Uint8List? imageBytes,
    required String? imageExt,
    required String? imageUrl,
    required String? newsUrl,
  }) onSubmit;

  final Map<String, dynamic>? initial;

  /// All available categories
  final List<String> allCategories;

  /// Categories pre-selected when editing
  final List<String> initialSelectedCategories;

  const NewsForm({
    super.key,
    required this.onSubmit,
    this.initial,
    required this.allCategories,
    required this.initialSelectedCategories,
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

  /// MULTIPLE SELECTED CATEGORIES
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();

    // Load initial categories
    _selectedCategories = List<String>.from(widget.initialSelectedCategories);

    final m = widget.initial;
    if (m != null) {
      _title.text = (m['title'] ?? '').toString();
      _subtitle.text = (m['subtitle'] ?? '').toString();
      _desc.text = (m['description'] ?? '').toString();
      _imageUrl.text = (m['imageUrl'] ?? '').toString();
      _newsUrl.text = (m['newsUrl'] ?? m['url'] ?? '').toString();
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

    final title = _title.text.trim();
    final subtitle = _subtitle.text.trim();
    final desc = _desc.text.trim();
    final imgUrl = _imageUrl.text.trim();
    final newsUrl = _newsUrl.text.trim();

    if (_selectedCategories.isEmpty || title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categories, title & description are required'),
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
      categories: _selectedCategories,
      title: title,
      subtitle: subtitle,
      description: desc,
      imageBytes: _source == ImageSourceKind.upload ? _imageBytes : null,
      imageExt: _source == ImageSourceKind.upload ? _imageExt : null,
      imageUrl: _source == ImageSourceKind.url ? imgUrl : null,
      newsUrl: newsUrl.isEmpty ? null : newsUrl,
    );

    setState(() => _saving = false);
  }

  /// NEW — Multi-select category dialog
  Future<void> _openCategoryDialog() async {
    List<String> options = {
      ...widget.allCategories,
      ..._selectedCategories
    }.toList();

    options.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final newCatController = TextEditingController();

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) {

        // TEMP list inside dialog
        List<String> tempSelected = [..._selectedCategories];

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: StatefulBuilder(
            builder: (ctx, setState2) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Select Categories",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),

                    const SizedBox(height: 12),

                    // Add new category textfield
                    TextField(
                      controller: newCatController,
                      decoration: InputDecoration(
                        hintText: "Add new category",
                        prefixIcon: const Icon(Icons.add),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isEmpty) return;
                        setState2(() {
                          tempSelected.add(v.trim());
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // List of existing categories
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (ctx, i) {
                          final cat = options[i];
                          final selected = tempSelected.contains(cat);

                          return CheckboxListTile(
                            value: selected,
                            title: Text(cat),
                            onChanged: (v) {
                              setState2(() {
                                if (v == true) {
                                  tempSelected.add(cat);
                                } else {
                                  tempSelected.remove(cat);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context, null),
                        ),
                        FilledButton(
                          child: const Text("Done"),
                          onPressed: () => Navigator.pop(context, tempSelected),
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedCategories = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('News Details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),

        /// CATEGORY MULTI SELECT SECTION
        const Text("Categories",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 6),

        InkWell(
          onTap: _openCategoryDialog,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: const Row(
              children: [
                Icon(Icons.category_outlined),
                SizedBox(width: 10),
                Text("Select Categories"),
                Spacer(),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Selected Category Chips
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _selectedCategories.map((cat) {
            return Chip(
              label: Text(cat),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() => _selectedCategories.remove(cat));
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // TITLE
        TextField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'Title',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 12),

        // SUBTITLE
        TextField(
          controller: _subtitle,
          decoration: const InputDecoration(
            labelText: 'Subtitle',
            prefixIcon: Icon(Icons.subtitles_outlined),
          ),
        ),
        const SizedBox(height: 12),

        // DESCRIPTION
        TextField(
          controller: _desc,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Short Description',
            prefixIcon: Icon(Icons.notes_outlined),
          ),
        ),
        const SizedBox(height: 16),

        // NEWS URL
        TextField(
          controller: _newsUrl,
          decoration: const InputDecoration(
            labelText: 'News URL',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 16),

        // IMAGE SOURCE TOGGLE
        SegmentedButton<ImageSourceKind>(
          segments: const [
            ButtonSegment(
              value: ImageSourceKind.url,
              label: Text("Image URL"),
              icon: Icon(Icons.link),
            ),
            ButtonSegment(
              value: ImageSourceKind.upload,
              label: Text("Upload Image"),
              icon: Icon(Icons.upload_file),
            ),
          ],
          selected: {_source},
          onSelectionChanged: (set) => setState(() => _source = set.first),
        ),
        const SizedBox(height: 16),

        _source == ImageSourceKind.url
            ? TextField(
                controller: _imageUrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(Icons.image),
                ),
              )
            : Column(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text("Choose Image"),
                    onPressed: _pickImage,
                  ),
                  if (_imageBytes != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  ]
                ],
              ),

        const SizedBox(height: 24),

        // SAVE BUTTON
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            onPressed: _saving ? null : _submit,
          ),
        ),
      ],
    );
  }
}
