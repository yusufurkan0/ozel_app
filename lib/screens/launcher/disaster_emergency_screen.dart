import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';

class DisasterEmergencyScreen extends StatefulWidget {
  const DisasterEmergencyScreen({super.key});

  @override
  State<DisasterEmergencyScreen> createState() => _DisasterEmergencyScreenState();
}

class _DisasterEmergencyScreenState extends State<DisasterEmergencyScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isWhistleActive = false;
  Timer? _whistleTimer;

  final List<Map<String, dynamic>> _safetyTips = [
    {
      'title': 'Deprem Anında: ÇÖK - KAPAN - TUTUN',
      'desc': 'Sağlam bir masanın yanına çök, başını koru ve sarsıntı bitene kadar bekle.',
      'icon': Icons.shield_rounded,
      'color': Colors.amber.shade800,
    },
    {
      'title': 'Yangın Anında: EĞİLEREK İLERLE',
      'desc': 'Dumandan korunmak için yere yakın kal, ağzını ve burnunu bir bezle kapat.',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.deepOrange,
    },
    {
      'title': 'Asansör Kullanma!',
      'desc': 'Deprem ve yangın anında kesinlikle asansöre binme, merdivenleri kullan.',
      'icon': Icons.stairs_rounded,
      'color': Colors.red,
    },
    {
      'title': '112 Acil Çağrı Merkezi',
      'desc': 'Tüm acil durumlar (Ambulans, İtfaiye, Polis) için tek numara 112.',
      'icon': Icons.emergency_rounded,
      'color': Colors.blue.shade700,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.48);
    } catch (_) {}
  }

  void _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  void _toggleWhistle() {
    if (_isWhistleActive) {
      _whistleTimer?.cancel();
      _tts.stop();
      setState(() => _isWhistleActive = false);
    } else {
      setState(() => _isWhistleActive = true);
      _playWhistleCycle();
      _whistleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _playWhistleCycle();
      });
    }
  }

  void _playWhistleCycle() async {
    await _tts.speak('Düdük! Buradayım, yardım edin!');
  }

  @override
  void dispose() {
    _whistleTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            _whistleTimer?.cancel();
            _tts.stop();
            Navigator.pop(context);
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Afet ve Acil Durum', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Acil Düdük ve Siren Butonu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isWhistleActive
                      ? [Colors.orange.shade800, Colors.red.shade900]
                      : [Colors.red.shade700, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isWhistleActive ? Icons.notifications_active_rounded : Icons.campaign_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ACİL DEPREM DÜDÜĞÜ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enkaz altında veya yardım çağırmak için sürekli ses çıkarır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(_isWhistleActive ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(
                      _isWhistleActive ? 'DÜDÜĞÜ DURDUR' : 'DÜDÜK ÇAL / SES VER',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _toggleWhistle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 112 Acil Çağrı Kartı
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 26),
                label: const Text('112 ACİL ÇAĞRIYI ARA', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _speak('112 Acil Yardım aranıyor.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('112 Acil Yardım aranıyor...'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Hayati Güvenlik Kuralları
            const Text(
              'Görsel Hayati Bilgiler:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ..._safetyTips.map((tip) {
              final color = tip['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tip['icon'] as IconData, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(tip['desc'] as String, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo),
                      onPressed: () => _speak('${tip['title']}. ${tip['desc']}'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
