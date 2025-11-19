import 'package:flutter/material.dart';
import '../../app/models/course.dart';
import '../services/admin_courses_repository.dart';
import '../widgets/course_form.dart';

class AdminCoursesScreen extends StatelessWidget {
  const AdminCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminCoursesRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => const CourseForm(),
          );
          if (changed == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Course saved')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
      body: StreamBuilder<List<Course>>(
        stream: repo.watchAll(),
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
                    '${c.category} • '
                    '${c.isPaid ? 'PKR ${c.pricePkr ?? '-'}' : 'Free'}',
                  ),
                  onTap: () async {
                    final changed = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => CourseForm(initial: c),
                    );
                    if (changed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Course updated')),
                      );
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete course?'),
                          content: Text(
                              'Are you sure you want to delete "${c.title}"?'),
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
                        await repo.deleteCourse(c.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Course deleted successfully')),
                          );
                        }
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
