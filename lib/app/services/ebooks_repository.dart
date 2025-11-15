import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ebook.dart';

class EbooksRepository {
  static const String collectionPath = 'ebooks';

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(collectionPath);

  Stream<List<Ebook>> streamEbooks({String? category}) {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ebook.fromDoc(doc)).toList(),
        );
  }

  Future<List<Ebook>> fetchOnce({String? category}) async {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Ebook.fromDoc(doc)).toList();
  }

  Future<void> addEbook(Ebook ebook) async {
    final now = DateTime.now();
    final docRef = _collection.doc();

    final toSave = ebook.copyWith(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(toSave.toMap());
  }

  Future<void> updateEbook(Ebook ebook) async {
    final docRef = _collection.doc(ebook.id);
    final updated = ebook.copyWith(updatedAt: DateTime.now());
    await docRef.update(updated.toMap());
  }

  Future<void> deleteEbook(String id) async {
    await _collection.doc(id).delete();
  }
}
