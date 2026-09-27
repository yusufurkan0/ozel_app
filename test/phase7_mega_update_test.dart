import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/models/makaton_item.dart';
import 'package:ozel_app/models/routine_step.dart';
import 'package:ozel_app/services/ocr_translation_service.dart';
import 'package:ozel_app/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final allItems = MakatonItem.all();
  final ocrService = OcrTranslationService();

  group('Phase 7 Mega Update Tests', () {
    // 1. Görsel Günlük Rutin Testleri
    test('RoutineStep provides rich default steps across time slots', () {
      final steps = RoutineStep.defaultSteps();
      expect(steps.length >= 15, isTrue);

      final sabah = steps.where((s) => s.timeSlot == 'sabah').toList();
      final okul = steps.where((s) => s.timeSlot == 'okul').toList();
      final aksam = steps.where((s) => s.timeSlot == 'aksam').toList();

      expect(sabah.isNotEmpty, isTrue);
      expect(okul.isNotEmpty, isTrue);
      expect(aksam.isNotEmpty, isTrue);
    });

    test('RoutineStep JSON serialization round-trip', () {
      final step = RoutineStep(
        id: 'test_1',
        title: 'Diş Fırçala',
        emoji: '🪥',
        timeSlot: 'sabah',
        durationMinutes: 3,
        isCompleted: true,
        audioPrompt: 'Dişlerimizi fırçalayalım',
      );

      final json = step.toJson();
      final restored = RoutineStep.fromJson(json);

      expect(restored.id, equals('test_1'));
      expect(restored.title, equals('Diş Fırçala'));
      expect(restored.isCompleted, isTrue);
      expect(restored.durationMinutes, equals(3));
    });

    // 2. Canlı Konuşma Dinleyici (Speech-to-AAC) Eşleştirme Testleri
    test('Live speech natural sentences translate to Makaton symbols', () {
      const sentence = 'Hadi montunu giy, bahçede oyun oynayalım ve su içelim.';
      final matched = ocrService.translateTextToMakaton(sentence, allItems);

      final ids = matched.map((m) => m.id).toList();
      expect(ids.contains('oyun'), isTrue);
      expect(ids.contains('su'), isTrue);
    });

    test('Live speech polite and question phrases translate accurately', () {
      const sentence = 'Lütfen bana yardım eder misin, acıktım yemek istiyorum.';
      final matched = ocrService.translateTextToMakaton(sentence, allItems);

      final ids = matched.map((m) => m.id).toList();
      expect(ids.contains('lutfen'), isTrue);
      expect(ids.contains('yardim'), isTrue);
      expect(ids.contains('yemek'), isTrue);
      expect(ids.contains('istiyorum'), isTrue);
    });

    // 3. PDF / PECS Kart Yazdırıcı Servisi Testleri
    test('PdfGeneratorService produces valid non-empty PDF bytes', () async {
      final service = PdfGeneratorService();
      final sampleItems = allItems.take(6).toList();

      final pdfBytes = await service.generatePecsPdf(
        sampleItems,
        title: 'Test PECS Kartları',
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length > 500, isTrue);
      // PDF başlık imzası (%PDF-)
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header.startsWith('%PDF'), isTrue);
    });

    // 4. Makaton Oyunları Mantık Testleri
    test('All items have valid labels and categories for games', () {
      for (final item in allItems) {
        expect(item.id.isNotEmpty, isTrue);
        expect(item.label.isNotEmpty, isTrue);
        expect(item.emoji.isNotEmpty, isTrue);
      }
    });
  });
}
