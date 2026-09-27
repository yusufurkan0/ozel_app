import 'package:flutter_test/flutter_test.dart';
import 'package:ozel_app/models/user_account.dart';
import 'package:ozel_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth & Account Linking Tests', () {
    test('UserAccount JSON serialization round-trip', () {
      final original = UserAccount(
        username: 'can',
        password: 'password123',
        role: UserRole.student,
        displayName: 'Can Yılmaz',
        avatar: '🐰',
      );

      final json = original.toJson();
      final restored = UserAccount.fromJson(json);

      expect(restored.username, equals('can'));
      expect(restored.password, equals('password123'));
      expect(restored.role, equals(UserRole.student));
      expect(restored.displayName, equals('Can Yılmaz'));
      expect(restored.avatar, equals('🐰'));
      expect(restored.isStudent, isTrue);
      expect(restored.isParent, isFalse);
    });

    test('AuthService starts with empty accounts on clean install (no demo accounts)', () async {
      final auth = AuthService();
      await auth.initialize();

      expect(auth.allAccounts.isEmpty, isTrue);
      expect(auth.getAccount('ali'), isNull);
      expect(auth.getAccount('anne'), isNull);
    });

    test('AuthService login verifies credentials and sets active session', () async {
      final auth = AuthService();
      await auth.initialize();

      // Test kullanıcısını kaydet
      final reg = await auth.register(
        username: 'can_test',
        password: 'password456',
        role: UserRole.student,
        displayName: 'Can',
      );
      expect(reg.success, isTrue);

      await auth.logout();
      expect(auth.isLoggedIn, isFalse);

      // Hatalı kullanıcı adı
      final wrongUser = await auth.login(username: 'olmayan_biri', password: '123');
      expect(wrongUser.success, isFalse);
      expect(wrongUser.error, contains('bulunamadı'));

      // Hatalı şifre
      final wrongPass = await auth.login(username: 'can_test', password: 'wrongpassword');
      expect(wrongPass.success, isFalse);
      expect(wrongPass.error, contains('Hatalı şifre'));

      // Doğru giriş
      final correctLogin = await auth.login(username: 'can_test', password: 'password456');
      expect(correctLogin.success, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.username, equals('can_test'));
      expect(auth.currentUser?.isStudent, isTrue);

      // Çıkış yap (Logout)
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('AuthService registers new student and parent accounts', () async {
      final auth = AuthService();
      await auth.initialize();

      // Yeni öğrenci kaydet
      final regStudent = await auth.register(
        username: 'mehmet',
        password: '5678',
        role: UserRole.student,
        displayName: 'Mehmet',
        avatar: '🦁',
      );
      expect(regStudent.success, isTrue);
      expect(auth.currentUser?.username, equals('mehmet'));

      // Yeni veli kaydet ve Mehmet'e bağla
      final regParent = await auth.register(
        username: 'baba_ahmet',
        password: '5678',
        role: UserRole.parent,
        displayName: 'Ahmet Bey',
        avatar: '👨',
        linkedStudentUsername: 'mehmet',
      );
      expect(regParent.success, isTrue);
      expect(auth.currentUser?.username, equals('baba_ahmet'));
      expect(auth.currentUser?.linkedStudentUsername, equals('mehmet'));
    });

    test('AuthService links student to parent dynamically', () async {
      final auth = AuthService();
      await auth.initialize();

      // Öğrenci kaydet
      await auth.register(
        username: 'ogrenci_can',
        password: '1234',
        role: UserRole.student,
        displayName: 'Can',
      );

      // Veli hesabı aç (öğrencisiz)
      await auth.register(
        username: 'ogretmen_elif',
        password: '9999',
        role: UserRole.parent,
        displayName: 'Elif Öğretmen',
      );

      expect(auth.currentUser?.linkedStudentUsername, isNull);

      // Can'ı bu hesaba bağla
      final linkResult = await auth.linkStudentToParent(
        parentUsername: 'ogretmen_elif',
        studentUsername: 'ogrenci_can',
      );

      expect(linkResult.success, isTrue);
      expect(auth.currentUser?.linkedStudentUsername, equals('ogrenci_can'));
    });
  });
}
