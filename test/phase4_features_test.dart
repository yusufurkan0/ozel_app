import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/models/makaton_item.dart';
import 'package:ozel_app/services/game_progress_service.dart';
import 'package:ozel_app/services/database/app_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MakatonItem Phase 4 Tests', () {
    test('MakatonItem with imagePath and customAudioPath serialization', () {
      final item = MakatonItem(
        id: 'custom_photo_1',
        label: 'Kedim Pamuk',
        icon: Icons.pets_rounded,
        color: Colors.pinkAccent,
        category: MakatonCategory.activities,
        imagePath: '/data/user/0/com.example/app_flutter/card_img_123.jpg',
        customAudioPath: '/data/user/0/com.example/app_flutter/card_audio_123.m4a',
      );

      final json = item.toJson();
      expect(json['imagePath'], '/data/user/0/com.example/app_flutter/card_img_123.jpg');
      expect(json['customAudioPath'], '/data/user/0/com.example/app_flutter/card_audio_123.m4a');

      final restored = MakatonItem.fromJson(json);
      expect(restored.id, 'custom_photo_1');
      expect(restored.label, 'Kedim Pamuk');
      expect(restored.imagePath, '/data/user/0/com.example/app_flutter/card_img_123.jpg');
      expect(restored.customAudioPath, '/data/user/0/com.example/app_flutter/card_audio_123.m4a');
    });
  });

  group('GameProgressService Phase 4 Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('PIN verification and setup', () async {
      final service = GameProgressService();
      await service.loadData();

      expect(service.isPinSet, isFalse);
      expect(service.verifyPin('1234'), isTrue); // Empty pin allows

      await service.setPin('5678');
      expect(service.isPinSet, isTrue);
      expect(service.parentPin, '5678');
      expect(service.verifyPin('5678'), isTrue);
      expect(service.verifyPin('0000'), isFalse);
    });

    test('Full JSON backup export and import restoration', () async {
      final service = GameProgressService();
      await service.loadData();

      // Setup initial data
      await service.saveFullProfile(
        name: 'Ali',
        avatar: '🦁',
        birthDate: '2018-05-15',
        height: '115',
        weight: '22',
        caregiverName: 'Ayşe',
        caregiverRole: 'Anne',
      );

      await service.saveSettings(
        soundEnabled: false,
        vibrationEnabled: true,
        dailyGoal: 15,
        buttonSize: 2,
        themeIndex: 3,
      );

      final customCard = MakatonItem(
        id: 'card_backup_1',
        label: 'Mavi Biberon',
        icon: Icons.local_cafe_rounded,
        color: Colors.blueAccent,
        category: MakatonCategory.food,
        imagePath: '/path/biberon.jpg',
        customAudioPath: '/path/biberon.m4a',
      );
      await service.addCustomItem(customCard);

      // Export
      final exportedJson = service.exportBackupJson();
      expect(exportedJson.contains('Ali'), isTrue);
      expect(exportedJson.contains('Mavi Biberon'), isTrue);
      expect(exportedJson.contains('biberon.jpg'), isTrue);

      // Clear/Reset preferences
      SharedPreferences.setMockInitialValues({});
      await AppDatabaseService().deleteCustomCard('card_backup_1');
      final restoredService = GameProgressService();
      await restoredService.loadData();

      expect(restoredService.childName, '');
      expect(restoredService.customItems.length, 0);

      // Import
      final success = await restoredService.importBackupJson(exportedJson);
      expect(success, isTrue);

      // Verify restored values
      expect(restoredService.childName, 'Ali');
      expect(restoredService.avatar, '🦁');
      expect(restoredService.birthDate, '2018-05-15');
      expect(restoredService.caregiverName, 'Ayşe');
      expect(restoredService.soundEnabled, isFalse);
      expect(restoredService.buttonSize, 2);
      expect(restoredService.themeIndex, 3);
      expect(restoredService.customItems.length, 1);
      expect(restoredService.customItems.first.label, 'Mavi Biberon');
      expect(restoredService.customItems.first.imagePath, '/path/biberon.jpg');
      expect(restoredService.customItems.first.customAudioPath, '/path/biberon.m4a');
    });

    test('Invalid JSON returns false gracefully on import', () async {
      final service = GameProgressService();
      await service.loadData();

      final success = await service.importBackupJson('not valid json {{{');
      expect(success, isFalse);
    });
  });
}
