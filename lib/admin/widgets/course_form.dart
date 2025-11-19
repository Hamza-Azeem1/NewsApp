import 'package:flutter/material.dart';
import '../../app/models/course.dart';
import '../services/admin_courses_repository.dart';

class CourseForm extends StatefulWidget {
  final Course? initial;

  const CourseForm({super.key, this.initial});

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
  late TextEditingController _categoryCtrl;
  late TextEditingController _buyUrlCtrl;
  late TextEditingController _imageUrlCtrl;

  bool _isPaid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initial ?? Course.empty();

    _titleCtrl = TextEditingController(text: c.title);
    _descCtrl = TextEditingController(text: c.description);
    _topicsCtrl = TextEditingController(text: c.topicsCovered);
    _priceCtrl =
        TextEditingController(text: c.pricePkr?.toString() ?? '');
    _categoryCtrl = TextEditingController(text: c.category);
    _buyUrlCtrl = TextEditingController(text: c.buyUrl);
    _imageUrlCtrl = TextEditingController(text: c.imageUrl);
    _isPaid = c.isPaid;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _topicsCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
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

    setState(() => _saving = true);

    final base = widget.initial ?? Course.empty();

    final price = _isPaid ? int.tryParse(_priceCtrl.text.trim()) : null;

    final course = base.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      topicsCovered: _topicsCtrl.text.trim(),
      isPaid: _isPaid,
      pricePkr: price,
      category: _categoryCtrl.text.trim().isEmpty
          ? (_isPaid ? 'Paid' : 'Free')
          : _categoryCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AbsorbPointer(
      absorbing: _saving,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Edit Course' : 'Add Course',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
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
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category (e.g. Free, Paid, Tech, History)',
                    prefixIcon: Icon(Icons.category),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isEdit ? 'Save changes' : 'Create course'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
