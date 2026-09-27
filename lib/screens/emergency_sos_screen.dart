import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_progress_service.dart';
import '../services/tts_service.dart';
import '../services/parent_child_sync_service.dart';
import '../theme/app_theme.dart';

/// 🚨 Acil Durum & Hızlı İletişim (SOS Güvenlik Kartı)
class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  String _childName = '';
  String _childAge = '';
  String _parentName = '';
  String _parentPhone = '';
  String _altPhone = '';
  String _homeAddress = '';
  String _medicalNotes = '';

  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyInfo();
  }

  Future<void> _loadEmergencyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final game = Provider.of<GameProgressService>(context, listen: false);
    setState(() {
      _childName = prefs.getString('sos_child_name') ?? (game.childName.isNotEmpty ? game.childName : 'Kayıtlı Çocuk');
      _childAge = prefs.getString('sos_child_age') ?? '';
      _parentName = prefs.getString('sos_parent_name') ?? 'Veli / Aile';
      _parentPhone = prefs.getString('sos_parent_phone') ?? '';
      _altPhone = prefs.getString('sos_alt_phone') ?? '';
      _homeAddress = prefs.getString('sos_home_address') ?? 'Adres bilgisi eklenmedi';
      _medicalNotes = prefs.getString('sos_medical_notes') ?? 'Özel gereksinimli bireydir, lütfen aileme ulaşın.';
    });
  }

  Future<void> _saveEmergencyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_child_name', _childName);
    await prefs.setString('sos_child_age', _childAge);
    await prefs.setString('sos_parent_name', _parentName);
    await prefs.setString('sos_parent_phone', _parentPhone);
    await prefs.setString('sos_alt_phone', _altPhone);
    await prefs.setString('sos_home_address', _homeAddress);
    await prefs.setString('sos_medical_notes', _medicalNotes);
  }

  void _broadcastSosVoice() {
    final phoneNotice = _parentPhone.isNotEmpty ? 'Ailemin telefonu: $_parentPhone.' : '';
    final broadcastText =
        'Lütfen dikkat! Ben özel gereksinimli bir bireyim, kendimi ifade edemiyorum. Kayboldum veya yardıma ihtiyacım var. Lütfen ekrandaki numarayı arayarak aileme haber verin. $phoneNotice';

    setState(() => _isSpeaking = true);
    TtsService().speak(broadcastText);

    // Ebeveyn paneline anında acil durum sinyali ve bildirimi gönder
    ParentChildSyncService().dispatchSosEvent(
      childName: _childName.isNotEmpty ? _childName : 'Öğrenci',
      emergencyNote: _medicalNotes,
      caregiverPhone: _parentPhone,
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _childName);
    final ageCtrl = TextEditingController(text: _childAge);
    final parentCtrl = TextEditingController(text: _parentName);
    final phoneCtrl = TextEditingController(text: _parentPhone);
    final altPhoneCtrl = TextEditingController(text: _altPhone);
    final addrCtrl = TextEditingController(text: _homeAddress);
    final notesCtrl = TextEditingController(text: _medicalNotes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Acil Durum Bilgilerini Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Çocuğun Adı Soyadı'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ageCtrl,
                decoration: const InputDecoration(labelText: 'Yaş / Doğum Yılı'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: parentCtrl,
                decoration: const InputDecoration(labelText: 'Ebeveyn Adı & Yakınlık'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Birinci Telefon Numarası'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: altPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'İkinci Telefon (Yedek)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addrCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Ev / Okul Adresi'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Önemli Sağlık / İlaç / Alerji Notu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _childName = nameCtrl.text.trim();
                _childAge = ageCtrl.text.trim();
                _parentName = parentCtrl.text.trim();
                _parentPhone = phoneCtrl.text.trim();
                _altPhone = altPhoneCtrl.text.trim();
                _homeAddress = addrCtrl.text.trim();
                _medicalNotes = notesCtrl.text.trim();
              });
              _saveEmergencyInfo();
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F1), // Yüksek kontrastlı sıcak açık kırmızı
      appBar: AppBar(
        title: const Text('🚨 Acil Durum & SOS Kartı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: AppColors.accentRed, size: 28),
            tooltip: 'Bilgileri Düzenle',
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Kırmızı Acil Durum Tepe Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentRed,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentRed.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🚨', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 8),
                  const Text(
                    'BEN ÖZEL GEREKSİNİMLİ BİR BİREYİM\nKONUŞAMIYORUM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lütfen aileme ulaşmama yardım edin!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Sesli Anons Butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSpeaking ? Colors.amber.shade800 : AppColors.buttonIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                ),
                icon: Icon(
                  _isSpeaking ? Icons.record_voice_over_rounded : Icons.volume_up_rounded,
                  size: 26,
                ),
                label: Text(
                  _isSpeaking ? 'Sesli Yardım Anonsu Yapılıyor...' : '🔊 ÇEVREYE SESLİ ANONS YAP',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _broadcastSosVoice,
              ),
            ),
            const SizedBox(height: 20),

            // Çocuğun Kimlik Bilgileri Kartı
            _buildInfoCard(
              title: 'Birey Bilgileri',
              icon: Icons.person_rounded,
              iconColor: AppColors.buttonIndigo,
              children: [
                _buildRow('Adı Soyadı:', _childName, isBold: true),
                const SizedBox(height: 6),
                _buildRow('Yaş / Durum:', _childAge),
              ],
            ),
            const SizedBox(height: 14),

            // Ebeveyn & İletişim Kartı
            _buildInfoCard(
              title: 'İletişim & Aile',
              icon: Icons.phone_in_talk_rounded,
              iconColor: AppColors.positiveGreen,
              children: [
                _buildRow('İletişim Kişisi:', _parentName),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.positiveGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.positiveGreen, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Acil Telefon Numarası:',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            _parentPhone,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.positiveGreen,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.positiveGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('ARA'),
                        onPressed: () {
                          if (_parentPhone.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lütfen sağ üstteki kalemle ebeveyn telefonunu kaydediniz.'),
                                backgroundColor: AppColors.accentRed,
                              ),
                            );
                            return;
                          }
                          TtsService().speak('$_parentPhone numarası aranıyor.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$_parentPhone aranıyor...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (_altPhone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildRow('Yedek Telefon:', _altPhone),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Adres Kartı
            _buildInfoCard(
              title: 'Ev / Güvenli Adres',
              icon: Icons.home_rounded,
              iconColor: AppColors.buttonAmber,
              children: [
                Text(
                  _homeAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Sağlık / İlaç Notları
            _buildInfoCard(
              title: 'Önemli Sağlık & Davranış Notları',
              icon: Icons.medical_services_rounded,
              iconColor: AppColors.accentRed,
              children: [
                Text(
                  _medicalNotes,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
