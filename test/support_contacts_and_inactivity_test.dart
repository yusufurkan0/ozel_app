import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/screens/register_screen.dart';
import 'package:ozel_app/services/game_progress_service.dart';
import 'package:ozel_app/services/inactivity_help_service.dart';
import 'package:ozel_app/screens/launcher/cooking_step_by_step_screen.dart';
import 'package:ozel_app/models/kitchen_recipe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Destek Kişileri & 1 Dk Hareketsizlik Yardımı Testleri', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Kayıt ekranında Destek Kişisi (İş Koçu & Aile) ekleme ve kaydetme alanları bulunmalı', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final gameService = GameProgressService();

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProgressService>.value(
          value: gameService,
          child: const MaterialApp(
            home: RegisterScreen(isEditing: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aşağı kaydır
      final scrollFinder = find.byType(SingleChildScrollView);
      await tester.drag(scrollFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Bölüm 3 başlığı ve kontroller
      expect(find.text('👥 3. Destek Kişilerini Seç & Bilgilerini Gir'), findsOneWidget);
      expect(find.text('💼 İş Koçu (WhatsApp)'), findsWidgets);
      expect(find.text('👨‍👩‍👧 Aile (Arama)'), findsWidgets);
      expect(find.text('Destek Kişisi Adı Soyadı'), findsOneWidget);
      expect(find.text('Telefon Numarası (11 Hane)'), findsWidgets);
      expect(find.text('+ Bu Destek Kişisini Ekle (WhatsApp)'), findsOneWidget);
    });

    test('Destek kişisi verisi Aile için tel, İş Koçu için WhatsApp (wa.me) formatını desteklemeli', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final List<Map<String, dynamic>> testContacts = [
        {
          'name': 'Selim Koç',
          'role': 'İş Koçu',
          'phone': '05321112233',
          'avatar': '💼',
          'isJobCoach': true,
        },
        {
          'name': 'Ayşe Anne',
          'role': 'Aile',
          'phone': '05559998877',
          'avatar': '👨‍👩‍👧',
          'isJobCoach': false,
        },
      ];

      await prefs.setString('user_support_contacts', jsonEncode(testContacts));

      final saved = prefs.getString('user_support_contacts');
      expect(saved, isNotNull);
      final decoded = jsonDecode(saved!) as List;
      expect(decoded.length, 2);

      // İş Koçu -> wa.me
      final jobCoach = decoded.firstWhere((c) => c['role'] == 'İş Koçu');
      expect(jobCoach['name'], 'Selim Koç');
      expect(jobCoach['isJobCoach'], isTrue);
      final cleanPhone = (jobCoach['phone'] as String).replaceAll(RegExp(r'\D'), '');
      final formattedWa = cleanPhone.startsWith('0') ? '9$cleanPhone' : '90$cleanPhone';
      expect(formattedWa, '905321112233');

      // Aile -> tel:
      final family = decoded.firstWhere((c) => c['role'] == 'Aile');
      expect(family['name'], 'Ayşe Anne');
      expect(family['isJobCoach'], isFalse);
      expect('tel:${family['phone']}', 'tel:05559998877');
    });

    testWidgets('InactivityHelpService 1 dakikalık zaman aşımı diyaloğunu açar', (tester) async {
      final helpService = InactivityHelpService(timeoutDuration: const Duration(seconds: 60));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => helpService.start(ctx),
                  child: const Text('Başlat'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Başlat'));
      await tester.pump();

      // 60 saniye süre dolduğunda yardım sorulmalı
      await tester.pump(const Duration(seconds: 61));
      await tester.pump();

      // Uyarı diyaloğu görünmeli
      expect(find.text('Yardım İster Misin?'), findsOneWidget);
      expect(find.text('Hayır, Devam Edeceğim'), findsOneWidget);
      expect(find.text('Evet, Yardım İste'), findsOneWidget);

      // Hayır'a basınca kapanmalı
      await tester.tap(find.text('Hayır, Devam Edeceğim'));
      await tester.pump();

      expect(find.text('Yardım İster Misin?'), findsNothing);
      helpService.stop();
    });

    testWidgets('CookingStepByStepScreen InactivityHelpService ile sorunsuz açılmalı ve adımlar çalışmalı', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final recipe = KitchenRecipe(
        id: 'test_recipe_1',
        title: 'Muzlu Süt Test',
        category: 'İçecekler',
        subtitle: 'Pratik ve lezzetli',
        portions: '1 Kişilik',
        prepTime: '5 Dakika',
        cookTime: '0 Dakika',
        difficulty: 'Kolay',
        themeColor: Colors.amber,
        icon: Icons.local_drink_rounded,
        ingredients: [
          RecipeCheckItem(id: 'i1', name: '1 Muz'),
          RecipeCheckItem(id: 'i2', name: '1 Bardak Süt'),
        ],
        tools: [
          RecipeCheckItem(id: 't1', name: 'Blender'),
        ],
        steps: [
          const RecipeStepItem(
            stepNumber: 1,
            instruction: 'Muzu soy ve dilimle.',
            icon: Icons.kitchen_rounded,
          ),
          const RecipeStepItem(
            stepNumber: 2,
            instruction: 'Süt ekleyip karıştır.',
            icon: Icons.blender_rounded,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CookingStepByStepScreen(recipe: recipe),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Muzlu Süt Test'), findsOneWidget);
      expect(find.text('Muzu soy ve dilimle.'), findsOneWidget);

      // Sıradaki adıma geçiş
      await tester.tap(find.text('Sıradaki Adım ▶'));
      await tester.pumpAndSettle();

      expect(find.text('Süt ekleyip karıştır.'), findsOneWidget);
    });
  });
}
