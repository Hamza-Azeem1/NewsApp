import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/models/app_category.dart';

class CategoriesRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('categories');

  Stream<List<AppCategory>> streamCategories() {
    return _collection.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppCategory.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<AppCategory>> fetchOnce() async {
    final snap = await _collection.orderBy('name').get();
    return snap.docs
        .map((doc) => AppCategory.fromMap(doc.id, doc.data()))
        .toList();
  }
}
