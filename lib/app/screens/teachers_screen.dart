import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/teachers_repository.dart';
import '../widgets/teacher_card.dart';

class TeachersScreen extends StatefulWidget {
  TeachersScreen({super.key});
  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final repo = TeachersRepository();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Our Teachers'), centerTitle: true),
      body: Column(
        children: [
          // 🔍 Inline search bar (same look as Home)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 6),

          // List/Grid content
          Expanded(
            child: StreamBuilder<List<Teacher>>(
              stream: repo.watchAll(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                final all = snap.data!;
                final q = _query;
                bool contains(String s) => s.toLowerCase().contains(q);
                bool inList(List<String> l) => l.any((x) => contains(x));
                bool inMap(Map<String, String> m) =>
                    m.entries.any((e) => contains(e.key) || contains(e.value));

                final list = q.isEmpty
                    ? all
                    : all.where((t) {
                        return contains(t.name) ||
                            contains(t.intro ?? '') ||
                            inList(t.specializations) ||
                            inList(t.qualifications) ||
                            inMap(t.socials);
                      }).toList();

                if (list.isEmpty) return const Center(child: Text('No teachers matched your search.'));

                return LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final isMobile  = w < 600;
                    final isDesktop = w >= 1100;

                    // Phones: natural-height list (no overflow)
                    if (isMobile) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => TeacherCard(t: list[i]),
                      );
                    }

                    // Tablet/Desktop: grid with fixed row height
                    final crossAxisCount = isDesktop ? 3 : 2;
                    const tileHeight = 420.0; // enough for avatar + chips

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: tileHeight,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => TeacherCard(t: list[i]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
