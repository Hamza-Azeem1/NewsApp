import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';

class TeachersRepository {
  final _col = FirebaseFirestore.instance.collection('teachers');

  Stream<List<Teacher>> watchAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (s) => s.docs.map((d) => Teacher.fromDoc(d)).toList(),
        );
  }
}
