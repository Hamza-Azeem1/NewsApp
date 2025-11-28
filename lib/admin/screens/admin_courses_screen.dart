import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../app/models/course.dart';
import '../services/admin_courses_repository.dart';
import '../widgets/course_form.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final _repo = AdminCoursesRepository();

  List<String> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Load distinct category tokens from `courses.category` (comma-separated),
  /// excluding "Free" / "Paid".
  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _loadingCategories = true;
    });

    try {
      final snap =
          await FirebaseFirestore.instance.collection('courses').get();

      final setCats = <String>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final catString = (data['category'] ?? '').toString();

        for (final raw in catString.split(',')) {
          final cat = raw.trim();
          if (cat.isEmpty) continue;

          final lower = cat.toLowerCase();
          if (lower == 'free' || lower == 'paid') continue;

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
      // ✅ Capture context before async gap or check mounted before using it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load course categories: $e')),
        );
      }
    }
  }

  /// Open centered dialog with CourseForm instead of bottom sheet
  Future<void> _openForm({Course? initial}) async {
    // ✅ Capture context before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // close via X or buttons only
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: CourseForm(
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
            initial == null ? 'Course saved' : 'Course updated',
          ),
        ),
      );
      _loadCategories(); // in case a new category was added
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
      body: StreamBuilder<List<Course>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(
              child: Text('No courses yet. Tap + to add one.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final c = courses[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        c.imageUrl.isNotEmpty ? NetworkImage(c.imageUrl) : null,
                    child: c.imageUrl.isEmpty
                        ? const Icon(Icons.school)
                        : null,
                  ),
                  title: Text(c.title),
                  subtitle: Text(
                    c.isPaid ? 'PKR ${c.pricePkr ?? '-'}' : 'Free',
                  ),
                  onTap: () => _openForm(initial: c),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      // ✅ Capture context before async gap
                      Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete course?'),
                          content: Text(
                            'Are you sure you want to delete "${c.title}"?',
                          ),
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
                      );

                      if (confirm == true) {
                        await _repo.deleteCourse(c.id);
                        if (!mounted) return;
                        // ✅ Use captured ScaffoldMessenger
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Course deleted successfully'),
                          ),
                        );
                        _loadCategories();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}