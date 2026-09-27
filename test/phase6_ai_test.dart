import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/models/makaton_item.dart';
import 'package:ozel_app/services/ai_aac_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final allItems = MakatonItem.all();
  final aiService = AiAacService();

  group('AiAacService Prediction Tests', () {
    test('Empty sentence predicts core starter subjects and requests', () {
      final predictions = aiService.predictNextItems([], allItems);
      expect(predictions.isNotEmpty, isTrue);

      final labels = predictions.map((e) => e.label).toList();
      // Should include Ben, İstiyorum or Anne
      final hasStarters = labels.any((l) => ['Ben', 'İstiyorum', 'Anne', 'Su', 'Yemek'].contains(l));
      expect(hasStarters, isTrue);
    });

    test('Sentence ending with "Ben" predicts actions or requests', () {
      final benItem = allItems.firstWhere((i) => i.id == 'ben');
      final predictions = aiService.predictNextItems([benItem], allItems);
      expect(predictions.isNotEmpty, isTrue);

      final labels = predictions.map((e) => e.label).toList();
      // Should suggest actionable cards or desires
      final hasRelevantAction = labels.any((l) => ['İstiyorum', 'Seviyorum', 'Mutlu', 'Yemek'].contains(l));
      expect(hasRelevantAction, isTrue);
    });

    test('Sentence ending with food/drink predicts consumption verbs or polite tags', () {
      final suItem = allItems.firstWhere((i) => i.id == 'su');
      final predictions = aiService.predictNextItems([suItem], allItems);
      expect(predictions.isNotEmpty, isTrue);

      final labels = predictions.map((e) => e.label).toList();
      final hasConsumptionOrPolite = labels.any((l) => ['İstiyorum', 'Ver', 'Lütfen', 'Teşekkür Ederim'].contains(l));
      expect(hasConsumptionOrPolite, isTrue);
    });

    test('Sentence ending with "Park" predicts movement/play items', () {
      final parkItem = allItems.firstWhere((i) => i.id == 'park');
      final predictions = aiService.predictNextItems([parkItem], allItems);
      expect(predictions.isNotEmpty, isTrue);

      final labels = predictions.map((e) => e.label).toList();
      final hasPlayOrGo = labels.any((l) => ['Gidelim', 'İstiyorum', 'Çok Güzel', 'Bitti'].contains(l));
      expect(hasPlayOrGo, isTrue);
    });
  });

  group('AiAacService Social Stories Tests', () {
    test('generateSocialStory generates 4 valid progressive steps with child name', () {
      final story = aiService.generateSocialStory(topic: 'Doktora Gitmek & Aşı', childName: 'Ali');

      expect(story.title.contains('Ali'), isTrue);
      expect(story.steps.length, 4);

      for (var i = 0; i < story.steps.length; i++) {
        final step = story.steps[i];
        expect(step.title.isNotEmpty, isTrue);
        expect(step.text.isNotEmpty, isTrue);
        expect(step.icon, isNotNull);
      }
    });

    test('generateSocialStory handles custom topics gracefully', () {
      final story = aiService.generateSocialStory(topic: 'Tiyatroya Gitmek', childName: 'Zeynep');

      expect(story.title.contains('Zeynep'), isTrue);
      expect(story.steps.length, 4);
      expect(story.steps.first.text.contains('Zeynep'), isTrue);
    });
  });

  group('AiAacService Clinical Insights Tests', () {
    test('generateClinicalInsights produces structured report without errors', () {
      final report = aiService.generateClinicalInsights(
        childName: 'Can',
        totalPresses: 42,
        streak: 5,
        topSymbols: const [MapEntry('Su', 15), MapEntry('Park', 10), MapEntry('Anne', 8)],
        todayEmotion: 'Mutlu',
        routineRate: 0.85,
      );

      expect(report.contains('Can'), isTrue);
      expect(report.contains('42'), isTrue);
      expect(report.contains('Su'), isTrue);
      expect(report.contains('Mutlu'), isTrue);
      expect(report.contains('%85'), isTrue);
      expect(report.contains('KLİNİK AAC'), isTrue);
    });
  });
}
