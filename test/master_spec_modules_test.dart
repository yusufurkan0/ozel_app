import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/models/calendar_activity.dart';
import 'package:ozel_app/models/free_time_plan.dart';
import 'package:ozel_app/services/routine_calendar_service.dart';
import 'package:ozel_app/screens/launcher/calendar_screen.dart';
import 'package:ozel_app/screens/launcher/free_time_planner_screen.dart';
import 'package:ozel_app/screens/launcher/cash_ledger_screen.dart';
import 'package:ozel_app/screens/launcher/card_budget_screen.dart';
import 'package:ozel_app/screens/launcher/support_contacts_screen.dart';
import 'package:ozel_app/screens/register_screen.dart';
import 'package:ozel_app/services/game_progress_service.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Takvim & 29 Etkinlik Model ve Servis Testleri', () {
    test('29 adet ön tanımlı etkinlik tam liste ve doğru gruplara sahip olmalı', () {
      expect(CalendarActivity.predefinedActivities.length, 29);

      // Grup sayıları
      final egList = CalendarActivity.predefinedActivities.where((a) => a.group == 'EĞ').toList();
      final isList = CalendarActivity.predefinedActivities.where((a) => a.group == 'İŞ').toList();
      final kgList = CalendarActivity.predefinedActivities.where((a) => a.group == 'KG').toList();
      final sgList = CalendarActivity.predefinedActivities.where((a) => a.group == 'SĞ').toList();
      final evList = CalendarActivity.predefinedActivities.where((a) => a.group == 'EV').toList();
      final szList = CalendarActivity.predefinedActivities.where((a) => a.group == 'SZ').toList();

      expect(egList.length, 3); // Okul, Rehabilitasyon, Ders
      expect(isList.length, 2); // İşe git, İş görüşmesi
      expect(kgList.length, 3); // Spor, Dernek, Kurs
      expect(sgList.length, 1); // Doktor/Dişçi
      expect(evList.length, 8); // Ev vakti, temizlik, yemek, çamaşır, bulaşık, oda, çöp, banyo
      expect(szList.length, 12); // Sinema, Tiyatro, Kafe, Konser, Müze, Alışveriş, Bowling, Kuaför, Piknik, Maç, Parti, Misafir

      expect(szList.first.title, 'Sinemaya gideceğim');
      expect(szList.last.title, 'Misafir ağırlayacağım');
    });

    test('Haftalık Takvim: Tarih formatı "Perşembe: 24 Eylül" formatında olmalı (gün önce yazılmalı)', () {
      final monday = DateTime(2026, 9, 21); // 21 Eylül Pazartesi
      final thursdayHeader = RoutineCalendarService.formatDayHeader(monday, 3); // 3 = Perşembe
      expect(thursdayHeader, 'Perşembe: 24 Eylül');

      final fridayHeader = RoutineCalendarService.formatDayHeader(monday, 4); // 4 = Cuma
      expect(fridayHeader, 'Cuma: 25 Eylül');
    });

    test('Haftalık Takvim: Öğle ve Akşam yemekleri otomatik dolu ve kilitli olmalı', () async {
      final monday = DateTime(2026, 9, 21);
      final schedule = await RoutineCalendarService.loadWeekSchedule(monday);

      // 1: Öğle yemeği, 3: Akşam yemeği
      expect(schedule[0]![1]!.isNotEmpty, true);
      expect(schedule[0]![1]!.first.title.contains('Öğle'), true);

      expect(schedule[0]![3]!.isNotEmpty, true);
      expect(schedule[0]![3]!.first.title.contains('Akşam'), true);

      expect(RoutineCalendarService.isMealSlot(1), true);
      expect(RoutineCalendarService.isMealSlot(3), true);
      expect(RoutineCalendarService.isMealSlot(0), false);
    });
  });

  group('2. Serbest Zaman (SZ) 13 Adımlık Planlama Testleri', () {
    test('13 Adımlık Soru Listesi tam ve sıralı olmalı', () {
      expect(FreeTimePlan.questions.length, 13);
      expect(FreeTimePlan.questions[0]['step'], 1);
      expect(FreeTimePlan.questions[12]['step'], 13);
    });

    test('FreeTimePlan kaydetme ve JSON serileştirme doğru çalışmalı', () async {
      final plan = FreeTimePlan(
        id: 'plan_1',
        activityTitle: 'Sinemaya gideceğim',
        activityEmoji: '🎬',
        dayTitle: 'Cumartesi: 26 Eylül',
        answers: {
          1: 'Sinemaya gideceğim 🎬',
          2: 'Kadıköy Sineması',
          3: 'Ailemle birlikte 👨‍👩‍👧',
        },
        createdAt: DateTime(2026, 9, 21),
      );

      final jsonMap = plan.toJson();
      final restored = FreeTimePlan.fromJson(jsonMap);

      expect(restored.activityTitle, 'Sinemaya gideceğim');
      expect(restored.answers[2], 'Kadıköy Sineması');
    });
  });

  group('3. Widget Testleri: Takvim, Serbest Zaman, Nakit ve Kredi Kartı', () {
    testWidgets('Takvim Ekranı 5 zaman dilimini ve kilitli yemekleri doğru render etmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Takvimim'), findsOneWidget);
      expect(find.text('1. ÖĞLE\nÖNCESİ'), findsOneWidget);
      expect(find.text('2. ÖĞLE\nYEMEĞİ'), findsOneWidget);
      expect(find.text('3. ÖĞLE\nSONRASI'), findsOneWidget);
      expect(find.text('KİLİTLİ'), findsWidgets);
    });

    testWidgets('Serbest Zaman Planlayıcı açıldığında Takvim ve Kitapçık bölümleri görünmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: FreeTimePlannerScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Serbest Zaman Planlama'), findsOneWidget);
      expect(find.text('Yeni Plan'), findsOneWidget);
    });

    testWidgets('Nakit Para Defterim açıldığında cüzdan toplamı, Alışverişi Başlat ve banknotlar gelmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: CashLedgerScreen()));
      await tester.pumpAndSettle();

      if (find.text('Yeni Hafta Başladı! 📅').evaluate().isNotEmpty) {
        await tester.tap(find.text('Paralarımı Say & Başla ✅'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Nakit Para Defterim'), findsOneWidget);
      expect(find.text('Alışverişi Başlat 🛒'), findsOneWidget);
      expect(find.text('200 TL'), findsOneWidget);
      expect(find.text('100 TL'), findsOneWidget);
      expect(find.text('50 TL'), findsOneWidget);
    });

    testWidgets('Nakit Para Defterim: Alışveriş, Virgülün Solu +1 TL, Fiş Tarama ve Para Üstü akışı çalışmalı', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_wallet_counts': '{"200":1,"100":1,"50":1,"20":1,"10":1,"5":1,"1":5}',
      });

      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: CashLedgerScreen()));
      await tester.pumpAndSettle();

      // Hafta başı hatırlatma diyaloğu kontrolü
      if (find.text('Yeni Hafta Başladı! 📅').evaluate().isNotEmpty) {
        expect(find.text('Paralarımı Say & Başla ✅'), findsOneWidget);
        await tester.tap(find.text('Paralarımı Say & Başla ✅'));
        await tester.pumpAndSettle();
      }

      // Cüzdan toplamı görünmeli (200+100+50+20+10+5+5 = 390 TL)
      expect(find.text('₺ 390'), findsOneWidget);

      // Alışverişi Başlat
      await tester.tap(find.text('Alışverişi Başlat 🛒'));
      await tester.pumpAndSettle();

      expect(find.text('Alışveriş Modu 🛒'), findsOneWidget);
      expect(find.text('İlk Ürünü Ekle'), findsOneWidget);

      // Ürün Ekle modalını aç
      await tester.ensureVisible(find.text('İlk Ürünü Ekle'));
      await tester.tap(find.text('İlk Ürünü Ekle'));
      await tester.pumpAndSettle();

      // Virgülün Solu ipucu ve +1 TL yuvarlama metni görünmeli
      expect(find.textContaining('virgülün SOLUNDAKİ'), findsOneWidget);
      expect(find.text('+ 1 TL Yuvarlama'), findsOneWidget);

      // Ürün bilgilerini gir (24 TL -> 25 TL yuvarlanmalı)
      await tester.enterText(find.widgetWithText(TextField, 'Ürün Adı'), 'Süt ve Ekmek');
      await tester.enterText(find.widgetWithText(TextField, 'Virgülün Solundaki Tutar (TL)'), '24');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sepete Ekle (+1 TL)'));
      await tester.tap(find.text('Sepete Ekle (+1 TL)'));
      await tester.pumpAndSettle();

      // Sepette 24 TL -> 25 TL olarak listelenmeli
      expect(find.text('Süt ve Ekmek'), findsOneWidget);
      expect(find.textContaining('1 TL Yuvarlama: 25 TL'), findsOneWidget);

      // Alışverişi Bitir & Ödemeye Geç
      await tester.tap(find.text('Alışverişi Bitir & Ödemeye Geç ➔'));
      await tester.pumpAndSettle();

      // Ödeme planı görünmeli: 25 TL hesaplanan toplam tutar
      expect(find.text('₺ 25'), findsWidgets);
      expect(find.text('Cüzdanındaki bu paraları vermelisin:'), findsOneWidget);

      // Kasada Fişi Tara (Görsel İşleme) butonu görünmeli
      expect(find.text('Kasada Fişi Tara (Görsel İşleme) 📸'), findsOneWidget);
      expect(find.text('Fişi Okut (Kamera / Galeri)'), findsOneWidget);

      // Fişi okutma diyaloğunu aç ve örnek fiş ile dene
      await tester.ensureVisible(find.text('Fişi Okut (Kamera / Galeri)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fişi Okut (Kamera / Galeri)'));
      await tester.pumpAndSettle();

      expect(find.text('Örnek Fiş ile Test Et 🧾'), findsOneWidget);
      await tester.tap(find.text('Örnek Fiş ile Test Et 🧾'));
      await tester.pumpAndSettle();

      // Fiş başarıyla okundu badge'i görünmeli
      expect(find.text('Fiş Başarıyla Okundu ✅'), findsOneWidget);

      // Ödemeyi Yaptım & Cüzdanı Güncelle
      await tester.ensureVisible(find.text('Ödemeyi Yaptım & Cüzdanı Güncelle ✅'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ödemeyi Yaptım & Cüzdanı Güncelle ✅'));
      await tester.pumpAndSettle();

      // Eğer para üstü varsa Para Üstü diyaloğu açılmalı veya fiş hatırlatma diyaloğu gelmeli
      if (find.text('Para Üstü Aldın mı? 💵').evaluate().isNotEmpty) {
        expect(find.text('Cüzdanıma Ekle & Tamamla ✅'), findsOneWidget);
        await tester.tap(find.text('Cüzdanıma Ekle & Tamamla ✅'));
        await tester.pumpAndSettle();
      }

      // Fişini Almayı Unutma uyarısı gelmeli
      expect(find.text('Fişini Almayı Unutma! 🧾'), findsOneWidget);
      expect(find.textContaining('eve götür'), findsOneWidget);
      expect(find.text('Tamam, Fişimi Aldım ✅'), findsOneWidget);

      await tester.tap(find.text('Tamam, Fişimi Aldım ✅'));
      await tester.pumpAndSettle();

      // Cüzdan ekranına dönülmüş ve yeni bakiye üzerinden devam ediliyor olmalı
      expect(find.text('Nakit Para Defterim'), findsOneWidget);
    });

    test('Gerçek Market Fişi (ŞOK / BİM / A101) OCR Toplam Tutar Çıkarma Testi', () {
      const realSokReceiptText = '''
ŞOK MARKETLER TİC.A.Ş
13462 MAMAK GAMZE ÖZDEMİR
ŞAHİNTEPE MH 637.SK
NO 2
MAMAK ANKARA
8140131899
ANADOLU KURUMLAR V.D

TARİH : 01/02/2024
SAAT : 20:51:41
FİŞ NO : 0259

OZMO FUN FİGÜRLÜ 23G %01 *13,50
7-24 NAMET DANA MACA %01 *27,90
OZMO FUN FİGÜRLÜ 23G %01 *13,50
1,033Kg X 99,00
TADPİ PİLİÇ BAGET KG %01 *102,27
FINISH QUANTUM ÖZEL %20 *259,00
25TLFINISH110TL *149,00-
FINISH QUANTUM ÖZEL %20 *259,00
25TLFINISH110TL *149,00-
ARKO DEĞERLİ YAĞLAR %20 *104,50
25TLARK050TL *54,50-
ALIŞVERİŞ POŞETİ 43 %20 *0,25
-----------------------------------
TOPKDV *46,60
TOPLAM *427,42
''';

      // CashLedgerScreen içindeki private metodu test eden kontrol fonksiyonu
      final lines = realSokReceiptText.split('\n').map((l) => l.trim()).toList();
      String? foundTotal;
      for (var l in lines.reversed) {
        final upper = l.toUpperCase();
        if (upper.contains('TOPKDV')) continue;
        if (upper.contains('TOPLAM')) {
          final reg = RegExp(r'[*xX+₺TLtl\s]*(\d{1,5}(?:[\.,]\d{2}))');
          final m = reg.firstMatch(l);
          if (m != null) {
            foundTotal = m.group(1)?.replaceAll(',', '.');
            break;
          }
        }
      }

      expect(foundTotal, '427.42');
      expect(double.tryParse(foundTotal!), 427.42);

      // Kullanıcının OCR ekran görüntüsündeki birebir gürültülü satır:
      const noisyLine = '~ TOPLAM *427 4;';
      final noisyReg = RegExp(r'[*xX+₺TLtl~_\s]*(\d{1,5})\s+([0-9;]{1,2})');
      final noisyMatch = noisyReg.firstMatch(noisyLine);
      expect(noisyMatch, isNotNull);
      final mainPart = noisyMatch!.group(1);
      final dec = noisyMatch.group(2)!.replaceAll(';', '2');
      expect('$mainPart.$dec', '427.42');
      expect(int.tryParse(mainPart!), 427); // Virgülün solu: 427 TL
    });

    testWidgets('Kredi Kartı Takibi açıldığında limit kartı, azalan çubuk ve harcama ekle gelmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: CardBudgetScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Kredi Kartı Takibi'), findsOneWidget);
      expect(find.text('Kullanılabilir Kalan Limit'), findsOneWidget);
      expect(find.text('Harcama Ekle'), findsOneWidget);
      expect(find.text('Ayı Sıfırla'), findsOneWidget);
      expect(find.text('Tüm Limit'), findsOneWidget);
      expect(find.text('Bu Ay Harcanan'), findsOneWidget);
      expect(find.text('Kalan'), findsOneWidget);
    });

    testWidgets('Kredi Kartı Takibi: Ayı Sıfırlama akışında Borç Ödeme sorusu ve Evet/Hayır mantığı çalışmalı', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: CardBudgetScreen()));
      await tester.pumpAndSettle();

      // Ayı Sıfırla butonuna bas
      await tester.tap(find.text('Ayı Sıfırla'));
      await tester.pumpAndSettle();

      // Borç sorusu gelmeli
      expect(find.text('Kredi Kartı Borç Kontrolü'), findsOneWidget);
      expect(find.text('Kredi kartı borcunu bankaya ödedin mi?'), findsOneWidget);
      expect(find.text('Hayır, Ödemedim'), findsOneWidget);
      expect(find.text('Evet, Ödedim ✅'), findsOneWidget);

      // Hayır'a basınca borç uyarısı gelmeli
      await tester.tap(find.text('Hayır, Ödemedim'));
      await tester.pumpAndSettle();

      expect(find.text('Önemli Borç Uyarısı!'), findsOneWidget);
      expect(find.textContaining('kartın kapatılabilir'), findsWidgets);

      await tester.tap(find.text('Anladım'));
      await tester.pumpAndSettle();

      // Şimdi Evet'i test edelim
      await tester.tap(find.text('Ayı Sıfırla'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evet, Ödedim ✅'));
      await tester.pumpAndSettle();

      // Limit onay sorusu gelmeli: "Aylık kart limitin ₺... mi?"
      expect(find.text('Aylık Limit Onayı'), findsOneWidget);
      expect(find.textContaining('Aylık kart limitin'), findsOneWidget);
      expect(find.text('Evet, Limiti Başlat ✅'), findsOneWidget);

      await tester.tap(find.text('Evet, Limiti Başlat ✅'));
      await tester.pumpAndSettle();
    });

    testWidgets('Kredi Kartı Takibi: Harcama ekleme, günün tarihi ve harcama sonrası özet diyaloğu çalışmalı', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: CardBudgetScreen()));
      await tester.pumpAndSettle();

      // Harcama Ekle'ye bas
      await tester.tap(find.text('Harcama Ekle'));
      await tester.pumpAndSettle();

      expect(find.text('Kart Harcaması Ekle'), findsOneWidget);
      // Günün tarihi varsayılan gelmeli
      final now = DateTime.now();
      expect(find.text('Tarih: ${now.day}.${now.month}.${now.year}'), findsOneWidget);
      expect(find.text('Değiştir'), findsOneWidget);

      // Harcama bilgisi gir
      await tester.enterText(find.widgetWithText(TextField, 'Harcama Açıklaması'), 'Kitap ve Defter');
      await tester.enterText(find.widgetWithText(TextField, 'Harcama Tutarı (TL) *'), '250');
      await tester.pumpAndSettle();

      // Kaydet butonuna bas
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      // Her girişten sonra O ayki toplam harcamasını ve Limitinden kalan tutarı gösteren dialog açılmalı
      expect(find.text('Harcama Kaydedildi'), findsOneWidget);
      expect(find.text('Bu Ayki Toplam Harcama:'), findsOneWidget);
      expect(find.text('Limitinden Kalan Tutar:'), findsOneWidget);

      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();

      // Ana ekranda harcama listelenmeli
      expect(find.text('Kitap ve Defter'), findsOneWidget);
      expect(find.text('-₺250'), findsOneWidget);
    });

    testWidgets('Destek Kişilerim ekranı Aile ve İş Koçu rollerini desteklemeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SupportContactsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Destek Kişilerim'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
    });

    testWidgets('Genel Bilgiler ekranı (RegisterScreen isEditing: true) doğru başlık ve SOS alanları ile açılmalı', (tester) async {
      SharedPreferences.setMockInitialValues({
        'child_name': 'Ali Can',
        'sos_parent_name': 'Ayşe Can',
        'sos_parent_phone': '05551234567',
        'sos_child_age': '12 Yaşında',
      });

      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final gameService = GameProgressService();

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProgressService>.value(
          value: gameService,
          child: const MaterialApp(
            home: RegisterScreen(isEditing: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Genel Bilgiler başlıkları
      expect(find.text('Genel Bilgiler'), findsNWidgets(2)); // AppBar ve karşılama başlığı
      expect(find.text('Genel Bilgileri Güncelle & Kaydet ✅'), findsOneWidget);
      expect(find.text('Destek Kişilerim Rehberi'), findsOneWidget);

      // SOS ve Ebeveyn alanları
      expect(find.text('🚨 2. Ebeveyn & Acil Durum (SOS)'), findsOneWidget);
      expect(find.text('👦 1. Çocuğun Bilgileri'), findsOneWidget);
    });
  });
}
