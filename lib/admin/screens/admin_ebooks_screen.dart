import 'package:flutter/material.dart';
import '../../app/models/ebook.dart';
import '../../app/services/ebooks_repository.dart';

class AdminEbooksScreen extends StatefulWidget {
  const AdminEbooksScreen({super.key});

  @override
  State<AdminEbooksScreen> createState() => _AdminEbooksScreenState();
}

class _AdminEbooksScreenState extends State<AdminEbooksScreen> {
  final _repository = EbooksRepository();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _buyUrlController = TextEditingController();
  final _priceController = TextEditingController(); // 🔹 new

  final _formKey = GlobalKey<FormState>();

  Ebook? _editingEbook;
  bool _isSubmitting = false;

  /// controls if the left form panel is visible
  bool _showForm = false;

  /// 🔹 Free / Paid toggle
  bool _isPaid = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _buyUrlController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _startCreate() {
    setState(() {
      _showForm = true;
      _editingEbook = null;
      _titleController.clear();
      _descriptionController.clear();
      _authorController.clear();
      _categoryController.clear();
      _imageUrlController.clear();
      _buyUrlController.clear();
      _priceController.clear();
      _isPaid = false;
    });
  }

  void _startEdit(Ebook ebook) {
    setState(() {
      _showForm = true;
      _editingEbook = ebook;
      _titleController.text = ebook.title;
      _descriptionController.text = ebook.description;
      _authorController.text = ebook.author;
      _categoryController.text = ebook.category;
      _imageUrlController.text = ebook.imageUrl;
      _buyUrlController.text = ebook.buyUrl;
      _isPaid = ebook.isPaid;
      _priceController.text =
          ebook.pricePkr != null ? ebook.pricePkr.toString() : '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // validate price if paid
    int? pricePkr;
    if (_isPaid) {
      final raw = _priceController.text.trim();
      if (raw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter price for paid ebooks')),
        );
        return;
      }
      pricePkr = int.tryParse(raw);
      if (pricePkr == null || pricePkr <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid PKR price')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final ebook = Ebook(
        id: _editingEbook?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        author: _authorController.text.trim(),
        category: _categoryController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        buyUrl: _buyUrlController.text.trim(),
        createdAt: _editingEbook?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isPaid: _isPaid,
        pricePkr: pricePkr,
      );

      if (_editingEbook == null) {
        await _repository.addEbook(ebook);
      } else {
        await _repository.updateEbook(ebook);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingEbook == null
                  ? 'Ebook added successfully'
                  : 'Ebook updated successfully',
            ),
          ),
        );
      }

      // keep form open so admin can add another; just clear it
      _startCreate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _delete(Ebook ebook) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete ebook'),
            content: Text('Are you sure you want to delete "${ebook.title}"?'),
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
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _repository.deleteEbook(ebook.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ebook deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin – Ebooks'),
        actions: [
          IconButton(
            tooltip: 'Add new ebook',
            icon: const Icon(Icons.add),
            onPressed: _startCreate,
          ),
        ],
      ),
      body: Row(
        children: [
          // LEFT: FORM (only when _showForm == true)
          if (_showForm)
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingEbook == null
                                ? 'Add New Ebook'
                                : 'Edit Ebook',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _titleController,
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
                          TextFormField(
                            controller: _authorController,
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
                          TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              hintText: 'Economy, History, Technology, etc.',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a category';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _imageUrlController,
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
                          TextFormField(
                            controller: _buyUrlController,
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
                          TextFormField(
                            controller: _descriptionController,
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

                          // 🔹 Free / Paid toggle + price
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Free'),
                                selected: !_isPaid,
                                onSelected: (_) {
                                  setState(() {
                                    _isPaid = false;
                                    _priceController.clear();
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
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price (PKR)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed:
                                    _isSubmitting ? null : () => _submit(),
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(
                                  _editingEbook == null
                                      ? 'Add Ebook'
                                      : 'Update Ebook',
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed:
                                    _isSubmitting ? null : _startCreate,
                                child: const Text('Clear'),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Hide form',
                                onPressed: () {
                                  setState(() => _showForm = false);
                                },
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // RIGHT: LIST (always visible)
          Expanded(
            flex: 3,
            child: StreamBuilder<List<Ebook>>(
              stream: _repository.streamEbooks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final ebooks = snapshot.data ?? [];

                if (ebooks.isEmpty) {
                  return const Center(
                    child: Text('No ebooks added yet.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ebooks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ebook = ebooks[index];
                    return ListTile(
                      tileColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: CircleAvatar(
                        backgroundImage: ebook.imageUrl.isNotEmpty
                            ? NetworkImage(ebook.imageUrl)
                            : null,
                        child: ebook.imageUrl.isEmpty
                            ? const Icon(Icons.book_outlined)
                            : null,
                      ),
                      title: Text(ebook.title),
                      subtitle: Text(
                        '${ebook.author} • ${ebook.category}'
                        ' • ${ebook.isPaid ? (ebook.pricePkr != null ? 'PKR ${ebook.pricePkr}' : 'Paid') : 'Free'}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _startEdit(ebook),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(ebook),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
