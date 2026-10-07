import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';
import '../services/auth_service.dart';
import '../services/game_progress_service.dart';
import '../services/parent_child_sync_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'parent_dashboard_screen.dart';

import 'launcher/support_contacts_screen.dart';

/// 📝 Genel Bilgiler & Kayıt Ekranı (Öğrenci, Veli & Acil Durum SOS)
/// Öğrenci kaydında tam çocuk & SOS profilini alır. İsteğe bağlı tek seferde Veli hesabı da açar.
/// Düzenleme modunda (isEditing: true) ise "Genel Bilgiler" olarak açılıp kayıtlı tüm bilgileri günceller.
class RegisterScreen extends StatefulWidget {
  final UserRole initialRole;
  final bool isEditing;
  final bool isOnboarding;

  const RegisterScreen({
    super.key,
    this.initialRole = UserRole.student,
    this.isEditing = false,
    this.isOnboarding = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late UserRole _selectedRole;

  // Hesap / Giriş Bilgileri
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _studentUsernameCtrl = TextEditingController();

  // Çocuğun Bilgileri
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Ebeveyn & Acil Durum (SOS)
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _medicalNotesController = TextEditingController();

  // Destek Kişileri (İş Koçu & Aile)
  final List<Map<String, dynamic>> _supportContacts = [];
  final TextEditingController _newContactNameCtrl = TextEditingController();
  final TextEditingController _newContactPhoneCtrl = TextEditingController();
  String _selectedContactRole = 'İş Koçu'; // 'İş Koçu', 'Aile', 'Öğretmen', 'Diğer'

  // Öğrenci kaydederken tek seferde Veli hesabı da açma seçeneği
  bool _createDualParentAccount = false;
  final TextEditingController _dualParentUsernameCtrl = TextEditingController();
  final TextEditingController _dualParentPasswordCtrl = TextEditingController();

  String _selectedAvatar = '🐻';
  String _selectedDiagnosis = 'Otizm Spektrumu 🧩';
  bool _obscurePassword = true;
  bool _obscureDualPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  static const List<String> _avatars = [
    '🐻', '🐰', '🦁', '🐼', '🦊', '🐱',
    '🐶', '🐨', '🦄', '🚀', '🌟', '🐬',
  ];

  static const List<String> _parentAvatars = [
    '👩', '👨', '🧑‍🏫', '🌟', '🐻', '🦁',
  ];

  static const List<String> _diagnosisOptions = [
    'Otizm Spektrumu 🧩',
    'Dil ve Konuşma Güçlüğü 🗣️',
    'Down Sendromu 💛',
    'Gelişimsel Gecikme 🌱',
    'Dikkat & Hiperaktivite ⚡',
    'İşitme Güçlüğü 🦻',
    'Diğer Özel Gereksinim 🌟',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    if (_selectedRole == UserRole.parent) {
      _selectedAvatar = '👩';
    }
    if (widget.isEditing) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final childName = prefs.getString('child_name') ??
          prefs.getString('sos_child_name') ??
          prefs.getString('user_emergency_name') ??
          '';
      final ageStr = prefs.getString('sos_child_age') ?? '';
      final parentName = prefs.getString('sos_parent_name') ?? '';
      final parentPhone = prefs.getString('sos_parent_phone') ??
          prefs.getString('user_emergency_phone') ??
          '';
      final altPhone = prefs.getString('sos_alt_phone') ?? '';
      final address = prefs.getString('sos_home_address') ??
          prefs.getString('user_home_address') ??
          '';
      final notes = prefs.getString('sos_medical_notes') ??
          prefs.getString('user_emergency_notes') ??
          '';
      final diagnosis = prefs.getString('child_diagnosis') ?? '';
      final avatar = prefs.getString('avatar') ?? '';

      _childNameController.text = childName;
      _ageController.text = ageStr.replaceAll(RegExp(r'\D'), '');
      _parentNameController.text = parentName;
      _parentPhoneController.text = parentPhone;
      _altPhoneController.text = altPhone;
      _addressController.text = address;
      _medicalNotesController.text = notes;
      if (_diagnosisOptions.contains(diagnosis)) {
        _selectedDiagnosis = diagnosis;
      }
      if (_avatars.contains(avatar)) {
        _selectedAvatar = avatar;
      }

      final savedContactsStr = prefs.getString('user_support_contacts');
      if (savedContactsStr != null && savedContactsStr.isNotEmpty) {
        final decoded = jsonDecode(savedContactsStr) as List;
        _supportContacts.clear();
        for (final item in decoded) {
          _supportContacts.add(Map<String, dynamic>.from(item as Map));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _studentUsernameCtrl.dispose();
    _childNameController.dispose();
    _ageController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _medicalNotesController.dispose();
    _dualParentUsernameCtrl.dispose();
    _dualParentPasswordCtrl.dispose();
    _newContactNameCtrl.dispose();
    _newContactPhoneCtrl.dispose();
    super.dispose();
  }

  void _addSupportContact() {
    final name = _newContactNameCtrl.text.trim();
    final phone = _newContactPhoneCtrl.text.trim();

    if (name.isEmpty) {
      _showError('Lütfen destek kişisinin adını yazınız.');
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) {
      _showError('Lütfen geçerli bir telefon numarası giriniz (en az 10-11 hane).');
      return;
    }

    final isJobCoach = _selectedContactRole == 'İş Koçu';
    final avatar = isJobCoach
        ? '💼'
        : (_selectedContactRole == 'Öğretmen' ? '🧑‍🏫' : '👨‍👩‍👧');

    setState(() {
      _supportContacts.add({
        'name': name,
        'role': _selectedContactRole,
        'phone': phone,
        'avatar': avatar,
        'isJobCoach': isJobCoach,
      });
      _newContactNameCtrl.clear();
      _newContactPhoneCtrl.clear();
      _errorMessage = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name ($_selectedContactRole) destek kişilerinize eklendi! ✨'),
        backgroundColor: AppColors.positiveGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeSupportContact(int index) {
    if (index >= 0 && index < _supportContacts.length) {
      final name = _supportContacts[index]['name'] ?? 'Kişi';
      setState(() {
        _supportContacts.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name destek kişileri listesinden çıkarıldı.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.accentRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    setState(() => _errorMessage = '');

    // 1. Temel Hesap Doğrulamaları
    if (username.isEmpty) {
      _showError('Lütfen bir kullanıcı adı belirleyin.');
      return;
    }
    if (password.length < 3) {
      _showError('Şifreniz en az 3 karakter olmalıdır.');
      return;
    }

    // ─── VELİ KAYDI AKIŞI (Sade & Pratik) ───────────────────────────
    if (_selectedRole == UserRole.parent) {
      final parentName = _parentNameController.text.trim();
      final linkedStudent = _studentUsernameCtrl.text.trim();

      if (parentName.isEmpty) {
        _showError('Lütfen adınızı ve soyadınızı giriniz.');
        return;
      }

      setState(() => _isLoading = true);

      final res = await AuthService().register(
        username: username,
        password: password,
        role: UserRole.parent,
        displayName: parentName,
        avatar: _selectedAvatar,
        linkedStudentUsername: linkedStudent.isNotEmpty ? linkedStudent : null,
      );

      setState(() => _isLoading = false);

      if (!res.success) {
        _showError(res.error ?? 'Veli kaydı başarısız oldu.');
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(linkedStudent.isNotEmpty
              ? 'Veli hesabınız oluşturuldu ve "@$linkedStudent" öğrencisine bağlandı! 🎉'
              : 'Veli hesabınız başarıyla oluşturuldu! 🎉'),
          backgroundColor: AppColors.positiveGreen,
        ),
      );

      await ParentChildSyncService().setDeviceRole(DeviceRole.parentCompanion);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
        (route) => false,
      );
      return;
    }

    // ─── ÖĞRENCİ KAYDI AKIŞI (Tam Profil & SOS) ─────────────────────
    final childName = _childNameController.text.trim();
    final parentPhone = _parentPhoneController.text.trim();

    if (childName.isEmpty) {
      _showError('Lütfen çocuğun adını ve soyadını giriniz.');
      return;
    }
    if (parentPhone.isEmpty) {
      _showError('Acil durumda aranacak ebeveyn telefon numarasını giriniz.');
      return;
    }

    final cleanPhone = parentPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) {
      _showError('Lütfen geçerli bir telefon numarası giriniz (en az 10-11 hane).');
      return;
    }

    // Çift hesap (Öğrenci + Veli birlikte açma) kontrolü
    if (_createDualParentAccount) {
      final dualParentUser = _dualParentUsernameCtrl.text.trim();
      final dualParentPass = _dualParentPasswordCtrl.text.trim();

      if (dualParentUser.isEmpty) {
        _showError('Lütfen oluşturulacak ebeveyn kullanıcı adını girin.');
        return;
      }
      if (dualParentPass.length < 3) {
        _showError('Ebeveyn şifresi en az 3 karakter olmalıdır.');
        return;
      }
      if (dualParentUser.toLowerCase() == username.toLowerCase()) {
        _showError('Öğrenci ve ebeveyn kullanıcı adı aynı olamaz.');
        return;
      }
    }

    setState(() => _isLoading = true);

    final childAge = _ageController.text.trim();
    final parentName = _parentNameController.text.trim().isNotEmpty
        ? _parentNameController.text.trim()
        : 'Ebeveyn';
    final altPhone = _altPhoneController.text.trim();
    final address = _addressController.text.trim();

    String notes = _medicalNotesController.text.trim();
    if (notes.isEmpty) {
      notes = 'Tanı: $_selectedDiagnosis. Konuşma güçlüğü vardır, sakin yaklaşınız.';
    }

    // 1. Öğrenci Hesabını Oluştur
    final res = await AuthService().register(
      username: username,
      password: password,
      role: UserRole.student,
      displayName: childName,
      avatar: _selectedAvatar,
    );

    if (!res.success) {
      setState(() => _isLoading = false);
      _showError(res.error ?? 'Kayıt başarısız oldu.');
      return;
    }

    // 2. Eğer istendiyse Ebeveyn Hesabını da Arka Planda Oluştur ve Öğrenciye Bağla
    if (_createDualParentAccount) {
      await AuthService().register(
        username: _dualParentUsernameCtrl.text.trim(),
        password: _dualParentPasswordCtrl.text.trim(),
        role: UserRole.parent,
        displayName: parentName,
        avatar: '👩',
        linkedStudentUsername: username,
      );
      // Aktif oturumu öğrenci olarak tut
      await AuthService().login(username: username, password: password);
    }

    // 3. SOS ve Profil Verilerini Kalıcı Sakla
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_child_name', childName);
    await prefs.setString('child_name', childName);
    await prefs.setString('user_emergency_name', childName);
    await prefs.setString('sos_child_age', childAge.isNotEmpty ? '$childAge Yaşında' : '');
    await prefs.setString('sos_parent_name', parentName);
    await prefs.setString('sos_parent_phone', parentPhone);
    await prefs.setString('user_emergency_phone', parentPhone);
    await prefs.setString('sos_alt_phone', altPhone);
    await prefs.setString('sos_home_address', address);
    await prefs.setString('user_home_address', address);
    await prefs.setString('sos_medical_notes', notes);
    await prefs.setString('user_emergency_notes', notes);
    await prefs.setString('child_diagnosis', _selectedDiagnosis);
    await prefs.setString('avatar', _selectedAvatar);
    await prefs.setBool('is_registered', true);
    await prefs.setBool('initial_info_completed', true);

    // Destek Kişileri (user_support_contacts) kaydı
    final List<Map<String, dynamic>> finalContacts = List.from(_supportContacts);
    final cleanParentPhone = parentPhone.replaceAll(RegExp(r'\D'), '');
    final hasParent = finalContacts.any((c) =>
        (c['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '') == cleanParentPhone);
    if (!hasParent) {
      finalContacts.insert(0, {
        'name': parentName,
        'role': 'Aile',
        'phone': parentPhone,
        'avatar': '👨‍👩‍👧',
        'isJobCoach': false,
      });
    }
    if (altPhone.isNotEmpty) {
      final cleanAlt = altPhone.replaceAll(RegExp(r'\D'), '');
      final hasAlt = finalContacts.any((c) =>
          (c['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '') == cleanAlt);
      if (!hasAlt) {
        finalContacts.add({
          'name': '2. Destek Kişim',
          'role': 'Aile',
          'phone': altPhone,
          'avatar': '👨‍👩‍👧',
          'isJobCoach': false,
        });
      }
    }
    await prefs.setString('user_support_contacts', jsonEncode(finalContacts));

    if (!mounted) return;
    final gameService = Provider.of<GameProgressService>(context, listen: false);
    await gameService.saveProfile(childName, _selectedAvatar);
    await gameService.loadData();

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_createDualParentAccount
            ? 'Öğrenci ve Ebeveyn hesapları başarıyla oluşturulup bağlandı! 🎉'
            : 'Genel bilgiler ve öğrenci hesabı başarıyla kaydedildi! 🎉'),
        backgroundColor: AppColors.positiveGreen,
      ),
    );

    await ParentChildSyncService().setDeviceRole(DeviceRole.childTerminal);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// 💾 Genel Bilgileri Güncelle & Kaydet (Düzenleme Modu)
  Future<void> _handleSaveGeneralInfo() async {
    final childName = _childNameController.text.trim();
    final parentPhone = _parentPhoneController.text.trim();

    if (childName.isEmpty) {
      _showError('Lütfen öğrencinin / çocuğun adını giriniz.');
      return;
    }
    if (parentPhone.isEmpty) {
      _showError('Acil durumda aranacak ebeveyn telefon numarasını giriniz.');
      return;
    }

    final cleanPhone = parentPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) {
      _showError('Lütfen geçerli bir telefon numarası giriniz (en az 10-11 hane).');
      return;
    }

    setState(() => _isLoading = true);

    final childAge = _ageController.text.trim();
    final parentName = _parentNameController.text.trim().isNotEmpty
        ? _parentNameController.text.trim()
        : 'Ebeveyn';
    final altPhone = _altPhoneController.text.trim();
    final address = _addressController.text.trim();

    String notes = _medicalNotesController.text.trim();
    if (notes.isEmpty) {
      notes = 'Tanı: $_selectedDiagnosis.';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_child_name', childName);
    await prefs.setString('child_name', childName);
    await prefs.setString('user_emergency_name', childName);
    await prefs.setString('sos_child_age', childAge.isNotEmpty ? '$childAge Yaşında' : '');
    await prefs.setString('sos_parent_name', parentName);
    await prefs.setString('sos_parent_phone', parentPhone);
    await prefs.setString('user_emergency_phone', parentPhone);
    await prefs.setString('sos_alt_phone', altPhone);
    await prefs.setString('sos_home_address', address);
    await prefs.setString('user_home_address', address);
    await prefs.setString('sos_medical_notes', notes);
    await prefs.setString('user_emergency_notes', notes);
    await prefs.setString('child_diagnosis', _selectedDiagnosis);
    await prefs.setString('avatar', _selectedAvatar);
    await prefs.setBool('is_registered', true);
    await prefs.setBool('initial_info_completed', true);

    // Destek kişileri rehberinde Ebeveyn kaydını senkronize et ve kaydet
    try {
      final List<Map<String, dynamic>> finalContacts = List.from(_supportContacts);
      final cleanParentPhone = parentPhone.replaceAll(RegExp(r'\D'), '');
      final parentIdx = finalContacts.indexWhere((c) =>
          (c['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '') == cleanParentPhone ||
          (c['role'] ?? '').toString().toLowerCase() == 'aile');
      if (parentIdx >= 0) {
        finalContacts[parentIdx]['name'] = parentName;
        finalContacts[parentIdx]['phone'] = parentPhone;
      } else {
        finalContacts.insert(0, {
          'name': parentName,
          'role': 'Aile',
          'phone': parentPhone,
          'avatar': '👨‍👩‍👧',
          'isJobCoach': false,
        });
      }
      await prefs.setString('user_support_contacts', jsonEncode(finalContacts));
    } catch (_) {}

    if (mounted) {
      final gameService = Provider.of<GameProgressService>(context, listen: false);
      await gameService.saveProfile(childName, _selectedAvatar);
      await gameService.loadData();
    }

    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Genel bilgiler ve acil durum kayıtları başarıyla güncellendi! ✅'),
        backgroundColor: AppColors.positiveGreen,
      ),
    );
    if (widget.isOnboarding || !Navigator.canPop(context)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isParentRole = _selectedRole == UserRole.parent && !widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding
            ? 'Genel Bilgiler'
            : (widget.isEditing
                ? 'Genel Bilgiler'
                : (isParentRole ? 'Veli Hesabı Oluştur' : 'Genel Bilgiler & Kayıt'))),
        elevation: 0,
        actions: [
          if (widget.isOnboarding)
            TextButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('initial_info_completed', true);
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.blue),
              label: const Text(
                'Daha Sonra',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.getGradient(0)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── BAŞLIK & KARŞILAMA BANNERI ────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: widget.isEditing
                            ? AppColors.buttonIndigo.withValues(alpha: 0.15)
                            : AppColors.buttonOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.isEditing
                              ? '📋'
                              : (isParentRole ? '👨‍👩‍👧' : '🎈'),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing
                                ? 'Genel Bilgiler'
                                : (isParentRole ? 'Veli Kontrol Hesabı' : 'Genel Bilgiler & Kayıt'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.isEditing
                                ? 'Öğrenci, veli ve acil durum (SOS) bilgilerinizi buradan inceleyip güncelleyebilirsiniz.'
                                : (isParentRole
                                    ? 'Çocuğunuzun iletişimini takip etmek ve yönetmek için veli hesabı açın.'
                                    : 'Çocuğunuzun bilgileri, veli ve acil durum iletişimi için formu doldurunuz.'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hata Banner'ı
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (!widget.isEditing) ...[
                  // ─── ROL SEÇİCİ ─────────────────────────────────────────
                  _buildSectionHeader('👤 Hesap Rolü', 'Kayıt olmak istediğiniz kullanıcı türünü seçin'),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleChip(
                          role: UserRole.student,
                          title: 'Öğrenci (Çocuk)',
                          icon: Icons.child_care_rounded,
                          onSelect: () {
                            setState(() {
                              _selectedRole = UserRole.student;
                              _selectedAvatar = '🐻';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildRoleChip(
                          role: UserRole.parent,
                          title: 'Veli (Ebeveyn)',
                          icon: Icons.family_restroom_rounded,
                          onSelect: () {
                            setState(() {
                              _selectedRole = UserRole.parent;
                              _selectedAvatar = '👩';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ═══════════════════════════════════════════════════════════
                // A) SADE VELİ KAYDI FORMU
                // ═══════════════════════════════════════════════════════════
                if (isParentRole) ...[
                  _buildSectionHeader('🔐 Veli Giriş & Bağlantı Bilgileri', 'Windows veya telefonunuzdan giriş için kullanılacaktır'),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        const Text('Veli Avatarı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: _parentAvatars.map((av) {
                            final isSel = av == _selectedAvatar;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedAvatar = av),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: isSel
                                    ? BoxDecoration(
                                        color: AppColors.buttonIndigo.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.buttonIndigo, width: 2.5),
                                      )
                                    : BoxDecoration(
                                        color: AppColors.background,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black12),
                                      ),
                                child: Center(child: Text(av, style: const TextStyle(fontSize: 22))),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _parentNameController,
                          label: 'Veli Adı Soyadı *',
                          hint: 'Örn: Ayşe Hanım (Annesi)',
                          icon: Icons.badge_rounded,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _usernameCtrl,
                          label: 'Veli Kullanıcı Adı *',
                          hint: 'Örn: ayse_anne veya veli123',
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _passwordCtrl,
                          label: 'Veli Giriş Şifresi *',
                          hint: 'En az 3 karakter',
                          icon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bağlanılacak Öğrenci
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.buttonTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.buttonTeal.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: _studentUsernameCtrl,
                                label: '🔗 Bağlanacak Öğrencinin Kullanıcı Adı',
                                hint: 'Örn: az önce oluşturduğunuz öğrencinin kullanıcı adı',
                                icon: Icons.link_rounded,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '💡 Chrome\'da veya başka cihazda açtığınız öğrenci hesabının adını buraya yazarak anında eşleşebilirsiniz.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ═══════════════════════════════════════════════════════════
                  // B) ÖĞRENCİ KAYDI FORMU (TAM PROFİL & SOS + ÇİFT HESAP SEÇENEĞİ)
                  // ═══════════════════════════════════════════════════════════

                  // 0. BÖLÜM: ÖĞRENCİ HESAP BİLGİLERİ (Sadece Yeni Kayıtta)
                  if (!widget.isEditing) ...[
                    _buildSectionHeader('🔐 Öğrenci Giriş Bilgileri', 'Öğrenci terminaline giriş için kullanılacaktır'),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: Neu.elevated(radius: 20, blur: 8),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _usernameCtrl,
                            label: 'Öğrenci Kullanıcı Adı *',
                            hint: 'Örn: can veya ahmet123',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: _passwordCtrl,
                            label: 'Giriş Şifresi *',
                            hint: 'En az 3 karakter',
                            icon: Icons.lock_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 1. BÖLÜM: ÇOCUĞUN BİLGİLERİ
                  _buildSectionHeader('👦 1. Çocuğun Bilgileri', 'Uygulama içinde görünecek profil'),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Çocuğun Maskotu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const Text('Sevdiği karakteri aşağıdan seçin', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _avatars.map((av) {
                            final isSel = av == _selectedAvatar;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedAvatar = av),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: isSel
                                    ? BoxDecoration(
                                        color: AppColors.buttonIndigo.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.buttonIndigo, width: 2.5),
                                      )
                                    : BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black12),
                                      ),
                                child: Center(child: Text(av, style: const TextStyle(fontSize: 22))),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _childNameController,
                          label: 'Çocuğun Adı Soyadı *',
                          hint: 'Örn: Can Yılmaz',
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _ageController,
                          label: 'Çocuğun Yaşı',
                          hint: 'Örn: 7',
                          icon: Icons.cake_rounded,
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text('Özel Durumu / Tanısı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _diagnosisOptions.map((diag) {
                            final isSel = diag == _selectedDiagnosis;
                            return ChoiceChip(
                              label: Text(diag, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppColors.textPrimary)),
                              selected: isSel,
                              selectedColor: AppColors.buttonIndigo,
                              backgroundColor: AppColors.background,
                              onSelected: (val) {
                                if (val) setState(() => _selectedDiagnosis = diag);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. BÖLÜM: EBEVEYN & ACİL DURUM (SOS)
                  _buildSectionHeader('🚨 2. Ebeveyn & Acil Durum (SOS)', 'Acil butonuna ve güvenlik kartına işlenir'),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _parentNameController,
                          label: 'Ebeveyn Adı & Yakınlık',
                          hint: 'Örn: Ayşe Yılmaz (Annesi)',
                          icon: Icons.family_restroom_rounded,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _parentPhoneController,
                          label: 'Acil Durum Telefonu * (Direkt Aranacak - 11 Hane)',
                          hint: 'Örn: 05551234567 (11 Hane)',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          iconColor: AppColors.accentRed,
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _altPhoneController,
                          label: 'İkinci Telefon (Baba/Vasi - 11 Hane Opsiyonel)',
                          hint: 'Örn: 05329876543 (11 Hane)',
                          icon: Icons.phone_forwarded_rounded,
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _addressController,
                          label: 'Ev Adresi / Semt',
                          hint: 'Örn: Kadıköy, İstanbul (Kaybolma durumunda kullanılır)',
                          icon: Icons.home_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _medicalNotesController,
                          label: 'Özel Notlar & Alerjiler',
                          hint: 'Örn: Fıstık alerjisi var. Yüksek sesten tedirgin olur.',
                          icon: Icons.medical_information_rounded,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (widget.isEditing) ...[
                    // DESTEK KİŞİLERİ REHBERİ (Hızlı Erişim & Test Uyumluluğu)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE7F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFBE185D), size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Destek Kişilerim Rehberi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF9D174D))),
                                SizedBox(height: 3),
                                Text('İş koçu, öğretmen ve aile numaralarını yönetin.', style: TextStyle(fontSize: 11, color: Color(0xFFBE185D))),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBE185D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SupportContactsScreen()),
                              ).then((_) => _loadExistingData());
                            },
                            child: const Text('Rehber 📖', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── 3. BÖLÜM: DESTEK KİŞİLERİ (İŞ KOÇU & AİLE REHBERİ) ───
                  _buildSectionHeader(
                    '👥 3. Destek Kişilerini Seç & Bilgilerini Gir',
                    '1 dk beklenildiğinde (yemek, rutin, takvim vb.) "Yardım ister misin?" uyarısında aranacak veya WhatsApp atılacak kişiler',
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bilgilendirme Kutusu
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('💡', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Adımlarda 1 dakika beklenildiğinde sistem sesli ve görsel "Yardım ister misin?" uyarısı verir.\n'
                                  '• Aileden biri seçilirse telefonla arar (tel:)\n'
                                  '• İş Koçu seçilirse WhatsApp mesajı (wa.me) açar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Ekli Destek Kişileri Başlığı
                        Text(
                          'Kayıtlı Destek Kişileri (${_supportContacts.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),

                        if (_supportContacts.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'ℹ️ Henüz özel bir iş koçu veya ek destek kişisi eklenmedi. Yukarıdaki Ebeveyn numaranız otomatik olarak ana Aile desteği olacaktır. Aşağıdan hemen İş Koçunuzu (WhatsApp) ekleyebilirsiniz.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          )
                        else
                          Column(
                            children: _supportContacts.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final c = entry.value;
                              final role = (c['role'] ?? 'Aile').toString();
                              final isJobCoach = role.toLowerCase().contains('koç') ||
                                  role.toLowerCase().contains('koc') ||
                                  c['isJobCoach'] == true;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isJobCoach ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isJobCoach ? const Color(0xFF86EFAC) : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isJobCoach ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (c['avatar'] ?? (isJobCoach ? '💼' : '👨‍👩‍👧')).toString(),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  c['name'] ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isJobCoach ? const Color(0xFF16A34A) : AppColors.buttonIndigo,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isJobCoach ? '💼 İş Koçu (WP)' : '$role (Arama)',
                                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c['phone'] ?? '',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      tooltip: 'Sil',
                                      onPressed: () => _removeSupportContact(idx),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 16),

                        // Yeni Destek Kişisi Ekleme Formu
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '➕ Destek Kişisi Seç & Ekle',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),

                              const Text('Kişinin Rolü:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  ChoiceChip(
                                    label: const Text('💼 İş Koçu (WhatsApp)'),
                                    selected: _selectedContactRole == 'İş Koçu',
                                    selectedColor: const Color(0xFF86EFAC),
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedContactRole = 'İş Koçu');
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('👨‍👩‍👧 Aile (Arama)'),
                                    selected: _selectedContactRole == 'Aile',
                                    selectedColor: const Color(0xFFBFDBFE),
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedContactRole = 'Aile');
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('🧑‍🏫 Öğretmen (Arama)'),
                                    selected: _selectedContactRole == 'Öğretmen',
                                    selectedColor: const Color(0xFFFED7AA),
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedContactRole = 'Öğretmen');
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('🌟 Diğer'),
                                    selected: _selectedContactRole == 'Diğer',
                                    selectedColor: const Color(0xFFE2E8F0),
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedContactRole = 'Diğer');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                controller: _newContactNameCtrl,
                                label: 'Destek Kişisi Adı Soyadı',
                                hint: _selectedContactRole == 'İş Koçu' ? 'Örn: Mehmet Koç (İş Koçum)' : 'Örn: Fatma Teyze',
                                icon: Icons.badge_rounded,
                              ),
                              const SizedBox(height: 10),

                              _buildTextField(
                                controller: _newContactPhoneCtrl,
                                label: 'Telefon Numarası (11 Hane)',
                                hint: 'Örn: 05321234567',
                                icon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                                maxLength: 11,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                              ),
                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedContactRole == 'İş Koçu' ? const Color(0xFF16A34A) : AppColors.buttonIndigo,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.person_add_rounded, size: 18),
                                  label: Text(
                                    '+ Bu Destek Kişisini Ekle (${_selectedContactRole == 'İş Koçu' ? 'WhatsApp' : 'Telefon'})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: _addSupportContact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (widget.isEditing) ...[
                    // Düzenleme modunda ek rehber butonu
                  ] else ...[
                    // 3. BÖLÜM: OTOMATİK EBEVEYN HESABI OLUŞTURMA (Opsiyonel Kolaylık)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.buttonIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.buttonIndigo.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              '👨‍👩‍👧 Ebeveyn Giriş Hesabı da Açılsın',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Diğer cihazdan (Windows/telefon) veli girişi yapmak için tek seferde hesabınızı bağlar.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            value: _createDualParentAccount,
                            activeThumbColor: AppColors.buttonIndigo,
                            onChanged: (val) => setState(() => _createDualParentAccount = val),
                          ),
                          if (_createDualParentAccount) ...[
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _dualParentUsernameCtrl,
                              label: 'Ebeveyn Kullanıcı Adı *',
                              hint: 'Örn: anne_ayse',
                              icon: Icons.person_pin_rounded,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _dualParentPasswordCtrl,
                              label: 'Ebeveyn Giriş Şifresi *',
                              hint: 'En az 3 karakter',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureDualPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDualPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscureDualPassword = !_obscureDualPassword),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 28),

                // ─── KAYDET BUTONU ──────────────────────────────────────
                GestureDetector(
                  onTap: _isLoading ? null : (widget.isEditing ? _handleSaveGeneralInfo : _handleRegister),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: Neu.colored(color: AppColors.buttonIndigo),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        else ...[
                          Flexible(
                            child: Text(
                              widget.isEditing
                                  ? 'Genel Bilgileri Güncelle & Kaydet ✅'
                                  : (isParentRole
                                      ? 'Veli Hesabını Oluştur & Bağla 🚀'
                                      : 'Genel Bilgileri & Hesabı Kaydet 🚀'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required UserRole role,
    required String title,
    required IconData icon,
    required VoidCallback onSelect,
  }) {
    final isSel = _selectedRole == role;
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: isSel
            ? BoxDecoration(
                color: AppColors.buttonIndigo,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonIndigo.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSel ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    Color? iconColor,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: Neu.inset(radius: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLength: maxLength,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              icon: Icon(icon, color: iconColor ?? AppColors.buttonIndigo, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              border: InputBorder.none,
              counterText: '',
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
