import 'package:cloud_firestore/cloud_firestore.dart';

class NewsVideo {
  final String id;
  final String title;
  final String description;

  /// Multiple categories (e.g. ["Economy", "Geopolitics"])
  final List<String> categories;

  /// Thumbnail image for the card
  final String thumbnailUrl;

  /// YouTube URL or direct .mp4 URL
  final String videoUrl;

  /// Created time for ordering
  final DateTime createdAt;

  NewsVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.categories,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.createdAt,
  });

  String get primaryCategory =>
      categories.isNotEmpty ? categories.first : 'General';

  factory NewsVideo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    List<String> categories = [];
    final rawCats = data['categories'];

    if (rawCats is Iterable) {
      categories = rawCats.map((e) => e.toString()).toList();
    } else if (data['category'] != null) {
      // backward compatibility if only "category" string exists
      categories = [data['category'].toString()];
    }

    return NewsVideo(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      categories: categories,
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'categories': categories,
      'primaryCategory': primaryCategory,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
