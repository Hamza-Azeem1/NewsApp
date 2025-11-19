import 'package:shared_preferences/shared_preferences.dart';

class NewsEngagementService {
  static const _bookmarkKey = 'bookmarked_news_ids';
  static const _likeKey = 'liked_news_ids';

  static Future<Set<String>> _getSet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? <String>[];
    return list.toSet();
  }

  static Future<void> _saveSet(String key, Set<String> set) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, set.toList());
  }

  // BOOKMARKS
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

  // LIKES
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
}
