import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String category;
  final DateTime date; // safe default if missing
  final String description;
  final String imageUrl;
  final String subtitle;
  final String title;

  NewsArticle({
    required this.id,
    required this.category,
    required this.date,
    required this.description,
    required this.imageUrl,
    required this.subtitle,
    required this.title,
  });

  static DateTime _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
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
    );
  }
}
