import 'package:flutter/material.dart';
import '../../app/models/teacher.dart';
import '../services/storage_service.dart';

class TeacherForm extends StatefulWidget {
  final Teacher? initial;
  final Future<void> Function(Teacher data) onSubmit;

  const TeacherForm({super.key, this.initial, required this.onSubmit});

  @override
  State<TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<TeacherForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _intro;
  late TextEditingController _imageUrl;

  final List<String> _specializations = [];
  final List<String> _qualifications = [];
  final Map<String, String> _socials = {}; // label -> url

  final _chipCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _socialLabelCtrl = TextEditingController();
  final _socialUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _name = TextEditingController(text: t?.name ?? '');
    _intro = TextEditingController(text: t?.intro ?? '');
    _imageUrl = TextEditingController(text: t?.imageUrl ?? '');
    _specializations.addAll(t?.specializations ?? []);
    _qualifications.addAll(t?.qualifications ?? []);
    _socials.addAll(t?.socials ?? {});
  }

  @override
  void dispose() {
    _name.dispose();
    _intro.dispose();
    _imageUrl.dispose();
    _chipCtrl.dispose();
    _qualCtrl.dispose();
    _socialLabelCtrl.dispose();
    _socialUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    final url = await StorageService.pickAndUploadTeacherImage();
    if (url != null) {
      setState(() => _imageUrl.text = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded')),
        );
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.initial ??
        Teacher(
          id: 'new',
          name: _name.text.trim(),
        );

    final data = base.copyWith(
      name: _name.text.trim(),
      intro: _intro.text.trim().isEmpty ? null : _intro.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      specializations: List<String>.from(_specializations),
      qualifications: List<String>.from(_qualifications),
      socials: Map<String, String>.from(_socials),
    );

    widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Dr. Sara Khan',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: Column(
                  children: [
                    InkWell(
                      onTap: _uploadImage,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _imageUrl.text.isEmpty
                            ? Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                                ),
                                child: const Icon(Icons.add_a_photo),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(_imageUrl.text, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _uploadImage,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Upload'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _imageUrl,
            decoration: const InputDecoration(
              labelText: 'Image URL (optional)',
              hintText: 'https://...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _intro,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Intro / Profile',
              hintText: 'Short teacher bio',
            ),
          ),
          const SizedBox(height: 16),

          // Specializations chips
          _ChipEditor(
            title: 'Specializations',
            items: _specializations,
            controller: _chipCtrl,
          ),
          const SizedBox(height: 12),

          // Qualifications chips
          _ChipEditor(
            title: 'Qualifications',
            items: _qualifications,
            controller: _qualCtrl,
          ),
          const SizedBox(height: 16),

          // Social links
          _SocialsEditor(
            map: _socials,
            labelCtrl: _socialLabelCtrl,
            urlCtrl: _socialUrlCtrl,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _submit,
            icon: Icon(isEditing ? Icons.save : Icons.add),
            label: Text(isEditing ? 'Save Changes' : 'Create Teacher'),
          ),
        ],
      ),
    );
  }
}

class _ChipEditor extends StatefulWidget {
  final String title;
  final List<String> items;
  final TextEditingController controller;
  const _ChipEditor({
    required this.title,
    required this.items,
    required this.controller,
  });

  @override
  State<_ChipEditor> createState() => _ChipEditorState();
}

class _ChipEditorState extends State<_ChipEditor> {
  void _add() {
    final t = widget.controller.text.trim();
    if (t.isEmpty) return;
    if (!widget.items.contains(t)) {
      setState(() => widget.items.add(t));
    }
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final it in widget.items)
              Chip(
                label: Text(it),
                onDeleted: () => setState(() => widget.items.remove(it)),
              ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: widget.controller,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  labelText: 'Add ${widget.title.substring(0, 1).toLowerCase()}${widget.title.substring(1)}',
                  suffixIcon: IconButton(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialsEditor extends StatefulWidget {
  final Map<String, String> map;
  final TextEditingController labelCtrl;
  final TextEditingController urlCtrl;
  const _SocialsEditor({
    required this.map,
    required this.labelCtrl,
    required this.urlCtrl,
  });

  @override
  State<_SocialsEditor> createState() => _SocialsEditorState();
}

class _SocialsEditorState extends State<_SocialsEditor> {
  void _add() {
    final label = widget.labelCtrl.text.trim();
    final url = widget.urlCtrl.text.trim();
    if (label.isEmpty || url.isEmpty) return;
    setState(() => widget.map[label] = url);
    widget.labelCtrl.clear();
    widget.urlCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.map.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Socials / Links', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in entries)
              InputChip(
                label: Text('${e.key}: ${e.value}'),
                onDeleted: () => setState(() => widget.map.remove(e.key)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.labelCtrl,
                decoration: const InputDecoration(labelText: 'Label (e.g. YouTube, Website)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: widget.urlCtrl,
                decoration: const InputDecoration(labelText: 'URL (https://...)'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: _add, icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }
}
