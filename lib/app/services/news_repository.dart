import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/news_article.dart';
import '../models/app_category.dart';
import 'firestore_service.dart';

class NewsRepository {
  final _fs = FirestoreService.instance;

  // Categories: use collection if exists, else derive from news
  Stream<List<AppCategory>> streamCategories() async* {
    final catRef = _fs.col(categoriesCollection).orderBy('name');
    await for (final snap in catRef.snapshots()) {
      final items = snap.docs.map((d) => AppCategory.fromMap(d.id, d.data())).toList();
      if (items.isNotEmpty) {
        yield items;
      } else {
        yield* _derivedCategoriesFromNews();
      }
    }
  }

  Stream<List<AppCategory>> _derivedCategoriesFromNews() {
    return _fs.col(newsCollection).snapshots().map((s) {
      final set = <String>{};
      for (final d in s.docs) {
        final n = (d.data()['category'] ?? '').toString().trim();
        if (n.isNotEmpty) set.add(n);
      }
      final names = set.toList()..sort();
      return names.map((n) => AppCategory(id: n, name: n)).toList();
    });
  }

  // NEWS: no server orderBy; fetch all, sort locally by date desc.
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
}
