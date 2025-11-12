import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CoursesRepository {
  final _col = FirebaseFirestore.instance.collection('courses');
  Stream<List<Course>> watchAll() {
    return _col.snapshots().map((s) => s.docs.map((d) => Course.fromMap(d.id, d.data())).toList());
  }
}
