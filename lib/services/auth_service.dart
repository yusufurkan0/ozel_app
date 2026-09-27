import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';
import 'database/app_database_service.dart';

/// 🔐 Kullanıcı Kimlik Doğrulama & Oturum Yönetim Servisi
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _prefAccountsKey = 'app_users_list_v1';
  static const String _prefActiveUserKey = 'active_session_username_v1';

  final Map<String, UserAccount> _accounts = {};
  UserAccount? _currentUser;

  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  List<UserAccount> get allAccounts => _accounts.values.toList();

  /// Servisi başlat, kayıtlı hesapları ve aktif oturumu yükle
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefAccountsKey) ?? [];

    _accounts.clear();
    for (final raw in jsonList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final acc = UserAccount.fromJson(map);
        _accounts[acc.username.toLowerCase()] = acc;
      } catch (_) {}
    }

    // Eğer prefs boşsa SQLite'a bak
    if (_accounts.isEmpty) {
      final dbUsers = await AppDatabaseService().getAllUsers();
      for (final u in dbUsers) {
        _accounts[u.username.toLowerCase()] = u;
      }
    }

    // Demo hesaplar kaldırıldı (kullanıcı isteği: temiz ve gerçek kayıt)
    _accounts.remove('ali');
    _accounts.remove('anne');

    // Aktif oturumu yükle
    final activeUsername = prefs.getString(_prefActiveUserKey);
    if (activeUsername != null && _accounts.containsKey(activeUsername.toLowerCase())) {
      _currentUser = _accounts[activeUsername.toLowerCase()];
    }

    notifyListeners();
  }

  Future<void> _saveAccountsToPrefs(SharedPreferences prefs) async {
    final list = _accounts.values.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_prefAccountsKey, list);
    for (final acc in _accounts.values) {
      await AppDatabaseService().saveUser(acc);
    }
  }

  /// Kullanıcı Girişi
  Future<({bool success, String? error})> login({
    required String username,
    required String password,
  }) async {
    final key = username.trim().toLowerCase();

    if (!_accounts.containsKey(key)) {
      return (success: false, error: 'Kullanıcı adı bulunamadı!');
    }

    final account = _accounts[key]!;
    if (account.password != password.trim()) {
      return (success: false, error: 'Hatalı şifre! Lütfen tekrar deneyin.');
    }

    _currentUser = account;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveUserKey, account.username);

    notifyListeners();
    return (success: true, error: null);
  }

  /// Yeni Hesap Kaydı
  Future<({bool success, String? error})> register({
    required String username,
    required String password,
    required UserRole role,
    required String displayName,
    String avatar = '🦁',
    String? linkedStudentUsername,
  }) async {
    final cleanUsername = username.trim().toLowerCase();

    if (cleanUsername.isEmpty) {
      return (success: false, error: 'Kullanıcı adı boş bırakılamaz.');
    }
    if (password.trim().length < 3) {
      return (success: false, error: 'Şifre en az 3 karakter olmalıdır.');
    }
    if (_accounts.containsKey(cleanUsername)) {
      return (success: false, error: 'Bu kullanıcı adı zaten kullanılıyor.');
    }

    // Veli için bağlanacak öğrenci kullanıcı adı (aynı cihazda veya diğer terminalde olabilir)
    final studentKey = (role == UserRole.parent && linkedStudentUsername != null && linkedStudentUsername.trim().isNotEmpty)
        ? linkedStudentUsername.trim().toLowerCase()
        : null;

    final newAccount = UserAccount(
      username: cleanUsername,
      password: password.trim(),
      role: role,
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : cleanUsername,
      avatar: avatar,
      linkedStudentUsername: studentKey,
    );

    _accounts[cleanUsername] = newAccount;
    _currentUser = newAccount;

    final prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await prefs.setString(_prefActiveUserKey, cleanUsername);

    notifyListeners();
    return (success: true, error: null);
  }

  /// Veli Hesabına Öğrenci Bağlama (Account Linking)
  Future<({bool success, String? error})> linkStudentToParent({
    required String parentUsername,
    required String studentUsername,
  }) async {
    final pKey = parentUsername.trim().toLowerCase();
    final sKey = studentUsername.trim().toLowerCase();

    if (!_accounts.containsKey(pKey)) {
      return (success: false, error: 'Veli hesabı bulunamadı.');
    }

    final parent = _accounts[pKey]!;
    final updatedParent = parent.copyWith(linkedStudentUsername: sKey);
    _accounts[pKey] = updatedParent;

    if (_currentUser?.username.toLowerCase() == pKey) {
      _currentUser = updatedParent;
    }

    final prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);

    notifyListeners();
    return (success: true, error: null);
  }

  /// Oturumu Kapat
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefActiveUserKey);
    notifyListeners();
  }

  /// Kullanıcı hesabını sorgula
  UserAccount? getAccount(String username) {
    return _accounts[username.trim().toLowerCase()];
  }

  /// Tüm kullanıcıları, oturumları ve yerel verileri sıfırla
  Future<void> resetAllData() async {
    _currentUser = null;
    _accounts.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await AppDatabaseService().clearAllTables();
    notifyListeners();
  }
}
