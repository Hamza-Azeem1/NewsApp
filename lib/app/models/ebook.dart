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
  final bool isPaid;      // true = paid, false = free
  final int? pricePkr;    // null for free or unknown

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
    this.pricePkr,
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
      pricePkr: null,
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
    int? pricePkr,
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
      pricePkr: pricePkr ?? this.pricePkr,
    );
  }

  factory Ebook.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // backward compatible
    final rawIsPaid = data['isPaid'];
    final bool isPaid = rawIsPaid is bool ? rawIsPaid : false;

    int? pricePkr;
    final rawPrice = data['pricePkr'];
    if (rawPrice is int) {
      pricePkr = rawPrice;
    } else if (rawPrice is num) {
      pricePkr = rawPrice.toInt();
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
      pricePkr: pricePkr,
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPaid': isPaid,
      'pricePkr': pricePkr,
    };
  }
}
