import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/data/disaster_dictionary_data.dart';
import 'package:ozel_app/screens/launcher/lost_sos_screen.dart';
import 'package:ozel_app/screens/launcher/disaster_emergency_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'user_emergency_name': 'Ahmet Yılmaz',
      'user_emergency_phone': '05551234567',
      'user_home_address': 'Atatürk Mah. Karanfil Sok. No:5 Kadıköy/İstanbul',
      'user_emergency_notes': 'Özel gereksinimli, sakin yaklaşınız.',
      'user_support_contacts': '[{"name":"Annem","role":"Anne","phone":"05559876543","avatar":"👩"}]',
    });
  });

  group('Afet Sözlüğü Veri Testleri', () {
    test('Sözlük 77 resmi AFAD ve ESOGÜ terimini eksiksiz barındırmalı', () {
      expect(DisasterDictionaryData.terms.length, 77);

      final titles = DisasterDictionaryData.terms.map((t) => t.title).toList();
      expect(titles.contains('Deprem'), isTrue);
      expect(titles.contains('Yangın'), isTrue);
      expect(titles.contains('Sel'), isTrue);
      expect(titles.contains('Araba Kazası'), isTrue);
      expect(titles.contains('Kaybolma'), isTrue);
      expect(titles.contains('Çök-Kapan-Tutun'), isTrue);
      expect(titles.contains('Düdük'), isTrue);
      expect(titles.contains('AFAD'), isTrue);
      expect(titles.contains('İlk Yardım'), isTrue);
      expect(titles.contains('Toplanma Alanı'), isTrue);

      for (final t in DisasterDictionaryData.terms) {
        expect(t.title.isNotEmpty, isTrue);
        expect(t.category.isNotEmpty, isTrue);
        expect(t.definition.isNotEmpty, isTrue);
        expect(t.imageAsset.startsWith('assets/images/disaster_dict/'), isTrue);
        expect(t.firstLetter.isNotEmpty, isTrue);
      }
    });

    test('Kullanılabilir harfler listesi doğru ve benzersiz olmalı', () {
      final letters = DisasterDictionaryData.availableLetters;
      expect(letters.isNotEmpty, isTrue);
      expect(letters.contains('A'), isTrue);
      expect(letters.contains('D'), isTrue);
      expect(letters.contains('Y'), isTrue);
    });
  });

  group('Kayboldum! Ne Yapmalıyım? Ekranı Testleri', () {
    testWidgets('3 ana seçenek ekranda açık ve anlaşılır şekilde sunulmalı', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostSosScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Başlık ve sakinleştirici afiş
      expect(find.text('Kayboldum! Ne Yapmalıyım?'), findsOneWidget);
      expect(find.text('KORKMA! GÜVENDESİN.'), findsOneWidget);

      // 1. Seçenek: Çevrende bir dükkân varsa gideceğin adresi sor.
      expect(find.textContaining('Çevrende bir dükkân varsa gideceğin adresi sor.'), findsOneWidget);
      expect(find.text('Dükkân Yardımını Aç 🏪'), findsOneWidget);

      // 2. Seçenek: Çevrende polis varsa polisten yardım iste.
      expect(find.textContaining('Çevrende polis varsa polisten yardım iste.'), findsOneWidget);
      expect(find.text('Polis Yardımını Aç 👮‍♂️'), findsOneWidget);

      // 3. Seçenek: Aileni ara. Bulunduğun yerden ayrılma.
      expect(find.textContaining('Aileni ara. Bulunduğun yerden ayrılma.'), findsOneWidget);
      expect(find.text('Aileni Ara & Konum Gönder 📞📍'), findsOneWidget);
      expect(find.text('ÖNEMLİ: ASLA AYRILMA'), findsOneWidget);

      // Düdük / Sesli Çağrı Butonu
      expect(find.textContaining('Acil Durum Düdüğü'), findsOneWidget);
    });

    testWidgets('1. Seçenek (Dükkân) açıldığında görevliye gösterilecek adres kartı gelmeli', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostSosScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dükkân Yardımını Aç 🏪'));
      await tester.pumpAndSettle();

      expect(find.text('1. SEÇENEK: DÜKKÂNA SOR'), findsOneWidget);
      expect(find.text('ESNAFA / GÖREVLİYE GÖSTER:'), findsOneWidget);
      expect(find.textContaining('Gideceğim Ev Adresi:'), findsOneWidget);
      expect(find.textContaining('Kadıköy/İstanbul'), findsOneWidget);
    });

    testWidgets('2. Seçenek (Polis) açıldığında polise gösterilecek kart ve 112 butonu gelmeli', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostSosScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Polis Yardımını Aç 👮‍♂️'));
      await tester.pumpAndSettle();

      expect(find.text('2. SEÇENEK: POLİSE GİT'), findsOneWidget);
      expect(find.text('SAYIN POLİS MEMURUNA:'), findsOneWidget);
      expect(find.text('112 POLİS İMDAT\'I ARA'), findsOneWidget);
    });

    testWidgets('3. Seçenek (Aileni Ara) açıldığında Ayrılma uyarısı ve rehber kişileri gelmeli', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LostSosScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final callButton = find.text('Aileni Ara & Konum Gönder 📞📍');
      await tester.ensureVisible(callButton);
      await tester.pumpAndSettle();
      await tester.tap(callButton);
      await tester.pumpAndSettle();

      expect(find.text('3. SEÇENEK: AİLENİ ARA'), findsOneWidget);
      expect(find.text('BULUNDUĞUN YERDEN AYRILMA!'), findsOneWidget);
      expect(find.textContaining('Annem'), findsOneWidget);
      expect(find.text('Ara'), findsWidgets);
    });
  });

  group('Afet ve Acil Durum Ekranı Testleri', () {
    testWidgets('5 Temel Afet Eğitimi (Deprem, Yangın, Sel, Kaza, Kaybolma) Kitap ve YouTube butonlarıyla gelmeli', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DisasterEmergencyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Afet Eğitimleri'), findsOneWidget);
      expect(find.text('Afet Sözlüğü'), findsOneWidget);

      // 5 Konu
      expect(find.text('Deprem Eğitimi'), findsOneWidget);
      expect(find.text('Yangın Eğitimi'), findsOneWidget);
      expect(find.text('Sel Eğitimi'), findsOneWidget);
      expect(find.text('Trafik Kazası Eğitimi'), findsOneWidget);
      expect(find.text('Kaybolma Eğitimi'), findsOneWidget);

      // Hem Kitap hem YouTube Butonları
      expect(find.text('Kitap Olarak Oku'), findsNWidgets(5));
      expect(find.text('YouTube Video'), findsNWidgets(5));
    });

    testWidgets('Deprem eğitimi Kitap Olarak Oku tıklandığında interaktif sayfa görüntüleyici açılmalı', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DisasterEmergencyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kitap Olarak Oku').first);
      await tester.pumpAndSettle();

      expect(find.text('Sayfa 1 / 5'), findsOneWidget);
      expect(find.text('Deprem Başladığında Sakin Ol'), findsOneWidget);
      expect(find.text('Sonraki'), findsOneWidget);

      // 2. sayfaya geç (ÇÖK!)
      await tester.tap(find.text('Sonraki'));
      await tester.pumpAndSettle();

      expect(find.text('Sayfa 2 / 5'), findsOneWidget);
      expect(find.text('1. Adım: ÇÖK!'), findsOneWidget);
      expect(find.text('Önceki'), findsOneWidget);
    });

    testWidgets('Afet Sözlüğü sekmesi açıldığında alfabetik terimler ve arama çalışmalı', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DisasterEmergencyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Sözlük sekmesine tıkla
      await tester.tap(find.text('Afet Sözlüğü'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sözlükte kelime ara'), findsOneWidget);
      expect(find.text('Tümü'), findsWidgets);

      // Arama yap: "Düdük"
      await tester.enterText(find.byType(TextField), 'Düdük');
      await tester.pumpAndSettle();

      final dudukInList = find.descendant(of: find.byType(ListView), matching: find.text('Düdük'));
      expect(dudukInList, findsOneWidget);
      expect(find.textContaining('üfleyerek yüksek ses çıkardığımız'), findsOneWidget);

      // Tıklayınca büyük resimli detay modalı açılmalı
      await tester.tap(dudukInList);
      await tester.pumpAndSettle();

      expect(find.text('Sesli Oku / Tekrar Dinle'), findsOneWidget);
    });
  });
}
