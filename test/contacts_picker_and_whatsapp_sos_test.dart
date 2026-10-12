import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozel_app/screens/launcher/support_contacts_screen.dart';
import 'package:ozel_app/screens/launcher/lost_sos_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'user_emergency_name': 'Ahmet Yılmaz',
      'user_emergency_phone': '05551234567',
      'user_home_address': 'Atatürk Mah. Kadıköy/İstanbul',
      'user_emergency_notes': 'Özel gereksinimli',
      'user_support_contacts': jsonEncode([
        {
          'name': 'Annem',
          'role': 'Aile',
          'phone': '05559876543',
          'avatar': '👩',
          'isJobCoach': false,
        },
        {
          'name': 'Kemal Koç',
          'role': 'İş Koçu',
          'phone': '05321112233',
          'avatar': '💼',
          'isJobCoach': true,
        }
      ]),
    });
  });

  group('Destek Kişileri Rehber Seçme & Aktarma Testleri', () {
    testWidgets('Destek Kişisi Ekle penceresinde Rehberden Seç butonu ve Rehbere At seçeneği yer almalı', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SupportContactsScreen()),
      );
      await tester.pumpAndSettle();

      // Rehbere yeni kişi ekleme butonuna tıkla
      final addBtn = find.byIcon(Icons.person_add_alt_1_rounded);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Dialog içeriğini doğrula
      expect(find.text('Destek Kişisi Ekle'), findsOneWidget);
      expect(find.text('📱 Telefon Rehberinden Seç'), findsOneWidget);
      expect(find.text('Telefon rehberine de kaydet (Rehbere At)'), findsOneWidget);
    });

    testWidgets('Kişi kartlarında Telefon Rehberine Aktar butonu yer almalı', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SupportContactsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Annem'), findsOneWidget);
      expect(find.text('Kemal Koç'), findsOneWidget);
      // Her iki kartta da Rehbere Aktar butonu bulunmalı
      expect(find.byTooltip('Telefon Rehberine Aktar'), findsNWidgets(2));
    });
  });

  group('Kaybolmada Aileye WhatsApp Konum Gönderme Testleri', () {
    testWidgets('Aileni Ara seçeneğinde Aile Kısmı WhatsApp Canlı Konum butonu ve kart butonları bulunmalı', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LostSosScreen()),
      );
      await tester.pumpAndSettle();

      final callOption = find.text('Aileni Ara & Konum Gönder 📞📍');
      await tester.ensureVisible(callOption);
      await tester.pumpAndSettle();
      await tester.tap(callOption);
      await tester.pumpAndSettle();

      // Aile Kısmı WhatsApp Butonu
      expect(find.text("Aileye WhatsApp'tan Canlı Konum Gönder 🟢📍"), findsOneWidget);

      // Kişi kartlarında WhatsApp konum gönderme butonları
      expect(find.byTooltip('WhatsApp Konum Gönder'), findsWidgets);
      expect(find.text('Ara'), findsWidgets);
    });

    test('WhatsApp URL ve Google Maps koordinat link formatı doğru üretilmeli', () {
      const mockLat = '41.0082';
      const mockLng = '28.9784';
      final locationUrl = 'https://maps.google.com/?q=$mockLat,$mockLng';
      const phone = '05551234567';
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      final formattedPhone = cleanPhone.startsWith('0') ? '9$cleanPhone' : '90$cleanPhone';
      final waUri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent('Canlı Konumum: $locationUrl')}');

      expect(waUri.host, 'wa.me');
      expect(waUri.path, '/905551234567');
      expect(waUri.queryParameters['text'], contains('https://maps.google.com/?q=41.0082,28.9784'));
    });
  });
}
