import 'dart:convert';

/// Sosyal Öykü veya Görev Kitabının tek bir sayfası
class SocialStoryPage {
  final String id;
  String text;
  String? imagePath;
  String? audioPath;
  bool isDone;
  int pageNumber;

  SocialStoryPage({
    required this.id,
    required this.text,
    this.imagePath,
    this.audioPath,
    this.isDone = false,
    required this.pageNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'imagePath': imagePath,
      'audioPath': audioPath,
      'isDone': isDone,
      'pageNumber': pageNumber,
    };
  }

  factory SocialStoryPage.fromMap(Map<String, dynamic> map) {
    return SocialStoryPage(
      id: map['id'] as String? ?? 'page_${DateTime.now().millisecondsSinceEpoch}',
      text: map['text'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      audioPath: map['audioPath'] as String?,
      isDone: map['isDone'] as bool? ?? false,
      pageNumber: map['pageNumber'] as int? ?? 1,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory SocialStoryPage.fromJson(String source) =>
      SocialStoryPage.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Sosyal Öykü veya Görev Kitabı Modeli
class SocialStoryBook {
  final String id;
  String title;
  String? coverImagePath;
  int coverColorValue;
  List<SocialStoryPage> pages;
  final DateTime createdAt;
  final String type; // 'social_story' veya 'task_list'

  SocialStoryBook({
    required this.id,
    required this.title,
    this.coverImagePath,
    this.coverColorValue = 0xFF7C3AED, // Default Mor
    List<SocialStoryPage>? pages,
    DateTime? createdAt,
    this.type = 'social_story',
  })  : pages = pages ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverImagePath': coverImagePath,
      'coverColorValue': coverColorValue,
      'pages': pages.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'type': type,
    };
  }

  factory SocialStoryBook.fromMap(Map<String, dynamic> map) {
    return SocialStoryBook(
      id: map['id'] as String? ?? 'book_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? 'Yeni Kitap',
      coverImagePath: map['coverImagePath'] as String?,
      coverColorValue: map['coverColorValue'] as int? ?? 0xFF7C3AED,
      pages: (map['pages'] as List<dynamic>?)
              ?.map((p) => SocialStoryPage.fromMap(Map<String, dynamic>.from(p as Map)))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      type: map['type'] as String? ?? 'social_story',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory SocialStoryBook.fromJson(String source) =>
      SocialStoryBook.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
