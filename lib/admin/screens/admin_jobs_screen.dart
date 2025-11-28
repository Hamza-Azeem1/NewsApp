import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:news_swipe/app/models/job.dart';
import 'package:news_swipe/app/services/jobs_repository.dart';

import '../widgets/job_form.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  final _repo = JobsRepository.instance;

  List<String> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Load distinct category tokens from `jobs.category` (comma-separated)
  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() => _loadingCategories = true);

    try {
      final snap =
          await FirebaseFirestore.instance.collection('jobs').get();

      final setCats = <String>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final catString = (data['category'] ?? '').toString();

        for (final raw in catString.split(',')) {
          final cat = raw.trim();
          if (cat.isEmpty) continue;
          setCats.add(cat);
        }
      }

      final list = setCats.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _categories = list;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      // ✅ Check mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load job categories: $e')),
        );
      }
    }
  }

  Future<void> _openForm({Job? initial}) async {
    // ✅ Capture ScaffoldMessenger before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: JobForm(
            initial: initial,
            categories: _categories,
          ),
        );
      },
    );

    if (!mounted) return;
    
    if (changed == true) {
      // ✅ Use captured ScaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            initial == null ? 'Job added successfully' : 'Job updated successfully',
          ),
        ),
      );
      _loadCategories();
    }
  }

  Future<void> _confirmDelete(Job job) async {
    // ✅ Capture context-dependent objects before async gap
    Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete job'),
            content: Text('Delete "${job.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    await _repo.deleteJob(job.id);
    if (!mounted) return;
    
    // ✅ Use captured ScaffoldMessenger
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Job deleted')),
    );
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin – Jobs'),
        actions: [
          if (_loadingCategories)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add job',
            onPressed: () => _openForm(),
          )
        ],
      ),
      body: StreamBuilder<List<Job>>(
        stream: _repo.watchJobs(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final job = jobs[index];

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: cs.surfaceContainerHighest,
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
                      onPressed: () => _openForm(initial: job),
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
    );
  }
}