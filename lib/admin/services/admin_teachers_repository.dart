import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/models/teacher.dart';

class AdminTeachersRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('teachers');

  /// Live list (order by name for stability; switch to createdAt if you prefer)
  Stream<List<Teacher>> watchAll() {
    return _col.orderBy('name').snapshots().map(
          (s) => s.docs.map((d) => Teacher.fromDoc(d)).toList(),
        );
  }

  /// ✅ The method your editor needs
  Future<Teacher?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Teacher.fromDoc(doc);
  }

  /// Create with server timestamps
  Future<String> create(Teacher teacher) async {
    final data = teacher.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _col.add(data);
    return ref.id;
  }

  /// Update with server timestamp
  Future<void> update(Teacher teacher) async {
    final data = teacher.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(teacher.id).update(data);
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
