import 'package:flutter/material.dart';
import '../../app/models/course.dart';
import '../services/admin_courses_repository.dart';

class CourseForm extends StatefulWidget {
  final Course? initial;

  /// All available categories for selection (e.g. Marketing, SEO, Tech)
  final List<String> categories;

  const CourseForm({
    super.key,
    this.initial,
    required this.categories,
  });

  @override
  State<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<CourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AdminCoursesRepository();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _topicsCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _buyUrlCtrl;
  late TextEditingController _imageUrlCtrl;

  bool _isPaid = false;
  bool _saving = false;

  /// Multiple selected categories
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    final c = widget.initial ?? Course.empty();

    _titleCtrl = TextEditingController(text: c.title);
    _descCtrl = TextEditingController(text: c.description);
    _topicsCtrl = TextEditingController(text: c.topicsCovered);
    _priceCtrl = TextEditingController(text: c.pricePkr?.toString() ?? '');
    _buyUrlCtrl = TextEditingController(text: c.buyUrl);
    _imageUrlCtrl = TextEditingController(text: c.imageUrl);
    _isPaid = c.isPaid;

    // Pre-select categories from stored comma-separated string,
    // ignoring any "Free"/"Paid" legacy values.
    final initialCat = c.category.trim();
    if (initialCat.isNotEmpty) {
      _selectedCategories = initialCat
          .split(',')
          .map((s) => s.trim())
          .where((s) {
            final lower = s.toLowerCase();
            return s.isNotEmpty && lower != 'free' && lower != 'paid';
          })
          .toSet();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _topicsCtrl.dispose();
    _priceCtrl.dispose();
    _buyUrlCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPaid && _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter price in PKR')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() => _saving = true);

    final base = widget.initial ?? Course.empty();
    final price = _isPaid ? int.tryParse(_priceCtrl.text.trim()) : null;

    // Store categories as comma-separated string (sorted)
    final sortedCats = _selectedCategories.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final joinedCategories = sortedCats.join(', ');

    final course = base.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      topicsCovered: _topicsCtrl.text.trim(),
      isPaid: _isPaid,
      pricePkr: price,
      category: joinedCategories,
      buyUrl: _buyUrlCtrl.text.trim(),
      imageUrl: _imageUrlCtrl.text.trim(),
    );

    try {
      await _repo.upsertCourse(course);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save course: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  /// Category picker – Option A:
  /// Tap category → dialog closes → category added
  Future<void> _openCategoryDialog() async {
    // Combine provided categories + already-used ones, filter out Free/Paid
    final options = <String>{
      ...widget.categories,
      ..._selectedCategories,
    }
        .where((c) {
          final t = c.trim();
          final lower = t.toLowerCase();
          return t.isNotEmpty && lower != 'free' && lower != 'paid';
        })
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final newCatController = TextEditingController();

    final selectedOrNew = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select category',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(null),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Add new category
                TextField(
                  controller: newCatController,
                  decoration: InputDecoration(
                    hintText: 'Add new category',
                    prefixIcon: const Icon(Icons.add),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (value) {
                    final text = value.trim();
                    if (text.isEmpty) return;
                    Navigator.of(ctx).pop(text);
                  },
                ),

                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: .3),
                ),
                const SizedBox(height: 8),

                if (options.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Text(
                      'No existing categories yet.\nAdd one using the field above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: .7),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (ctx2, index) {
                        final cat = options[index];

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.of(ctx).pop(cat),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: cs.surfaceContainerHighest.withValues(alpha: .25),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: .4),
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
              ],
            ),
          ),
        );
      },
    );

    if (selectedOrNew != null && selectedOrNew.trim().isNotEmpty) {
      setState(() {
        _selectedCategories.add(selectedOrNew.trim());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AbsorbPointer(
      absorbing: _saving,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 14,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEdit ? 'Edit Course' : 'Add Course',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Course name',
                          prefixIcon: Icon(Icons.school),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _topicsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Topics covered',
                          hintText: 'Comma-separated or multi-line list',
                          prefixIcon: Icon(Icons.list_alt),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Course description',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Paid course'),
                        value: _isPaid,
                        onChanged: (v) => setState(() => _isPaid = v),
                      ),
                      if (_isPaid) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Price (PKR)',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 12),

                      /// 🔥 New category styling (matches EbookForm)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Categories',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        isEmpty: _selectedCategories.isEmpty,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedCategories.isEmpty)
                              Text(
                                'Tap "Add Category" to select or create categories',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _selectedCategories.map((cat) {
                                  return InputChip(
                                    label: Text(cat),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedCategories.remove(cat);
                                      });
                                    },
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _openCategoryDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Category'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _buyUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Buy / Enroll URL',
                          prefixIcon: Icon(Icons.link),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Course image URL',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label:
                              Text(isEdit ? 'Save changes' : 'Create course'),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
