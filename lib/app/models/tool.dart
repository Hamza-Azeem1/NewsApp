import 'package:cloud_firestore/cloud_firestore.dart';

class Tool {
  final String id;
  final String name;
  final String shortDesc;
  final String description;
  final bool isFree;
  final double? price;
  final String toolLink;
  final String imageUrl;
  final String category; // 👈 NEW
  final DateTime createdAt;

  Tool({
    required this.id,
    required this.name,
    required this.shortDesc,
    required this.description,
    required this.isFree,
    this.price,
    required this.toolLink,
    required this.imageUrl,
    required this.category,
    required this.createdAt,
  });

  /// Empty tool for forms
  factory Tool.empty() {
    final now = DateTime.now();
    return Tool(
      id: '',
      name: '',
      shortDesc: '',
      description: '',
      isFree: true,
      price: null,
      toolLink: '',
      imageUrl: '',
      category: 'General',
      createdAt: now,
    );
  }

  Tool copyWith({
    String? id,
    String? name,
    String? shortDesc,
    String? description,
    bool? isFree,
    double? price,
    String? toolLink,
    String? imageUrl,
    String? category,
    DateTime? createdAt,
  }) {
    return Tool(
      id: id ?? this.id,
      name: name ?? this.name,
      shortDesc: shortDesc ?? this.shortDesc,
      description: description ?? this.description,
      isFree: isFree ?? this.isFree,
      price: price ?? this.price,
      toolLink: toolLink ?? this.toolLink,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Tool.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Tool(
      id: doc.id,
      name: data['name'] ?? '',
      shortDesc: data['shortDesc'] ?? '',
      description: data['description'] ?? '',
      isFree: data['isFree'] ?? true,
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : null,
      toolLink: data['toolLink'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'General', // 👈 NEW, default if old docs
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortDesc': shortDesc,
      'description': description,
      'isFree': isFree,
      'price': price,
      'toolLink': toolLink,
      'imageUrl': imageUrl,
      'category': category, // 👈 NEW
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
