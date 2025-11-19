import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/models/course.dart';

class AdminCoursesRepository {
  static const _collectionName = 'courses';
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection(_collectionName);

  Stream<List<Course>> watchAll() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Course.fromDoc).toList());
  }

  Future<void> upsertCourse(Course course) async {
    final now = DateTime.now();

    if (course.id.isEmpty) {
      final doc = _ref.doc();
      final toSave = course.copyWith(
        id: doc.id,
        createdAt: now,
        updatedAt: now,
      );
      await doc.set(toSave.toMap());
    } else {
      final doc = _ref.doc(course.id);
      final toSave = course.copyWith(
        updatedAt: now,
      );
      await doc.update(toSave.toMap());
    }
  }

  Future<void> deleteCourse(String id) async {
    await _ref.doc(id).delete();
  }
}
