import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String category;
  final DateTime date;
  final String description;
  final String imageUrl;
  final String subtitle;
  final String title;

  /// 🔗 NEW – external link for full news
  final String? newsUrl;

  NewsArticle({
    required this.id,
    required this.category,
    required this.date,
    required this.description,
    required this.imageUrl,
    required this.subtitle,
    required this.title,
    this.newsUrl,
  });

  NewsArticle copyWith({
    String? id,
    String? category,
    DateTime? date,
    String? description,
    String? imageUrl,
    String? subtitle,
    String? title,
    String? newsUrl,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      subtitle: subtitle ?? this.subtitle,
      title: title ?? this.title,
      newsUrl: newsUrl ?? this.newsUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'date': Timestamp.fromDate(date),
      'description': description,
      'imageUrl': imageUrl,
      'subtitle': subtitle,
      'title': title,
      'newsUrl': newsUrl,
    };
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) {
      // assume millis
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    return DateTime.now();
  }

  factory NewsArticle.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return NewsArticle(
      id: doc.id,
      category: (data['category'] ?? '').toString(),
      date: _parseDate(data['date']),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      newsUrl: (data['newsUrl'] ?? data['url'] ?? '').toString().trim().isEmpty
          ? null
          : (data['newsUrl'] ?? data['url']).toString(),
    );
  }
}
