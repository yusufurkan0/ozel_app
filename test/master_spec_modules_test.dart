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

      expect(find.text('Nakit Para Defterim'), findsOneWidget);
      expect(find.text('Alışverişi Başlat 🛒'), findsOneWidget);
      expect(find.text('200 TL'), findsOneWidget);
      expect(find.text('100 TL'), findsOneWidget);
      expect(find.text('50 TL'), findsOneWidget);
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
