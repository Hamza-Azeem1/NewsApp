import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String topicsCovered;
  final bool isPaid;
  final int? pricePkr;
  final String category; // e.g. "Free", "Paid", "Economy", "Tech"
  final String buyUrl;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.topicsCovered,
    required this.isPaid,
    required this.pricePkr,
    required this.category,
    required this.buyUrl,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.empty() {
    final now = DateTime.now();
    return Course(
      id: '',
      title: '',
      description: '',
      topicsCovered: '',
      isPaid: false,
      pricePkr: null,
      category: 'General',
      buyUrl: '',
      imageUrl: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? topicsCovered,
    bool? isPaid,
    int? pricePkr,
    String? category,
    String? buyUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      topicsCovered: topicsCovered ?? this.topicsCovered,
      isPaid: isPaid ?? this.isPaid,
      pricePkr: pricePkr ?? this.pricePkr,
      category: category ?? this.category,
      buyUrl: buyUrl ?? this.buyUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      topicsCovered: data['topicsCovered'] ?? '',
      isPaid: (data['isPaid'] ?? false) as bool,
      pricePkr: (data['pricePkr'] as num?)?.toInt(),
      category: data['category'] ?? 'General',
      buyUrl: data['buyUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'topicsCovered': topicsCovered,
      'isPaid': isPaid,
      'pricePkr': pricePkr,
      'category': category,
      'buyUrl': buyUrl,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
