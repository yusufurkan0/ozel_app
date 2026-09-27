import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/models/makaton_item.dart';
import 'package:ozel_app/models/user_account.dart';
import 'package:ozel_app/services/database/app_database_service.dart';
import 'package:ozel_app/services/parent_child_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SQLite Database Service Tests', () {
    test('Database initializes and performs User CRUD operations', () async {
      final db = AppDatabaseService();
      await db.init();

      final user = UserAccount(
        username: 'deniz',
        password: 'deniz_password',
        role: UserRole.student,
        displayName: 'Deniz',
        avatar: '🐬',
      );

      await db.saveUser(user);

      final retrieved = await db.getUser('deniz');
      expect(retrieved, isNotNull);
      expect(retrieved!.username, equals('deniz'));
      expect(retrieved.displayName, equals('Deniz'));
      expect(retrieved.avatar, equals('🐬'));
      expect(retrieved.isStudent, isTrue);

      final all = await db.getAllUsers();
      expect(all.any((u) => u.username == 'deniz'), isTrue);
    });

    test('Database logs child speech events and queries history', () async {
      final db = AppDatabaseService();
      await db.init();

      final speechEvent = SyncEvent.speech(
        childName: 'Deniz',
        words: ['Elma', 'İstiyorum'],
        emoji: '🍎',
        fullSentence: 'Elma istiyorum lütfen',
      );

      await db.logSpeech(speechEvent);

      final logs = await db.getRecentSpeechLogs(limit: 10);
      expect(logs.isNotEmpty, isTrue);

      final latest = logs.first;
      expect(latest['child_name'], equals('Deniz'));
      expect(latest['full_sentence'], equals('Elma istiyorum lütfen'));
      expect(latest['emoji'], equals('🍎'));
    });

    test('Database saves, retrieves, and deletes custom Makaton cards', () async {
      final db = AppDatabaseService();
      await db.init();

      final customCard = MakatonItem(
        id: 'card_kedi_pamuk',
        label: 'Pamuk Kedi',
        category: MakatonCategory.social,
        icon: Icons.pets_rounded,
        color: Colors.orange,
        imagePath: '/path/to/cat.jpg',
      );

      await db.saveCustomCard(customCard);

      final cards = await db.getCustomCards();
      expect(cards.any((c) => c.id == 'card_kedi_pamuk'), isTrue);

      final loaded = cards.firstWhere((c) => c.id == 'card_kedi_pamuk');
      expect(loaded.label, equals('Pamuk Kedi'));
      expect(loaded.imagePath, equals('/path/to/cat.jpg'));

      // Silme testi
      await db.deleteCustomCard('card_kedi_pamuk');
      final updated = await db.getCustomCards();
      expect(updated.any((c) => c.id == 'card_kedi_pamuk'), isFalse);
    });
  });
}
