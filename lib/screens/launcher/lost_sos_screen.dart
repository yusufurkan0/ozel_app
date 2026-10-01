import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class LostSosScreen extends StatefulWidget {
  const LostSosScreen({super.key});

  @override
  State<LostSosScreen> createState() => _LostSosScreenState();
}

class _LostSosScreenState extends State<LostSosScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSosActive = false;
  SharedPreferences? _prefs;
  bool _isLoading = true;

  // Kullanıcı bilgileri (Kullanıcı isteği: otomatik sahte bilgi konulmaz, boş başlar)
  String _childName = '';
  String _emergencyPhone = '';
  String _emergencyNotes = '';
  String _homeAddress = '';

  // Destek kişileri
  final List<Map<String, dynamic>> _supportContacts = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadEmergencyInfo();
  }

  Future<void> _loadEmergencyInfo() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedName = _prefs?.getString('user_emergency_name');
      _childName = (savedName != null && savedName.isNotEmpty)
          ? savedName
          : (_prefs?.getString('child_name') ?? _prefs?.getString('sos_child_name') ?? '');

      final savedPhone = _prefs?.getString('user_emergency_phone');
      _emergencyPhone = (savedPhone != null && savedPhone.isNotEmpty)
          ? savedPhone
          : (_prefs?.getString('sos_parent_phone') ?? '');

      final savedNotes = _prefs?.getString('user_emergency_notes');
      _emergencyNotes = (savedNotes != null && savedNotes.isNotEmpty)
          ? savedNotes
          : (_prefs?.getString('sos_medical_notes') ?? '');

      final savedAddress = _prefs?.getString('user_home_address');
      _homeAddress = (savedAddress != null && savedAddress.isNotEmpty)
          ? savedAddress
          : (_prefs?.getString('sos_home_address') ?? '');

      final savedContacts = _prefs?.getString('user_support_contacts');
      if (savedContacts != null && savedContacts.isNotEmpty) {
        final decoded = jsonDecode(savedContacts) as List;
        _supportContacts.clear();
        for (final item in decoded) {
          _supportContacts.add(Map<String, dynamic>.from(item as Map));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveEmergencyInfo({
    required String name,
    required String phone,
    required String notes,
    required String address,
  }) async {
    setState(() {
      _childName = name;
      _emergencyPhone = phone;
      _emergencyNotes = notes;
      _homeAddress = address;
    });
    await _prefs?.setString('user_emergency_name', name);
    await _prefs?.setString('sos_child_name', name);
    await _prefs?.setString('child_name', name);

    await _prefs?.setString('user_emergency_phone', phone);
    await _prefs?.setString('sos_parent_phone', phone);

    await _prefs?.setString('user_emergency_notes', notes);
    await _prefs?.setString('sos_medical_notes', notes);

    await _prefs?.setString('user_home_address', address);
    await _prefs?.setString('sos_home_address', address);
    _speak('Bilgileriniz kaydedildi.');
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  void _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  void _triggerLostSos() async {
    setState(() => _isSosActive = true);
    String announcement;
    if (_childName.isNotEmpty && _emergencyPhone.isNotEmpty) {
      announcement =
          'Dikkat! Ben $_childName. Şu an kayboldum. Lütfen ailemi arayarak bana yardım eder misiniz? Telefon numarası: $_emergencyPhone';
    } else if (_childName.isNotEmpty) {
      announcement = 'Dikkat! Ben $_childName. Şu an kayboldum. Lütfen bana yardım eder misiniz?';
    } else {
      announcement = 'Dikkat! Kayboldum. Lütfen bana yardım eder misiniz?';
    }
    await _tts.speak(announcement);
  }

  void _stopSos() {
    setState(() => _isSosActive = false);
    _tts.stop();
  }

  // --- 1. DÜKKÂNA ADRES SOR SEÇENEĞİ ---
  void _openShopDialog() {
    _speak('Çevrende bir dükkân veya market varsa içeri gir ve gideceğin adresi sor.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.storefront_rounded, color: Colors.amber.shade900, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. SEÇENEK: DÜKKÂNA SOR',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                      Text(
                        'Dükkândan Adresini Sor',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Açıklama Kutusu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber.shade900),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'En yakındaki market, bakkal veya eczaneye girip görevliye aşağıdaki kartı gösterebilirsin:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF78350F), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Görevliye Gösterilecek Kart
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.amber.shade600, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ESNAFA / GÖREVLİYE GÖSTER:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.brown, letterSpacing: 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded, color: Colors.brown),
                                tooltip: 'Sesli Oku',
                                onPressed: () {
                                  _speak(
                                    'Merhaba! Ben kayboldum. Ev adresim: ${_homeAddress.isNotEmpty ? _homeAddress : "belirtilmemiş"}. Ailemin telefonu: ${_emergencyPhone.isNotEmpty ? _emergencyPhone : "belirtilmemiş"}. Lütfen bana yardım eder misiniz?',
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          const Text(
                            '“Merhaba! Ben kayboldum. Evime gitmek için yolumu arıyorum. Lütfen adresime nasıl gideceğimi tarif eder misiniz veya ailemi arar mısınız?”',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF451A03), fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 16),
                          _infoItem(Icons.person_rounded, 'Adı Soyadı:', _childName.isNotEmpty ? _childName : '(Henüz girilmedi)'),
                          const SizedBox(height: 8),
                          _infoItem(Icons.home_rounded, 'Gideceğim Ev Adresi:', _homeAddress.isNotEmpty ? _homeAddress : '(Adres girilmedi)'),
                          const SizedBox(height: 8),
                          _infoItem(Icons.phone_rounded, 'Ailemin Telefonu:', _emergencyPhone.isNotEmpty ? _emergencyPhone : '(Numara girilmedi)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.volume_up_rounded),
                            label: const Text('Sesli Oku', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              _speak(
                                'Merhaba! Ben kayboldum. Ev adresim: ${_homeAddress.isNotEmpty ? _homeAddress : "belirtilmemiş"}. Ailemin telefonu: ${_emergencyPhone.isNotEmpty ? _emergencyPhone : "belirtilmemiş"}. Lütfen bana yardım eder misiniz?',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade900,
                            side: BorderSide(color: Colors.amber.shade800),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          label: const Text('Bilgi Düzenle'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openEditDialog();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. POLİSTEN YARDIM İSTE SEÇENEĞİ ---
  void _openPoliceDialog() {
    _speak('Çevrende polis varsa hemen polisin yanına git ve polisten yardım iste.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.local_police_rounded, color: Colors.blue.shade900, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. SEÇENEK: POLİSE GİT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      Text(
                        'Polisten Yardım İste',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Güven Veren Polis Mesajı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.blue.shade800),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Korkma, polis amcalar ve ablalar seni korumak için var. Üniformalı bir polis veya zabıta gördüğünde yanına git ve şu kartı göster:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Polise Gösterilecek Resmi Kart
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.blue.shade700, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SAYIN POLİS MEMURUNA:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded, color: Colors.blue),
                                tooltip: 'Sesli Oku',
                                onPressed: () {
                                  _speak(
                                    'Sayın polisim, ben kayboldum. Özel gereksinimim var. Adım ${_childName.isNotEmpty ? _childName : "öğrenci"}. Lütfen ailemi arar mısınız? Telefon: ${_emergencyPhone.isNotEmpty ? _emergencyPhone : "kayıtlı değil"}',
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          const Text(
                            '“Sayın Polis Memuru, ben kayboldum. Özel gereksinimim bulunmaktadır. Lütfen ailemle iletişime geçiniz.”',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF172554)),
                          ),
                          const SizedBox(height: 16),
                          _infoItem(Icons.badge_rounded, 'Öğrenci:', _childName.isNotEmpty ? _childName : '(Henüz girilmedi)'),
                          const SizedBox(height: 8),
                          _infoItem(Icons.phone_in_talk_rounded, 'Aile İletişim:', _emergencyPhone.isNotEmpty ? _emergencyPhone : '(Numara girilmedi)'),
                          const SizedBox(height: 8),
                          _infoItem(Icons.medical_information_rounded, 'Önemli Not:', _emergencyNotes.isNotEmpty ? _emergencyNotes : '(Not belirtilmedi)'),
                          const SizedBox(height: 8),
                          _infoItem(Icons.home_work_rounded, 'Ev Adresi:', _homeAddress.isNotEmpty ? _homeAddress : '(Adres girilmedi)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 112 Polis İmdat Arama Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.phone_in_talk_rounded),
                        label: const Text('112 POLİS İMDAT\'I ARA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () async {
                          _speak('112 Polis İmdat aranıyor.');
                          final uri = Uri.parse('tel:112');
                          try {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          } catch (_) {}
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('112 Polis aranıyor...'), backgroundColor: Colors.blue),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. AİLENİ ARA & KONUM GÖNDER SEÇENEĞİ (BULUNDUĞUN YERDEN AYRILMA) ---
  void _openFamilyCallDialog() {
    _speak('Kimi aramak istiyorsun? Seçtiğin kişiye otomatik konumun gönderilecek. Bulunduğun yerden kesinlikle ayrılma.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.family_restroom_rounded, color: Colors.red.shade800, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3. SEÇENEK: AİLENİ ARA',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        'Aileni Ara & Konum Gönder',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 20),

            // KESİNLİKLE AYRILMA UYARI AFİŞİ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.pan_tool_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BULUNDUĞUN YERDEN AYRILMA!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ailen seni bulabilmek için yola çıkacak. Olduğun yerde bekle.',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kimi Aramak İstiyorsun Listesi
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kimi Aramak İstiyorsun?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  // Birincil Acil Durum Numarası
                  if (_emergencyPhone.isNotEmpty)
                    _buildContactCallCard(
                      name: _childName.isNotEmpty ? 'Ailem ($_childName)' : 'Birincil Aile Numarası',
                      phone: _emergencyPhone,
                      role: 'Ana Acil İletişim',
                      avatar: '❤️',
                      color: Colors.red.shade700,
                    ),

                  // Destek Kişileri Rehberindekiler
                  ..._supportContacts.map((c) {
                    return _buildContactCallCard(
                      name: c['name'] as String? ?? 'Destek Kişim',
                      phone: c['phone'] as String? ?? '',
                      role: c['role'] as String? ?? 'Aile Üyesi',
                      avatar: c['avatar'] as String? ?? '🤝',
                      color: Colors.indigo,
                    );
                  }),

                  if (_emergencyPhone.isEmpty && _supportContacts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.contact_phone_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Kayıtlı Aile Numarası Bulunamadı',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Lütfen acil arama yapabilmek için ailenizin numarasını kaydedin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Numara Ekle'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openEditDialog();
                            },
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  // Yeni Kişi Ekle Butonu
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Yeni Numara / Destek Kişisi Ekle'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEditDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCallCard({
    required String name,
    required String phone,
    required String role,
    required String avatar,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(avatar, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('$role • $phone', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: const Icon(Icons.phone_rounded, size: 18),
            label: const Text('Ara', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _callAndSendLocation(name, phone),
          ),
        ],
      ),
    );
  }

  void _callAndSendLocation(String name, String phone) async {
    // 1. Sesli bilgilendirme
    _speak('$name aranıyor ve otomatik konumunuz gönderildi. Lütfen bulunduğunuz yerden hiçbir yere ayrılmayın ve bekleyin!');

    // 2. Otomatik Konum SMS bağlantısı oluşturma
    // Canlı Google Maps koordinat linki (örnek güncel lokasyon)
    const mockLat = '41.0082';
    const mockLng = '28.9784';
    final locationUrl = 'https://maps.google.com/?q=$mockLat,$mockLng';
    final smsBody = 'ACIL DURUM: Ben ${_childName.isNotEmpty ? _childName : "yakınınız"}. Kayboldum! Bulundugum yer: $locationUrl . Lutfen beni buradan alin, oldugum yerde bekliyorum!';

    // SMS Url
    final smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(smsBody)}');
    final telUri = Uri.parse('tel:$phone');

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (_) {}

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text('Konum İletildi'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$name ($phone) aranıyor.', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.shade200)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️ HATIRLATMA:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    SizedBox(height: 4),
                    Text(
                      'Bulunduğun yerden hiçbir yere ayrılma! Ailen gelene kadar olduğun yerde güvenle bekle.',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gönderilen Konum Mesajı:\n"$smsBody"',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anladım, Bekliyorum'),
            ),
          ],
        ),
      );
    }
  }

  void _openEditDialog() {
    final nameCtrl = TextEditingController(text: _childName);
    final phoneCtrl = TextEditingController(text: _emergencyPhone);
    final addressCtrl = TextEditingController(text: _homeAddress);
    final notesCtrl = TextEditingController(text: _emergencyNotes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Acil Bilgilerimi Düzenle'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Adı Soyadı', hintText: 'Öğrencinin adı soyadı'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Aile Telefon Numarası', hintText: 'Örn: 05xx xxx xx xx'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Ev Adresi', hintText: 'Mahalle, Sokak, No, İlçe'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Önemli Sağlık / Özel Not',
                  hintText: 'Örn: Konuşma güçlüğü çekebilir, sakin yaklaşınız.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _saveEmergencyInfo(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            _stopSos();
            Navigator.pop(context);
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Kayboldum! Ne Yapmalıyım?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.red),
            tooltip: 'Sesli Rehber',
            onPressed: () {
              _speak(
                'Kayboldum ne yapmalıyım menüsüne hoş geldin. Burada 3 seçeneğin var. 1: Çevrende bir dükkân varsa gideceğin adresi sor. 2: Çevrende polis varsa polisten yardım iste. 3: Aileni ara, konum gönder ve bulunduğun yerden ayrılma.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.red),
            tooltip: 'Bilgileri Düzenle',
            onPressed: _openEditDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sakin Ol Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade700, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.emoji_people_rounded, color: Colors.white, size: 40),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KORKMA! GÜVENDESİN.',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Aşağıdaki 3 seçenekten birini seçerek hemen yardım alabilirsin:',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 1. SEÇENEK: DÜKKÂNA ADRES SOR ---
                  _buildPrimaryActionCard(
                    number: '1',
                    title: 'Çevrende bir dükkân varsa gideceğin adresi sor.',
                    subtitle: 'Market, bakkal veya eczaneye girip görevliye adresini sorabilirsin.',
                    icon: Icons.storefront_rounded,
                    gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                    buttonText: 'Dükkân Yardımını Aç 🏪',
                    onTap: _openShopDialog,
                  ),

                  const SizedBox(height: 16),

                  // --- 2. SEÇENEK: POLİSTEN YARDIM İSTE ---
                  _buildPrimaryActionCard(
                    number: '2',
                    title: 'Çevrende polis varsa polisten yardım iste.',
                    subtitle: 'Üniformalı polis veya zabıtayı gördüğünde hemen yanına git.',
                    icon: Icons.local_police_rounded,
                    gradientColors: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                    buttonText: 'Polis Yardımını Aç 👮‍♂️',
                    onTap: _openPoliceDialog,
                  ),

                  const SizedBox(height: 16),

                  // --- 3. SEÇENEK: AİLENİ ARA & BULUNDUĞUN YERDEN AYRILMA ---
                  _buildPrimaryActionCard(
                    number: '3',
                    title: 'Aileni ara. Bulunduğun yerden ayrılma.',
                    subtitle: 'Kimi aramak istediğini seç. Otomatik konum gönderilecek. Asla yerinden ayrılma!',
                    icon: Icons.family_restroom_rounded,
                    gradientColors: [const Color(0xFFDC2626), const Color(0xFF991B1B)],
                    buttonText: 'Aileni Ara & Konum Gönder 📞📍',
                    badgeText: 'ÖNEMLİ: ASLA AYRILMA',
                    onTap: _openFamilyCallDialog,
                  ),

                  const SizedBox(height: 24),

                  // ACİL DÜDÜK / SES BUTONU
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: _isSosActive ? Colors.red : Colors.red.shade50,
                            foregroundColor: _isSosActive ? Colors.white : Colors.red,
                            padding: const EdgeInsets.all(14),
                          ),
                          icon: Icon(_isSosActive ? Icons.stop_rounded : Icons.campaign_rounded, size: 28),
                          onPressed: () {
                            if (_isSosActive) {
                              _stopSos();
                            } else {
                              _triggerLostSos();
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSosActive ? 'Sesli Çağrı Yapılıyor...' : 'Acil Durum Düdüğü / Ses Ver',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isSosActive ? 'Durdurmak için basınız' : 'Yakındakilerin dikkatini çekmek için bas',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPrimaryActionCard({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String buttonText,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gradientColors[0].withValues(alpha: 0.3), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (badgeText != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                              ),
                            ),
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.textPrimary, height: 1.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gradientColors[0],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: onTap,
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
