import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/news_article.dart';
import '../models/app_category.dart';
import 'firestore_service.dart';
import '../models/news_video.dart';

/// 🔥 Auto delete after 10 days
const int kContentMaxAgeDays = 10;

class NewsRepository {
  final _fs = FirestoreService.instance;

  // =====================
  // StreamControllers
  // =====================
  final _newsController = StreamController<List<NewsArticle>>.broadcast();
  final _videoController = StreamController<List<NewsVideo>>.broadcast();

  // =====================
  // Categories
  // Reads both 'categories' array AND 'primaryCategory'/'category' string
  // fields from news & video docs — matches however docs were written.
  // =====================
  Stream<List<AppCategory>> streamCategories() {
    return Stream.fromFuture(_loadAllCategories());
  }

  Future<List<AppCategory>> _loadAllCategories() async {
    final newsSnap = await _fs.col(newsCollection).get();
    final videoSnap = await _fs.col('videos').get();

    final nameSet = <String>{};

    // ── News docs ──────────────────────────────────────────────────────
    for (final doc in newsSnap.docs) {
      final data = doc.data();

      // 1. categories array (what Firestore actually stores)
      final cats = data['categories'];
      if (cats is List) {
        for (final c in cats) {
          final s = c.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'all') nameSet.add(s);
        }
      }

      // 2. primaryCategory string
      final primary = (data['primaryCategory'] ?? '').toString().trim();
      if (primary.isNotEmpty && primary.toLowerCase() != 'all') {
        nameSet.add(primary);
      }

      // 3. category string (legacy fallback)
      final single = (data['category'] ?? '').toString().trim();
      if (single.isNotEmpty && single.toLowerCase() != 'all') {
        nameSet.add(single);
      }
    }

    // ── Video docs ─────────────────────────────────────────────────────
    for (final doc in videoSnap.docs) {
      final data = doc.data();

      final cats = data['categories'];
      if (cats is List) {
        for (final c in cats) {
          final s = c.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'all') nameSet.add(s);
        }
      }

      final single = (data['category'] ?? '').toString().trim();
      if (single.isNotEmpty && single.toLowerCase() != 'all') {
        nameSet.add(single);
      }
    }

    final names = nameSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return names
        .map((n) => AppCategory(id: n.toLowerCase(), name: n))
        .toList();
  }

  // =====================
  // NEWS STREAM
  // =====================
  Stream<List<NewsArticle>> streamNews({
    String? category,
    int maxAgeDays = kContentMaxAgeDays,
  }) {
    refreshNews(category: category, maxAgeDays: maxAgeDays);
    return _newsController.stream;
  }

  Future<void> refreshNews({
    String? category,
    int maxAgeDays = kContentMaxAgeDays,
  }) async {
    Query<Map<String, dynamic>> q = _fs.col(newsCollection);

    if (category != null && category.isNotEmpty) {
      // ✅ FIX: news docs store categories as an ARRAY field, so we must
      // use arrayContains — NOT isEqualTo (which only works on string fields).
      // isEqualTo was returning 0 results even though docs had the category.
      q = q.where('categories', arrayContains: category);
    }

    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));

    final snap = await q.get();
    final list = snap.docs
        .map(NewsArticle.fromDoc)
        .where((a) => !a.date.isBefore(cutoff))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (!_newsController.isClosed) _newsController.add(list);
  }

  // =====================
  // VIDEO STREAM
  // =====================
  Stream<List<NewsVideo>> streamVideos({
    String? category,
    int maxAgeDays = kContentMaxAgeDays,
  }) {
    refreshVideos(category: category, maxAgeDays: maxAgeDays);
    return _videoController.stream;
  }

  Future<void> refreshVideos({
    String? category,
    int maxAgeDays = kContentMaxAgeDays,
  }) async {
    Query<Map<String, dynamic>> q = _fs.col('videos');

    if (category != null && category.isNotEmpty) {
      // Videos already used arrayContains — keeping it correct
      q = q.where('categories', arrayContains: category);
    }

    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));

    final snap = await q.get();
    final list = snap.docs
        .map(NewsVideo.fromDoc)
        .where((v) => !v.createdAt.isBefore(cutoff))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

       if (!_videoController.isClosed) _videoController.add(list);
  }

  // =====================
  // CLEANUP OLD CONTENT
  // =====================
  Future<void> cleanupOldContent(
      {int maxAgeDays = kContentMaxAgeDays}) async {
    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
    final cutoffTs = Timestamp.fromDate(cutoff);

    final oldNews = await _fs
        .col(newsCollection)
        .where('date', isLessThan: cutoffTs)
        .get();
    final oldVideos = await _fs
        .col('videos')
        .where('createdAt', isLessThan: cutoffTs)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in oldNews.docs) batch.delete(doc.reference);
    for (final doc in oldVideos.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  // =====================
  // Dispose
  // =====================
  void dispose() {
    _newsController.close();
    _videoController.close();
  }
}