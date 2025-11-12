import 'package:flutter/material.dart';
import '../../app/models/teacher.dart';
import '../services/admin_teachers_repository.dart';
import '../widgets/teacher_form.dart';

class TeacherEditorScreen extends StatefulWidget {
  final String? teacherId; // null => create
  const TeacherEditorScreen({super.key, this.teacherId});

  @override
  State<TeacherEditorScreen> createState() => _TeacherEditorScreenState();
}

class _TeacherEditorScreenState extends State<TeacherEditorScreen> {
  final repo = AdminTeachersRepository();
  Teacher? _initial;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.teacherId == null) {
      _loading = false;
    } else {
      repo.fetchById(widget.teacherId!).then((t) {
        setState(() {
          _initial = t;
          _loading = false;
        });
      });
    }
  }

  Future<void> _handleSubmit(Teacher data) async {
    try {
      if (_initial == null) {
        final id = await repo.create(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher created')));
          Navigator.pop(context, id);
        }
      } else {
        final toSave = data.copyWith(id: _initial!.id);
        await repo.update(toSave);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved')));
          Navigator.pop(context, _initial!.id);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teacherId == null ? 'Add Teacher' : 'Edit Teacher'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TeacherForm(initial: _initial, onSubmit: _handleSubmit),
    );
  }
}
