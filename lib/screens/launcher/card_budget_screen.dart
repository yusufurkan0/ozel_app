import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';

class CardBudgetScreen extends StatefulWidget {
  const CardBudgetScreen({super.key});

  @override
  State<CardBudgetScreen> createState() => _CardBudgetScreenState();
}

class _CardBudgetScreenState extends State<CardBudgetScreen> {
  final FlutterTts _tts = FlutterTts();
  double _cardBalance = 320.0;
  final double _monthlyLimit = 500.0;

  final List<String> _safetyRules = [
    'Kart şifreni (PIN) asla yabancılara söyleme! 🔒',
    'Temassız ödeme yaparken tutarı mutlaka ekranda kontrol et! 📱',
    'Alışverişten sonra kartını ve fişini almayı unutma! 🧾',
    'Kartını kaybedersen hemen ailene haber ver! 📢',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.5);
    } catch (_) {}
  }

  void _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  void _simulateCardPayment() {
    if (_cardBalance < 35) {
      _speak('Kartında yeterli bakiye bulunmuyor.');
      return;
    }
    setState(() {
      _cardBalance -= 35;
    });
    _speak('Bip! Temassız ödeme başarılı. Otobüs veya market için 35 lira ödendi. Kalan kart bakiyesi ${_cardBalance.toInt()} lira.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.contactless_rounded, color: Colors.blue, size: 28),
            SizedBox(width: 8),
            Text('Ödeme Başarılı! ✅'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Temassız kart ödemesi tamamlandı.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Tutar: 35.00 TL\nKalan Bakiye: ${_cardBalance.toStringAsFixed(0)} TL', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonIndigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Harika'),
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
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.credit_card_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Kredi Kartı Defterim', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo),
            onPressed: () => _speak('Kart bakiyen ${_cardBalance.toInt()} Türk Lirası.'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gerçekçi Kart Görseli
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3C72).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ÖĞRENCİ YAŞAM KARTI',
                        style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.contactless_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        '••••  ••••  ••••  4821',
                        style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('KART BAKİYESİ', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          Text(
                            '₺${_cardBalance.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Text('GÜVENLİ', style: TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Temassız Ödeme Simülasyonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.contactless_rounded),
                label: const Text('Temassız Ödemeyi Dene (35 TL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _simulateCardPayment,
              ),
            ),

            const SizedBox(height: 28),

            // Kart Güvenliği ve Kurallar
            const Text(
              'Kart Kullanırken Dikkat Edilecekler:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ..._safetyRules.map((rule) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rule,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo, size: 20),
                    onPressed: () => _speak(rule),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
