import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/models/makaton_item.dart';
import 'package:ozel_app/services/ocr_translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final allItems = MakatonItem.all();
  final service = OcrTranslationService();

  group('OcrTranslationService Tests', () {
    test('Translates food and beverage phrases to Makaton cards', () {
      const text = 'Ben soğuk su ve yemek istiyorum, teşekkür ederim.';
      final items = service.translateTextToMakaton(text, allItems);

      final ids = items.map((i) => i.id).toList();
      expect(ids.contains('ben'), isTrue);
      expect(ids.contains('su'), isTrue);
      expect(ids.contains('yemek'), isTrue);
      expect(ids.contains('istiyorum'), isTrue);
      expect(ids.contains('tesekkurler'), isTrue);
    });

    test('Translates playground and polite request text', () {
      const text = 'Parkta oyun oynamak istiyoruz, lütfen izin ver!';
      final items = service.translateTextToMakaton(text, allItems);

      final ids = items.map((i) => i.id).toList();
      expect(ids.contains('park'), isTrue);
      expect(ids.contains('oyun'), isTrue);
      expect(ids.contains('istiyorum'), isTrue);
      expect(ids.contains('lutfen'), isTrue);
    });

    test('Translates health and doctor notes', () {
      const text = 'Hastaneye gidip doktora görüneceğiz, geçmiş olsun.';
      final items = service.translateTextToMakaton(text, allItems);

      final ids = items.map((i) => i.id).toList();
      expect(ids.contains('hastane'), isTrue);
    });

    test('Case insensitivity and punctuation resilience', () {
      const text = 'ANNE! BABA! LÜTFEN GEL...';
      final items = service.translateTextToMakaton(text, allItems);

      final ids = items.map((i) => i.id).toList();
      expect(ids.contains('anne'), isTrue);
      expect(ids.contains('baba'), isTrue);
      expect(ids.contains('lutfen'), isTrue);
      expect(ids.contains('gel'), isTrue);
    });

    test('Empty text returns empty list gracefully', () {
      final items = service.translateTextToMakaton('', allItems);
      expect(items.isEmpty, isTrue);
    });

    test('Detects English text accurately', () {
      expect(service.isLikelyEnglish('Turkish Journal of Education published quarterly'), isTrue);
      expect(service.isLikelyEnglish('Hello teacher I want water and food please'), isTrue);
      expect(service.isLikelyEnglish('Bu bir Türkçe metindir, parka gidiyoruz.'), isFalse);
    });

    test('Translates English words directly to Makaton cards', () {
      const engText = 'Please help me, I want water and food at school.';
      final items = service.translateTextToMakaton(engText, allItems);

      final ids = items.map((i) => i.id).toList();
      expect(ids.contains('lutfen'), isTrue);
      expect(ids.contains('yardim'), isTrue);
      expect(ids.contains('su'), isTrue);
      expect(ids.contains('yemek'), isTrue);
      expect(ids.contains('okul'), isTrue);
    });

    test('Translates English text to Turkish (with offline fallback resilience)', () async {
      final translation = await service.translateToTurkish('Turkish Journal of Education');
      expect(translation.isNotEmpty, isTrue);
      expect(translation.toLowerCase().contains('türkiye') || translation.toLowerCase().contains('dergi') || translation.toLowerCase().contains('eğitim'), isTrue);
    });

    test('Simplifies text for child cognition', () {
      final simplifiedPark = service.simplifyText('Parkta dikkat edilmesi gereken kurallar.');
      expect(simplifiedPark.contains('park') || simplifiedPark.contains('Park'), isTrue);

      final simplifiedWc = service.simplifyText('Bayanlar ve baylar umumi tuvalet girişi');
      expect(simplifiedWc.contains('tuvalet'), isTrue);
    });

    test('Returns rich demo scenarios for testing', () {
      final scenarios = service.getDemoScenarios();
      expect(scenarios.length >= 4, isTrue);

      for (final s in scenarios) {
        expect(s.title.isNotEmpty, isTrue);
        expect(s.sampleText.isNotEmpty, isTrue);
        expect(s.emoji.isNotEmpty, isTrue);
      }
    });
  });
}
