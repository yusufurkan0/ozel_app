import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/services/timer_service.dart';
import 'package:ozel_app/screens/launcher/visual_timer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dual Visual Timer & iPhone Style Tests', () {
    test('Timer 1 and Timer 2 can run independently with custom times and sounds', () {
      final service = VisualTimerService.instance;

      // Set Timer 1 to 1 hour, 15 mins, 30 secs
      service.setTimer1Time(1, 15, 30);
      expect(service.timer1.totalSeconds, 3600 + (15 * 60) + 30);
      expect(service.timer1.hours, 1);
      expect(service.timer1.minutes, 15);
      expect(service.timer1.seconds, 30);

      // Set Timer 2 to 0 hours, 20 mins, 0 secs
      service.setTimer2Time(0, 20, 0);
      expect(service.timer2.totalSeconds, 20 * 60);

      // Start Timer 2
      service.startTimer2();
      expect(service.timer2.isRunning, true);
      expect(service.timer1.isRunning, false); // Timer 1 is unaffected

      // Pause Timer 2
      service.pauseTimer2();
      expect(service.timer2.isRunning, false);

      // Reset Timer 2
      service.resetTimer2();
      expect(service.timer2.remainingSeconds, 20 * 60);

      // Test sound selection
      service.setTimerSound(service.timer1, 'buzzer', 'Buzzer (Zil Sesi)');
      expect(service.timer1.soundKey, 'buzzer');
      expect(service.timer1.soundTitle, 'Buzzer (Zil Sesi)');
    });

    testWidgets('Renders iOS style timers and toggles dual timer mode', (WidgetTester tester) async {
      final service = VisualTimerService.instance;
      service.setDualMode(false);
      service.setTimer1Time(0, 5, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VisualTimerService>.value(
            value: service,
            child: const VisualTimerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and iOS wheel elements
      expect(find.text('Sayaçlar'), findsOneWidget);
      expect(find.text('+ 2. Sayaç'), findsOneWidget);
      expect(find.text('Sayaç 1'), findsWidgets);
      expect(find.text('Vazgeç'), findsOneWidget);
      expect(find.text('Başlat'), findsOneWidget);
      expect(find.text('Etiket'), findsOneWidget);
      expect(find.text('Sayaç Bitince'), findsOneWidget);

      // Tap "+ 2. Sayaç" to enable dual mode
      await tester.tap(find.text('+ 2. Sayaç'));
      await tester.pumpAndSettle();

      // Now both Sayaç 1 and Sayaç 2 should be on screen!
      expect(find.text('Sayaç 1'), findsWidgets);
      expect(find.text('Sayaç 2'), findsWidgets);
      expect(find.text('Tek Sayaç'), findsOneWidget);

      // Tap "Başlat" on Timer 1 to start running
      await tester.tap(find.text('Başlat').first);
      await tester.pump(const Duration(milliseconds: 100));

      expect(service.timer1.isRunning, true);
      expect(find.text('Duraklat'), findsWidgets);

      // Pause it
      await tester.tap(find.text('Duraklat').first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(service.timer1.isRunning, false);
    });

    testWidgets('Visual style toggle changes between circle and column', (WidgetTester tester) async {
      final service = VisualTimerService.instance;
      service.setDualMode(false);
      service.startTimer();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VisualTimerService>.value(
            value: service,
            child: const VisualTimerScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Circular clock is default
      expect(find.byType(CustomPaint), findsWidgets);

      // Toggle to column mode
      await tester.tap(find.byTooltip('Dikey Sütun Görünümü'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(service.timer1.visualStyle, 'column');
      expect(find.textContaining('Kalan: %'), findsOneWidget);

      service.resetTimer();
    });
  });
}
