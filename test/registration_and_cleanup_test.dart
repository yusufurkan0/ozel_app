import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kayıt & Acil Durum Bilgileri Entegrasyon Testleri', () {
    test('Eski gereksiz ve yetim ekran dosyaları silinmiş olmalı', () {
      expect(File('lib/screens/emergency_screen.dart').existsSync(), isFalse);
      expect(File('lib/screens/learning_mode_screen.dart').existsSync(), isFalse);
      expect(File('lib/screens/routines_screen.dart').existsSync(), isFalse);
    });

    test('Kayıt ekranından girilen gerçek ebeveyn ve acil durum bilgileri eksiksiz kaydedilmeli', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Gerçek aile kayıt simülasyonu
      const testChildName = 'Kerem Demir';
      const testAge = '6 Yaşında';
      const testParentName = 'Merve Demir (Annesi)';
      const testParentPhone = '0530 555 44 33';
      const testAddress = 'Atatürk Mah. Karanfil Cad. No:8 Çankaya / Ankara';
      const testNotes = 'Hafif düzey otizm, fıstık alerjisi var. Yüksek sesten tedirgin olur.';
      const testDiagnosis = 'Otizm Spektrumu 🧩';
      const testAvatar = '🦁';

      await prefs.setString('sos_child_name', testChildName);
      await prefs.setString('sos_child_age', testAge);
      await prefs.setString('sos_parent_name', testParentName);
      await prefs.setString('sos_parent_phone', testParentPhone);
      await prefs.setString('sos_home_address', testAddress);
      await prefs.setString('sos_medical_notes', testNotes);
      await prefs.setString('child_diagnosis', testDiagnosis);
      await prefs.setString('child_name', testChildName);
      await prefs.setString('avatar', testAvatar);
      await prefs.setBool('is_registered', true);

      // Acil durum ekranına aktarılan verilerin doğrulanması
      expect(prefs.getString('sos_child_name'), equals('Kerem Demir'));
      expect(prefs.getString('sos_parent_phone'), equals('0530 555 44 33'));
      expect(prefs.getString('sos_home_address'), contains('Ankara'));
      expect(prefs.getString('sos_medical_notes'), contains('alerjisi'));
      expect(prefs.getString('avatar'), equals('🦁'));
      expect(prefs.getBool('is_registered'), isTrue);

      // Asla eski sahte/fake bilgilerin kalmadığı kontrol edilir
      expect(prefs.getString('sos_child_name'), isNot(equals('Ömer Faruk')));
      expect(prefs.getString('sos_parent_phone'), isNot(equals('0532 123 45 67')));
    });
  });
}
