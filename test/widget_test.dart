import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/main.dart';

void main() {
  testWidgets('Uygulama açılış testi - Profil tanımlıysa 12 modül ile açılmalı', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'child_name': 'Ali Can',
      'is_registered': true,
      'initial_info_completed': true,
    });

    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const OzelApp());
    await tester.pumpAndSettle();

    // Yeni ana ekranın 12 modülüyle açıldığını kontrol et
    expect(find.text('Takvim'), findsOneWidget);
    expect(find.text('Kronometre'), findsOneWidget);
    expect(find.text('Görev Listesi'), findsOneWidget);
  });

  testWidgets('Uygulama açılış testi - Bilgi doldurulmamışsa ilk açılışta Genel Bilgiler formu gelmeli', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const OzelApp());
    await tester.pumpAndSettle();

    // Bilgi doldurma kısmının (Genel Bilgiler) açıldığını kontrol et
    expect(find.text('Genel Bilgiler'), findsWidgets);
    expect(find.text('Daha Sonra'), findsOneWidget);
  });
}
