import 'package:cloud_firestore/cloud_firestore.dart';

// These collections should match your Firestore setup.
const String newsCollection = 'news';
const String videosCollection = 'videos';

class AdminNewsRepository {
  final _db = FirebaseFirestore.instance;

  Future<String> createNews({
    required String category,
    required String title,
    required String subtitle,
    required String description,
    required DateTime date,
    required String imageUrl,
    String? newsUrl,
  }) async {
    final doc = await _db.collection(newsCollection).add({
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'newsUrl': newsUrl,
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

/// Separate repository for video items used by the admin UI.
class AdminVideosRepository {
  final _db = FirebaseFirestore.instance;

  Future<String> createVideo({
    required String title,
    required String description,
    required List<String> categories,
    required String thumbnailUrl,
    required String videoUrl,
  }) async {
    final doc = await _db.collection(videosCollection).add({
      'title': title,
      'description': description,
      'categories': categories,
      'primaryCategory':
          categories.isNotEmpty ? categories.first : 'General',
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateVideo(String id, Map<String, dynamic> data) async {
    await _db.collection(videosCollection).doc(id).update(data);
  }

  Future<void> deleteVideo(String id) async {
    await _db.collection(videosCollection).doc(id).delete();
  }
}

