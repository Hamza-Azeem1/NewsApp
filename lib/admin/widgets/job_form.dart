import 'package:flutter/material.dart';
import '../../app/models/job.dart';
import '../../app/services/jobs_repository.dart';

class JobForm extends StatefulWidget {
  final Job? initial;
  final List<String> categories;

  const JobForm({
    super.key,
    this.initial,
    required this.categories,
  });

  @override
  State<JobForm> createState() => _JobFormState();
}

class _JobFormState extends State<JobForm> {
  final _formKey = GlobalKey<FormState>();
  final _repo = JobsRepository.instance;

  late TextEditingController _titleCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _shortDescCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _longDescCtrl;
  late TextEditingController _applyLinkCtrl;

  bool _saving = false;

  /// Multiple selected categories (stored as comma-separated string)
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    final j = widget.initial ?? Job.empty();

    _titleCtrl = TextEditingController(text: j.title);
    _companyCtrl = TextEditingController(text: j.companyName);
    _locationCtrl = TextEditingController(text: j.location);
    _shortDescCtrl = TextEditingController(text: j.shortDesc);
    _descCtrl = TextEditingController(text: j.desc);
    _longDescCtrl = TextEditingController(text: j.longDesc);
    _applyLinkCtrl = TextEditingController(text: j.applyLink);

    final initialCat = j.category.trim();
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
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _shortDescCtrl.dispose();
    _descCtrl.dispose();
    _longDescCtrl.dispose();
    _applyLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final base = widget.initial ?? Job.empty();

      final sortedCats = _selectedCategories.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final joinedCategories = sortedCats.join(', ');

      final job = base.copyWith(
        title: _titleCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        shortDesc: _shortDescCtrl.text.trim(),
        desc: _descCtrl.text.trim(),
        longDesc: _longDescCtrl.text.trim(),
        applyLink: _applyLinkCtrl.text.trim(),
        category: joinedCategories,
        createdAt: base.createdAt,
      );

      await _repo.upsertJob(job);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Centered dialog: select existing or add new category (Option A)
  Future<void> _openCategoryDialog() async {
    final options = <String>{
      ...widget.categories,
      ..._selectedCategories,
    }
        .where((c) => c.trim().isNotEmpty)
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
                  color: cs.outlineVariant.withValues(alpha: 0.3),
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
                        color: cs.onSurface.withValues(alpha: 0.7),
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

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            elevation: 14,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Job' : 'Add Job',
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
                        labelText: 'Job title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _companyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Company name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Location / Remote',
                        hintText: 'e.g. Lahore (Remote) / Remote',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Categories multi-select
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
                      controller: _shortDescCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Short description (shown in list)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      maxLength: 160,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Short extra description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _longDescCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _applyLinkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Apply link (URL)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(isEdit ? 'Save changes' : 'Add Job'),
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
