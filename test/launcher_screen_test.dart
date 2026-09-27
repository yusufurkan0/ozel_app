import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ozel_app/screens/home_screen.dart';
import 'package:ozel_app/services/game_progress_service.dart';
import 'package:ozel_app/services/predictive_engine.dart';

void main() {
  testWidgets('Launcher HomeScreen renders 12 grid modules and dock items', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gameProgress = GameProgressService();
    final predictive = PredictiveEngine();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameProgress),
          ChangeNotifierProvider.value(value: predictive),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 12 Modules Exist
    expect(find.text('Takvim'), findsOneWidget);
    expect(find.text('Kronometre'), findsOneWidget);
    expect(find.text('Görev Listesi'), findsOneWidget);
    expect(find.text('Kendini\nDeğerlendirme'), findsOneWidget);
    expect(find.text('Nakit Para\nDefteri'), findsOneWidget);
    expect(find.text('Kredi Kartı\nDefteri'), findsOneWidget);
    expect(find.text('Kaybolma'), findsOneWidget);
    expect(find.text('Afet ve\nAcil Durum'), findsOneWidget);
    expect(find.text('Serbest\nZaman Planı'), findsOneWidget);
    expect(find.text('Mutfak'), findsOneWidget);
    expect(find.text('Oyun ve\nSosyal Öyküler'), findsOneWidget);
    expect(find.text('Destek\nKişilerim'), findsOneWidget);

    // Verify Dock is removed
    expect(find.byIcon(Icons.phone_rounded), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsNothing);
  });
}
