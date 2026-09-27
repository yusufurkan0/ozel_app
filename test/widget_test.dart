import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/main.dart';

void main() {
  testWidgets('Uygulama açılış testi', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const OzelApp());
    await tester.pumpAndSettle();

    // Yeni ana ekranın 12 modülüyle doğrudan açıldığını kontrol et
    expect(find.text('Takvim'), findsOneWidget);
    expect(find.text('Kronometre'), findsOneWidget);
    expect(find.text('Görev Listesi'), findsOneWidget);
  });
}
