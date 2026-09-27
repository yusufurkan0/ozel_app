import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';

class CashLedgerScreen extends StatefulWidget {
  const CashLedgerScreen({super.key});

  @override
  State<CashLedgerScreen> createState() => _CashLedgerScreenState();
}

class _CashLedgerScreenState extends State<CashLedgerScreen> {
  final FlutterTts _tts = FlutterTts();

  // Kullanıcının butonlara basarak kendi oluşturduğu nakit toplamı
  int _totalBalance = 0;

  // Hangi paradan kaç adet basıldığının sayacı
  final Map<int, int> _counts = {
    1: 0,
    5: 0,
    10: 0,
    20: 0,
    50: 0,
    100: 0,
    200: 0,
  };

  // İşlem modu: true = Para Ekle (Cüzdana koy), false = Para Çıkar (Harcama)
  bool _isAddMode = true;

  // 1 TL'den başlayan tüm orijinal Türk Lirası birimleri ve görselleri
  final List<Map<String, dynamic>> _liraCurrencies = [
    {
      'val': 1,
      'name': '1 TL',
      'sub': 'Madeni Para',
      'isCoin': true,
      'image': 'assets/images/tl_1_coin.jpg',
      'color': const Color(0xFFD97706),
      'bgColor': const Color(0xFFFEF3C7),
    },
    {
      'val': 5,
      'name': '5 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_5_note.jpg',
      'color': const Color(0xFF854D0E),
      'bgColor': const Color(0xFFFDE68A),
    },
    {
      'val': 10,
      'name': '10 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_10_note.jpg',
      'color': const Color(0xFFDC2626),
      'bgColor': const Color(0xFFFEE2E2),
    },
    {
      'val': 20,
      'name': '20 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_20_note.jpg',
      'color': const Color(0xFF16A34A),
      'bgColor': const Color(0xFFDCFCE7),
    },
    {
      'val': 50,
      'name': '50 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_50_note.jpg',
      'color': const Color(0xFFEA580C),
      'bgColor': const Color(0xFFFFEDD5),
    },
    {
      'val': 100,
      'name': '100 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_100_note.jpg',
      'color': const Color(0xFF0284C7),
      'bgColor': const Color(0xFFE0F2FE),
    },
    {
      'val': 200,
      'name': '200 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_200_note.jpg',
      'color': const Color(0xFF9333EA),
      'bgColor': const Color(0xFFF3E8FF),
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
      await _tts.setSpeechRate(0.5);
    } catch (_) {}
  }

  void _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  void _onMoneyPressed(int val) {
    setState(() {
      if (_isAddMode) {
        _totalBalance += val;
        _counts[val] = (_counts[val] ?? 0) + 1;
        _speak('$val Lira eklendi. Toplam $_totalBalance Türk Lirası.');
      } else {
        if (_totalBalance >= val && (_counts[val] ?? 0) > 0) {
          _totalBalance -= val;
          _counts[val] = (_counts[val] ?? 1) - 1;
          _speak('$val Lira çıkarıldı. Kalan paranız $_totalBalance Lira.');
        } else if (_totalBalance >= val) {
          _totalBalance -= val;
          _speak('$val Lira harcandı. Kalan paranız $_totalBalance Lira.');
        } else {
          _speak('Cüzdanda $val Lira kalmadı.');
        }
      }
    });
  }

  void _resetMoney() {
    setState(() {
      _totalBalance = 0;
      _counts.updateAll((key, value) => 0);
    });
    _speak('Cüzdan sıfırlandı. Şimdi paralarını saymaya baştan başlayabilirsin.');
  }

  void _showLargeImagePreview(BuildContext context, Map<String, dynamic> item) {
    final name = item['name'] as String;
    final sub = item['sub'] as String;
    final imagePath = item['image'] as String;
    final isCoin = item['isCoin'] as bool;
    final color = item['color'] as Color;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$name ($sub)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(isCoin ? 120 : 12),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isCoin ? 200 : 340,
                    maxHeight: isCoin ? 200 : 200,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                    borderRadius: BorderRadius.circular(isCoin ? 120 : 12),
                  ),
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add_circle_rounded),
                  label: Text('Cüzdana 1 Adet $name Ekle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    _onMoneyPressed(item['val'] as int);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text(
              'Nakit Para Defterim',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Cüzdanı Sıfırla',
            onPressed: _resetMoney,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Toplam Para Gösterge Kartı ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF15803D), Color(0xFF166534)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2515803D),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Cüzdanımdaki Toplam Para',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_totalBalance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'TL',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Sesli Oku & Sıfırla
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF166534),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.volume_up_rounded, size: 18),
                          label: const Text('Paranı Seslendir', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _speak('Cüzdanınızda toplam $_totalBalance Türk Lirası bulunuyor.'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Sıfırla', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _resetMoney,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ─── Ekle / Çıkar Modu Seçici ───
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAddMode = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isAddMode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isAddMode
                                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_rounded, color: _isAddMode ? const Color(0xFF16A34A) : Colors.grey, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Para Ekle (+)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isAddMode ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAddMode = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isAddMode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isAddMode
                                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_circle_rounded, color: !_isAddMode ? const Color(0xFFDC2626) : Colors.grey, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Para Çıkar / Harca (-)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_isAddMode ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ─── Türk Lirası Butonları (1 TL'den 200 TL'ye) ───
              Text(
                _isAddMode
                    ? 'Parana Dokun ve Ekle (1 TL - 200 TL):'
                    : 'Harcadığın Paraya Dokun ve Düş:',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),

              // 7 Adet Türk Lirası Kartı (Büyük Orijinal Görseller ile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _liraCurrencies.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _liraCurrencies[index];
                  final val = item['val'] as int;
                  final count = _counts[val] ?? 0;
                  final color = item['color'] as Color;
                  final bgColor = item['bgColor'] as Color;
                  final isCoin = item['isCoin'] as bool;
                  final imagePath = item['image'] as String;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: count > 0 ? color : const Color(0xFFE2E8F0),
                        width: count > 0 ? 2 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: count > 0 ? color.withValues(alpha: 0.14) : const Color(0x060F172A),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _onMoneyPressed(val),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // ─── BÜYÜK ORİJİNAL PARA GÖRSELİ ───
                              GestureDetector(
                                onTap: () => _showLargeImagePreview(context, item),
                                child: Hero(
                                  tag: 'money_img_$val',
                                  child: Container(
                                    width: isCoin ? 80 : 136,
                                    height: isCoin ? 80 : 76,
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      shape: isCoin ? BoxShape.circle : BoxShape.rectangle,
                                      borderRadius: isCoin ? null : BorderRadius.circular(10),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1F000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(isCoin ? 80 : 8),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, _, __) => Center(
                                              child: Icon(
                                                isCoin ? Icons.monetization_on_rounded : Icons.payments_rounded,
                                                color: color,
                                                size: 36,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            bottom: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.45),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // ─── BİLGİLER VE SAYAC ───
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item['name'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item['sub'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      count > 0
                                          ? '$count Adet var (Toplam: ${count * val} TL)'
                                          : 'Cüzdanda henüz yok',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: count > 0 ? FontWeight.w800 : FontWeight.w500,
                                        color: count > 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // ─── HIZLI ARTI / EKSİ BUTONLARI ───
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (count > 0) ...[
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFDC2626), size: 28),
                                      tooltip: '1 Adet Çıkar',
                                      onPressed: () {
                                        setState(() {
                                          _totalBalance -= val;
                                          _counts[val] = (_counts[val] ?? 1) - 1;
                                        });
                                        _speak('$val Lira çıkarıldı. Kalan $_totalBalance Lira.');
                                      },
                                    ),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF16A34A), size: 34),
                                    tooltip: '1 Adet Ekle',
                                    onPressed: () {
                                      setState(() {
                                        _totalBalance += val;
                                        _counts[val] = (_counts[val] ?? 0) + 1;
                                      });
                                      _speak('$val Lira eklendi. Toplam $_totalBalance Lira.');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ─── Cüzdandaki Paraların Dökümü ───
              const Text(
                'Cüzdanınızdaki Paraların Dağılımı:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _liraCurrencies.map((item) {
                  final val = item['val'] as int;
                  final count = _counts[val] ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: count > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: count > 0 ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      '${item['name']}: $count adet',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                        color: count > 0 ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
