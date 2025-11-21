import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String desc;        // short description / tagline
  final String companyName;
  final String longDesc;
  final String shortDesc;   // used on card
  final String applyLink;
  final String category;
  final String location;    // e.g. "Lahore (Remote)" or "Remote"
  final DateTime createdAt;

  Job({
    required this.id,
    required this.title,
    required this.desc,
    required this.companyName,
    required this.longDesc,
    required this.shortDesc,
    required this.applyLink,
    required this.category,
    required this.location,
    required this.createdAt,
  });

  factory Job.empty() {
    final now = DateTime.now();
    return Job(
      id: '',
      title: '',
      desc: '',
      companyName: '',
      longDesc: '',
      shortDesc: '',
      applyLink: '',
      category: 'General',
      location: 'Remote',
      createdAt: now,
    );
  }

  Job copyWith({
    String? id,
    String? title,
    String? desc,
    String? companyName,
    String? longDesc,
    String? shortDesc,
    String? applyLink,
    String? category,
    String? location,
    DateTime? createdAt,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      companyName: companyName ?? this.companyName,
      longDesc: longDesc ?? this.longDesc,
      shortDesc: shortDesc ?? this.shortDesc,
      applyLink: applyLink ?? this.applyLink,
      category: category ?? this.category,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Job.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Job(
      id: doc.id,
      title: data['title'] ?? '',
      desc: data['desc'] ?? '',
      companyName: data['companyName'] ?? '',
      longDesc: data['longDesc'] ?? '',
      shortDesc: data['shortDesc'] ?? '',
      applyLink: data['applyLink'] ?? '',
      category: data['category'] ?? 'General',
      location: data['location'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'desc': desc,
      'companyName': companyName,
      'longDesc': longDesc,
      'shortDesc': shortDesc,
      'applyLink': applyLink,
      'category': category,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
