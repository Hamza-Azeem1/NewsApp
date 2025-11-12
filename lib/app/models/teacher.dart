import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String id;
  final String name;
  final String? imageUrl;
  final String? intro;
  final List<String> specializations; // chips
  final List<String> qualifications;  // chips
  final Map<String, String> socials;  // label -> url
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Teacher({
    required this.id,
    required this.name,
    this.imageUrl,
    this.intro,
    this.specializations = const [],
    this.qualifications = const [],
    this.socials = const {},
    Timestamp? createdAt,
    Timestamp? updatedAt,
  })  : createdAt = createdAt ?? Timestamp.now(),
        updatedAt = updatedAt ?? Timestamp.now();

  factory Teacher.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Teacher(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      imageUrl: d['imageUrl'] as String?,
      intro: d['intro'] as String?,
      specializations: List<String>.from(d['specializations'] ?? const []),
      qualifications: List<String>.from(d['qualifications'] ?? const []),
      socials: (d['socials'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      createdAt: d['createdAt'] is Timestamp ? d['createdAt'] : Timestamp.now(),
      updatedAt: d['updatedAt'] is Timestamp ? d['updatedAt'] : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'imageUrl': imageUrl,
      'intro': intro,
      'specializations': specializations,
      'qualifications': qualifications,
      'socials': socials,
      'createdAt': createdAt,
      'updatedAt': Timestamp.now(),
    };
  }

  Teacher copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? intro,
    List<String>? specializations,
    List<String>? qualifications,
    Map<String, String>? socials,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      intro: intro ?? this.intro,
      specializations: specializations ?? this.specializations,
      qualifications: qualifications ?? this.qualifications,
      socials: socials ?? this.socials,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
    );
  }
}
