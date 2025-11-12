class Course {
  final String id;
  final String title;
  final String? intro;
  final List<String> tags; // topics/skills

  Course({required this.id, required this.title, this.intro, this.tags = const []});

  factory Course.fromMap(String id, Map<String, dynamic> d) => Course(
        id: id,
        title: (d['title'] ?? '') as String,
        intro: d['intro'] as String?,
        tags: List<String>.from(d['tags'] ?? const []),
      );
}
