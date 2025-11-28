import 'package:flutter/material.dart';

import '../../app/models/teacher.dart';
import '../services/admin_teachers_repository.dart';
import '../widgets/teacher_form.dart';

class TeacherEditorScreen extends StatefulWidget {
  final String? teacherId;

  const TeacherEditorScreen({
    super.key,
    this.teacherId,
  });

  bool get isEditing => teacherId != null;

  @override
  State<TeacherEditorScreen> createState() => _TeacherEditorScreenState();
}

class _TeacherEditorScreenState extends State<TeacherEditorScreen> {
  final _repo = AdminTeachersRepository();

  Teacher? _initial;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (!widget.isEditing) {
      setState(() {
        _initial = Teacher.empty();
        _loading = false;
      });
      return;
    }

    final t = await _repo.fetchById(widget.teacherId!);
    setState(() {
      _initial = t ?? Teacher.empty().copyWith(id: widget.teacherId);
      _loading = false;
    });
  }

  Future<void> _handleSave(Teacher updated) async {
    final base = _initial ?? Teacher.empty();
    final toSave = updated.copyWith(
      id: base.id.isNotEmpty ? base.id : '',
      createdAt: base.createdAt,
    );

    await _repo.upsertTeacher(toSave);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit teacher' : 'Add teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TeacherForm(
                initial: _initial,
                onSaved: _handleSave,
              ),
            ),
    );
  }
}
