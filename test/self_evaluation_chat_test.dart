import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/screens/launcher/self_evaluation_screen.dart';

void main() {
  testWidgets('SelfEvaluationScreen renders 3 form selection buttons (İş, Okul, Gün)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SelfEvaluationScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Check header and buttons
    expect(find.text('Kendimi Değerlendiriyorum'), findsOneWidget);
    expect(find.text('Lütfen Bir Alan Seç:'), findsOneWidget);
    expect(find.text('İŞ'), findsOneWidget);
    expect(find.text('OKUL'), findsOneWidget);
    expect(find.text('GÜN'), findsOneWidget);
    expect(find.text('İşyerinde Günüm Nasıl Geçti?'), findsOneWidget);
    expect(find.text('Okulda Günüm Nasıl Geçti?'), findsOneWidget);
    expect(find.text('Günüm Nasıl Geçti?'), findsOneWidget);

    // Tap on Okul button
    await tester.tap(find.text('OKUL'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify chat screen loads with Okul questions
    expect(find.text('Okul Değerlendirmesi'), findsOneWidget);
    expect(find.textContaining('Soru 1 / 20'), findsOneWidget);
    expect(find.text('Tarihi Seç:'), findsOneWidget);

    // Confirm date question by clicking "Bu Tarihle Devam Et"
    await tester.tap(find.text('Bu Tarihle Devam Et'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Soru 2: Bugün okula vaktinde gittim mi?
    expect(find.text('Bugün okula vaktinde gittim mi?'), findsOneWidget);
    expect(find.text('Evet'), findsOneWidget);
    expect(find.text('Hayır'), findsOneWidget);

    // Answer Evet
    await tester.tap(find.text('Evet'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Soru 3: Bugün derslere saatinde girdim mi?
    expect(find.text('Bugün derslere saatinde girdim mi?'), findsOneWidget);
  });

  testWidgets('İşyeri form loads and navigates correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SelfEvaluationScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('İŞ'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('İşyeri Değerlendirmesi'), findsOneWidget);
    expect(find.textContaining('Soru 1 / 23'), findsOneWidget);
  });

  testWidgets('Tüm Gün form loads and navigates correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SelfEvaluationScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('GÜN'), 150);
    await tester.tap(find.text('GÜN'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Tüm Gün Değerlendirmesi'), findsOneWidget);
    expect(find.textContaining('Soru 1 / 19'), findsOneWidget);
  });
}
