import 'package:cloud_firestore/cloud_firestore.dart';

class Ebook {
  final String id;
  final String title;
  final String description;
  final String author;
  final String category;
  final String imageUrl;
  final String buyUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 🔹 Pricing
  final bool isPaid;       // true = paid, false = free
  final double? priceUsd;  // null for free or unknown

  Ebook({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.category,
    required this.imageUrl,
    required this.buyUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isPaid,
    this.priceUsd,
  });

  factory Ebook.empty() {
    final now = DateTime.now();
    return Ebook(
      id: '',
      title: '',
      description: '',
      author: '',
      category: '',
      imageUrl: '',
      buyUrl: '',
      createdAt: now,
      updatedAt: now,
      isPaid: false,
      priceUsd: null,
    );
  }

  Ebook copyWith({
    String? id,
    String? title,
    String? description,
    String? author,
    String? category,
    String? imageUrl,
    String? buyUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPaid,
    double? priceUsd,
  }) {
    return Ebook(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      buyUrl: buyUrl ?? this.buyUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPaid: isPaid ?? this.isPaid,
      priceUsd: priceUsd ?? this.priceUsd,
    );
  }

  factory Ebook.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // backward compatible
    final rawIsPaid = data['isPaid'];
    final bool isPaid = rawIsPaid is bool ? rawIsPaid : false;

    double? priceUsd;
    final rawUsd = data['priceUsd'];
    if (rawUsd is num) {
      priceUsd = rawUsd.toDouble();
    } else {
      // optional: fallback if old docs still have pricePkr
      final rawPkr = data['pricePkr'];
      if (rawPkr is num) {
        priceUsd = rawPkr.toDouble();
      }
    }

    return Ebook(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      buyUrl: data['buyUrl'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: isPaid,
      priceUsd: priceUsd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'author': author,
      'category': category,
      'imageUrl': imageUrl,
      'buyUrl': buyUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPaid': isPaid,
      'priceUsd': priceUsd,
    };
  }
}
