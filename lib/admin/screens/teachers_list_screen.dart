import 'package:flutter/material.dart';
import '../../app/models/teacher.dart';
import '../services/admin_teachers_repository.dart';
import 'teacher_editor_screen.dart';

class TeachersListScreen extends StatelessWidget {
  TeachersListScreen({super.key});
  final repo = AdminTeachersRepository();

  Future<void> _delete(BuildContext context, Teacher t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete teacher?'),
        content: Text('This will remove ${t.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await repo.delete(t.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: [
          IconButton(
            tooltip: 'Add teacher',
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherEditorScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Teacher>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No teachers yet. Tap + to add.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = list[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: t.imageUrl == null
                      ? const CircleAvatar(child: Icon(Icons.person))
                      : CircleAvatar(backgroundImage: NetworkImage(t.imageUrl!)),
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Wrap(
                    spacing: 6,
                    runSpacing: -8,
                    children: [
                      for (final s in t.specializations.take(3)) Chip(label: Text(s)),
                      if (t.specializations.length > 3) Text('+${t.specializations.length - 3} more'),
                    ],
                  ),
                  trailing: Wrap(spacing: 8, children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TeacherEditorScreen(teacherId: t.id)),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, t),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherEditorScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('New Teacher'),
      ),
    );
  }
}
