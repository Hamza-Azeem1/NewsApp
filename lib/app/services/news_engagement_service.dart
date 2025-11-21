import 'package:shared_preferences/shared_preferences.dart';

class NewsEngagementService {
  static const _bookmarkKey = 'bookmarked_news_ids';
  static const _likeKey = 'liked_news_ids';

  // prefix for storing per-article like counts
  static const _likeCountPrefix = 'like_count_';

  // --------------------
  // Internal helpers
  // --------------------

  static Future<Set<String>> _getSet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? <String>[];
    return list.toSet();
  }

  static Future<void> _saveSet(String key, Set<String> set) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, set.toList());
  }

  // --------------------
  // BOOKMARKS
  // --------------------

  static Future<Set<String>> getBookmarks() async => _getSet(_bookmarkKey);

  static Future<bool> isBookmarked(String id) async {
    final set = await _getSet(_bookmarkKey);
    return set.contains(id);
  }

  static Future<bool> toggleBookmark(String id) async {
    final set = await _getSet(_bookmarkKey);
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await _saveSet(_bookmarkKey, set);
    return set.contains(id);
  }

  // --------------------
  // LIKES (per-article, per-device)
  // --------------------

  static Future<bool> isLiked(String id) async {
    final set = await _getSet(_likeKey);
    return set.contains(id);
  }

  static Future<bool> toggleLike(String id) async {
    final set = await _getSet(_likeKey);
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await _saveSet(_likeKey, set);
    return set.contains(id);
  }

  // --------------------
  // LIKE COUNTS (stored locally per device)
  // --------------------

  /// Returns the stored like count for this article on this device.
  static Future<int> getLikeCount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_likeCountPrefix$id') ?? 0;
  }

  /// Toggles like status AND updates the local like counter.
  /// Returns the updated like count.
  static Future<int> toggleLikeAndGetCount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_likeCountPrefix$id';

    // current count for this article on this device
    int current = prefs.getInt(key) ?? 0;

    // are we currently liked?
    final likedNow = await isLiked(id);

    // if already liked, unlike and decrement; else like and increment
    if (likedNow) {
      if (current > 0) current -= 1;
    } else {
      current += 1;
    }

    await prefs.setInt(key, current);

    // flip like state in the set
    await toggleLike(id);

    return current;
  }
}
