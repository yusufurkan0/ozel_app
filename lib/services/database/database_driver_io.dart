import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Windows, Android ve iOS için gerçek disk tabanlı SQLite sürücüsü.
class DatabaseDriver {
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, 'ozel_app_v1.db');
    } catch (_) {
      // Test ortamında veya platform channel erişilemediğinde FFI in-memory veritabanı kullanılır
      dbPath = inMemoryDatabasePath;
    }

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // 1. Kullanıcı Hesapları Tablosu
        await db.execute('''
          CREATE TABLE users (
            username TEXT PRIMARY KEY,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            display_name TEXT NOT NULL,
            avatar TEXT,
            linked_student_username TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // 2. Canlı Konuşma & İletişim Geçmişi Tablosu
        await db.execute('''
          CREATE TABLE speech_logs (
            id TEXT PRIMARY KEY,
            child_name TEXT NOT NULL,
            full_sentence TEXT NOT NULL,
            words_json TEXT,
            emoji TEXT,
            timestamp TEXT NOT NULL
          )
        ''');

        // 3. Kişiye Özel Makaton Kartları Tablosu
        await db.execute('''
          CREATE TABLE custom_cards (
            id TEXT PRIMARY KEY,
            label TEXT NOT NULL,
            category TEXT NOT NULL,
            emoji TEXT,
            icon_code INTEGER,
            color_value INTEGER,
            is_emergency INTEGER DEFAULT 0,
            image_path TEXT,
            custom_audio_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // 4. Günlük Rutinler Tablosu
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            period TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insert(String table, Map<String, dynamic> values) async {
    await init();
    await _db?.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    await init();
    final rows = await _db?.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
    return rows ?? [];
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    await init();
    return await _db?.delete(
          table,
          where: where,
          whereArgs: whereArgs,
        ) ??
        0;
  }
}
