import 'package:flutter/material.dart';

import '../models/news_article.dart';
import '../services/news_repository.dart';
import '../services/news_engagement_service.dart';
import '../widgets/news_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _repo = NewsRepository();
  Set<String> _bookmarkIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final ids = await NewsEngagementService.getBookmarks();
    if (!mounted) return;
    setState(() => _bookmarkIds = ids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved articles'),
      ),
      body: StreamBuilder<List<NewsArticle>>(
        stream: _repo.streamNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final all = snapshot.data ?? [];
          final saved =
              all.where((n) => _bookmarkIds.contains(n.id)).toList();

          if (saved.isEmpty) {
            return const Center(
              child: Text('No bookmarks yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadBookmarks,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: saved.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NewsCard(article: saved[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
