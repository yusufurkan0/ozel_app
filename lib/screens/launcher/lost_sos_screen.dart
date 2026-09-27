import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Kullanıcı isteği: Kesinlikle otomatik/sahte bilgi konulmaz, tamamen boş başlar.
  String _childName = '';
  String _emergencyPhone = '';
  String _emergencyNotes = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadEmergencyInfo();
  }

  Future<void> _loadEmergencyInfo() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _childName = _prefs?.getString('user_emergency_name') ?? '';
      _emergencyPhone = _prefs?.getString('user_emergency_phone') ?? '';
      _emergencyNotes = _prefs?.getString('user_emergency_notes') ?? '';
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveEmergencyInfo(String name, String phone, String notes) async {
    setState(() {
      _childName = name;
      _emergencyPhone = phone;
      _emergencyNotes = notes;
    });
    await _prefs?.setString('user_emergency_name', name);
    await _prefs?.setString('user_emergency_phone', phone);
    await _prefs?.setString('user_emergency_notes', notes);
    _speak('Acil durum bilgileriniz kaydedildi.');
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
      await _tts.speak(text);
    } catch (_) {}
  }

  void _triggerLostSos() async {
    setState(() => _isSosActive = true);
    String announcement;
    if (_childName.isNotEmpty && _emergencyPhone.isNotEmpty) {
      announcement = 'Dikkat! Ben $_childName. Şu an kayboldum. Lütfen ailemi arayarak bana yardım eder misiniz? Telefon numarası: $_emergencyPhone';
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

  void _openEditDialog() {
    final nameCtrl = TextEditingController(text: _childName);
    final phoneCtrl = TextEditingController(text: _emergencyPhone);
    final notesCtrl = TextEditingController(text: _emergencyNotes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                decoration: const InputDecoration(
                  labelText: 'Adı Soyadı',
                  hintText: 'Öğrencinin adı soyadı',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Acil Durum Telefon Numarası',
                  hintText: 'Örn: 05xx xxx xx xx',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Önemli Sağlık / İletişim Notu',
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
                nameCtrl.text.trim(),
                phoneCtrl.text.trim(),
                notesCtrl.text.trim(),
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
      backgroundColor: const Color(0xFFFFF5F5),
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
            Text('Kayboldum / Acil Yardım', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Dev Acil Durum Butonu
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_isSosActive) {
                          _stopSos();
                        } else {
                          _triggerLostSos();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isSosActive
                                ? [Colors.orange.shade700, Colors.red.shade900]
                                : [Colors.red.shade500, Colors.red.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: _isSosActive ? 0.6 : 0.35),
                              blurRadius: _isSosActive ? 30 : 16,
                              spreadRadius: _isSosActive ? 6 : 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSosActive ? Icons.volume_up_rounded : Icons.sos_rounded,
                              color: Colors.white,
                              size: 68,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isSosActive ? 'SESİ DURDUR' : 'KAYBOLDUM!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSosActive ? 'Sesli çağrı yapılıyor' : 'Yardım istemek için bas',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Kimlik ve Acil Bilgi Kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.red.shade200, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A0F172A),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ACİL KİMLİK KARTI',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 1.2),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Düzenle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: _openEditDialog,
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _infoRow(
                          Icons.person_rounded,
                          'Adı Soyadı:',
                          _childName.isNotEmpty ? _childName : '(Henüz girilmedi)',
                          isSet: _childName.isNotEmpty,
                        ),
                        const SizedBox(height: 10),
                        _infoRow(
                          Icons.phone_in_talk_rounded,
                          'Aile İletişim:',
                          _emergencyPhone.isNotEmpty ? _emergencyPhone : '(Numara eklenmedi)',
                          isSet: _emergencyPhone.isNotEmpty,
                        ),
                        const SizedBox(height: 10),
                        _infoRow(
                          Icons.medical_information_rounded,
                          'Önemli Not:',
                          _emergencyNotes.isNotEmpty ? _emergencyNotes : '(Not eklenmedi)',
                          isSet: _emergencyNotes.isNotEmpty,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ailemi Ara Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emergencyPhone.isNotEmpty ? Colors.green.shade600 : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 24),
                      label: Text(
                        _emergencyPhone.isNotEmpty ? 'Ailemi Ara ($_emergencyPhone)' : 'Acil Durum Numarası Ekle',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        if (_emergencyPhone.isNotEmpty) {
                          _tts.speak('Aile numarası aranıyor: $_emergencyPhone');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$_emergencyPhone aranıyor...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          _openEditDialog();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isSet = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: isSet ? Colors.red.shade700 : Colors.grey),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isSet ? AppColors.textPrimary : const Color(0xFF94A3B8),
              fontStyle: isSet ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

