import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/teacher.dart';

class TeachersRepository {
  TeachersRepository._();
  static final instance = TeachersRepository._();

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
}
