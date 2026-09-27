import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Web ve desteklenmeyen platformlar için SQLite uyumlu in-memory/prefs sürücüsü.
class DatabaseDriver {
  static const String _prefDbKey = 'app_local_sqlite_fallback_v1';
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'users': [],
    'speech_logs': [],
    'custom_cards': [],
    'routines': [],
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefDbKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final k in map.keys) {
          final list = (map[k] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _tables[k] = list;
        }
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDbKey, jsonEncode(_tables));
  }

  Future<void> insert(String table, Map<String, dynamic> values) async {
    _tables.putIfAbsent(table, () => []);
    // Primary key 'id' veya 'username' varsa güncelle veya ekle
    final pk = values['username'] ?? values['id'];
    if (pk != null) {
      _tables[table]!.removeWhere((row) => (row['username'] ?? row['id']) == pk);
    }
    _tables[table]!.add(Map<String, dynamic>.from(values));
    await _persist();
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final rows = _tables[table] ?? [];
    var result = List<Map<String, dynamic>>.from(rows);

    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      if (where.contains('username = ?')) {
        final target = whereArgs.first.toString().toLowerCase();
        result = result.where((r) => r['username']?.toString().toLowerCase() == target).toList();
      } else if (where.contains('id = ?')) {
        final target = whereArgs.first.toString();
        result = result.where((r) => r['id']?.toString() == target).toList();
      }
    }

    if (orderBy != null && orderBy.contains('DESC')) {
      result = result.reversed.toList();
    }

    if (limit != null && result.length > limit) {
      result = result.sublist(0, limit);
    }

    return result;
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    if (_tables[table] == null) return 0;
    final prevCount = _tables[table]!.length;

    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      if (where.contains('id = ?')) {
        final target = whereArgs.first.toString();
        _tables[table]!.removeWhere((r) => r['id']?.toString() == target);
      } else if (where.contains('username = ?')) {
        final target = whereArgs.first.toString().toLowerCase();
        _tables[table]!.removeWhere((r) => r['username']?.toString().toLowerCase() == target);
      }
    } else {
      _tables[table]!.clear();
    }

    await _persist();
    return prevCount - _tables[table]!.length;
  }
}
