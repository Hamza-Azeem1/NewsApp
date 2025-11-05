import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app/core/constants.dart' show newsCollection;
import 'news_editor_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection(newsCollection)
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewsEditorScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add News'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No news yet. Click “Add News”.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final id = docs[i].id;
              final title = (d['title'] ?? '') as String;
              final subtitle = (d['subtitle'] ?? '') as String;
              final category = (d['category'] ?? '') as String;
              final date = (d['date'] is Timestamp)
                  ? (d['date'] as Timestamp).toDate()
                  : null;

              return ListTile(
                leading: const Icon(Icons.article_rounded),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('$category • $subtitle', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  date?.toLocal().toString().split('.').first ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  // Optional: open an editor with existing values (not requested).
                  // You can implement edit later.
                },
                onLongPress: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete this news?'),
                      content: Text(title),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await FirebaseFirestore.instance.collection(newsCollection).doc(id).delete();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
