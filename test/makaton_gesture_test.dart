import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/models/makaton_gesture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Makaton El İşaretleri & Kart Öğrenme Akademisi Testleri', () {
    test('Eski gereksiz eğitici oyunlar ekranı silinmiş olmalı', () {
      expect(File('lib/screens/educational_games_screen.dart').existsSync(), isFalse);
    });

    test('Makaton el işaretleri kütüphanesi temel kategorileri kapsamalı ve her birinin görseli olmalı', () {
      final gestures = MakatonGesture.allGestures();
      expect(gestures.length, equals(8));

      final categories = gestures.map((g) => g.category).toSet();
      expect(categories.contains('İhtiyaçlar'), isTrue);
      expect(categories.contains('Sosyal'), isTrue);
      expect(categories.contains('Eylemler'), isTrue);

      // Her işaretin özel adım adım resimli görseli bulunmalı
      for (final g in gestures) {
        expect(g.imageAssetPath.isNotEmpty, isTrue);
        expect(File(g.imageAssetPath).existsSync(), isTrue,
            reason: '${g.word} işaretinin görsel dosyası (${g.imageAssetPath}) diskte mevcut olmalı');
      }
    });

    test('Her bir el işareti pedagojik olarak eksiksiz tarif ve adımlara sahip olmalı', () {
      final gestures = MakatonGesture.allGestures();
      for (final g in gestures) {
        expect(g.id.isNotEmpty, isTrue);
        expect(g.word.isNotEmpty, isTrue);
        expect(g.emoji.isNotEmpty, isTrue);
        expect(g.gestureTitle.isNotEmpty, isTrue);
        expect(g.steps.length >= 2, isTrue, reason: '${g.word} en az 2 adıma sahip olmalı');
        expect(g.parentTip.isNotEmpty, isTrue, reason: '${g.word} ebeveyn ipucuna sahip olmalı');
        expect(g.speechText.isNotEmpty, isTrue, reason: '${g.word} sesli telaffuz cümlesine sahip olmalı');
        expect(g.imageAssetPath.isNotEmpty, isTrue);
      }
    });

    test('Öğrenilen işaretler SharedPreferences ile kalıcı olarak saklanabilmeli', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final learned = <String>['g_su', 'g_yemek', 'g_lutfen'];
      await prefs.setStringList('learned_gestures_v1', learned);

      final restored = prefs.getStringList('learned_gestures_v1') ?? [];
      expect(restored.length, equals(3));
      expect(restored.contains('g_su'), isTrue);
      expect(restored.contains('g_lutfen'), isTrue);
      expect(restored.contains('g_yardim'), isFalse);
    });
  });
}
