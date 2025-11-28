import 'package:flutter/material.dart';
import '../../app/models/ebook.dart';
import '../../app/services/ebooks_repository.dart';

class EbookForm extends StatefulWidget {
  final Ebook? initial;
  final List<String> categories;

  const EbookForm({
    super.key,
    this.initial,
    required this.categories,
  });

  @override
  State<EbookForm> createState() => _EbookFormState();
}

class _EbookFormState extends State<EbookForm> {
  final _formKey = GlobalKey<FormState>();
  final _repo = EbooksRepository();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _buyUrlCtrl;
  late TextEditingController _priceCtrl;

  bool _isPaid = false;
  bool _saving = false;

  /// Multiple selected categories (comma-separated on save)
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    final e = widget.initial;

    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _authorCtrl = TextEditingController(text: e?.author ?? '');
    _imageUrlCtrl = TextEditingController(text: e?.imageUrl ?? '');
    _buyUrlCtrl = TextEditingController(text: e?.buyUrl ?? '');
    _priceCtrl = TextEditingController(
      text: e?.pricePkr != null ? e!.pricePkr.toString() : '',
    );

    _isPaid = e?.isPaid ?? false;

    // Pre-select categories from stored comma-separated string
    final initialCat = e?.category.trim() ?? '';
    if (initialCat.isNotEmpty) {
      _selectedCategories = initialCat
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _authorCtrl.dispose();
    _imageUrlCtrl.dispose();
    _buyUrlCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // validate price if paid
    int? pricePkr;
    if (_isPaid) {
      final raw = _priceCtrl.text.trim();
      if (raw.isEmpty) {
        _showToast('Please enter price for paid ebooks');
        return;
      }
      pricePkr = int.tryParse(raw);
      if (pricePkr == null || pricePkr <= 0) {
        _showToast('Please enter a valid PKR price');
        return;
      }
    }

    if (_selectedCategories.isEmpty) {
      _showToast('Please select at least one category');
      return;
    }

    setState(() => _saving = true);

    try {
      // Join categories into a comma-separated string (sorted)
      final sortedCats = _selectedCategories.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final joinedCategories = sortedCats.join(', ');

      final base = widget.initial;
      final ebook = Ebook(
        id: base?.id ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        category: joinedCategories,
        imageUrl: _imageUrlCtrl.text.trim(),
        buyUrl: _buyUrlCtrl.text.trim(),
        createdAt: base?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isPaid: _isPaid,
        pricePkr: pricePkr,
      );

      if (base == null) {
        await _repo.addEbook(ebook);
      } else {
        await _repo.updateEbook(ebook);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      _showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Option A: tap category = select & close dialog
  Future<void> _openCategoryDialog() async {
    final options = <String>{
      ...widget.categories,
      ..._selectedCategories,
    }.toList()
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Select category",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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
                      itemBuilder: (ctx2, i) {
                        final cat = options[i];

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(ctx).pop(cat); // auto-close
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.4),
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
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.initial != null;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    // 🔹 Responsive width: ~70% of screen, min 420, max 820
    final screenWidth = MediaQuery.of(context).size.width;
    final targetWidth = screenWidth * 0.9;
    final formWidth = targetWidth.clamp(480.0, 920.0);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Center(
        child: SizedBox(
          width: formWidth, // <-- wider inner form, but not edge-to-edge
          child: Card(
            elevation: 14,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Ebook' : 'Add Ebook',
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
                    const SizedBox(height: 12),

                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Author
                    TextFormField(
                      controller: _authorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Author Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter author name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Categories multi-select display
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

                    // Image URL
                    TextFormField(
                      controller: _imageUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Book Image URL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter image URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Buy / Download URL
                    TextFormField(
                      controller: _buyUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buy / Download URL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter buy URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Free / Paid toggle
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Free'),
                          selected: !_isPaid,
                          onSelected: (_) {
                            setState(() {
                              _isPaid = false;
                              _priceCtrl.clear();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Paid'),
                          selected: _isPaid,
                          onSelected: (_) {
                            setState(() {
                              _isPaid = true;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isPaid) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (PKR)',
                          border: OutlineInputBorder(),
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
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isEdit ? 'Update Ebook' : 'Add Ebook',
                        ),
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
    );
  }
}
