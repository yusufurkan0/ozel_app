import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/social_story_book.dart';

class SocialStoryService extends ChangeNotifier {
  static final SocialStoryService _instance = SocialStoryService._internal();
  factory SocialStoryService() => _instance;
  SocialStoryService._internal();

  final Map<String, List<SocialStoryBook>> _cachedBooks = {
    'social_story': [],
    'task_list': [],
  };

  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    await loadBooks(type: 'social_story');
    await loadBooks(type: 'task_list');
    _isLoaded = true;
  }

  String _getKey(String type) => 'user_books_$type';

  List<SocialStoryBook> getBooks(String type) {
    return _cachedBooks[type] ?? [];
  }

  Future<List<SocialStoryBook>> loadBooks({required String type}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(type);
      final jsonStr = prefs.getString(key);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        final list = decoded
            .map((item) => SocialStoryBook.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        _cachedBooks[type] = list;
      } else {
        // Kullanıcı isteği: Kütüphane tamamen boş başlar.
        _cachedBooks[type] = [];
      }
      notifyListeners();
      return _cachedBooks[type]!;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToPrefs(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(type);
      final list = _cachedBooks[type] ?? [];
      final encoded = jsonEncode(list.map((b) => b.toMap()).toList());
      await prefs.setString(key, encoded);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveBook(SocialStoryBook book) async {
    final type = book.type;
    final list = _cachedBooks[type] ?? [];
    final index = list.indexWhere((b) => b.id == book.id);
    if (index >= 0) {
      list[index] = book;
    } else {
      list.insert(0, book);
    }
    _cachedBooks[type] = list;
    await _saveToPrefs(type);
  }

  Future<void> deleteBook(String bookId, String type) async {
    final list = _cachedBooks[type] ?? [];
    list.removeWhere((b) => b.id == bookId);
    _cachedBooks[type] = list;
    await _saveToPrefs(type);
  }

  Future<void> addPageToBook(String bookId, SocialStoryPage page, String type) async {
    final list = _cachedBooks[type] ?? [];
    final bookIndex = list.indexWhere((b) => b.id == bookId);
    if (bookIndex >= 0) {
      final book = list[bookIndex];
      page.pageNumber = book.pages.length + 1;
      book.pages.add(page);
      list[bookIndex] = book;
      _cachedBooks[type] = list;
      await _saveToPrefs(type);
    }
  }

  Future<void> updatePage(String bookId, SocialStoryPage page, String type) async {
    final list = _cachedBooks[type] ?? [];
    final bookIndex = list.indexWhere((b) => b.id == bookId);
    if (bookIndex >= 0) {
      final book = list[bookIndex];
      final pageIndex = book.pages.indexWhere((p) => p.id == page.id);
      if (pageIndex >= 0) {
        book.pages[pageIndex] = page;
        list[bookIndex] = book;
        _cachedBooks[type] = list;
        await _saveToPrefs(type);
      }
    }
  }

  Future<void> deletePage(String bookId, String pageId, String type) async {
    final list = _cachedBooks[type] ?? [];
    final bookIndex = list.indexWhere((b) => b.id == bookId);
    if (bookIndex >= 0) {
      final book = list[bookIndex];
      book.pages.removeWhere((p) => p.id == pageId);
      // Sayfa numaralarını yeniden düzenle
      for (int i = 0; i < book.pages.length; i++) {
        book.pages[i].pageNumber = i + 1;
      }
      list[bookIndex] = book;
      _cachedBooks[type] = list;
      await _saveToPrefs(type);
    }
  }

  Future<void> toggleStepDone(String bookId, String pageId, String type) async {
    final list = _cachedBooks[type] ?? [];
    final bookIndex = list.indexWhere((b) => b.id == bookId);
    if (bookIndex >= 0) {
      final book = list[bookIndex];
      final pageIndex = book.pages.indexWhere((p) => p.id == pageId);
      if (pageIndex >= 0) {
        book.pages[pageIndex].isDone = !book.pages[pageIndex].isDone;
        list[bookIndex] = book;
        _cachedBooks[type] = list;
        await _saveToPrefs(type);
      }
    }
  }
}
