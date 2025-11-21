import 'package:flutter/material.dart';
import '../../app/models/tool.dart';
import '../services/admin_tools_repository.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  final _repo = AdminToolsRepository();

  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _toolLinkCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(); // 👈 NEW

  bool _isFree = true;
  Tool? _editing;
  bool _showForm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortDescCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _toolLinkCtrl.dispose();
    _imageUrlCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tools'),
        actions: [
          IconButton(
            tooltip: 'Add tool',
            icon: const Icon(Icons.add),
            onPressed: _openForAdd,
          )
        ],
      ),
      body: Row(
        children: [
          // LIST
          Expanded(
            flex: 3,
            child: StreamBuilder<List<Tool>>(
              stream: _repo.watchTools(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text('Error loading tools'));
                }
                final tools = snap.data ?? [];
                if (tools.isEmpty) {
                  return const Center(child: Text('No tools yet'));
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: tools.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    final isSelected = _editing?.id == tool.id;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.06)
                          : null,
                      title: Text(tool.name),
                      subtitle: Text(
                        '${tool.category} • ${tool.shortDesc}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tool.isFree
                                ? 'Free'
                                : (tool.price != null
                                    ? 'PKR ${tool.price!.toStringAsFixed(0)}'
                                    : 'Paid'),
                            style: t.labelMedium,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _startEditing(tool),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(tool),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // FORM
          Expanded(
            flex: 4,
            child: _showForm
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editing == null ? 'Add new tool' : 'Edit tool',
                            style: t.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),

                          // Name
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Category
                          TextFormField(
                            controller: _categoryCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Category (e.g. Video, Design, AI)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Short desc
                          TextFormField(
                            controller: _shortDescCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Short description',
                              border: OutlineInputBorder(),
                            ),
                            maxLength: 100,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Full desc
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Price + Free toggle
                          Row(
                            children: [
                              Checkbox(
                                value: _isFree,
                                onChanged: (v) {
                                  setState(() => _isFree = v ?? true);
                                },
                              ),
                              const Text('Free tool'),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceCtrl,
                                  enabled: !_isFree,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                    prefixText: 'PKR ',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (_isFree) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter price for paid tool';
                                    }
                                    final parsed =
                                        double.tryParse(v.replaceAll(',', ''));
                                    if (parsed == null || parsed < 0) {
                                      return 'Invalid price';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Tool link
                          TextFormField(
                            controller: _toolLinkCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tool link (URL)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Image link
                          TextFormField(
                            controller: _imageUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Image URL',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _save,
                                icon:
                                    const Icon(Icons.save_outlined),
                                label: Text(
                                  _editing == null ? 'Add tool' : 'Save',
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: _resetForm,
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'Select a tool to edit, or click the + button to add a new tool.',
                      style: t.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openForAdd() {
    setState(() {
      _editing = null;
      _showForm = true;
      _nameCtrl.clear();
      _shortDescCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _toolLinkCtrl.clear();
      _imageUrlCtrl.clear();
      _categoryCtrl.clear();
      _isFree = true;
    });
  }

  void _startEditing(Tool tool) {
    setState(() {
      _editing = tool;
      _showForm = true;
      _nameCtrl.text = tool.name;
      _shortDescCtrl.text = tool.shortDesc;
      _descCtrl.text = tool.description;
      _isFree = tool.isFree;
      _priceCtrl.text =
          tool.price != null ? tool.price!.toStringAsFixed(0) : '';
      _toolLinkCtrl.text = tool.toolLink;
      _imageUrlCtrl.text = tool.imageUrl;
      _categoryCtrl.text = tool.category;
    });
  }

  Future<void> _confirmDelete(Tool tool) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tool'),
        content: Text('Are you sure you want to delete "${tool.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteTool(tool.id);
      if (_editing?.id == tool.id) {
        _resetForm();
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    double? price;
    if (!_isFree && _priceCtrl.text.trim().isNotEmpty) {
      price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', ''));
    }

    final base = _editing ?? Tool.empty();

    final tool = base.copyWith(
      name: _nameCtrl.text.trim(),
      shortDesc: _shortDescCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isFree: _isFree,
      price: price,
      toolLink: _toolLinkCtrl.text.trim(),
      imageUrl: _imageUrlCtrl.text.trim(),
      category: _categoryCtrl.text.trim(), // 👈 NEW
      createdAt: base.createdAt,
    );

    await _repo.upsertTool(tool);
    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _editing = null;
      _showForm = false;
      _nameCtrl.clear();
      _shortDescCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _toolLinkCtrl.clear();
      _imageUrlCtrl.clear();
      _categoryCtrl.clear();
      _isFree = true;
    });
  }
}
