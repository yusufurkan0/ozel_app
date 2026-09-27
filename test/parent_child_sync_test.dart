import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/services/parent_child_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Parent-Child Sync Architecture Tests', () {
    test('DeviceRole handles conversion, naming, and fallback correctly', () {
      expect(DeviceRole.childTerminal.displayName.contains('Çocuk'), isTrue);
      expect(DeviceRole.parentCompanion.displayName.contains('Ebeveyn'), isTrue);
      expect(DeviceRole.standalone.displayName.contains('Klasik'), isTrue);

      expect(DeviceRole.fromString('child'), equals(DeviceRole.childTerminal));
      expect(DeviceRole.fromString('childTerminal'), equals(DeviceRole.childTerminal));
      expect(DeviceRole.fromString('parent'), equals(DeviceRole.parentCompanion));
      expect(DeviceRole.fromString('parentCompanion'), equals(DeviceRole.parentCompanion));
      expect(DeviceRole.fromString('unknown_value'), equals(DeviceRole.standalone));
      expect(DeviceRole.fromString(null), equals(DeviceRole.standalone));
    });

    test('SyncEvent JSON serialization and deserialization round-trip', () {
      final original = SyncEvent.speech(
        childName: 'Ali',
        words: ['Su', 'İstiyorum', 'Lütfen'],
        emoji: '🥛',
        fullSentence: 'Su istiyorum lütfen',
      );

      final json = original.toJson();
      final restored = SyncEvent.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(SyncEventType.speech));
      expect(restored.childName, equals('Ali'));
      expect(restored.displayMessage, contains('Su istiyorum lütfen'));
      expect(restored.data['emoji'], equals('🥛'));
      expect(restored.data['fullSentence'], equals('Su istiyorum lütfen'));
    });

    test('SyncEvent factories produce correct event types and payloads', () {
      // SOS Event
      final sos = SyncEvent.sos(
        childName: 'Ayşe',
        emergencyNote: 'Özel not',
        caregiverPhone: '05551234567',
      );
      expect(sos.type, equals(SyncEventType.sos));
      expect(sos.displayMessage.contains('ACİL'), isTrue);
      expect(sos.data['caregiverPhone'], equals('05551234567'));

      // Emotion Event
      final em = SyncEvent.emotion(
        childName: 'Ali',
        emoji: '😊',
        emotionTitle: 'Mutlu',
      );
      expect(em.type, equals(SyncEventType.emotion));
      expect(em.displayMessage.contains('Mutlu'), isTrue);

      // Routine Event
      final rt = SyncEvent.routineCompleted(
        childName: 'Ali',
        stepId: 'r2',
        stepTitle: 'Diş Fırçalama',
        emoji: '🪥',
      );
      expect(rt.type, equals(SyncEventType.routineCompleted));
      expect(rt.displayMessage.contains('Diş Fırçalama'), isTrue);

      // Remote Cheer Event
      final ch = SyncEvent.cheer(
        childName: 'Ali',
        cheerType: 'aferin',
        cheerMessage: 'Aferin sana!',
        emoji: '🌟',
      );
      expect(ch.type, equals(SyncEventType.remoteCheer));
      expect(ch.displayMessage.contains('Aferin sana!'), isTrue);
    });

    test('ParentChildSyncService streams child speech events to listeners', () async {
      final syncService = ParentChildSyncService();
      await syncService.initialize();

      SyncEvent? received;
      final sub = syncService.eventStream.listen((e) {
        received = e;
      });

      syncService.dispatchSpeechEvent(
        childName: 'Mehmet',
        words: ['Oyun', 'Park'],
        emoji: '🛝',
        fullSentence: 'Parkta oyun oynayalım',
      );

      // Saniyenin altında olay teslimi
      await Future.delayed(const Duration(milliseconds: 50));

      expect(received, isNotNull);
      expect(received!.childName, equals('Mehmet'));
      expect(received!.displayMessage, contains('Parkta oyun oynayalım'));
      expect(syncService.recentEvents.isNotEmpty, isTrue);

      await sub.cancel();
    });

    test('ParentChildSyncService handles family code and role switches', () async {
      final syncService = ParentChildSyncService();
      await syncService.initialize();

      expect(syncService.familyCode.startsWith('OZEL-'), isTrue);

      await syncService.setDeviceRole(DeviceRole.parentCompanion);
      expect(syncService.isParentCompanion, isTrue);
      expect(syncService.isChildTerminal, isFalse);

      await syncService.setDeviceRole(DeviceRole.childTerminal);
      expect(syncService.isChildTerminal, isTrue);
      expect(syncService.isParentCompanion, isFalse);

      await syncService.setFamilyCode('OZEL-9999');
      expect(syncService.familyCode, equals('OZEL-9999'));
    });
  });
}
