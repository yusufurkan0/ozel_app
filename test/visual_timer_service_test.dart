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

  group('VisualTimerService Unit Tests', () {
    test('Initial values and state setup', () {
      final service = VisualTimerService.instance;
      service.setMinutes(5);
      expect(service.totalSeconds, 300);
      expect(service.remainingSeconds, 300);
      expect(service.isRunning, false);
      expect(service.isAlarmActive, false);
      expect(service.formattedTime, '05:00');
    });

    test('Adjust minutes clamps between 1 and 60 minutes', () {
      final service = VisualTimerService.instance;
      service.setMinutes(10);
      expect(service.totalSeconds, 600);

      service.adjustMinutes(5);
      expect(service.totalSeconds, 900); // 15 mins

      service.adjustMinutes(-20);
      expect(service.totalSeconds, 60); // Clamped to 1 min (60 sec)
    });

    test('Start, pause, and reset timer state transitions', () {
      final service = VisualTimerService.instance;
      service.setMinutes(3);
      expect(service.totalSeconds, 180);

      service.startTimer();
      expect(service.isRunning, true);
      expect(service.endTime, isNotNull);

      service.pauseTimer();
      expect(service.isRunning, false);

      service.resetTimer();
      expect(service.isRunning, false);
      expect(service.remainingSeconds, 180);
      expect(service.endTime, isNull);
    });

    test('Stop alarm deactivates alarm state', () {
      final service = VisualTimerService.instance;
      service.stopAlarm();
      expect(service.isAlarmActive, false);
    });
  });

  group('VisualTimerScreen Widget Tests', () {
    testWidgets('Renders VisualTimerScreen and controls', (WidgetTester tester) async {
      final service = VisualTimerService.instance;
      service.setMinutes(5);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VisualTimerService>.value(
            value: service,
            child: const VisualTimerScreen(),
          ),
        ),
      );

      expect(find.text('Kronometre & Görsel Süre'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('Başlat'), findsOneWidget);
      expect(find.text('Sıfırla'), findsOneWidget);
      expect(find.text('5 dk'), findsWidgets);
    });
  });
}
