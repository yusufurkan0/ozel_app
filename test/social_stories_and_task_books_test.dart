import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/models/social_story_book.dart';
import 'package:ozel_app/services/social_story_service.dart';
import 'package:ozel_app/screens/launcher/social_story_library_screen.dart';
import 'package:ozel_app/screens/launcher/social_story_reader_screen.dart';
import 'package:ozel_app/screens/launcher/games_social_stories_screen.dart';
import 'package:ozel_app/screens/launcher/task_checklist_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Sosyal Öykü & Görev Kitapları Model & Servis Testleri', () {
    test('SocialStoryPage JSON dönüşümü doğru çalışmalı', () {
      final page = SocialStoryPage(
        id: 'p1',
        text: 'Servise binerken sıramı beklerim.',
        imagePath: 'assets/images/lezzet/step_18.png',
        audioPath: 'sample.m4a',
        isDone: false,
        pageNumber: 1,
      );

      final jsonMap = page.toMap();
      final fromJson = SocialStoryPage.fromMap(jsonMap);

      expect(fromJson.id, 'p1');
      expect(fromJson.text, 'Servise binerken sıramı beklerim.');
      expect(fromJson.imagePath, 'assets/images/lezzet/step_18.png');
      expect(fromJson.audioPath, 'sample.m4a');
      expect(fromJson.isDone, isFalse);
      expect(fromJson.pageNumber, 1);
    });

    test('SocialStoryBook ve sayfaları servisle kaydedilip yüklenebilmeli', () async {
      final service = SocialStoryService();
      await service.init();

      // Başlangıçta kütüphane boş olmalı
      expect(service.getBooks('social_story').isEmpty, isTrue);

      final book = SocialStoryBook(
        id: 'book_test_1',
        title: 'Dişlerimi Fırçalıyorum',
        coverColorValue: 0xFF7C3AED,
        type: 'social_story',
      );

      await service.saveBook(book);
      expect(service.getBooks('social_story').length, 1);
      expect(service.getBooks('social_story').first.title, 'Dişlerimi Fırçalıyorum');

      // Sayfa ekleme
      final page = SocialStoryPage(
        id: 'page_1',
        text: 'Fırçama macun sürerim.',
        pageNumber: 1,
      );
      await service.addPageToBook(book.id, page, 'social_story');

      final updated = service.getBooks('social_story').first;
      expect(updated.pages.length, 1);
      expect(updated.pages.first.text, 'Fırçama macun sürerim.');
    });
  });

  group('Kütüphane Ekranı Testleri', () {
    testWidgets('Boş kütüphane uyarısı ve Yeni Kitap Ekle butonu görünmeli', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialStoryLibraryScreen(type: 'social_story'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sosyal Öykü Kütüphanem'), findsOneWidget);
      expect(find.text('Kütüphaneniz Henüz Boş'), findsOneWidget);
      expect(find.text('Yeni Kitap Ekle'), findsWidgets);
    });

    testWidgets('Yeni Kitap Ekle diyaloğu açılabilmeli', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialStoryLibraryScreen(type: 'social_story'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yeni Kitap Ekle').first);
      await tester.pumpAndSettle();

      expect(find.text('Yeni Sosyal Öykü Kitabı'), findsOneWidget);
      expect(find.text('Kitap Adı / Konusu:'), findsOneWidget);
      expect(find.text('Kapak Rengi:'), findsOneWidget);
      expect(find.text('Oluştur'), findsOneWidget);
    });
  });

  group('E-Kitap Okuyucu (Reader) Testleri', () {
    testWidgets('Tek resim, tek metin ve ses kontrolleri düzgün render edilmeli', (tester) async {
      final book = SocialStoryBook(
        id: 'b1',
        title: 'Okula Gidiyorum',
        pages: [
          SocialStoryPage(
            id: 'p1',
            text: 'Servise binerken arkadaşlarıma selam veririm.',
            imagePath: 'assets/images/lezzet/step_18.png',
            pageNumber: 1,
          ),
          SocialStoryPage(
            id: 'p2',
            text: 'Kendi koltuğuma oturup kemerimi bağlarım.',
            pageNumber: 2,
          ),
        ],
      );

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SocialStoryReaderScreen(book: book),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Okula Gidiyorum'), findsOneWidget);
      expect(find.text('Sayfa 1 / 2'), findsOneWidget);
      expect(find.text('Servise binerken arkadaşlarıma selam veririm.'), findsOneWidget);
      expect(find.text('Tekrar Dinle'), findsOneWidget);
      expect(find.text('Sonraki'), findsOneWidget);

      // Sonraki sayfaya geç
      await tester.tap(find.text('Sonraki'));
      await tester.pumpAndSettle();

      expect(find.text('Sayfa 2 / 2'), findsOneWidget);
      expect(find.text('Kendi koltuğuma oturup kemerimi bağlarım.'), findsOneWidget);
      expect(find.text('Bitir'), findsOneWidget);
    });
  });

  group('Menü Entegrasyon Testleri', () {
    testWidgets('GamesSocialStoriesScreen kütüphane sekmesini barındırmalı', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GamesSocialStoriesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sosyal Öyküler'), findsOneWidget);
      expect(find.text('Eğitici Oyunlar'), findsOneWidget);
      expect(find.text('Kütüphaneniz Henüz Boş'), findsOneWidget);
    });

    testWidgets('TaskChecklistScreen Görev Kitapları sekmesini barındırmalı', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskChecklistScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Görev Kitaplarım'), findsOneWidget);
      expect(find.text('Hızlı Liste'), findsOneWidget);
      expect(find.text('Görev Kütüphaneniz Boş'), findsOneWidget);
    });
  });
}
