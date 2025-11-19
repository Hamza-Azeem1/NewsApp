import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CoursesRepository {
  static const _collectionName = 'courses';
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection(_collectionName);

  Stream<List<Course>> watchAll() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Course.fromDoc).toList());
  }

  Future<List<Course>> fetchAllOnce() async {
    final snap =
        await _ref.orderBy('createdAt', descending: true).get();
    return snap.docs.map(Course.fromDoc).toList();
  }

  Stream<List<Course>> watchByCategory(String filter) {
    if (filter == 'Free') {
      return _ref.where('isPaid', isEqualTo: false).snapshots().map(
            (snap) => snap.docs.map(Course.fromDoc).toList(),
          );
    }
    if (filter == 'Paid') {
      return _ref.where('isPaid', isEqualTo: true).snapshots().map(
            (snap) => snap.docs.map(Course.fromDoc).toList(),
          );
    }
    if (filter == 'All') return watchAll();

    // specific category
    return _ref
        .where('category', isEqualTo: filter)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Course.fromDoc).toList());
  }

  Stream<List<Course>> searchCourses(String query) {
    if (query.trim().isEmpty) return watchAll();
    final q = query.toLowerCase();

    return watchAll().map(
      (courses) => courses
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              c.category.toLowerCase().contains(q) ||
              c.topicsCovered.toLowerCase().contains(q))
          .toList(),
    );
  }
}
