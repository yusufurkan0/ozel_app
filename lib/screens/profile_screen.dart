import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// 🌟 İlk Kurulum & Kayıt Ekranı (Aile, Çocuk ve Gerçek Acil SOS Bilgileri)
class ProfileScreen extends StatefulWidget {
  final bool isEditing;
  const ProfileScreen({super.key, this.isEditing = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _childNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  String _selectedAvatar = '🐻';
  String _selectedDiagnosis = 'Otizm Spektrumu 🧩';

  static const List<String> _avatars = [
    '🐻', '🐰', '🦁', '🐼', '🦊', '🐱',
    '🐶', '🐨', '🦄', '🚀', '🌟', '🐬',
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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final game = Provider.of<GameProgressService>(context, listen: false);

    final childName = prefs.getString('sos_child_name') ?? prefs.getString('child_name') ?? game.childName;
    final childAge = prefs.getString('sos_child_age') ?? '';
    final parentName = prefs.getString('sos_parent_name') ?? '';
    final parentPhone = prefs.getString('sos_parent_phone') ?? '';
    final altPhone = prefs.getString('sos_alt_phone') ?? '';
    final address = prefs.getString('sos_home_address') ?? '';
    final notes = prefs.getString('sos_medical_notes') ?? '';
    final avatar = prefs.getString('avatar') ?? game.avatar;
    final diagnosis = prefs.getString('child_diagnosis') ?? _selectedDiagnosis;

    if (mounted) {
      setState(() {
        _childNameController.text = childName;
        _ageController.text = childAge;
        _parentNameController.text = parentName;
        _parentPhoneController.text = parentPhone;
        _altPhoneController.text = altPhone;
        _addressController.text = address;
        _medicalNotesController.text = notes;
        if (avatar.isNotEmpty) _selectedAvatar = avatar;
        if (_diagnosisOptions.contains(diagnosis)) _selectedDiagnosis = diagnosis;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _ageController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final childName = _childNameController.text.trim();
    final parentPhone = _parentPhoneController.text.trim();

    if (childName.isEmpty) {
      _showError('Lütfen çocuğunuzun adını giriniz.');
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

    final childAge = _ageController.text.trim();
    final parentName = _parentNameController.text.trim().isNotEmpty
        ? _parentNameController.text.trim()
        : 'Ebeveyn';
    final altPhone = _altPhoneController.text.trim();
    final address = _addressController.text.trim();
    
    // Tanı ve sağlık notunu birleştir
    String notes = _medicalNotesController.text.trim();
    if (notes.isEmpty) {
      notes = 'Tanı: $_selectedDiagnosis. Konuşma güçlüğü vardır, sakin yaklaşınız.';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_child_name', childName);
    await prefs.setString('sos_child_age', childAge.isNotEmpty ? '$childAge Yaşında' : '');
    await prefs.setString('sos_parent_name', parentName);
    await prefs.setString('sos_parent_phone', parentPhone);
    await prefs.setString('sos_alt_phone', altPhone);
    await prefs.setString('sos_home_address', address);
    await prefs.setString('sos_medical_notes', notes);
    await prefs.setString('child_diagnosis', _selectedDiagnosis);
    await prefs.setBool('is_registered', true);

    // Servis profilini kaydet
    if (!mounted) return;
    final gameService = Provider.of<GameProgressService>(context, listen: false);
    await gameService.saveProfile(childName, _selectedAvatar);

    if (!mounted) return;

    if (widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bilgiler başarıyla güncellendi! ✅'),
          backgroundColor: AppColors.positiveGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, sec) => const HomeScreen(),
          transitionsBuilder: (ctx, anim, sec, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Bilgileri Güncelle' : 'Kayıt ve Kurulum'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Karşılama Başlığı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: Neu.elevated(radius: 20, blur: 8),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: Neu.inset(radius: 27),
                      child: const Center(
                        child: Text('🌟', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoş Geldiniz! 🎈',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Çocuğunuzun güvenliği ve doğru iletişim için bilgileri doldurunuz.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── 1. BÖLÜM: ÇOCUĞUN BİLGİLERİ ─────────────────
              _buildSectionHeader('🧒 1. Çocuğun Bilgileri', 'Uygulama içinde görünecek profil'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: Neu.elevated(radius: 20, blur: 8),
                child: Column(
                  children: [
                    // Avatar Seçici
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: Neu.inset(radius: 32),
                          child: Center(
                            child: Text(_selectedAvatar, style: const TextStyle(fontSize: 34)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Çocuğun Maskotu',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Sevdiği karakteri aşağıdan seçin',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Avatar Seçim Izgarası
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
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.buttonIndigo.withValues(alpha: 0.25) : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: isSel ? Border.all(color: AppColors.buttonIndigo, width: 2) : null,
                            ),
                            child: Center(
                              child: Text(av, style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // İsim Girişi
                    _buildTextField(
                      controller: _childNameController,
                      label: 'Çocuğun Adı Soyadı *',
                      hint: 'Örn: Can Yılmaz',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 12),

                    // Yaş Girişi
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

                    // Tanı / Özel Durum Seçimi
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Özel Durumu / Tanısı',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
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

              // ─── 2. BÖLÜM: EBEVEYN & ACİL DURUM İLETİŞİMİ ──────────
              _buildSectionHeader('🚨 2. Ebeveyn & Acil Durum (SOS)', 'Acil butonuna ve güvenlik kartına işlenir'),
              const SizedBox(height: 12),

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
              const SizedBox(height: 28),

              // Kaydet & Başla Butonu
              GestureDetector(
                onTap: _saveAndContinue,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: Neu.colored(color: AppColors.buttonIndigo),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isEditing ? 'Değişiklikleri Kaydet ✅' : 'Kaydı Tamamla & Başla 🚀',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    int maxLines = 1,
    Color? iconColor,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: Neu.inset(radius: 14),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              icon: Icon(icon, color: iconColor ?? AppColors.buttonIndigo, size: 20),
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.6)),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}
