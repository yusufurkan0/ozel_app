import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/inactivity_help_service.dart';
import '../../theme/app_theme.dart';

class CashLedgerScreen extends StatefulWidget {
  const CashLedgerScreen({super.key});

  @override
  State<CashLedgerScreen> createState() => _CashLedgerScreenState();
}

class _CashLedgerScreenState extends State<CashLedgerScreen> {
  final FlutterTts _tts = FlutterTts();
  late InactivityHelpService _inactivityHelp;

  // Cüzdandaki banknot adetleri (200, 100, 50, 20, 10, 5, 1 TL)
  final Map<int, int> _walletCounts = {
    200: 0,
    100: 0,
    50: 0,
    20: 0,
    10: 0,
    5: 0,
    1: 0,
  };

  int get _totalWalletBalance {
    int sum = 0;
    _walletCounts.forEach((val, count) => sum += val * count);
    return sum;
  }

  // Alışveriş Modu Durumları
  bool _isShoppingMode = false;
  final List<Map<String, dynamic>> _cartItems = [];
  bool _showPaymentGuidance = false;
  Map<int, int> _suggestedPaymentNotes = {};
  int _totalRoundedBill = 0;
  int _totalGivenMoney = 0;
  int _changeDue = 0;

  final List<Map<String, dynamic>> _denominations = [
    {
      'val': 200,
      'name': '200 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_200_note.jpg',
      'color': const Color(0xFF9333EA),
    },
    {
      'val': 100,
      'name': '100 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_100_note.jpg',
      'color': const Color(0xFF0284C7),
    },
    {
      'val': 50,
      'name': '50 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_50_note.jpg',
      'color': const Color(0xFFEA580C),
    },
    {
      'val': 20,
      'name': '20 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_20_note.jpg',
      'color': const Color(0xFF16A34A),
    },
    {
      'val': 10,
      'name': '10 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_10_note.jpg',
      'color': const Color(0xFFDC2626),
    },
    {
      'val': 5,
      'name': '5 TL',
      'sub': 'Banknot',
      'isCoin': false,
      'image': 'assets/images/tl_5_note.jpg',
      'color': const Color(0xFF854D0E),
    },
    {
      'val': 1,
      'name': '1 TL',
      'sub': 'Madeni Para',
      'isCoin': true,
      'image': 'assets/images/tl_1_coin.jpg',
      'color': const Color(0xFFD97706),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _inactivityHelp = InactivityHelpService();
    _loadWalletData();
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

  Future<void> _loadWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('user_wallet_counts');
      if (savedStr != null && savedStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(savedStr);
        setState(() {
          decoded.forEach((k, v) {
            final keyInt = int.tryParse(k);
            if (keyInt != null && _walletCounts.containsKey(keyInt)) {
              _walletCounts[keyInt] = v as int;
            }
          });
        });
      }
    } catch (_) {}

    // Sabah cüzdan kontrol yönergesi
    _speak('Günaydın! Cüzdanında ne kadar paran var hadi bakalım, paralarını say ve cüzdanını güncelle.');
  }

  Future<void> _saveWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> toSave = {};
      _walletCounts.forEach((k, v) => toSave[k.toString()] = v);
      await prefs.setString('user_wallet_counts', jsonEncode(toSave));
    } catch (_) {}
  }

  void _updateCount(int val, int delta) {
    _inactivityHelp.reset(context);
    setState(() {
      final current = _walletCounts[val] ?? 0;
      final updated = (current + delta).clamp(0, 99);
      _walletCounts[val] = updated;
    });
    _saveWalletData();
    _speak('$val Lira güncellendi. Toplam cüzdanında $_totalWalletBalance Türk Lirası var.');
  }

  // ─── ALIŞVERİŞ İŞLEMLERİ ───
  void _startShopping() {
    setState(() {
      _isShoppingMode = true;
      _cartItems.clear();
      _showPaymentGuidance = false;
      _suggestedPaymentNotes.clear();
      _totalRoundedBill = 0;
      _totalGivenMoney = 0;
      _changeDue = 0;
    });
    _inactivityHelp.start(context);
    _speak('Alışveriş başladı! Aldığın ürünlerin virgülden önceki kısmını gir. Her ürün 1 lira yukarı yuvarlanarak hesaplanacaktır.');
  }

  void _showAddProductModal() {
    final nameCtrl = TextEditingController(text: 'Ürün ${_cartItems.length + 1}');
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yeni Ürün Ekle 🛍️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),

              // Virgülün Solu Görsel İpucu Kartı
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                      ),
                      child: const Row(
                        children: [
                          Text('24', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          Text(',90 TL', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Fiyat etiketindeki virgülün SOLUNDAKİ rakamı girin.\n(Örn: 24,90 için 24 yazın)',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Ürün Adı',
                  hintText: 'Örn: Ekmek, Süt, Çikolata',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Virgülün Solundaki Tutar (TL)',
                  hintText: 'Örn: 24',
                  prefixText: '₺ ',
                  suffixText: '+ 1 TL Yuvarlama',
                  suffixStyle: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Sepete Ekle (+1 TL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () {
                    final rawPrice = int.tryParse(priceCtrl.text.trim()) ?? 0;
                    if (rawPrice > 0) {
                      final roundedPrice = rawPrice + 1; // 1 TL yuvarlama kuralı
                      setState(() {
                        _cartItems.add({
                          'name': nameCtrl.text.trim().isEmpty ? 'Ürün' : nameCtrl.text.trim(),
                          'rawPrice': rawPrice,
                          'roundedPrice': roundedPrice,
                        });
                      });
                      Navigator.pop(ctx);
                      _inactivityHelp.reset(context);
                      _speak('${nameCtrl.text.trim()} eklendi. $rawPrice lira, 1 lira yuvarlanarak $roundedPrice lira hesaplandı.');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finishShopping() {
    if (_cartItems.isEmpty) {
      _speak('Sepetinde henüz ürün bulunmuyor.');
      return;
    }

    int totalRounded = 0;
    for (var item in _cartItems) {
      totalRounded += (item['roundedPrice'] as int);
    }

    // Cüzdandaki mevcut paralardan en uygun kombinasyonu seç
    final paymentPlan = _calculateOptimalPayment(totalRounded);

    int totalPaid = 0;
    paymentPlan.forEach((val, count) => totalPaid += val * count);

    setState(() {
      _showPaymentGuidance = true;
      _totalRoundedBill = totalRounded;
      _suggestedPaymentNotes = paymentPlan;
      _totalGivenMoney = totalPaid;
      _changeDue = totalPaid >= totalRounded ? (totalPaid - totalRounded) : 0;
    });

    _inactivityHelp.reset(context);
    _speak('Alışveriş tamamlandı. Toplam harcamanız $totalRounded Türk Lirası. Cüzdanınızdan bu paraları vermelisiniz.');
  }

  /// Cüzdandaki paralarla toplam tutarı karşılayacak banknot kombinasyonu
  Map<int, int> _calculateOptimalPayment(int targetAmount) {
    final Map<int, int> chosen = {};
    int remaining = targetAmount;

    // Kopya cüzdan
    final available = Map<int, int>.from(_walletCounts);
    final sortedVals = [200, 100, 50, 20, 10, 5, 1];

    for (int val in sortedVals) {
      if (remaining <= 0) break;
      int availCount = available[val] ?? 0;
      if (availCount > 0) {
        int need = (remaining / val).floor();
        int take = need > availCount ? availCount : need;
        if (take > 0) {
          chosen[val] = take;
          remaining -= val * take;
          available[val] = availCount - take;
        }
      }
    }

    // Eğer tam yetmediyse en küçük büyük banknottan 1 adet daha al
    if (remaining > 0) {
      for (int val in sortedVals.reversed) {
        int availCount = available[val] ?? 0;
        if (availCount > 0 && val >= remaining) {
          chosen[val] = (chosen[val] ?? 0) + 1;
          remaining -= val;
          break;
        }
      }
    }

    return chosen;
  }

  void _confirmPaymentAndApply() async {
    // Verilen paraları cüzdandan düş
    _suggestedPaymentNotes.forEach((val, count) {
      _walletCounts[val] = ((_walletCounts[val] ?? 0) - count).clamp(0, 99);
    });

    // Para üstünü cüzdana ekle (en pratik dağılım)
    if (_changeDue > 0) {
      int tempChange = _changeDue;
      for (int val in [200, 100, 50, 20, 10, 5, 1]) {
        if (tempChange >= val) {
          int count = tempChange ~/ val;
          _walletCounts[val] = (_walletCounts[val] ?? 0) + count;
          tempChange -= count * val;
        }
      }
    }

    await _saveWalletData();

    setState(() {
      _isShoppingMode = false;
      _showPaymentGuidance = false;
      _cartItems.clear();
    });

    _inactivityHelp.stop();

    _speak('Ödeme tamamlandı! Para üstü cüzdana eklendi. Güncel cüzdan bakiyeniz $_totalWalletBalance Lira.');

    // Fiş Uyarısı Diyaloğu
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Color(0xFFF59E0B), size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text('Fişini Almayı Unutma! 🧾', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Kasadan ayrıldığında alışveriş fişini mutlaka alıp eve götür! 🧾🏠',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kalan Cüzdan Bakiyesi: $_totalWalletBalance TL',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam, Fişimi Aldım ✅'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _inactivityHelp.stop();
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
          onPressed: () {
            if (_isShoppingMode) {
              setState(() => _isShoppingMode = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _isShoppingMode ? 'Alışveriş Modu 🛒' : 'Nakit Para Defterim',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
      body: _isShoppingMode ? _buildShoppingModeView() : _buildWalletCounterView(),
    );
  }

  /// 1. Görünüm: Cüzdan Sayım ve Bakiye Kartları
  Widget _buildWalletCounterView() {
    return Column(
      children: [
        // Bakiye ve Hatırlatma Kartı
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF15803D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_sunny_rounded, color: Colors.yellow, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'SABAH CÜZDAN KONTROLÜ',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₺ $_totalWalletBalance',
                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cüzdanındaki Toplam Nakit Para',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.shopping_bag_rounded),
                  label: const Text('Alışverişi Başlat 🛒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: _startShopping,
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Cüzdanındaki paraların adetlerini işaretle:',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),

        // Kağıt ve Madeni Para Listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: _denominations.length,
            itemBuilder: (context, index) {
              final item = _denominations[index];
              final val = item['val'] as int;
              final name = item['name'] as String;
              final isCoin = item['isCoin'] as bool;
              final imagePath = item['image'] as String;
              final color = item['color'] as Color;
              final count = _walletCounts[val] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Banknot / Para Görseli
                      ClipRRect(
                        borderRadius: BorderRadius.circular(isCoin ? 30 : 10),
                        child: Container(
                          width: isCoin ? 54 : 90,
                          height: 54,
                          decoration: BoxDecoration(
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(isCoin ? 30 : 10),
                          ),
                          child: Image.asset(imagePath, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
                            Text(
                              isCoin ? 'Madeni Para' : 'Kağıt Banknot',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      // Artır / Azalt Kontrolleri
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 28),
                            onPressed: count > 0 ? () => _updateCount(val, -1) : null,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 32),
                            alignment: Alignment.center,
                            child: Text(
                              '$count',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF16A34A), size: 28),
                            onPressed: () => _updateCount(val, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 2. Görünüm: "Alışverişi Başlat" ve Ödeme Rehberi
  Widget _buildShoppingModeView() {
    return Column(
      children: [
        // Alışveriş Başlık Özeti
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aktif Alışveriş Sepeti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${_cartItems.length} Ürün eklendi (+1 TL yuvarlama aktif)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ürün Ekle'),
                onPressed: _showAddProductModal,
              ),
            ],
          ),
        ),

        // Sepetteki Ürünler Listesi veya Ödeme Rehberi
        Expanded(
          child: _showPaymentGuidance
              ? _buildPaymentResultCard()
              : (_cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart_rounded, size: 54, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          const Text('Sepetiniz Henüz Boş', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF475569))),
                          const SizedBox(height: 6),
                          const Text('Aldığın ürünlerin fiyatını eklemek için yukarıdaki butona bas.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('İlk Ürünü Ekle'),
                            onPressed: _showAddProductModal,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, idx) {
                        final item = _cartItems[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ),
                            title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Girilen: ${item['rawPrice']} TL ➔ 1 TL Yuvarlama: ${item['roundedPrice']} TL'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                              onPressed: () {
                                setState(() => _cartItems.removeAt(idx));
                              },
                            ),
                          ),
                        );
                      },
                    )),
        ),

        // Alt Çubuk: Alışverişi Bitir & Ödemeye Geç
        if (!_showPaymentGuidance && _cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.point_of_sale_rounded, size: 24),
                label: const Text('Alışverişi Bitir & Ödemeye Geç ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _finishShopping,
              ),
            ),
          ),
      ],
    );
  }

  /// Ödeme Detayı & Banknot Göstergesi
  Widget _buildPaymentResultCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              children: [
                const Text('HESAPLANAN TOPLAM TUTAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                const SizedBox(height: 6),
                Text('₺ $_totalRoundedBill', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cüzdanındaki bu paraları vermelisin:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Verilecek Paraların Görselleri
                if (_suggestedPaymentNotes.isEmpty)
                  const Text('Cüzdanındaki nakit para toplamı yetersiz kalabilir.', style: TextStyle(color: Colors.red))
                else
                  ..._suggestedPaymentNotes.entries.map((entry) {
                    final val = entry.key;
                    final count = entry.value;
                    final noteData = _denominations.firstWhere((d) => d['val'] == val);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(noteData['isCoin'] ? 24 : 8),
                            child: Image.asset(noteData['image'] as String, width: noteData['isCoin'] ? 48 : 80, height: 48, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              '$count Adet $val TL ver',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                          ),
                          Text('${val * count} TL', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                    );
                  }),

                const Divider(height: 24),

                // Para Üstü Hesabı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kasiyere Verilen Tutar:', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    Text('₺ $_totalGivenMoney', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Alınacak Para Üstü:', style: TextStyle(fontSize: 14, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                    Text('₺ $_changeDue', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fiş Hatırlatma Kutusu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_rounded, color: Color(0xFFD97706), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kasadan ayrıldığında alışveriş fişini eve götürmeyi unutma! 🧾',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Ödemeyi Onayla & Cüzdanı Güncelle Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 24),
              label: const Text('Ödemeyi Yaptım & Cüzdanı Güncelle ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: _confirmPaymentAndApply,
            ),
          ),
        ],
      ),
    );
  }
}
