import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user_account.dart';
import '../../models/makaton_item.dart';
import '../parent_child_sync_service.dart';
import 'database_platform.dart';

/// 🗄️ Merkezi SQLite Veritabanı Servisi
class AppDatabaseService {
  static final AppDatabaseService _instance = AppDatabaseService._internal();
  factory AppDatabaseService() => _instance;
  AppDatabaseService._internal();

  final DatabaseDriver _driver = DatabaseDriver();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _driver.init();
    _initialized = true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. KULLANICI İŞLEMLERİ (users tablosu)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> saveUser(UserAccount account) async {
    await init();
    await _driver.insert('users', {
      'username': account.username.toLowerCase(),
      'password': account.password,
      'role': account.role.name,
      'display_name': account.displayName,
      'avatar': account.avatar,
      'linked_student_username': account.linkedStudentUsername?.toLowerCase(),
      'created_at': account.createdAt.toIso8601String(),
    });
  }

  Future<UserAccount?> getUser(String username) async {
    await init();
    final rows = await _driver.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.toLowerCase()],
    );
    if (rows.isEmpty) return null;

    final r = rows.first;
    return UserAccount(
      username: r['username'] as String,
      password: r['password'] as String,
      role: UserRole.fromString(r['role'] as String?),
      displayName: r['display_name'] as String? ?? r['username'] as String,
      avatar: r['avatar'] as String? ?? '🦁',
      linkedStudentUsername: r['linked_student_username'] as String?,
      createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Future<List<UserAccount>> getAllUsers() async {
    await init();
    final rows = await _driver.query('users');
    return rows.map((r) {
      return UserAccount(
        username: r['username'] as String,
        password: r['password'] as String,
        role: UserRole.fromString(r['role'] as String?),
        displayName: r['display_name'] as String? ?? r['username'] as String,
        avatar: r['avatar'] as String? ?? '🦁',
        linkedStudentUsername: r['linked_student_username'] as String?,
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. KONUŞMA VE İLETİŞİM GEÇMİŞİ (speech_logs tablosu)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> logSpeech(SyncEvent event) async {
    await init();
    await _driver.insert('speech_logs', {
      'id': event.id,
      'child_name': event.childName,
      'full_sentence': event.data['fullSentence'] ?? event.displayMessage,
      'words_json': jsonEncode(event.data['words'] ?? []),
      'emoji': event.data['emoji'] ?? '🗣️',
      'timestamp': event.timestamp.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentSpeechLogs({int limit = 50}) async {
    await init();
    return await _driver.query(
      'speech_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ÖZEL KARTLAR (custom_cards tablosu)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> saveCustomCard(MakatonItem item) async {
    await init();
    await _driver.insert('custom_cards', {
      'id': item.id,
      'label': item.label,
      'category': item.category.name,
      'emoji': item.emoji,
      'icon_code': item.icon.codePoint,
      'color_value': item.color.toARGB32(),
      'is_emergency': item.isEmergency ? 1 : 0,
      'image_path': item.imagePath,
      'custom_audio_path': item.customAudioPath,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<MakatonItem>> getCustomCards() async {
    await init();
    final rows = await _driver.query('custom_cards');
    return rows.map((r) {
      return MakatonItem(
        id: r['id'] as String,
        label: r['label'] as String,
        category: MakatonCategory.values.firstWhere(
          (c) => c.name == r['category'],
          orElse: () => MakatonCategory.activities,
        ),
        icon: IconData(
          r['icon_code'] as int? ?? Icons.star.codePoint,
          fontFamily: 'MaterialIcons',
        ),
        color: Color(r['color_value'] as int? ?? 0xFF7EB8E0),
        isEmergency: (r['is_emergency'] as int? ?? 0) == 1,
        imagePath: r['image_path'] as String?,
        customAudioPath: r['custom_audio_path'] as String?,
      );
    }).toList();
  }

  Future<void> deleteCustomCard(String id) async {
    await init();
    await _driver.delete('custom_cards', where: 'id = ?', whereArgs: [id]);
  }

  /// Tüm veritabanı tablolarını temizle (Sıfırdan temiz başlangıç)
  Future<void> clearAllTables() async {
    await init();
    await _driver.delete('users');
    await _driver.delete('speech_logs');
    await _driver.delete('custom_cards');
    await _driver.delete('routines');
  }
}
