import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/data/lezzet_plus_recipes.dart';
import 'package:ozel_app/screens/launcher/cooking_step_by_step_screen.dart';
import 'package:ozel_app/screens/launcher/kitchen_recipe_detail_screen.dart';
import 'package:ozel_app/screens/launcher/kitchen_safety_screen.dart';

void main() {
  group('Lezzet +1 Data & Model Tests', () {
    test('LezzetPlusRecipes returns authentic recipes from the book', () {
      final recipes = LezzetPlusRecipes.getRecipes();
      expect(recipes.isNotEmpty, isTrue);

      final ispanak = recipes.firstWhere((r) => r.id == 'ispanak_corbasi');
      expect(ispanak.title, 'Ispanak Çorbası');
      expect(ispanak.category, 'Çorbalar');
      expect(ispanak.portions, '4 Kişilik');
      expect(ispanak.prepTime, '25 Dakika');
      expect(ispanak.cookTime, '25 Dakika');
      expect(ispanak.ingredients.length, 7);
      expect(ispanak.tools.length, 15);
      expect(ispanak.steps.length, 34);
      expect(ispanak.chefTips.isNotEmpty, isTrue);

      // Verify visual narration assets exist
      expect(ispanak.coverImagePath, isNotNull);
      expect(ispanak.ingredients.any((i) => i.imagePath != null), isTrue);
      expect(ispanak.steps.any((s) => s.imagePath != null), isTrue);

      // Verify timed steps exist
      final timedSteps = ispanak.steps.where((s) => s.timerSeconds != null).toList();
      expect(timedSteps.length, greaterThanOrEqualTo(3));
      expect(timedSteps.any((s) => s.timerSeconds == 60), isTrue); // 1 dk yağ ısınma
      expect(timedSteps.any((s) => s.timerSeconds == 120), isTrue); // 2 dk soğan kavurma
      expect(timedSteps.any((s) => s.timerSeconds == 900), isTrue); // 15 dk pişirme
    });

    test('RecipeCheckItem toggle and progress computation', () {
      final recipe = LezzetPlusRecipes.getRecipes().first;

      // Initially unchecked
      for (final i in recipe.ingredients) {
        i.isChecked = false;
      }
      for (final t in recipe.tools) {
        t.isChecked = false;
      }
      expect(recipe.totalChecklistProgress, 0.0);
      expect(recipe.isChecklistComplete, isFalse);

      // Check first ingredient
      recipe.ingredients.first.isChecked = true;
      expect(recipe.totalChecklistProgress, greaterThan(0.0));

      // Mark all
      for (final i in recipe.ingredients) {
        i.isChecked = true;
      }
      for (final t in recipe.tools) {
        t.isChecked = true;
      }
      expect(recipe.totalChecklistProgress, 1.0);
      expect(recipe.isChecklistComplete, isTrue);
    });
  });

  group('KitchenSafetyScreen Widget Tests', () {
    testWidgets('Renders Lezzet +1 Kitabı and Mutfak Güvenliği tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: KitchenSafetyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mutfağım & Lezzet +1'), findsOneWidget);
      expect(find.text('Lezzet +1 Kitabı'), findsOneWidget);
      expect(find.text('Mutfak Güvenliği'), findsOneWidget);
      expect(find.text('Ispanak Çorbası'), findsOneWidget);
      expect(find.text('Vitamin Deposu Sebze Çorbası'), findsOneWidget);

      // Switch to Mutfak Güvenliği tab
      await tester.tap(find.text('Mutfak Güvenliği'));
      await tester.pumpAndSettle();

      expect(find.text('Sıcak Ocağa ve Fırına Asla Dokunma!'), findsOneWidget);
    });
  });

  group('KitchenRecipeDetailScreen Checklist Tests', () {
    testWidgets('Toggles materials and updates checklist progress', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final recipe = LezzetPlusRecipes.getRecipes().first;
      // Reset items
      for (final i in recipe.ingredients) {
        i.isChecked = false;
      }
      for (final t in recipe.tools) {
        t.isChecked = false;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: KitchenRecipeDetailScreen(recipe: recipe),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ispanak Çorbası'), findsOneWidget);
      expect(find.textContaining('Kontrol Listesi: 0 / 22 Hazır'), findsOneWidget);

      // Tap on an ingredient (Ispanak)
      await tester.tap(find.text('Ispanak'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Kontrol Listesi: 1 / 22 Hazır'), findsOneWidget);
      expect(find.text('Hazır 👍'), findsOneWidget);

      // Tap "Hepsini Seç"
      await tester.tap(find.text('Hepsini Seç'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Kontrol Listesi: 22 / 22 Hazır'), findsOneWidget);
      expect(find.text('%100'), findsOneWidget);

      // Bottom start button exists
      expect(find.textContaining('Adım Adım Pişirmeye Başla'), findsOneWidget);
    });
  });

  group('CookingStepByStepScreen Sequential Progression Tests', () {
    testWidgets('Shows step 1, navigates to step 2, and displays timer on timed step', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final recipe = LezzetPlusRecipes.getRecipes().first;

      await tester.pumpWidget(
        MaterialApp(
          home: CookingStepByStepScreen(recipe: recipe),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1
      expect(find.text('Adım 1 / 34'), findsOneWidget);
      expect(find.text(recipe.steps[0].instruction), findsOneWidget);
      expect(find.text('Sıradaki Adım ▶'), findsOneWidget);

      // Navigate to Step 2
      await tester.tap(find.text('Sıradaki Adım ▶'));
      await tester.pumpAndSettle();

      expect(find.text('Adım 2 / 34'), findsOneWidget);
      expect(find.text(recipe.steps[1].instruction), findsOneWidget);
      expect(find.text('Önceki'), findsOneWidget);

      // Navigate back to Step 1
      await tester.tap(find.text('Önceki'));
      await tester.pumpAndSettle();
      expect(find.text('Adım 1 / 34'), findsOneWidget);
    });

    testWidgets('Displays timer controls on timed step (step 20)', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final recipe = LezzetPlusRecipes.getRecipes().first;

      await tester.pumpWidget(
        MaterialApp(
          home: CookingStepByStepScreen(recipe: recipe, initialStep: 19), // Step 20
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adım 20 / 34'), findsOneWidget);
      expect(find.text('1 Dakika Yağ Isınma Sayacı'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.text('Sayacı Başlat'), findsOneWidget);

      // Tap Sayacı Başlat
      await tester.tap(find.text('Sayacı Başlat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Duraklat'), findsOneWidget);
    });
  });
}
