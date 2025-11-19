import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CoursesRepository {
  static const _collectionName = 'courses';
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection(_collectionName);

  Stream<List<Course>> watchAll() {
    // This query is fine because it only has orderBy (no where clause)
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
    if (filter == 'All') return watchAll();

    // ---------------------------------------------------------
    // FIX APPLIED BELOW:
    // We removed .orderBy() from the Firestore query and added
    // .sort() inside the Dart code. This prevents the Index Error.
    // ---------------------------------------------------------

    if (filter == 'Free') {
      return _ref
          .where('isPaid', isEqualTo: false)
          .snapshots()
          .map((snap) {
            final courses = snap.docs.map(Course.fromDoc).toList();
            // Sort in app: Newest first
            courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return courses;
          });
    }

    if (filter == 'Paid') {
      return _ref
          .where('isPaid', isEqualTo: true)
          .snapshots()
          .map((snap) {
            final courses = snap.docs.map(Course.fromDoc).toList();
            // Sort in app: Newest first
            courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return courses;
          });
    }

    // specific category (This was the one crashing)
    return _ref
        .where('category', isEqualTo: filter)
        // REMOVED: .orderBy('createdAt', descending: true) <--- This caused the crash
        .snapshots()
        .map((snap) {
          final courses = snap.docs.map(Course.fromDoc).toList();
          // Sort in app: Newest first
          courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return courses;
        });
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