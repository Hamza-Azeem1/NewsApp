import 'package:flutter/material.dart';

import '../../app/models/teacher.dart';
import '../services/admin_teachers_repository.dart';
import 'teacher_editor_screen.dart';

class TeachersListScreen extends StatelessWidget {
  const TeachersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminTeachersRepository();
    // final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TeacherEditorScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add teacher'),
      ),
      body: StreamBuilder<List<Teacher>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Error loading teachers'));
          }

          final teachers = snap.data ?? [];
          if (teachers.isEmpty) {
            return const Center(child: Text('No teachers yet'));
          }

          return ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              final cats = teacher.categories;
              final subtitle = [
                if ((teacher.intro ?? '').isNotEmpty) teacher.intro!,
                if (cats.isNotEmpty) 'Categories: ${cats.join(', ')}',
              ].join(' • ');

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: CircleAvatar(
                  backgroundImage: (teacher.imageUrl ?? '').isNotEmpty
                      ? NetworkImage(teacher.imageUrl!)
                      : null,
                  child: (teacher.imageUrl ?? '').isEmpty
                      ? const Icon(Icons.person_rounded)
                      : null,
                ),
                title: Text(teacher.name),
                subtitle: subtitle.isEmpty
                    ? null
                    : Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TeacherEditorScreen(
                              teacherId: teacher.id,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete teacher'),
                            content: Text(
                                'Are you sure you want to delete "${teacher.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await repo.deleteTeacher(teacher.id);
                        }
                      },
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
