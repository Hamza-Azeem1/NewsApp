import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String topicsCovered;
  final bool isPaid;

  /// 🔥 Price now stored in USD instead of PKR
  final double? priceUsd;

  final String category;
  final String buyUrl;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<String> instructors;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.topicsCovered,
    required this.isPaid,
    required this.priceUsd,
    required this.category,
    required this.buyUrl,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.instructors,
  });

  factory Course.empty() {
    final now = DateTime.now();
    return Course(
      id: '',
      title: '',
      description: '',
      topicsCovered: '',
      isPaid: false,
      priceUsd: null,
      category: 'General',
      buyUrl: '',
      imageUrl: '',
      createdAt: now,
      updatedAt: now,
      instructors: const [],
    );
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? topicsCovered,
    bool? isPaid,
    double? priceUsd,
    String? category,
    String? buyUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? instructors,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      topicsCovered: topicsCovered ?? this.topicsCovered,
      isPaid: isPaid ?? this.isPaid,
      priceUsd: priceUsd ?? this.priceUsd,
      category: category ?? this.category,
      buyUrl: buyUrl ?? this.buyUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      instructors: instructors ?? this.instructors,
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

      /// 🔥 USD stored as double
      priceUsd: (data['priceUsd'] as num?)?.toDouble(),

      category: data['category'] ?? 'General',
      buyUrl: data['buyUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
      instructors: (data['instructors'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'topicsCovered': topicsCovered,
      'isPaid': isPaid,

      /// 🔥 Save USD only
      'priceUsd': priceUsd,

      'category': category,
      'buyUrl': buyUrl,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'instructors': instructors,
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
