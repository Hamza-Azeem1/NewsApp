class Ebook {
  final String id;
  final String title;
  final String? author;
  final String? description;
  final List<String> tags;

  Ebook({required this.id, required this.title, this.author, this.description, this.tags = const []});

  factory Ebook.fromMap(String id, Map<String, dynamic> d) => Ebook(
        id: id,
        title: (d['title'] ?? '') as String,
        author: d['author'] as String?,
        description: d['description'] as String?,
        tags: List<String>.from(d['tags'] ?? const []),
      );
}
