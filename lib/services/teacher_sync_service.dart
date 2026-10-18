import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Öğretmen ve Yönetici Portalı Canlı Senkronizasyon Servisi
/// Google Firebase Firestore (ozel-app-4ee23) ve Yerel Ağ Sunucusu üzerinden
/// çift yönlü, kesintisiz 7/24 bulut bağlantısı sağlar.
class TeacherSyncService {
  static final TeacherSyncService instance = TeacherSyncService._();
  TeacherSyncService._();

  static const int defaultPort = 8085;
  static const String firestoreProjectId = 'ozel-app-4ee23';

  /// Firestore REST API Document URL oluşturucu
  Uri _firestoreDocUri(String collection, String docId) {
    return Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents/$collection/$docId',
    );
  }

  /// Dart verisini Firestore REST Field formatına dönüştürücü
  Map<String, dynamic> _encodeFirestoreFields(Map<String, dynamic> raw) {
    final fields = <String, dynamic>{};
    raw.forEach((key, val) {
      if (val == null) {
        fields[key] = {'nullValue': null};
      } else if (val is bool) {
        fields[key] = {'booleanValue': val};
      } else if (val is int) {
        fields[key] = {'integerValue': val.toString()};
      } else if (val is double) {
        fields[key] = {'doubleValue': val};
      } else if (val is String) {
        fields[key] = {'stringValue': val};
      } else if (val is List) {
        fields[key] = {
          'arrayValue': {
            'values': val.map((item) {
              if (item is Map) {
                return {
                  'mapValue': {
                    'fields': _encodeFirestoreFields(Map<String, dynamic>.from(item)),
                  }
                };
              }
              return {'stringValue': item.toString()};
            }).toList()
          }
        };
      } else if (val is Map) {
        fields[key] = {
          'mapValue': {
            'fields': _encodeFirestoreFields(Map<String, dynamic>.from(val)),
          }
        };
      } else {
        fields[key] = {'stringValue': val.toString()};
      }
    });
    return fields;
  }

  /// Sunucu URL aday listesini oluştur
  Future<List<String>> _getCandidateUrls() async {
    final list = <String>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString('teacher_sync_server_url');
      if (customUrl != null && customUrl.trim().isNotEmpty) {
        list.add(customUrl.trim());
      }
    } catch (_) {}

    if (kIsWeb) {
      list.addAll([
        'http://127.0.0.1:$defaultPort',
        'http://localhost:$defaultPort',
        'http://192.168.1.103:$defaultPort',
      ]);
      return list.toSet().toList();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      list.addAll([
        'http://10.0.2.2:$defaultPort',
        'http://192.168.1.103:$defaultPort',
        'http://127.0.0.1:$defaultPort',
      ]);
    } else {
      list.addAll([
        'http://127.0.0.1:$defaultPort',
        'http://localhost:$defaultPort',
        'http://192.168.1.103:$defaultPort',
      ]);
    }
    return list.toSet().toList();
  }

  /// Sunucu URL'sini belirle
  Future<String> getBaseUrl() async {
    final urls = await _getCandidateUrls();
    return urls.isNotEmpty ? urls.first : 'http://127.0.0.1:$defaultPort';
  }

  /// Sunucu URL'sini elle değiştirmek için
  Future<void> setServerUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('teacher_sync_server_url', url.trim());
    } catch (_) {}
  }

  /// Çocuğun profilini / öğrencisini Firebase Bulutuna ve Öğretmen Paneline kaydet
  Future<bool> registerStudent({
    required String name,
    String? age,
    String? diagnosis,
    String? parentName,
    String? parentPhone,
    String? avatar,
    String? address,
    String? notes,
    http.Client? client,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;

    try {
      final cleanAge = int.tryParse((age ?? '').replaceAll(RegExp(r'\D'), '')) ?? 14;
      final docId = 'std_${cleanName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

      final payload = {
        'id': docId,
        'name': cleanName,
        'avatar': (avatar != null && avatar.trim().isNotEmpty) ? avatar.trim() : '🧒',
        'age': cleanAge,
        'diagnosis': (diagnosis != null && diagnosis.trim().isNotEmpty)
            ? diagnosis.trim()
            : 'Özel Eğitim Öğrencisi',
        'parentName': (parentName != null && parentName.trim().isNotEmpty)
            ? parentName.trim()
            : 'Veli',
        'parentPhone': (parentPhone != null && parentPhone.trim().isNotEmpty)
            ? parentPhone.trim()
            : 'Belirtilmedi',
        'address': address ?? '',
        'notes': notes ?? '',
        'cashBudget': 500,
        'cardLimit': 1000,
        'cardRemaining': 1000,
        'lastActive': 'Şimdi Aktif',
        'streakDays': 1,
      };

      final httpClient = client ?? http.Client();
      bool anySuccess = false;

      try {
        // 1. Google Firebase Firestore Bulutuna Gönder (7/24 Kesintisiz)
        try {
          final firestoreUri = _firestoreDocUri('students', docId);
          final firestoreBody = jsonEncode({
            'fields': _encodeFirestoreFields(payload),
          });

          final fsResponse = await httpClient
              .patch(
                firestoreUri,
                headers: {'Content-Type': 'application/json'},
                body: firestoreBody,
              )
              .timeout(const Duration(seconds: 4));

          if (fsResponse.statusCode == 200) {
            anySuccess = true;
            debugPrint('TeacherSyncService: Firebase Firestore Bulutuna başarıyla kaydedildi: $cleanName');
          }
        } catch (e) {
          debugPrint('TeacherSyncService Firestore sync hatası: $e');
        }

        // 2. Yerel Ağ / Bilgisayar Sunucusuna Gönder
        final localBody = jsonEncode(payload);
        final urls = await _getCandidateUrls();

        for (final baseUrl in urls) {
          try {
            final uri = Uri.parse('$baseUrl/api/students');
            final response = await httpClient
                .post(
                  uri,
                  headers: {'Content-Type': 'application/json; charset=utf-8'},
                  body: localBody,
                )
                .timeout(const Duration(seconds: 3));

            if (response.statusCode == 200) {
              await setServerUrl(baseUrl);
              anySuccess = true;
              break;
            }
          } catch (_) {}
        }
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }

      return anySuccess;
    } catch (e) {
      debugPrint('TeacherSyncService registerStudent genel hatası: $e');
    }
    return false;
  }

  /// Cihazdaki mevcut öğrenci bilgilerini buluta ve panele senkronize et
  Future<void> syncCurrentStudent({http.Client? client}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childName = prefs.getString('child_name') ??
          prefs.getString('sos_child_name') ??
          prefs.getString('user_emergency_name');

      if (childName == null || childName.trim().isEmpty) return;

      final childAge = prefs.getString('sos_child_age') ?? '';
      final diagnosis = prefs.getString('child_diagnosis') ?? '';
      final parentName = prefs.getString('sos_parent_name') ?? '';
      final parentPhone = prefs.getString('sos_parent_phone') ??
          prefs.getString('user_emergency_phone') ??
          '';
      final avatar = prefs.getString('avatar') ?? '🧒';
      final address = prefs.getString('sos_home_address') ?? prefs.getString('user_home_address') ?? '';
      final notes = prefs.getString('sos_medical_notes') ?? prefs.getString('user_emergency_notes') ?? '';

      await registerStudent(
        name: childName,
        age: childAge,
        diagnosis: diagnosis,
        parentName: parentName,
        parentPhone: parentPhone,
        avatar: avatar,
        address: address,
        notes: notes,
        client: client,
      );
    } catch (e) {
      debugPrint('TeacherSyncService syncCurrentStudent hatası: $e');
    }
  }

  /// Çocuğun tamamladığı formu Firebase Bulutuna ve Öğretmen Paneline Gönder
  Future<bool> sendEvaluationForm({
    required String formType,
    required String formTitle,
    required Map<String, dynamic> answers,
    String? mood,
    http.Client? client,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childName = prefs.getString('child_name') ??
          prefs.getString('sos_child_name') ??
          prefs.getString('user_emergency_name') ??
          'Özel Öğrenci';

      final formattedAnswers = answers.entries.map((e) {
        return {
          'q': e.key,
          'a': e.value.toString(),
        };
      }).toList();

      final now = DateTime.now();
      final evalId = 'eval_${now.millisecondsSinceEpoch}';
      final payload = {
        'id': evalId,
        'studentName': childName,
        'studentAvatar': '🧒',
        'formType': formType,
        'formTitle': formTitle,
        'mood': mood ?? 'Mutlu 😊',
        'date': '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'status': 'pending',
        'teacherNote': '',
        'answers': formattedAnswers,
      };

      final httpClient = client ?? http.Client();
      bool anySuccess = false;

      try {
        // 1. Firebase Firestore Bulutuna Gönder
        try {
          final firestoreUri = _firestoreDocUri('evaluations', evalId);
          final firestoreBody = jsonEncode({
            'fields': _encodeFirestoreFields(payload),
          });

          final fsResponse = await httpClient
              .patch(
                firestoreUri,
                headers: {'Content-Type': 'application/json'},
                body: firestoreBody,
              )
              .timeout(const Duration(seconds: 4));

          if (fsResponse.statusCode == 200) {
            anySuccess = true;
            debugPrint('TeacherSyncService: Anket Firebase Firestore Bulutuna iletildi: $evalId');
          }
        } catch (e) {
          debugPrint('TeacherSyncService Firestore eval hatası: $e');
        }

        // 2. Yerel Ağ / Bilgisayar Sunucusuna Gönder
        final localBody = jsonEncode(payload);
        final urls = await _getCandidateUrls();

        for (final baseUrl in urls) {
          try {
            final uri = Uri.parse('$baseUrl/api/evaluations');
            final response = await httpClient
                .post(
                  uri,
                  headers: {'Content-Type': 'application/json; charset=utf-8'},
                  body: localBody,
                )
                .timeout(const Duration(seconds: 3));

            if (response.statusCode == 200) {
              await setServerUrl(baseUrl);
              anySuccess = true;
              break;
            }
          } catch (_) {}
        }
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }

      return anySuccess;
    } catch (e) {
      debugPrint('TeacherSyncService: Canlı panele gönderilemedi: $e');
    }
    return false;
  }
  /// Firestore REST Fields decode edici
  Map<String, dynamic> _decodeFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((k, v) {
      if (v is Map) {
        if (v.containsKey('stringValue')) {
          result[k] = v['stringValue'];
        } else if (v.containsKey('integerValue')) {
          result[k] = int.tryParse(v['integerValue'].toString()) ?? 0;
        } else if (v.containsKey('booleanValue')) {
          result[k] = v['booleanValue'];
        } else if (v.containsKey('doubleValue')) {
          result[k] = v['doubleValue'];
        } else if (v.containsKey('nullValue')) {
          result[k] = null;
        } else if (v.containsKey('arrayValue')) {
          final arr = v['arrayValue']['values'] as List? ?? [];
          result[k] = arr.map((item) {
            if (item is Map && item.containsKey('stringValue')) return item['stringValue'];
            return item.toString();
          }).toList();
        } else {
          result[k] = v.values.isNotEmpty ? v.values.first : null;
        }
      } else {
        result[k] = v;
      }
    });
    return result;
  }

  /// Öğretmenin web panelinden çocuğa atadığı canlı görevleri Firebase Bulutundan getir
  Future<List<Map<String, dynamic>>> fetchTasksForStudent({
    String? studentName,
    http.Client? client,
  }) async {
    final tasks = <Map<String, dynamic>>[];
    final httpClient = client ?? http.Client();
    final targetName = (studentName ?? '').trim().toLowerCase();

    // 1. Google Firebase Firestore Bulutundan Çek (7/24 Canlı)
    try {
      final uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents/tasks',
      );
      final resp = await httpClient.get(uri).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final docs = data['documents'] as List? ?? [];

        for (final doc in docs) {
          final rawFields = doc['fields'] as Map<String, dynamic>? ?? {};
          final task = _decodeFirestoreFields(rawFields);
          final docName = doc['name'] as String? ?? '';
          task['id'] = task['id'] ?? docName.split('/').last;

          final sName = (task['studentName'] ?? '').toString().trim().toLowerCase();
          final sId = (task['studentId'] ?? '').toString().trim().toLowerCase();

          if (targetName.isEmpty || sName.isEmpty || sName == targetName || targetName.contains(sName) || sName.contains(targetName) || sId.contains(targetName)) {
            tasks.add(task);
          }
        }
        if (tasks.isNotEmpty) return tasks;
      }
    } catch (e) {
      debugPrint('TeacherSyncService fetchTasks Firestore hatası: $e');
    }

    // 2. Yerel Ağ / Bilgisayar Sunucusundan Çek (Yedek Hat)
    try {
      final urls = await _getCandidateUrls();
      for (final baseUrl in urls) {
        try {
          final uri = Uri.parse('$baseUrl/api/tasks');
          final resp = await httpClient.get(uri).timeout(const Duration(seconds: 3));
          if (resp.statusCode == 200) {
            final list = jsonDecode(resp.body) as List? ?? [];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final sName = (item['studentName'] ?? '').toString().trim().toLowerCase();
                if (targetName.isEmpty || sName.isEmpty || sName == targetName || targetName.contains(sName) || sName.contains(targetName)) {
                  tasks.add(Map<String, dynamic>.from(item));
                }
              }
            }
            if (tasks.isNotEmpty) return tasks;
          }
        } catch (_) {}
      }
    } catch (_) {}

    return tasks;
  }

  /// Görevin tamamlanma durumunu hem buluta hem panele anında senkronize et
  Future<bool> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    bool anySuccess = false;

    // 1. Firebase Firestore'u Güncelle (Bulut)
    try {
      final uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents/tasks/$taskId?updateMask.fieldPaths=isCompleted',
      );
      final body = jsonEncode({
        'fields': {
          'isCompleted': {'booleanValue': isCompleted},
        }
      });
      final resp = await httpClient.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        anySuccess = true;
        debugPrint('TeacherSyncService: Görev durumu Firestore Bulutunda güncellendi: $taskId -> $isCompleted');
      }
    } catch (e) {
      debugPrint('TeacherSyncService toggleTask Firestore hatası: $e');
    }

    return anySuccess;
  }
}
