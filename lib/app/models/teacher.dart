import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String id;
  final String name;
  final String? imageUrl;
  final String? intro;

  /// e.g. ["Math", "Physics"] – legacy field you already use
  final List<String> specializations;

  /// e.g. ["M.Phil in Economics", "10+ years teaching"]
  final List<String> qualifications;

  /// platform label → url (e.g. "LinkedIn" → "https://...")
  final Map<String, String> socials;

  /// NEW: dynamic categories for filters, e.g. ["Economy", "History"]
  final List<String> categories;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Teacher({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.intro,
    required this.specializations,
    required this.qualifications,
    required this.socials,
    required this.categories,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Teacher.empty() {
    final now = DateTime.now();
    return Teacher(
      id: '',
      name: '',
      imageUrl: null,
      intro: null,
      specializations: const [],
      qualifications: const [],
      socials: const {},
      categories: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Teacher copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? intro,
    List<String>? specializations,
    List<String>? qualifications,
    Map<String, String>? socials,
    List<String>? categories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      intro: intro ?? this.intro,
      specializations: specializations ?? this.specializations,
      qualifications: qualifications ?? this.qualifications,
      socials: socials ?? this.socials,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Teacher.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    List<String> stringList(dynamic raw) {
      if (raw is List) {
        return raw.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return <String>[];
    }

    Map<String, String> stringMap(dynamic raw) {
      if (raw is Map) {
        return raw.map((key, value) {
          final k = key?.toString().trim() ?? '';
          final v = value?.toString().trim() ?? '';
          return MapEntry(k, v);
        })
          ..removeWhere((k, v) => k.isEmpty || v.isEmpty);
      }
      return <String, String>{};
    }

    final createdAtRaw = data['createdAt'];
    final updatedAtRaw = data['updatedAt'];

    DateTime date(dynamic v, DateTime fallback) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return fallback;
    }

    final now = DateTime.now();

    return Teacher(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      imageUrl: (data['imageUrl'] as String?)?.trim(),
      intro: (data['intro'] as String?)?.trim(),
      specializations: stringList(data['specializations']),
      qualifications: stringList(data['qualifications']),
      socials: stringMap(data['socials']),
      // NEW: categories list – backwards compatible if missing
      categories: stringList(data['categories']),
      createdAt: date(createdAtRaw, now),
      updatedAt: date(updatedAtRaw, now),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'intro': intro,
      'specializations': specializations,
      'qualifications': qualifications,
      'socials': socials,
      'categories': categories,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
