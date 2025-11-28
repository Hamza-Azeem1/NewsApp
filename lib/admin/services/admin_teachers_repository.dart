import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/models/teacher.dart';

class AdminTeachersRepository {
  final _col = FirebaseFirestore.instance.collection('teachers')
      .withConverter<Teacher>(
    fromFirestore: (snap, _) => Teacher.fromDoc(snap),
    toFirestore: (teacher, _) => teacher.toMap(),
  );

  Stream<List<Teacher>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<Teacher?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Upsert (create or update)
  Future<void> upsertTeacher(Teacher teacher) async {
    final now = DateTime.now();

    if (teacher.id.isEmpty) {
      final doc = _col.doc();
      final newTeacher = teacher.copyWith(
        id: doc.id,
        createdAt: now,
        updatedAt: now,
      );
      await doc.set(newTeacher);
    } else {
      final docRef = _col.doc(teacher.id);
      final updated = teacher.copyWith(
        updatedAt: now,
      );
      await docRef.set(updated, SetOptions(merge: true));
    }
  }

  Future<void> deleteTeacher(String id) async {
    await _col.doc(id).delete();
  }
}
