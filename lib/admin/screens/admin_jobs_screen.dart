import 'package:flutter/material.dart';
import 'package:news_swipe/app/models/job.dart';
import 'package:news_swipe/app/services/jobs_repository.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  final _repo = JobsRepository.instance;

  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _longDescCtrl = TextEditingController();
  final _applyLinkCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  Job? _editing;
  bool _showForm = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _descCtrl.dispose();
    _shortDescCtrl.dispose();
    _longDescCtrl.dispose();
    _applyLinkCtrl.dispose();
    _categoryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add job',
            onPressed: _openForAdd,
          )
        ],
      ),
      body: Row(
        children: [
          // LIST
          Expanded(
            flex: 3,
            child: StreamBuilder<List<Job>>(
              stream: _repo.watchJobs(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text('Error loading jobs'));
                }
                final jobs = snap.data ?? [];
                if (jobs.isEmpty) {
                  return const Center(child: Text('No jobs yet'));
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final selected = _editing?.id == job.id;

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: selected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.06)
                          : null,
                      title: Text(job.title),
                      subtitle: Text(
                        '${job.companyName} • ${job.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            job.category,
                            style: t.labelSmall,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _startEditing(job),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(job),
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editing == null ? 'Add job' : 'Edit job',
                            style: t.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _companyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Company name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
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
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _categoryCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Category (e.g. Design, Dev, Writing)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _shortDescCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Short desc (shown in card)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            maxLength: 160,
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Desc',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _longDescCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Long desc / Full description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 5,
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _applyLinkCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Apply link (URL)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _save,
                                icon: const Icon(Icons.save_outlined),
                                label: Text(
                                  _editing == null ? 'Add job' : 'Save',
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
                      'Select a job to edit, or click + to add new.',
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
      _titleCtrl.clear();
      _companyCtrl.clear();
      _descCtrl.clear();
      _shortDescCtrl.clear();
      _longDescCtrl.clear();
      _applyLinkCtrl.clear();
      _categoryCtrl.clear();
      _locationCtrl.clear();
    });
  }

  void _startEditing(Job job) {
    setState(() {
      _editing = job;
      _showForm = true;
      _titleCtrl.text = job.title;
      _companyCtrl.text = job.companyName;
      _descCtrl.text = job.desc;
      _shortDescCtrl.text = job.shortDesc;
      _longDescCtrl.text = job.longDesc;
      _applyLinkCtrl.text = job.applyLink;
      _categoryCtrl.text = job.category;
      _locationCtrl.text = job.location;
    });
  }

  Future<void> _confirmDelete(Job job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete job'),
        content: Text('Delete "${job.title}"?'),
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
      await _repo.deleteJob(job.id);
      if (_editing?.id == job.id) {
        _resetForm();
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final base = _editing ?? Job.empty();

    final job = base.copyWith(
      title: _titleCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      desc: _descCtrl.text.trim(),
      longDesc: _longDescCtrl.text.trim(),
      shortDesc: _shortDescCtrl.text.trim(),
      applyLink: _applyLinkCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      createdAt: base.createdAt,
    );

    await _repo.upsertJob(job);
    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _editing = null;
      _showForm = false;
      _titleCtrl.clear();
      _companyCtrl.clear();
      _descCtrl.clear();
      _shortDescCtrl.clear();
      _longDescCtrl.clear();
      _applyLinkCtrl.clear();
      _categoryCtrl.clear();
      _locationCtrl.clear();
    });
  }
}
