import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/services/teacher_sync_service.dart';

void main() {
  test('TeacherSyncService live sync sends evaluation to server', () async {
    SharedPreferences.setMockInitialValues({
      'child_name': 'Ahmet Can',
      'teacher_sync_server_url': 'http://127.0.0.1:8085',
    });

    final mockClient = MockClient((request) async {
      return http.Response('{"success": true}', 200);
    });

    final success = await TeacherSyncService.instance.sendEvaluationForm(
      formType: 'okul',
      formTitle: 'Kendi Kendine Gözlem Formu - Okul',
      answers: {
        'okul_vaktinde_gittim_mi': 'Evet',
        'okul_dersler_nasildi': 'Eğlenceliydi',
      },
      mood: 'Harika 🌟',
      client: mockClient,
    );

    expect(success, isTrue);
  });

  test('TeacherSyncService registers student to server', () async {
    SharedPreferences.setMockInitialValues({
      'teacher_sync_server_url': 'http://127.0.0.1:8085',
    });

    final mockClient = MockClient((request) async {
      return http.Response('{"success": true}', 200);
    });

    final success = await TeacherSyncService.instance.registerStudent(
      name: 'Deniz Kaya',
      age: '12',
      diagnosis: 'Otizm Spektrumu 🧩',
      parentName: 'Ayşe Kaya',
      parentPhone: '0555 123 45 67',
      avatar: '🦊',
      client: mockClient,
    );

    expect(success, isTrue);
  });
}
