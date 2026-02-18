import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;

  /// Multi-category support
  final List<String> categories;

  /// Optional primaryCategory for sorting
  final String primaryCategory;

  final DateTime date;
  final String description;
  final String imageUrl;
  final String subtitle;
  final String title;

  /// External link
  final String? newsUrl;

  NewsArticle({
    required this.id,
    required this.categories,
    required this.primaryCategory,
    required this.date,
    required this.description,
    required this.imageUrl,
    required this.subtitle,
    required this.title,
    this.newsUrl,
  });

  // ------------------------------------------
  // COPYWITH
  // ------------------------------------------
  NewsArticle copyWith({
    String? id,
    List<String>? categories,
    String? primaryCategory,
    DateTime? date,
    String? description,
    String? imageUrl,
    String? subtitle,
    String? title,
    String? newsUrl,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      categories: categories ?? this.categories,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      date: date ?? this.date,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      subtitle: subtitle ?? this.subtitle,
      title: title ?? this.title,
      newsUrl: newsUrl ?? this.newsUrl,
    );
  }

  // ------------------------------------------
  // PARSE DATE
  // ------------------------------------------
  static DateTime _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    return DateTime.now();
  }

  // ------------------------------------------
  // FROM FIRESTORE
  // ------------------------------------------
  factory NewsArticle.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // 1) MULTI category
    List<String> cats = [];
    if (data['categories'] is List) {
      cats = List<String>.from(data['categories']);
    }

    // 2) FALLBACK for old single 'category'
    if (cats.isEmpty && data['category'] is String) {
      final c = data['category'].toString().trim();
      if (c.isNotEmpty) cats = [c];
    }

    // 3) Ensure at least one category
    if (cats.isEmpty) cats = ['General'];

    return NewsArticle(
      id: doc.id,
      categories: cats,
      primaryCategory: data['primaryCategory']?.toString() ?? cats.first,
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

  // ------------------------------------------
  // TO MAP
  // ------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'categories': categories,
      'primaryCategory': categories.isNotEmpty ? categories.first : "General",
      'date': Timestamp.fromDate(date),
      'description': description,
      'imageUrl': imageUrl,
      'subtitle': subtitle,
      'title': title,
      'newsUrl': newsUrl,
    };
  }
}
