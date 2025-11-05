class AppCategory {
  final String id;
  final String name;

  AppCategory({required this.id, required this.name});

  factory AppCategory.fromMap(String id, Map<String, dynamic> data) {
    return AppCategory(id: id, name: (data['name'] ?? '').toString());
  }
}
