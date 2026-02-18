import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/models/teacher.dart';

class TeacherForm extends StatefulWidget {
  final Teacher? initial;
  final Future<void> Function(Teacher teacher) onSaved;

  const TeacherForm({
    super.key,
    this.initial,
    required this.onSaved,
  });

  @override
  State<TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<TeacherForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _introCtrl;
  late TextEditingController _imageUrlCtrl;

  // Lists
  final Set<String> _specializations = {};
  final Set<String> _qualifications = {};

  // Categories
  final Set<String> _selectedCategories = {};
  List<String> _allCategories = [];

  // Dynamic social links
  late List<_SocialLinkEntry> _socialLinks;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial ?? Teacher.empty();

    _nameCtrl = TextEditingController(text: t.name);
    _introCtrl = TextEditingController(text: t.intro ?? '');
    _imageUrlCtrl = TextEditingController(text: t.imageUrl ?? '');

    _specializations.addAll(t.specializations);
    _qualifications.addAll(t.qualifications);
    _selectedCategories.addAll(t.categories);

    // Build dynamic social links list from existing map
    _socialLinks = _buildInitialSocialLinks(t.socials);

    _loadExistingCategories();

    // So avatar updates when URL text changes
    _imageUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  List<_SocialLinkEntry> _buildInitialSocialLinks(
    Map<String, String> socials,
  ) {
    final List<_SocialLinkEntry> list = [];
    int counter = 0;

    socials.forEach((key, value) {
      final url = value.trim();
      if (url.isEmpty) return;

      final label = _guessPlatformLabel(key, url);
      list.add(
        _SocialLinkEntry(
          id: 'init_$counter',
          label: label,
          url: url,
        ),
      );
      counter++;
    });

    return list;
  }

  String _guessPlatformLabel(String key, String url) {
    final lower = ('$key $url').toLowerCase();

    if (lower.contains('linkedin') || lower.contains('lnkd.in')) {
      return 'LinkedIn';
    }
    if (lower.contains('twitter') || lower.contains('x.com')) {
      return 'Twitter / X';
    }
    if (lower.contains('facebook') || lower.contains('fb.com')) {
      return 'Facebook';
    }
    if (lower.contains('instagram') || lower.contains('insta')) {
      return 'Instagram';
    }
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return 'YouTube';
    }
    if (lower.contains('tiktok')) {
      return 'TikTok';
    }
    if (lower.contains('github')) {
      return 'GitHub';
    }
    if (lower.contains('medium.com')) {
      return 'Medium';
    }

    // Very simple email detection
    final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (lower.contains('mailto:') || emailReg.hasMatch(url)) {
      return 'Email';
    }

    // Very simple phone / WhatsApp detection
    final phoneReg = RegExp(r'^\+?[0-9]{6,}$');
    if (lower.startsWith('tel:') || phoneReg.hasMatch(url.replaceAll(' ', ''))) {
      return 'Phone / WhatsApp';
    }

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return 'Website';
    }

    return key.isNotEmpty ? key : 'Other';
  }

  IconData _iconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('linkedin')) return Icons.business_center_outlined;
    if (lower.contains('twitter') || lower.contains('x')) {
      return Icons.alternate_email;
    }
    if (lower.contains('facebook')) return Icons.facebook_outlined;
    if (lower.contains('instagram')) return Icons.camera_alt_outlined;
    if (lower.contains('youtube')) return Icons.play_circle_outline;
    if (lower.contains('tiktok')) return Icons.music_note;
    if (lower.contains('email')) return Icons.email_outlined;
    if (lower.contains('phone') || lower.contains('whatsapp')) {
      return Icons.phone_outlined;
    }
    if (lower.contains('website')) return Icons.language;
    return Icons.link;
  }

  Future<void> _loadExistingCategories() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('teachers').get();
      final set = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final list =
            (data['categories'] as List?)?.whereType<String>().toList() ??
                const [];
        for (final c in list) {
          final trimmed = c.trim();
          if (trimmed.isNotEmpty) set.add(trimmed);
        }
      }
      set.addAll(_selectedCategories);
      if (!mounted) return;
      setState(() {
        _allCategories = set.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    } catch (_) {
      // helper only, safe to ignore
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _introCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _trySubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() => _saving = true);

    final base = widget.initial ?? Teacher.empty();

    final sortedCats = _selectedCategories.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final specs = _specializations.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final quals = _qualifications.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Build socials map from dynamic links
    final socials = <String, String>{};

    for (final link in _socialLinks) {
      final url = link.url.trim();
      if (url.isEmpty) continue;

      String label = link.label.trim();
      if (label.isEmpty) {
        label = _guessPlatformLabel('', url);
      }

      // Ensure unique keys so we don't overwrite when there are multiple websites, etc.
      var finalLabel = label;
      var idx = 2;
      while (socials.containsKey(finalLabel)) {
        finalLabel = '$label #$idx';
        idx++;
      }
      socials[finalLabel] = url;
    }

    final teacher = base.copyWith(
      name: _nameCtrl.text.trim(),
      intro: _introCtrl.text.trim().isEmpty ? null : _introCtrl.text.trim(),
      imageUrl:
          _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      categories: sortedCats,
      specializations: specs,
      qualifications: quals,
      socials: socials,
    );

    try {
      await widget.onSaved(teacher);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openCategoryDialog() async {
    final TextEditingController newCtrl = TextEditingController();

    final selectedOrNew = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final options = <String>{
          ..._allCategories,
          ..._selectedCategories,
        }.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Select category',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: newCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Add new category',
                          prefixIcon: Icon(Icons.add),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          final text = value.trim();
                          if (text.isEmpty) return;
                          Navigator.of(ctx).pop(text);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    if (options.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text(
                          'No existing categories yet.\nAdd one using the field above.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (ctx, index) {
                            final cat = options[index];
                            final alreadySelected =
                                _selectedCategories.contains(cat);
                            return ListTile(
                              dense: true,
                              title: Text(cat),
                              selected: alreadySelected,
                              onTap: () => Navigator.of(ctx).pop(cat),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(height: 4),
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
        _selectedCategories.add(selectedOrNew.trim());
        _allCategories = {
          ..._allCategories,
          ..._selectedCategories,
        }.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return AbsorbPointer(
      absorbing: _saving,
      child: SingleChildScrollView(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher details',
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Avatar + URL
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: cs.surfaceContainerHighest,
                        backgroundImage:
                            (_imageUrlCtrl.text.trim().isNotEmpty)
                                ? NetworkImage(_imageUrlCtrl.text.trim())
                                : null,
                        child: _imageUrlCtrl.text.trim().isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                color: cs.onSurfaceVariant,
                                size: 32,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _imageUrlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Profile image URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 12),

                  // Intro
                  TextFormField(
                    controller: _introCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Short intro (shown on card)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 12),

                  // Categories
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Categories (used for filters)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.category_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        onPressed: _openCategoryDialog,
                      ),
                    ),
                    isEmpty: _selectedCategories.isEmpty,
                    child: _selectedCategories.isEmpty
                        ? Text(
                            'Tap the arrow to select or add categories',
                            style: t.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          )
                        : Wrap(
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
                  ),

                  const SizedBox(height: 16),

                  // Specializations
                  Text(
                    'Specializations',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ChipsEditor(
                    values: _specializations,
                    hint: 'Add specialization (e.g. Economics)',
                    onChanged: (values) {
                      setState(() {
                        _specializations
                          ..clear()
                          ..addAll(values);
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Qualifications
                  Text(
                    'Qualifications',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ChipsEditor(
                    values: _qualifications,
                    hint: 'Add qualification (e.g. M.Phil, 10+ yrs)',
                    onChanged: (values) {
                      setState(() {
                        _qualifications
                          ..clear()
                          ..addAll(values);
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Socials (dynamic)
                  Text(
                    'Social & contact links',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SocialLinksEditor(
                    links: _socialLinks,
                    iconForLabel: _iconForLabel,
                    onChanged: (updated) {
                      setState(() {
                        _socialLinks = updated;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _trySubmit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Saving...' : 'Save teacher',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLinkEntry {
  final String id;
  final String label;
  final String url;

  _SocialLinkEntry({
    required this.id,
    required this.label,
    required this.url,
  });

  _SocialLinkEntry copyWith({
    String? label,
    String? url,
  }) {
    return _SocialLinkEntry(
      id: id,
      label: label ?? this.label,
      url: url ?? this.url,
    );
  }
}

class _SocialLinksEditor extends StatelessWidget {
  final List<_SocialLinkEntry> links;
  final IconData Function(String label) iconForLabel;
  final ValueChanged<List<_SocialLinkEntry>> onChanged;

  const _SocialLinksEditor({
//    super.key,
    required this.links,
    required this.iconForLabel,
    required this.onChanged,
  });

  void _addEmptyLink() {
    final updated = [
      ...links,
      _SocialLinkEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: '',
        url: '',
      ),
    ];
    onChanged(updated);
  }

  void _updateLink(int index, _SocialLinkEntry entry) {
    final updated = [...links];
    updated[index] = entry;
    onChanged(updated);
  }

  void _deleteLink(int index) {
    final updated = [...links]..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (links.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No links yet. Add website, LinkedIn, Twitter, YouTube, email, etc.',
              style: t.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ...List.generate(links.length, (index) {
          final link = links[index];
          final icon = iconForLabel(link.label);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: link.label,
                            decoration: const InputDecoration(
                              labelText: 'Label (e.g. LinkedIn, Website)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              _updateLink(
                                index,
                                link.copyWith(label: v),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove link',
                          onPressed: () => _deleteLink(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: link.url,
                      decoration: const InputDecoration(
                        labelText: 'URL (https://, mailto:, tel:, etc.)',
                        prefixIcon: Icon(Icons.link),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        _updateLink(
                          index,
                          link.copyWith(url: v),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addEmptyLink,
            icon: const Icon(Icons.add_link),
            label: const Text('Add link'),
          ),
        ),
      ],
    );
  }
}

class _ChipsEditor extends StatefulWidget {
  final Set<String> values;
  final String hint;
  final ValueChanged<Set<String>> onChanged;

  const _ChipsEditor({
    required this.values,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_ChipsEditor> createState() => _ChipsEditorState();
}

class _ChipsEditorState extends State<_ChipsEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addFromText() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final next = {...widget.values, text};
    widget.onChanged(next);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: widget.values.map((v) {
            return Chip(
              label: Text(v),
              onDeleted: () {
                final next = {...widget.values}..remove(v);
                widget.onChanged(next);
              },
              deleteIcon: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: widget.hint,
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addFromText,
            ),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _addFromText(),
        ),
        if (widget.values.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No items yet',
              style: t.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}
