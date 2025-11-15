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
    );
  }

  factory Ebook.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Ebook(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      buyUrl: data['buyUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    };
  }
}
