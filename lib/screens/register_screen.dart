import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';
import '../services/auth_service.dart';
import '../services/game_progress_service.dart';
import '../services/parent_child_sync_service.dart';
import '../services/teacher_sync_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'parent_dashboard_screen.dart';
import 'launcher/support_contacts_screen.dart';

/// 📝 Genel Bilgiler & Kayıt Ekranı (+1 Bağımsız Yaşam Planım)
/// Sıralama:
/// 1. Kullanıcı Bilgileri
/// 2. Destek Kişilerim
/// 3. Kişisel Hassasiyetlerim
/// 4. Acil Durum (SOS)
/// 5. Sağlık Bilgim
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

  // 1. KULLANICI BİLGİLERİ
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController(); // gg/aa/yyyy
  final TextEditingController _addressController = TextEditingController();
  String _selectedAvatar = 'assets/images/avatars/avatar_1.jpg';
  String _selectedDiagnosis = 'Down Sendromu';

  // Alfabetik sırada tanı listesi
  static const List<String> _diagnosisOptions = [
    'Cerebral Palsi',
    'Çoklu engel',
    'DEHB',
    'Diğer',
    'Diğer nörogelişimsel farklılıklar',
    'Diğer zihinsel engel',
    'Down Sendromu',
    'Görme Engeli',
    'İşitme Engeli',
    'Otizm',
    'Özgül Öğrenme Güçlüğü',
  ];

  // 2. DESTEK KİŞİLERİM
  static const List<String> _familyRelationOptions = [
    'Anne',
    'Baba',
    'Kardeş',
    'Abla',
    'Abi',
    'Diğer Akraba',
  ];

  // Aileden 1. Destek Kişisi
  final TextEditingController _family1NameCtrl = TextEditingController();
  final TextEditingController _family1PhoneCtrl = TextEditingController();
  String _family1Relation = 'Anne';
  bool _family1IsEmergency = true;

  // Aileden 2. Destek Kişisi
  final TextEditingController _family2NameCtrl = TextEditingController();
  final TextEditingController _family2PhoneCtrl = TextEditingController();
  String _family2Relation = 'Baba';
  bool _family2IsEmergency = false;

  // İş Koçu
  final TextEditingController _jobCoachNameCtrl = TextEditingController();
  final TextEditingController _jobCoachPhoneCtrl = TextEditingController();
  bool _jobCoachIsEmergency = false;

  // Gölge Öğretmen / Bakıcı vb.
  final TextEditingController _shadowTeacherNameCtrl = TextEditingController();
  final TextEditingController _shadowTeacherPhoneCtrl = TextEditingController();
  bool _shadowTeacherIsEmergency = false;

  // Ek destek kişileri (SupportContactsScreen ile senkron)
  final List<Map<String, dynamic>> _extraSupportContacts = [];

  // 3. KİŞİSEL HASSASİYETLERİM (Çoklu Seçim + Not)
  static const List<String> _sensitivityOptions = [
    'Ani veya yüksek sesten rahatsız olurum',
    'Işık hassasiyetim var',
    'Bazı hayvanlardan korkarım',
    'Alerjim var',
    'Diyabetim var',
    'Ses kesen kulaklık takmam gerek',
    'Beni sakinleştirecek bir eşyayı elimde tutarım',
    'Uzun süre ayakta duramam',
    'Bir yere inip çıkarken yardıma ihtiyacım var',
    'Duyamıyorum',
    'Konuşamıyorum',
    'Sürekli ilaç kullandığım bir hastalığım var',
    'Kaybolma riskim var',
    'Unutkanlığım var',
    'Diğer',
  ];
  final Set<String> _selectedSensitivities = {};
  final TextEditingController _sensitivityNotesCtrl = TextEditingController();

  // 4. ACİL DURUM (SOS) - Destek Kişilerinden Seçilen 1. ve 2. Kişi
  final TextEditingController _sos1NameCtrl = TextEditingController();
  final TextEditingController _sos1PhoneCtrl = TextEditingController();
  final TextEditingController _sos2NameCtrl = TextEditingController();
  final TextEditingController _sos2PhoneCtrl = TextEditingController();

  // Afet ve Acil Durum Kişi Kartı Alanları (İsteğe Bağlı, Kaldığı Yerden Devam Eder)
  final TextEditingController _disasterCardTcCtrl = TextEditingController();
  final TextEditingController _disasterCardBloodTypeCtrl = TextEditingController();
  final TextEditingController _disasterCardMeetingPlaceCtrl = TextEditingController();
  final TextEditingController _disasterCardOutCityContactCtrl = TextEditingController();
  final TextEditingController _disasterCardEquipmentCtrl = TextEditingController();
  final TextEditingController _disasterCardCommunicationWayCtrl = TextEditingController();
  final TextEditingController _disasterCardCalmingMethodsCtrl = TextEditingController();

  // 5. SAĞLIK BİLGİM
  final TextEditingController _medicationsCtrl = TextEditingController();
  final TextEditingController _chronicDiseasesCtrl = TextEditingController();
  final TextEditingController _healthExtraNotesCtrl = TextEditingController();

  // Veli Kaydı
  final TextEditingController _parentNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  static const List<String> _avatars = [
    'assets/images/avatars/avatar_1.jpg',
    'assets/images/avatars/avatar_2.jpg',
    'assets/images/avatars/avatar_3.jpg',
    'assets/images/avatars/avatar_4.jpg',
    'assets/images/avatars/avatar_5.jpg',
    'assets/images/avatars/avatar_6.jpg',
    'assets/images/avatars/avatar_7.jpg',
    'assets/images/avatars/avatar_8.jpg',
    'assets/images/avatars/avatar_9.jpg',
    'assets/images/avatars/avatar_10.jpg',
    'assets/images/avatars/avatar_11.jpg',
    'assets/images/avatars/avatar_12.jpg',
  ];

  static const List<String> _parentAvatars = [
    '👩', '👨', '🧑‍🏫', '🌟', '🐻', '🦁',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    if (_selectedRole == UserRole.parent) {
      _selectedAvatar = '👩';
    }

    // Destek kişisi alanları değiştikçe SOS 1. ve 2. kişiyi otomatik senkronize et
    _family1NameCtrl.addListener(_syncEmergencyContactsFromSupport);
    _family1PhoneCtrl.addListener(_syncEmergencyContactsFromSupport);
    _family2NameCtrl.addListener(_syncEmergencyContactsFromSupport);
    _family2PhoneCtrl.addListener(_syncEmergencyContactsFromSupport);
    _jobCoachNameCtrl.addListener(_syncEmergencyContactsFromSupport);
    _jobCoachPhoneCtrl.addListener(_syncEmergencyContactsFromSupport);
    _shadowTeacherNameCtrl.addListener(_syncEmergencyContactsFromSupport);
    _shadowTeacherPhoneCtrl.addListener(_syncEmergencyContactsFromSupport);

    _loadExistingData();
  }

  /// Destek Kişilerim bölümünde "Acil Durum Kişisi olarak seç" işaretlenenleri
  /// 4. Acil Durum (SOS) bölümündeki 1. ve 2. Kişi alanlarına otomatik yansıtır.
  void _syncEmergencyContactsFromSupport() {
    final selectedCandidates = <Map<String, String>>[];

    if (_family1IsEmergency &&
        (_family1NameCtrl.text.trim().isNotEmpty || _family1PhoneCtrl.text.trim().isNotEmpty)) {
      selectedCandidates.add({
        'name': '${_family1NameCtrl.text.trim()} ($_family1Relation)'.trim(),
        'phone': _family1PhoneCtrl.text.trim(),
      });
    }
    if (_family2IsEmergency &&
        (_family2NameCtrl.text.trim().isNotEmpty || _family2PhoneCtrl.text.trim().isNotEmpty)) {
      selectedCandidates.add({
        'name': '${_family2NameCtrl.text.trim()} ($_family2Relation)'.trim(),
        'phone': _family2PhoneCtrl.text.trim(),
      });
    }
    if (_jobCoachIsEmergency &&
        (_jobCoachNameCtrl.text.trim().isNotEmpty || _jobCoachPhoneCtrl.text.trim().isNotEmpty)) {
      selectedCandidates.add({
        'name': '${_jobCoachNameCtrl.text.trim()} (İş Koçu)'.trim(),
        'phone': _jobCoachPhoneCtrl.text.trim(),
      });
    }
    if (_shadowTeacherIsEmergency &&
        (_shadowTeacherNameCtrl.text.trim().isNotEmpty || _shadowTeacherPhoneCtrl.text.trim().isNotEmpty)) {
      selectedCandidates.add({
        'name': '${_shadowTeacherNameCtrl.text.trim()} (Gölge Öğretmen/Bakıcı)'.trim(),
        'phone': _shadowTeacherPhoneCtrl.text.trim(),
      });
    }

    if (selectedCandidates.isNotEmpty) {
      _sos1NameCtrl.text = selectedCandidates[0]['name'] ?? '';
      _sos1PhoneCtrl.text = selectedCandidates[0]['phone'] ?? '';
    } else {
      _sos1NameCtrl.text = '';
      _sos1PhoneCtrl.text = '';
    }

    if (selectedCandidates.length >= 2) {
      _sos2NameCtrl.text = selectedCandidates[1]['name'] ?? '';
      _sos2PhoneCtrl.text = selectedCandidates[1]['phone'] ?? '';
    } else {
      _sos2NameCtrl.text = '';
      _sos2PhoneCtrl.text = '';
    }
  }

  /// Mevcut tüm destek kişilerini (4. Acil Durum SOS bölümünde seçim için) döndürür
  List<Map<String, String>> _getAvailableSupportContactsForSelection() {
    final list = <Map<String, String>>[];
    if (_family1NameCtrl.text.trim().isNotEmpty || _family1PhoneCtrl.text.trim().isNotEmpty) {
      list.add({
        'key': 'family1',
        'label': '${_family1NameCtrl.text.trim().isEmpty ? "1. Aile Destek Kişisi" : _family1NameCtrl.text.trim()} ($_family1Relation)',
        'name': '${_family1NameCtrl.text.trim()} ($_family1Relation)'.trim(),
        'phone': _family1PhoneCtrl.text.trim(),
      });
    }
    if (_family2NameCtrl.text.trim().isNotEmpty || _family2PhoneCtrl.text.trim().isNotEmpty) {
      list.add({
        'key': 'family2',
        'label': '${_family2NameCtrl.text.trim().isEmpty ? "2. Aile Destek Kişisi" : _family2NameCtrl.text.trim()} ($_family2Relation)',
        'name': '${_family2NameCtrl.text.trim()} ($_family2Relation)'.trim(),
        'phone': _family2PhoneCtrl.text.trim(),
      });
    }
    if (_jobCoachNameCtrl.text.trim().isNotEmpty || _jobCoachPhoneCtrl.text.trim().isNotEmpty) {
      list.add({
        'key': 'jobCoach',
        'label': '${_jobCoachNameCtrl.text.trim().isEmpty ? "İş Koçu" : _jobCoachNameCtrl.text.trim()} (İş Koçu)',
        'name': '${_jobCoachNameCtrl.text.trim()} (İş Koçu)'.trim(),
        'phone': _jobCoachPhoneCtrl.text.trim(),
      });
    }
    if (_shadowTeacherNameCtrl.text.trim().isNotEmpty || _shadowTeacherPhoneCtrl.text.trim().isNotEmpty) {
      list.add({
        'key': 'shadowTeacher',
        'label': '${_shadowTeacherNameCtrl.text.trim().isEmpty ? "Gölge Öğretmen/Bakıcı" : _shadowTeacherNameCtrl.text.trim()} (Gölge Öğretmen/Bakıcı)',
        'name': '${_shadowTeacherNameCtrl.text.trim()} (Gölge Öğretmen/Bakıcı)'.trim(),
        'phone': _shadowTeacherPhoneCtrl.text.trim(),
      });
    }
    for (final extra in _extraSupportContacts) {
      final n = (extra['name'] ?? '').toString().trim();
      final p = (extra['phone'] ?? '').toString().trim();
      final r = (extra['role'] ?? 'Destek').toString().trim();
      if (n.isNotEmpty || p.isNotEmpty) {
        list.add({
          'key': 'extra_$n',
          'label': '$n ($r)',
          'name': '$n ($r)',
          'phone': p,
        });
      }
    }
    return list;
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final childName = prefs.getString('child_name') ??
          prefs.getString('sos_child_name') ??
          prefs.getString('user_emergency_name') ??
          '';
      final birthDate = prefs.getString('user_birth_date') ??
          prefs.getString('sos_child_age') ??
          '';
      final address = prefs.getString('sos_home_address') ??
          prefs.getString('user_home_address') ??
          '';
      final diagnosis = prefs.getString('child_diagnosis') ?? '';
      final avatar = prefs.getString('avatar') ?? '';

      _childNameController.text = childName;
      _birthDateController.text = birthDate;
      _addressController.text = address;

      // Eski tanı değerlerini yeni alfabetik listeye eşleştir
      if (_diagnosisOptions.contains(diagnosis)) {
        _selectedDiagnosis = diagnosis;
      } else if (diagnosis.toLowerCase().contains('down')) {
        _selectedDiagnosis = 'Down Sendromu';
      } else if (diagnosis.toLowerCase().contains('otizm')) {
        _selectedDiagnosis = 'Otizm';
      } else if (diagnosis.toLowerCase().contains('dikkat') || diagnosis.toLowerCase().contains('dehb')) {
        _selectedDiagnosis = 'DEHB';
      } else if (diagnosis.toLowerCase().contains('işitme')) {
        _selectedDiagnosis = 'İşitme Engeli';
      }

      if (_avatars.contains(avatar)) {
        _selectedAvatar = avatar;
      }

      // 2. Destek Kişilerim verilerini yükle
      _family1NameCtrl.text = prefs.getString('support_family1_name') ??
          prefs.getString('sos_parent_name') ??
          '';
      _family1PhoneCtrl.text = prefs.getString('support_family1_phone') ??
          prefs.getString('sos_parent_phone') ??
          prefs.getString('user_emergency_phone') ??
          '';
      final rel1 = prefs.getString('support_family1_relation') ?? 'Anne';
      if (_familyRelationOptions.contains(rel1)) _family1Relation = rel1;
      _family1IsEmergency = prefs.getBool('support_family1_is_emergency') ?? true;

      _family2NameCtrl.text = prefs.getString('support_family2_name') ?? '';
      _family2PhoneCtrl.text = prefs.getString('support_family2_phone') ??
          prefs.getString('sos_alt_phone') ??
          '';
      final rel2 = prefs.getString('support_family2_relation') ?? 'Baba';
      if (_familyRelationOptions.contains(rel2)) _family2Relation = rel2;
      _family2IsEmergency = prefs.getBool('support_family2_is_emergency') ??
          (_family2PhoneCtrl.text.trim().isNotEmpty);

      _jobCoachNameCtrl.text = prefs.getString('support_job_coach_name') ?? '';
      _jobCoachPhoneCtrl.text = prefs.getString('support_job_coach_phone') ?? '';
      _jobCoachIsEmergency = prefs.getBool('support_job_coach_is_emergency') ?? false;

      _shadowTeacherNameCtrl.text = prefs.getString('support_shadow_teacher_name') ?? '';
      _shadowTeacherPhoneCtrl.text = prefs.getString('support_shadow_teacher_phone') ?? '';
      _shadowTeacherIsEmergency = prefs.getBool('support_shadow_teacher_is_emergency') ?? false;

      // 3. Kişisel Hassasiyetlerim
      final savedSensList = prefs.getStringList('user_sensitivities') ?? [];
      _selectedSensitivities
        ..clear()
        ..addAll(savedSensList);
      _sensitivityNotesCtrl.text = prefs.getString('user_sensitivity_notes') ??
          prefs.getString('sos_medical_notes') ??
          '';

      // 4. Acil Durum (SOS)
      _sos1NameCtrl.text = prefs.getString('sos_contact1_name') ?? '';
      _sos1PhoneCtrl.text = prefs.getString('sos_contact1_phone') ?? '';
      _sos2NameCtrl.text = prefs.getString('sos_contact2_name') ?? '';
      _sos2PhoneCtrl.text = prefs.getString('sos_contact2_phone') ?? '';
      if (_sos1NameCtrl.text.isEmpty && _sos1PhoneCtrl.text.isEmpty) {
        _syncEmergencyContactsFromSupport();
      }

      // Afet ve Acil Durum Kişi Kartı (Kaldığı yerden devam eden veriler)
      _disasterCardTcCtrl.text = prefs.getString('disaster_card_tc') ?? '';
      _disasterCardBloodTypeCtrl.text = prefs.getString('disaster_card_blood') ?? '';
      _disasterCardMeetingPlaceCtrl.text = prefs.getString('disaster_card_meeting_place') ?? '';
      _disasterCardOutCityContactCtrl.text = prefs.getString('disaster_card_out_city_contact') ?? '';
      _disasterCardEquipmentCtrl.text = prefs.getString('disaster_card_equipment') ?? '';
      _disasterCardCommunicationWayCtrl.text = prefs.getString('disaster_card_comm_way') ?? '';
      _disasterCardCalmingMethodsCtrl.text = prefs.getString('disaster_card_calming') ?? '';

      // 5. Sağlık Bilgim
      _medicationsCtrl.text = prefs.getString('health_medications') ?? '';
      _chronicDiseasesCtrl.text = prefs.getString('health_chronic_diseases') ?? '';
      _healthExtraNotesCtrl.text = prefs.getString('health_extra_notes') ?? '';

      // Ek rehber kişileri
      final savedContactsStr = prefs.getString('user_support_contacts');
      if (savedContactsStr != null && savedContactsStr.isNotEmpty) {
        final decoded = jsonDecode(savedContactsStr) as List;
        _extraSupportContacts.clear();
        for (final item in decoded) {
          _extraSupportContacts.add(Map<String, dynamic>.from(item as Map));
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
    _birthDateController.dispose();
    _addressController.dispose();
    _family1NameCtrl.dispose();
    _family1PhoneCtrl.dispose();
    _family2NameCtrl.dispose();
    _family2PhoneCtrl.dispose();
    _jobCoachNameCtrl.dispose();
    _jobCoachPhoneCtrl.dispose();
    _shadowTeacherNameCtrl.dispose();
    _shadowTeacherPhoneCtrl.dispose();
    _sensitivityNotesCtrl.dispose();
    _sos1NameCtrl.dispose();
    _sos1PhoneCtrl.dispose();
    _sos2NameCtrl.dispose();
    _sos2PhoneCtrl.dispose();
    _disasterCardTcCtrl.dispose();
    _disasterCardBloodTypeCtrl.dispose();
    _disasterCardMeetingPlaceCtrl.dispose();
    _disasterCardOutCityContactCtrl.dispose();
    _disasterCardEquipmentCtrl.dispose();
    _disasterCardCommunicationWayCtrl.dispose();
    _disasterCardCalmingMethodsCtrl.dispose();
    _medicationsCtrl.dispose();
    _chronicDiseasesCtrl.dispose();
    _healthExtraNotesCtrl.dispose();
    _parentNameController.dispose();
    super.dispose();
  }

  /// Doğum Tarihi Seçici (gg/aa/yyyy)
  Future<void> _pickBirthDate() async {
    DateTime initial = DateTime(2012, 1, 1);
    final parts = _birthDateController.text.trim().split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null && y > 1940 && y <= DateTime.now().year) {
        initial = DateTime(y, m.clamp(1, 12), d.clamp(1, 31));
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'DOĞUM TARİHİNİ SEÇİN (GG/AA/YYYY)',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        _birthDateController.text = formatted;
      });
    }
  }

  /// gg/aa/yyyy metninden yaş hesaplayıcı
  int _calculateAgeFromBirthDate(String text) {
    final parts = text.trim().split('/');
    if (parts.length == 3) {
      final y = int.tryParse(parts[2]);
      if (y != null && y > 1940 && y <= DateTime.now().year) {
        return (DateTime.now().year - y).clamp(1, 99);
      }
    }
    return int.tryParse(text.replaceAll(RegExp(r'\D'), '')) ?? 14;
  }

  /// Afet ve Acil Durum Kişi Kartı anlık otomatik kayıt (Kullanıcı istediği aşamada çıkabilir, veriler korunur)
  Future<void> _saveDisasterCardDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('disaster_card_tc', _disasterCardTcCtrl.text.trim());
      await prefs.setString('disaster_card_blood', _disasterCardBloodTypeCtrl.text.trim());
      await prefs.setString('disaster_card_meeting_place', _disasterCardMeetingPlaceCtrl.text.trim());
      await prefs.setString('disaster_card_out_city_contact', _disasterCardOutCityContactCtrl.text.trim());
      await prefs.setString('disaster_card_equipment', _disasterCardEquipmentCtrl.text.trim());
      await prefs.setString('disaster_card_comm_way', _disasterCardCommunicationWayCtrl.text.trim());
      await prefs.setString('disaster_card_calming', _disasterCardCalmingMethodsCtrl.text.trim());
    } catch (_) {}
  }

  int _getDisasterCardFilledCount() {
    int count = 0;
    if (_disasterCardTcCtrl.text.trim().isNotEmpty) count++;
    if (_disasterCardBloodTypeCtrl.text.trim().isNotEmpty) count++;
    if (_disasterCardMeetingPlaceCtrl.text.trim().isNotEmpty) count++;
    if (_disasterCardOutCityContactCtrl.text.trim().isNotEmpty) count++;
    if (_disasterCardEquipmentCtrl.text.trim().isNotEmpty) count++;
    if (_disasterCardCommunicationWayCtrl.text.trim().isNotEmpty) count++;
    if (_disasterCardCalmingMethodsCtrl.text.trim().isNotEmpty) count++;
    return count;
  }

  /// Afet ve Acil Durum Kişi Kartı Doldurma ve Görüntüleme Modalı
  void _openDisasterPersonCardDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void onFieldChange(String _) {
              _saveDisasterCardDraft();
              setModalState(() {});
              setState(() {});
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Üst Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF991B1B),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Afet ve Acil Durum Kişi Kartı',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'İstediğiniz aşamada çıkabilirsiniz; yazdıklarınız otomatik kaydedilir.',
                                style: TextStyle(color: Color(0xFFFECACA), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          tooltip: 'Kaydet ve Çık',
                          onPressed: () {
                            _saveDisasterCardDraft();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Canlı Önizleme Kartı (Kayıtlı Bilgileri Görebilme)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFDA4AF), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.visibility_rounded, color: Color(0xFFBE123C), size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Kişi Kartı Canlı Özeti',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF881337)),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBE123C),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_getDisasterCardFilledCount()}/7 Alan Dolu',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text('👤 Ad Soyad: ${_childNameController.text.isEmpty ? "Belirtilmedi" : _childNameController.text}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('🎂 Doğum Tarihi: ${_birthDateController.text.isEmpty ? "Belirtilmedi" : _birthDateController.text} | Tanı: $_selectedDiagnosis',
                                  style: const TextStyle(fontSize: 12)),
                              Text('🩸 Kan Grubu: ${_disasterCardBloodTypeCtrl.text.isEmpty ? "Belirtilmedi" : _disasterCardBloodTypeCtrl.text} | TC: ${_disasterCardTcCtrl.text.isEmpty ? "-" : _disasterCardTcCtrl.text}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('📞 Acil 1. Kişi: ${_sos1NameCtrl.text.isEmpty ? "Seçilmedi" : "${_sos1NameCtrl.text} (${_sos1PhoneCtrl.text})"}',
                                  style: const TextStyle(fontSize: 12)),
                              if (_selectedSensitivities.isNotEmpty)
                                Text('⚠️ Hassasiyetler: ${_selectedSensitivities.join(", ")}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF9F1239))),
                            ],
                          ),
                        ),

                        _buildDisasterField(
                          controller: _disasterCardTcCtrl,
                          label: '1. T.C. Kimlik Numarası (11 Hane - İsteğe Bağlı)',
                          hint: '11 haneli T.C. Kimlik No',
                          icon: Icons.badge_rounded,
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          onChanged: onFieldChange,
                        ),
                        const SizedBox(height: 12),

                        _buildDisasterField(
                          controller: _disasterCardBloodTypeCtrl,
                          label: '2. Kan Grubu',
                          hint: 'Örn: A Rh(+), 0 Rh(-)',
                          icon: Icons.bloodtype_rounded,
                          maxLength: 15,
                          inputFormatters: [LengthLimitingTextInputFormatter(15)],
                          onChanged: onFieldChange,
                        ),
                        const SizedBox(height: 12),

                        _buildDisasterField(
                          controller: _disasterCardMeetingPlaceCtrl,
                          label: '3. Afet Toplanma Alanı / Buluşma Noktası',
                          hint: 'Örn: Mahalle Parkı 2 Nolu Afet Toplanma Alanı',
                          icon: Icons.location_on_rounded,
                          maxLength: 150,
                          inputFormatters: [LengthLimitingTextInputFormatter(150)],
                          onChanged: onFieldChange,
                        ),
                        const SizedBox(height: 12),

                        _buildDisasterField(
                          controller: _disasterCardOutCityContactCtrl,
                          label: '4. Şehir Dışı Acil İletişim Kişisi & Telefonu',
                          hint: 'Örn: Mehmet Amca (Ankara) - 0532 XXX XX XX',
                          icon: Icons.contact_phone_rounded,
                          maxLength: 100,
                          inputFormatters: [LengthLimitingTextInputFormatter(100)],
                          onChanged: onFieldChange,
                        ),
                        const SizedBox(height: 12),

                        _buildDisasterField(
                          controller: _disasterCardEquipmentCtrl,
                          label: '5. Kullandığı Destekleyici Cihaz / Ekipmanlar',
                          hint: 'Örn: İşitme cihazı, gözlük, gürültü önleyici kulaklık',
                          icon: Icons.hearing_rounded,
                          maxLength: 150,
                          inputFormatters: [LengthLimitingTextInputFormatter(150)],
                          onChanged: onFieldChange,
                        ),
                        const SizedBox(height: 12),

                        _buildDisasterField(
                          controller: _disasterCardCommunicationWayCtrl,
                          label: '6. İletişim Kurma Biçimi',
                          hint: 'Örn: Kısa ve net cümlelerle konuşun, görsel kart gösterin',
                          icon: Icons.record_voice_over_rounded,
                          maxLength: 150,
                          inputFormatters: [LengthLimitingTextInputFormatter(150)],
                          onChanged: onFieldChange,
                        ),
                        const SizedBox(height: 12),

                        _buildDisasterField(
                          controller: _disasterCardCalmingMethodsCtrl,
                          label: '7. Kriz / Panik Anında Sakinleştirme Yöntemleri',
                          hint: 'Örn: Sevdiği müziği dinletin, kalabalıktan uzaklaştırın',
                          icon: Icons.favorite_rounded,
                          maxLength: 150,
                          inputFormatters: [LengthLimitingTextInputFormatter(150)],
                          onChanged: onFieldChange,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Alt Butonlar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.pause_circle_outline_rounded),
                            label: const Text('Şimdilik Çık (Kaldığım Yer Kaydedildi)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              _saveDisasterCardDraft();
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final tcText = _disasterCardTcCtrl.text.trim();
                            if (tcText.isNotEmpty && tcText.length != 11) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('T.C. Kimlik Numarası girilecekse 11 haneli olmalıdır.'),
                                  backgroundColor: AppColors.accentRed,
                                ),
                              );
                              return;
                            }
                            _saveDisasterCardDraft();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Afet ve Acil Durum Kişi Kartı bilgileriniz kaydedildi! ✅'),
                                backgroundColor: AppColors.positiveGreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDisasterField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              icon: Icon(icon, color: const Color(0xFFBE123C), size: 20),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              border: InputBorder.none,
              counterText: maxLength == 11 ? null : '',
            ),
          ),
        ),
      ],
    );
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

  /// Tüm yeni alanları SharedPreferences ve Destek Kişileri listesine kaydeder
  Future<void> _persistAllProfileFields() async {
    final prefs = await SharedPreferences.getInstance();
    final childName = _childNameController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final address = _addressController.text.trim();

    _syncEmergencyContactsFromSupport();

    final primarySosName = _sos1NameCtrl.text.trim().isNotEmpty
        ? _sos1NameCtrl.text.trim()
        : (_family1NameCtrl.text.trim().isNotEmpty ? _family1NameCtrl.text.trim() : 'Destek Kişisi');
    final primarySosPhone = _sos1PhoneCtrl.text.trim().isNotEmpty
        ? _sos1PhoneCtrl.text.trim()
        : _family1PhoneCtrl.text.trim();
    final secondarySosPhone = _sos2PhoneCtrl.text.trim().isNotEmpty
        ? _sos2PhoneCtrl.text.trim()
        : _family2PhoneCtrl.text.trim();

    // Kişisel hassasiyetler + sağlık bilgisi birleşik özet (SOS ekranı ve öğretmen paneli için)
    final summaryParts = <String>[
      'Tanı: $_selectedDiagnosis',
      if (_selectedSensitivities.isNotEmpty) 'Hassasiyetler: ${_selectedSensitivities.join(", ")}',
      if (_sensitivityNotesCtrl.text.trim().isNotEmpty) 'Hassasiyet Notu: ${_sensitivityNotesCtrl.text.trim()}',
      if (_medicationsCtrl.text.trim().isNotEmpty) 'Sürekli İlaçlar: ${_medicationsCtrl.text.trim()}',
      if (_chronicDiseasesCtrl.text.trim().isNotEmpty) 'Kronik Hastalıklar: ${_chronicDiseasesCtrl.text.trim()}',
      if (_healthExtraNotesCtrl.text.trim().isNotEmpty) 'Sağlık Notu: ${_healthExtraNotesCtrl.text.trim()}',
    ];
    final combinedMedicalSummary = summaryParts.join(' | ');

    // 1. Kullanıcı Bilgileri
    await prefs.setString('child_name', childName);
    await prefs.setString('sos_child_name', childName);
    await prefs.setString('user_emergency_name', childName);
    await prefs.setString('user_birth_date', birthDate);
    await prefs.setString('sos_child_age', birthDate);
    await prefs.setString('sos_home_address', address);
    await prefs.setString('user_home_address', address);
    await prefs.setString('child_diagnosis', _selectedDiagnosis);
    await prefs.setString('avatar', _selectedAvatar);

    // 2. Destek Kişilerim
    await prefs.setString('support_family1_name', _family1NameCtrl.text.trim());
    await prefs.setString('support_family1_phone', _family1PhoneCtrl.text.trim());
    await prefs.setString('support_family1_relation', _family1Relation);
    await prefs.setBool('support_family1_is_emergency', _family1IsEmergency);

    await prefs.setString('support_family2_name', _family2NameCtrl.text.trim());
    await prefs.setString('support_family2_phone', _family2PhoneCtrl.text.trim());
    await prefs.setString('support_family2_relation', _family2Relation);
    await prefs.setBool('support_family2_is_emergency', _family2IsEmergency);

    await prefs.setString('support_job_coach_name', _jobCoachNameCtrl.text.trim());
    await prefs.setString('support_job_coach_phone', _jobCoachPhoneCtrl.text.trim());
    await prefs.setBool('support_job_coach_is_emergency', _jobCoachIsEmergency);

    await prefs.setString('support_shadow_teacher_name', _shadowTeacherNameCtrl.text.trim());
    await prefs.setString('support_shadow_teacher_phone', _shadowTeacherPhoneCtrl.text.trim());
    await prefs.setBool('support_shadow_teacher_is_emergency', _shadowTeacherIsEmergency);

    // Destek Kişilerim Rehberi (SupportContactsScreen ve InactivityHelpService için birleştirilmiş liste)
    final structuredContacts = <Map<String, dynamic>>[];
    if (_family1NameCtrl.text.trim().isNotEmpty || _family1PhoneCtrl.text.trim().isNotEmpty) {
      structuredContacts.add({
        'name': _family1NameCtrl.text.trim().isNotEmpty ? _family1NameCtrl.text.trim() : _family1Relation,
        'role': _family1Relation,
        'phone': _family1PhoneCtrl.text.trim(),
        'avatar': '👨‍👩‍👧',
        'isJobCoach': false,
        'isEmergency': _family1IsEmergency,
      });
    }
    if (_family2NameCtrl.text.trim().isNotEmpty || _family2PhoneCtrl.text.trim().isNotEmpty) {
      structuredContacts.add({
        'name': _family2NameCtrl.text.trim().isNotEmpty ? _family2NameCtrl.text.trim() : _family2Relation,
        'role': _family2Relation,
        'phone': _family2PhoneCtrl.text.trim(),
        'avatar': '👨‍👩‍👧',
        'isJobCoach': false,
        'isEmergency': _family2IsEmergency,
      });
    }
    if (_jobCoachNameCtrl.text.trim().isNotEmpty || _jobCoachPhoneCtrl.text.trim().isNotEmpty) {
      structuredContacts.add({
        'name': _jobCoachNameCtrl.text.trim().isNotEmpty ? _jobCoachNameCtrl.text.trim() : 'İş Koçu',
        'role': 'İş Koçu',
        'phone': _jobCoachPhoneCtrl.text.trim(),
        'avatar': '💼',
        'isJobCoach': true,
        'isEmergency': _jobCoachIsEmergency,
      });
    }
    if (_shadowTeacherNameCtrl.text.trim().isNotEmpty || _shadowTeacherPhoneCtrl.text.trim().isNotEmpty) {
      structuredContacts.add({
        'name': _shadowTeacherNameCtrl.text.trim().isNotEmpty
            ? _shadowTeacherNameCtrl.text.trim()
            : 'Gölge Öğretmen/Bakıcı',
        'role': 'Gölge Öğretmen/Bakıcı',
        'phone': _shadowTeacherPhoneCtrl.text.trim(),
        'avatar': '🧑‍🏫',
        'isJobCoach': false,
        'isEmergency': _shadowTeacherIsEmergency,
      });
    }
    await prefs.setString('user_support_contacts', jsonEncode(structuredContacts));

    // 3. Kişisel Hassasiyetlerim
    await prefs.setStringList('user_sensitivities', _selectedSensitivities.toList());
    await prefs.setString('user_sensitivity_notes', _sensitivityNotesCtrl.text.trim());

    // 4. Acil Durum (SOS)
    await prefs.setString('sos_parent_name', primarySosName);
    await prefs.setString('sos_parent_phone', primarySosPhone);
    await prefs.setString('user_emergency_phone', primarySosPhone);
    await prefs.setString('sos_alt_phone', secondarySosPhone);
    await prefs.setString('sos_contact1_name', _sos1NameCtrl.text.trim());
    await prefs.setString('sos_contact1_phone', _sos1PhoneCtrl.text.trim());
    await prefs.setString('sos_contact2_name', _sos2NameCtrl.text.trim());
    await prefs.setString('sos_contact2_phone', _sos2PhoneCtrl.text.trim());
    await prefs.setString('sos_medical_notes', combinedMedicalSummary);
    await prefs.setString('user_emergency_notes', combinedMedicalSummary);
    await _saveDisasterCardDraft();

    // 5. Sağlık Bilgim
    await prefs.setString('health_medications', _medicationsCtrl.text.trim());
    await prefs.setString('health_chronic_diseases', _chronicDiseasesCtrl.text.trim());
    await prefs.setString('health_extra_notes', _healthExtraNotesCtrl.text.trim());

    await prefs.setBool('is_registered', true);
    await prefs.setBool('initial_info_completed', true);

    // Öğretmen Paneline Senkronize Et
    final calculatedAge = _calculateAgeFromBirthDate(birthDate).toString();
    await TeacherSyncService.instance.registerStudent(
      name: childName,
      age: calculatedAge,
      diagnosis: _selectedDiagnosis,
      parentName: primarySosName,
      parentPhone: primarySosPhone,
      avatar: _selectedAvatar,
      address: address,
      notes: combinedMedicalSummary,
    );
  }

  /// Girilen telefon numaralarının (10 veya 11 hane) ve T.C. Kimlik numarasının (11 hane) limitlerini doğrular
  String? _validatePhoneAndNumericLimits() {
    final phoneChecks = <Map<String, String>>[
      {'label': 'Aileden 1. Destek Kişisi Telefonu', 'val': _family1PhoneCtrl.text.trim()},
      {'label': 'Aileden 2. Destek Kişisi Telefonu', 'val': _family2PhoneCtrl.text.trim()},
      {'label': 'İş Koçu Telefonu', 'val': _jobCoachPhoneCtrl.text.trim()},
      {'label': 'Gölge Öğretmen/Bakıcı Telefonu', 'val': _shadowTeacherPhoneCtrl.text.trim()},
      {'label': 'Acil Durum 1. Kişi Telefonu', 'val': _sos1PhoneCtrl.text.trim()},
      {'label': 'Acil Durum 2. Kişi Telefonu', 'val': _sos2PhoneCtrl.text.trim()},
    ];

    for (final item in phoneChecks) {
      final raw = item['val'] ?? '';
      if (raw.isNotEmpty) {
        final digits = raw.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 10 || digits.length > 11) {
          return '${item['label']} 10 veya 11 haneli olmalıdır (Girilen: ${digits.length} hane).';
        }
      }
    }

    final tc = _disasterCardTcCtrl.text.trim();
    if (tc.isNotEmpty && tc.length != 11) {
      return 'Afet Kişi Kartındaki T.C. Kimlik Numarası 11 haneli olmalıdır.';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    setState(() => _errorMessage = '');

    if (username.isEmpty) {
      _showError('Lütfen bir kullanıcı adı belirleyin.');
      return;
    }
    if (password.length < 3) {
      _showError('Şifreniz en az 3 karakter olmalıdır.');
      return;
    }

    // VELİ KAYDI AKIŞI
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
      await ParentChildSyncService().setDeviceRole(DeviceRole.parentCompanion);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
        (route) => false,
      );
      return;
    }

    // KULLANICI / ÖĞRENCİ KAYDI AKIŞI
    final childName = _childNameController.text.trim();
    if (childName.isEmpty) {
      _showError('Lütfen 1. Kullanıcı Bilgileri bölümünden Kullanıcı Adı Soyadı giriniz.');
      return;
    }

    final limitErr = _validatePhoneAndNumericLimits();
    if (limitErr != null) {
      _showError(limitErr);
      return;
    }

    setState(() => _isLoading = true);

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

    await _persistAllProfileFields();

    if (!mounted) return;
    final gameService = Provider.of<GameProgressService>(context, listen: false);
    await gameService.saveProfile(childName, _selectedAvatar);
    await gameService.loadData();

    setState(() => _isLoading = false);
    if (!mounted) return;

    await ParentChildSyncService().setDeviceRole(DeviceRole.childTerminal);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// 💾 Genel Bilgileri Güncelle & Kaydet
  Future<void> _handleSaveGeneralInfo() async {
    final childName = _childNameController.text.trim();
    if (childName.isEmpty) {
      _showError('Lütfen 1. Kullanıcı Bilgileri bölümünden Kullanıcı Adı Soyadı giriniz.');
      return;
    }

    final limitErr = _validatePhoneAndNumericLimits();
    if (limitErr != null) {
      _showError(limitErr);
      return;
    }

    setState(() => _isLoading = true);

    await _persistAllProfileFields();

    if (mounted) {
      final gameService = Provider.of<GameProgressService>(context, listen: false);
      await gameService.saveProfile(childName, _selectedAvatar);
      await gameService.loadData();
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Genel bilgiler başarıyla kaydedildi! ✅'),
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
    final availableSupportContacts = _getAvailableSupportContactsForSelection();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding || widget.isEditing
            ? 'Genel Bilgiler'
            : (isParentRole ? 'Veli Hesabı Oluştur' : 'Genel Bilgiler & Kayıt')),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.positiveGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('KAYDET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _isLoading ? null : (widget.isEditing ? _handleSaveGeneralInfo : _handleRegister),
            ),
          ),
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
                // ─── BAŞLIK BANNERI ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('📋', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Genel Bilgiler',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '+1 Bağımsız Yaşam Planım — Kullanıcı, destek kişileri, kişisel hassasiyetler, SOS ve sağlık bilgileri.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

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
                  _buildSectionHeader('👤 Hesap Rolü', 'Kayıt olmak istediğiniz kullanıcı türünü seçin'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleChip(
                          role: UserRole.student,
                          title: 'Kullanıcı',
                          icon: Icons.person_rounded,
                          onSelect: () {
                            setState(() {
                              _selectedRole = UserRole.student;
                              _selectedAvatar = 'assets/images/avatars/avatar_1.jpg';
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

                if (isParentRole) ...[
                  // VELİ KAYDI FORMU
                  _buildSectionHeader('🔐 Veli Giriş & Bağlantı Bilgileri', 'Veli kontrol paneline giriş için kullanılır'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          hint: 'Örn: Ayşe Yılmaz',
                          icon: Icons.badge_rounded,
                          maxLength: 50,
                          inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _usernameCtrl,
                          label: 'Veli Kullanıcı Adı *',
                          hint: 'Örn: ayse_anne',
                          icon: Icons.alternate_email_rounded,
                          maxLength: 30,
                          inputFormatters: [LengthLimitingTextInputFormatter(30)],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _passwordCtrl,
                          label: 'Veli Giriş Şifresi *',
                          hint: 'En az 3 karakter (Maks. 32)',
                          icon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          maxLength: 32,
                          inputFormatters: [LengthLimitingTextInputFormatter(32)],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _studentUsernameCtrl,
                          label: 'Bağlanacak Kullanıcının Hesap Adı',
                          hint: 'Örn: can123',
                          icon: Icons.link_rounded,
                          maxLength: 30,
                          inputFormatters: [LengthLimitingTextInputFormatter(30)],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (!widget.isEditing) ...[
                    _buildSectionHeader('🔐 Giriş Bilgileri', 'Uygulamaya giriş için kullanılacaktır'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: Neu.elevated(radius: 20, blur: 8),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _usernameCtrl,
                            label: 'Hesap Kullanıcı Adı *',
                            hint: 'Örn: can123',
                            icon: Icons.alternate_email_rounded,
                            maxLength: 30,
                            inputFormatters: [LengthLimitingTextInputFormatter(30)],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _passwordCtrl,
                            label: 'Giriş Şifresi *',
                            hint: 'En az 3 karakter (Maks. 32)',
                            icon: Icons.lock_rounded,
                            obscureText: _obscurePassword,
                            maxLength: 32,
                            inputFormatters: [LengthLimitingTextInputFormatter(32)],
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

                  // ═══════════════════════════════════════════════════════════
                  // 1. KULLANICI BİLGİLERİ
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader('👤 1. Kullanıcı Bilgileri', 'Uygulama içinde görünecek kullanıcı profili'),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kullanıcı Avatarı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _avatars.map((av) {
                            final isSel = av == _selectedAvatar;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedAvatar = av),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 64,
                                height: 64,
                                padding: const EdgeInsets.all(3),
                                decoration: isSel
                                    ? BoxDecoration(
                                        color: AppColors.buttonIndigo.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.buttonIndigo, width: 3),
                                      )
                                    : BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.black12),
                                      ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    av,
                                    fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                    errorBuilder: (_, _, _) => const Center(child: Icon(Icons.person)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _childNameController,
                          label: 'Kullanıcı Adı Soyadı *',
                          hint: 'Örn: Can Yılmaz',
                          icon: Icons.person_rounded,
                          maxLength: 50,
                          inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        ),
                        const SizedBox(height: 12),

                        // Kullanıcı Yaşı (gg/aa/yyyy olarak seçilsin)
                        GestureDetector(
                          onTap: _pickBirthDate,
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _birthDateController,
                              label: 'Kullanıcı Yaşı (gg/aa/yyyy)',
                              hint: 'gg/aa/yyyy seçmek için dokunun',
                              icon: Icons.calendar_month_rounded,
                              maxLength: 10,
                              suffixIcon: const Icon(Icons.date_range_rounded, color: AppColors.buttonIndigo),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ev Adresi (Buraya taşındı)
                        _buildTextField(
                          controller: _addressController,
                          label: 'Ev Adresi',
                          hint: 'Örn: Kadıköy, İstanbul',
                          icon: Icons.home_rounded,
                          maxLines: 2,
                          maxLength: 250,
                          inputFormatters: [LengthLimitingTextInputFormatter(250)],
                        ),
                        const SizedBox(height: 16),

                        // Tanı (Alfabetik Sırada)
                        const Text('Tanı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _diagnosisOptions.map((diag) {
                            final isSel = diag == _selectedDiagnosis;
                            return ChoiceChip(
                              label: Text(
                                diag,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
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

                  // ═══════════════════════════════════════════════════════════
                  // 2. DESTEK KİŞİLERİM
                  // (Altındaki 1 dk açıklaması ve Kayıtlı Destek Kişileri (0) kaldırıldı)
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader('👥 2. Destek Kişilerim', ''),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- AİLEDEN 1. DESTEK KİŞİSİ ---
                        _buildSupportPersonBlock(
                          blockTitle: '👨‍👩‍👧 Aileden Bir Destek Kişisi',
                          nameController: _family1NameCtrl,
                          nameLabel: 'Aileden Bir Destek Kişisi Adı Soyadı',
                          nameHint: 'Örn: Ayşe Yılmaz',
                          phoneController: _family1PhoneCtrl,
                          phoneLabel: 'Telefon Numarası (En Fazla 11 Hane)',
                          selectedRelation: _family1Relation,
                          onRelationChanged: (val) {
                            setState(() {
                              _family1Relation = val;
                              _syncEmergencyContactsFromSupport();
                            });
                          },
                          isEmergencySelected: _family1IsEmergency,
                          onEmergencyChanged: (val) {
                            setState(() {
                              _family1IsEmergency = val ?? false;
                              _syncEmergencyContactsFromSupport();
                            });
                          },
                        ),
                        const Divider(height: 28),

                        // --- AİLEDEN 2. DESTEK KİŞİSİ ---
                        _buildSupportPersonBlock(
                          blockTitle: '👨‍👩‍👧‍👦 Aileden İkinci Destek Kişisi',
                          nameController: _family2NameCtrl,
                          nameLabel: 'Aileden İkinci Destek Kişisi Adı Soyadı',
                          nameHint: 'Örn: Mehmet Yılmaz',
                          phoneController: _family2PhoneCtrl,
                          phoneLabel: 'Telefon Numarası (En Fazla 11 Hane)',
                          selectedRelation: _family2Relation,
                          onRelationChanged: (val) {
                            setState(() {
                              _family2Relation = val;
                              _syncEmergencyContactsFromSupport();
                            });
                          },
                          isEmergencySelected: _family2IsEmergency,
                          onEmergencyChanged: (val) {
                            setState(() {
                              _family2IsEmergency = val ?? false;
                              _syncEmergencyContactsFromSupport();
                            });
                          },
                        ),
                        const Divider(height: 28),

                        // --- İŞ KOÇU ---
                        const Text(
                          '💼 İş Koçu',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _jobCoachNameCtrl,
                          label: 'İş Koçu Adı Soyadı',
                          hint: 'Örn: Selin Demir',
                          icon: Icons.work_rounded,
                          maxLength: 50,
                          inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _jobCoachPhoneCtrl,
                          label: 'İş Koçu Telefonu (En Fazla 11 Hane)',
                          hint: 'Örn: 05321234567',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          showCounter: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.accentRed,
                          title: const Text(
                            'Bu kişiyi Acil Durum Kişisi olarak seç',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          value: _jobCoachIsEmergency,
                          onChanged: (val) {
                            setState(() {
                              _jobCoachIsEmergency = val ?? false;
                              _syncEmergencyContactsFromSupport();
                            });
                          },
                        ),
                        const Divider(height: 24),

                        // --- GÖLGE ÖĞRETMEN / BAKICI VB. ---
                        const Text(
                          '🧑‍🏫 Gölge Öğretmen / Bakıcı vb.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _shadowTeacherNameCtrl,
                          label: 'Gölge Öğretmen/Bakıcı vb. Adı Soyadı',
                          hint: 'Örn: Zeynep Kaya',
                          icon: Icons.school_rounded,
                          maxLength: 50,
                          inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _shadowTeacherPhoneCtrl,
                          label: 'Gölge Öğretmen/Bakıcı vb. Telefonu (En Fazla 11 Hane)',
                          hint: 'Örn: 05441234567',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          showCounter: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.accentRed,
                          title: const Text(
                            'Bu kişiyi Acil Durum Kişisi olarak seç',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          value: _shadowTeacherIsEmergency,
                          onChanged: (val) {
                            setState(() {
                              _shadowTeacherIsEmergency = val ?? false;
                              _syncEmergencyContactsFromSupport();
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // --- DESTEK KİŞİLERİM REHBERİ (Bu menü altına taşındı) ---
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCE7F3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFBE185D), size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Destek Kişilerim Rehberi',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9D174D)),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Tüm destek kişilerini görüntüleyin ve yönetin.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFFBE185D)),
                                    ),
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
                                onPressed: () async {
                                  await _persistAllProfileFields();
                                  if (!context.mounted) return;
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // 3. KİŞİSEL HASSASİYETLERİM (Çoklu Seçim + Not Kısmı)
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader(
                    '💛 3. Kişisel Hassasiyetlerim',
                    'Birden fazla seçeneği işaretleyebilirsiniz',
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
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
                                'Hassasiyet Seçimi (Birden Fazla Seçebilirsiniz):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _sensitivityOptions.map((item) {
                                  final isSelected = _selectedSensitivities.contains(item);
                                  return ChoiceChip(
                                    label: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF86EFAC),
                                    onSelected: (bool value) {
                                      setState(() {
                                        if (value) {
                                          _selectedSensitivities.add(item);
                                        } else {
                                          _selectedSensitivities.remove(item);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildTextField(
                          controller: _sensitivityNotesCtrl,
                          label: 'Kişisel Hassasiyetlerim Notu',
                          hint: 'Hassasiyetlerinizle ilgili eklemek istediğiniz bilgileri buraya yazabilirsiniz...',
                          icon: Icons.edit_note_rounded,
                          maxLines: 3,
                          maxLength: 300,
                          inputFormatters: [LengthLimitingTextInputFormatter(300)],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // 4. ACİL DURUM (SOS)
                  // (Destek Kişilerinden Seçilen 1. ve 2. Kişi + Afet Kişi Kartı Butonu)
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader(
                    '🚨 4. Acil Durum (SOS)',
                    'Acil durumlarda aranacak kişiler Destek Kişilerim bölümünden seçilir',
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Destek Kişilerinden Hızlı Seçim Çipleri
                        if (availableSupportContacts.isNotEmpty) ...[
                          const Text(
                            'Destek Kişilerimden 1. Acil Durum Kişisini Seç:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: availableSupportContacts.map((c) {
                              final isCurrent = _sos1NameCtrl.text == c['name'] && _sos1PhoneCtrl.text == c['phone'];
                              return ChoiceChip(
                                label: Text(c['label'] ?? '', style: const TextStyle(fontSize: 11)),
                                selected: isCurrent,
                                selectedColor: const Color(0xFFFECACA),
                                onSelected: (_) {
                                  setState(() {
                                    _sos1NameCtrl.text = c['name'] ?? '';
                                    _sos1PhoneCtrl.text = c['phone'] ?? '';
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        _buildTextField(
                          controller: _sos1NameCtrl,
                          label: 'Acil Durumlarda Aranacak 1. Kişi Adı',
                          hint: 'Destek Kişilerim bölümünden seçilir',
                          icon: Icons.person_pin_rounded,
                          iconColor: AppColors.accentRed,
                          maxLength: 50,
                          inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        ),
                        const SizedBox(height: 10),

                        _buildTextField(
                          controller: _sos1PhoneCtrl,
                          label: 'Acil Durumlarda Aranacak 1. Kişi Telefonu (En Fazla 11 Hane)',
                          hint: 'Destek Kişilerim bölümünden seçilir (05xxxxxxxxx)',
                          icon: Icons.phone_in_talk_rounded,
                          iconColor: AppColors.accentRed,
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          showCounter: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                        const Divider(height: 24),

                        if (availableSupportContacts.isNotEmpty) ...[
                          const Text(
                            'Destek Kişilerimden 2. Acil Durum Kişisini Seç:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: availableSupportContacts.map((c) {
                              final isCurrent = _sos2NameCtrl.text == c['name'] && _sos2PhoneCtrl.text == c['phone'];
                              return ChoiceChip(
                                label: Text(c['label'] ?? '', style: const TextStyle(fontSize: 11)),
                                selected: isCurrent,
                                selectedColor: const Color(0xFFFED7AA),
                                onSelected: (_) {
                                  setState(() {
                                    _sos2NameCtrl.text = c['name'] ?? '';
                                    _sos2PhoneCtrl.text = c['phone'] ?? '';
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        _buildTextField(
                          controller: _sos2NameCtrl,
                          label: 'Acil Durumlarda Aranacak 2. Kişi Adı',
                          hint: 'Destek Kişilerim bölümünden seçilir',
                          icon: Icons.person_pin_circle_rounded,
                          maxLength: 50,
                          inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        ),
                        const SizedBox(height: 10),

                        _buildTextField(
                          controller: _sos2PhoneCtrl,
                          label: 'Acil Durumlarda Aranacak 2. Kişi Telefonu (En Fazla 11 Hane)',
                          hint: 'Destek Kişilerim bölümünden seçilir (05xxxxxxxxx)',
                          icon: Icons.phone_forwarded_rounded,
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          showCounter: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Afet ve Acil Durum Kişi Kartını Doldur Butonu (İsteğe Bağlı, Kaldığı Yerden Devam Eder)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBE123C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.assignment_ind_rounded, size: 22),
                            label: Text(
                              _getDisasterCardFilledCount() > 0
                                  ? 'Afet ve Acil Durum Kişi Kartını Görüntüle / Düzenle (${_getDisasterCardFilledCount()}/7 Dolu)'
                                  : 'Afet ve Acil Durum Kişi Kartını Doldur (İsteğe Bağlı)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: _openDisasterPersonCardDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // 5. SAĞLIK BİLGİM
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader(
                    '🏥 5. Sağlık Bilgim',
                    'Sürekli kullanılan ilaçlar ve kronik hastalık bilgileri',
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: Neu.elevated(radius: 20, blur: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _medicationsCtrl,
                          label: 'Sürekli Kullandığı İlaçlar',
                          hint: 'Örn: Sabah/akşam kullanılan düzenli ilaçlar ve dozları...',
                          icon: Icons.medication_rounded,
                          maxLines: 2,
                          maxLength: 300,
                          inputFormatters: [LengthLimitingTextInputFormatter(300)],
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _chronicDiseasesCtrl,
                          label: 'Kronik Hastalıklar',
                          hint: 'Örn: Hipotiroidi, çölyak, kalp rahatsızlığı, diyabet vb.',
                          icon: Icons.monitor_heart_rounded,
                          maxLines: 2,
                          maxLength: 300,
                          inputFormatters: [LengthLimitingTextInputFormatter(300)],
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _healthExtraNotesCtrl,
                          label: 'Ek Sağlık Bilgileri & Notlar',
                          hint: 'Doktor/hastane bilgisi veya ek sağlık açıklamaları...',
                          icon: Icons.medical_information_rounded,
                          maxLines: 2,
                          maxLength: 300,
                          inputFormatters: [LengthLimitingTextInputFormatter(300)],
                        ),
                      ],
                    ),
                  ),
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

  /// Aileden 1. ve 2. Destek Kişisi Bloğu (Ad Soyad + Yakınlık Seçimi + Telefon + Acil Durum Kişisi Seçeneği)
  Widget _buildSupportPersonBlock({
    required String blockTitle,
    required TextEditingController nameController,
    required String nameLabel,
    required String nameHint,
    required TextEditingController phoneController,
    required String phoneLabel,
    required String selectedRelation,
    required ValueChanged<String> onRelationChanged,
    required bool isEmergencySelected,
    required ValueChanged<bool?> onEmergencyChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          blockTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: nameController,
          label: nameLabel,
          hint: nameHint,
          icon: Icons.person_rounded,
          maxLength: 50,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
        ),
        const SizedBox(height: 10),
        const Text(
          'Destek Kişisi Yakınlığı:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _familyRelationOptions.map((rel) {
            final isSel = rel == selectedRelation;
            return ChoiceChip(
              label: Text(
                rel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSel,
              selectedColor: AppColors.buttonIndigo,
              backgroundColor: AppColors.background,
              onSelected: (val) {
                if (val) onRelationChanged(rel);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: phoneController,
          label: phoneLabel,
          hint: 'Örn: 05551234567',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          showCounter: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.accentRed,
          title: const Text(
            'Bu kişiyi Acil Durum Kişisi olarak seç',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          value: isEmergencySelected,
          onChanged: onEmergencyChanged,
        ),
      ],
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
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
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
    bool showCounter = false,
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
              counterText: showCounter ? null : '',
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
