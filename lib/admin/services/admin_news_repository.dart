import 'package:cloud_firestore/cloud_firestore.dart';

// If you already have core/constants.dart with this constant, import it instead:
// import '../../core/constants.dart' show newsCollection;
const String newsCollection = 'news';

class AdminNewsRepository {
  final _db = FirebaseFirestore.instance;

  Future<String> createNews({
    required String category,
    required String title,
    required String subtitle,
    required String description,
    required DateTime date,
    required String imageUrl,
  }) async {
    final doc = _db.collection(newsCollection).doc();
    await doc.set({
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
    });
    return doc.id;
  }

  Future<void> updateNews(String id, Map<String, dynamic> data) async {
    await _db.collection(newsCollection).doc(id).update(data);
  }

  Future<void> deleteNews(String id) async {
    await _db.collection(newsCollection).doc(id).delete();
  }
}
