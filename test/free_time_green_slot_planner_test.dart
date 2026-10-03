import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/models/calendar_activity.dart';
import 'package:ozel_app/models/free_time_plan.dart';
import 'package:ozel_app/screens/launcher/free_time_planner_screen.dart';
import 'package:ozel_app/services/routine_calendar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Serbest Zaman Planlama & Yeşil Slot Entegrasyon Testleri', () {
    testWidgets('Serbest Zaman ekranı açıldığında rehber başlığı ve Yeni Plan butonu görünmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: FreeTimePlannerScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Serbest Zaman Planlama'), findsOneWidget);
      expect(find.text('Yeni Plan'), findsOneWidget);
      expect(find.text('Etkinlik Ekle & Planla'), findsOneWidget);
    });

    testWidgets('Yeni Plan butonuna basıldığında Serbest Zaman etkinlikleri listelenmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: FreeTimePlannerScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yeni Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Serbest Zaman Etkinliği Seç'), findsOneWidget);
      expect(find.text('Sinemaya gideceğim'), findsOneWidget);
      expect(find.text('Kafeye gideceğim'), findsOneWidget);
    });

    testWidgets('Etkinlik seçildiğinde "Yeşil renkli yerlerden seç" takvim slot seçicisi açılmalı', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: FreeTimePlannerScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yeni Plan'));
      await tester.pumpAndSettle();

      // "Sinemaya gideceğim" etkinliğini seç
      await tester.tap(find.text('Sinemaya gideceğim'));
      await tester.pumpAndSettle();

      // Takvim slot seçici modalı açılmalı
      expect(find.text('Yeşil renkli yerlerden seç'), findsOneWidget);
      expect(find.text('Haftalık Takvimde Zaman Seç'), findsOneWidget);
      expect(find.text('DOLU ⛔'), findsWidgets); // Yemek saatleri dolu
      expect(find.text('SEÇ 🟢'), findsWidgets); // Boş slotlar yeşil
    });

    testWidgets('Dolu slot seçilirse "Burası dolu, yeşillerden seç!" uyarısı verilmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: FreeTimePlannerScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yeni Plan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sinemaya gideceğim'));
      await tester.pumpAndSettle();

      // Dolu olan bir slota (örneğin ilk DOLU butonuna / yemek saatine) bas
      final doluFinder = find.text('DOLU ⛔').first;
      await tester.tap(doluFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // "Burası dolu, yeşillerden seç!" uyarısı gelmeli
      expect(find.text('Burası dolu, yeşillerden seç!'), findsOneWidget);
    });

    testWidgets('Yeşil slot seçildiğinde takvime kaydedilmeli ve 13 adımlık soru sihirbazına geçilmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: FreeTimePlannerScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yeni Plan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sinemaya gideceğim'));
      await tester.pumpAndSettle();

      // Yeşil olan ilk boş slota bas
      final secFinder = find.text('SEÇ 🟢').first;
      await tester.tap(secFinder);
      await tester.pumpAndSettle();

      // Soru sihirbazı başlamalı (Soru 2 / 13)
      expect(find.text('Etkinlik Planlama'), findsOneWidget);
      expect(find.text('Soru 2 / 13'), findsOneWidget);
      expect(find.text('Bitir'), findsOneWidget);

      // Takvim veritabanının güncellendiğini doğrula
      final currentMonday = RoutineCalendarService.getMondayOfWeek(DateTime.now());
      final szList = await RoutineCalendarService.getFreeTimeActivitiesForWeek(currentMonday);
      expect(szList.any((item) => (item['activity'] as CalendarActivity).title == 'Sinemaya gideceğim'), isTrue);
    });

    testWidgets('Bitir tuşuna basıldığında eksik sorular varsa uyarı verip o soruya yönlendirmeli', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: FreeTimePlannerScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yeni Plan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sinemaya gideceğim'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SEÇ 🟢').first);
      await tester.pumpAndSettle();

      // Henüz tüm sorular cevaplanmadan "Bitir" butonuna bas
      await tester.tap(find.text('Bitir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Eksik sorular için SnackBar uyarısı verilmeli
      expect(find.textContaining('soruları da cevaplayın'), findsOneWidget);
    });
  });
}
