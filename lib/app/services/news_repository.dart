import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/news_article.dart';
import '../models/app_category.dart';
import 'firestore_service.dart';
import '../models/news_video.dart';

class NewsRepository {
  final _fs = FirestoreService.instance;

  /// 🔥 Categories = union of news & video categories
  Stream<List<AppCategory>> streamCategories() {
    return Stream.fromFuture(_loadAllCategories());
  }

  Future<List<AppCategory>> _loadAllCategories() async {
    // use the same FirestoreService wrapper
    final newsSnap = await _fs.col(newsCollection).get();
    final videoSnap = await _fs.col('videos').get();

    final set = <String>{};

    // From news.category
    for (final doc in newsSnap.docs) {
      final cat = (doc.data()['category'] ?? '').toString().trim();
      if (cat.isNotEmpty && cat.toLowerCase() != 'all') {
        set.add(cat);
      }
    }

    // From videos.categories or videos.category
    for (final doc in videoSnap.docs) {
      final data = doc.data();
      final cats = data['categories'];

      if (cats is Iterable) {
        for (final c in cats) {
          final s = c.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'all') {
            set.add(s);
          }
        }
      } else if (data['category'] != null) {
        final s = data['category'].toString().trim();
        if (s.isNotEmpty && s.toLowerCase() != 'all') {
          set.add(s);
        }
      }
    }

    final names = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return names
        .map((n) => AppCategory(id: n.toLowerCase(), name: n))
        .toList();
  }

  /// NEWS: fetch, then sort locally by date desc.
  Stream<List<NewsArticle>> streamNews({String? category}) {
    Query<Map<String, dynamic>> q = _fs.col(newsCollection);
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map((s) {
      final list = s.docs.map(NewsArticle.fromDoc).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// VIDEOS: fetch, optional category filter, sort by createdAt desc.
  Stream<List<NewsVideo>> streamVideos({String? category}) {
    Query<Map<String, dynamic>> q = _fs.col('videos');

    if (category != null && category.isNotEmpty) {
      q = q.where('categories', arrayContains: category);
    }

    return q.snapshots().map((s) {
      final list = s.docs.map(NewsVideo.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
