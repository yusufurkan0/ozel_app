import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/models/makaton_item.dart';
import 'package:ozel_app/services/game_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MakatonItem Phase 3 Tests', () {
    test('MakatonItem includes actions and social categories', () {
      final all = MakatonItem.all();
      final hasActions = all.any((i) => i.category == MakatonCategory.actions);
      final hasSocial = all.any((i) => i.category == MakatonCategory.social);

      expect(hasActions, isTrue);
      expect(hasSocial, isTrue);

      // Check specific new core vocabulary
      expect(all.any((i) => i.label == 'İstiyorum'), isTrue);
      expect(all.any((i) => i.label == 'İstemiyorum'), isTrue);
      expect(all.any((i) => i.label == 'Lütfen'), isTrue);
      expect(all.any((i) => i.label == 'Teşekkür Ederim'), isTrue);
    });

    test('Custom MakatonItem toJson and fromJson round-trip', () {
      final custom = MakatonItem(
        id: 'custom_123',
        label: 'Mavi Araba',
        category: MakatonCategory.activities,
        color: const Color(0xFF4A90E2),
        icon: Icons.directions_car_rounded,
        soundPath: null,
      );

      final json = custom.toJson();
      final restored = MakatonItem.fromJson(json);

      expect(restored.id, 'custom_123');
      expect(restored.label, 'Mavi Araba');
      expect(restored.category, MakatonCategory.activities);
      expect(restored.color.toARGB32(), const Color(0xFF4A90E2).toARGB32());
      expect(restored.icon.codePoint, Icons.directions_car_rounded.codePoint);
    });
  });

  group('GameProgressService Phase 3 Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Add and remove custom card updates allItems', () async {
      final service = GameProgressService();
      await service.loadData();

      final initialCount = service.allItems.length;
      final newCard = MakatonItem(
        id: 'test_card_1',
        label: 'Kedim Pamuk',
        category: MakatonCategory.emotions,
        color: Colors.purple,
        icon: Icons.pets_rounded,
      );

      await service.addCustomItem(newCard);
      expect(service.customItems.length, 1);
      expect(service.allItems.length, initialCount + 1);
      expect(service.allItems.any((i) => i.id == 'test_card_1'), isTrue);

      await service.removeCustomItem('test_card_1');
      expect(service.customItems.length, 0);
      expect(service.allItems.length, initialCount);
    });

    test('Accessibility settings can be saved and retrieved', () async {
      final service = GameProgressService();
      await service.loadData();

      expect(service.scanModeEnabled, isFalse);
      expect(service.scanSpeedMs, 1500);
      expect(service.holdDurationMs, 0);

      await service.saveAccessibilitySettings(
        scanMode: true,
        scanSpeed: 2000,
        holdDuration: 500,
      );

      expect(service.scanModeEnabled, isTrue);
      expect(service.scanSpeedMs, 2000);
      expect(service.holdDurationMs, 500);
    });
  });
}
