import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/inactivity_help_service.dart';
import '../../services/ocr_translation_service.dart';
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

  int get _effectiveBillAmount =>
      (_scannedReceiptTotal != null ? _scannedReceiptTotal!.ceil() : _totalRoundedBill);

  bool get _isMoneyInsufficient => _totalWalletBalance < _effectiveBillAmount;

  int get _missingMoneyAmount =>
      _isMoneyInsufficient ? (_effectiveBillAmount - _totalWalletBalance) : 0;

  void _recalculatePaymentPlan(int targetAmount) {
    final paymentPlan = _calculateOptimalPayment(targetAmount);
    int totalPaid = 0;
    paymentPlan.forEach((val, count) => totalPaid += val * count);
    setState(() {
      _totalRoundedBill = targetAmount;
      _suggestedPaymentNotes = paymentPlan;
      _totalGivenMoney = totalPaid;
      _changeDue = totalPaid >= targetAmount ? (totalPaid - targetAmount) : 0;
    });
  }

  // Alışveriş Modu Durumları
  bool _isShoppingMode = false;
  final List<Map<String, dynamic>> _cartItems = [];
  bool _showPaymentGuidance = false;
  Map<int, int> _suggestedPaymentNotes = {};
  int _totalRoundedBill = 0;
  int _totalGivenMoney = 0;
  int _changeDue = 0;

  // Fiş Tarama & Görsel İşleme Durumları
  String? _scannedReceiptImage;
  double? _scannedReceiptTotal;
  bool _isScanningReceipt = false;

  // Fiyat Etiketi Tarama Durumları

  // Haftalık ve Sabah Rutini Durumları
  String _currentWeekLabel = '';
  bool _showMorningBanner = true;

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

  String _calculateCurrentWeekLabel() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${monday.day} ${months[monday.month]} - ${sunday.day} ${months[sunday.month]} Haftası';
  }

  void _showStartOfWeekReminderDialog() {
    _speak('Yeni hafta başladı! Hadi cüzdanındaki paraları sayalım, kâğıt paraların resimlerine bakarak cüzdanını güncelle.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: Color(0xFF16A34A), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Yeni Hafta Başladı! 📅',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                '$_currentWeekLabel için haftalık cüzdan sayımı zamanı!\n\nCüzdanındaki paraları kâğıt paraların resimlerine bakarak işaretle ve haftaya hazır başla.',
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF166534), height: 1.4, fontWeight: FontWeight.w600),
              ),
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
            child: const Text('Paralarımı Say & Başla ✅'),
          ),
        ],
      ),
    );
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

      setState(() {
        _currentWeekLabel = _calculateCurrentWeekLabel();
      });

      // Haftalık kontrol: Yeni hafta başlangıcında hatırlatma
      final now = DateTime.now();
      final currentWeekKey = '${now.year}_W${((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor() + 1}';
      final lastWeekKey = prefs.getString('user_wallet_last_week');

      if (lastWeekKey != currentWeekKey) {
        await prefs.setString('user_wallet_last_week', currentWeekKey);
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showStartOfWeekReminderDialog();
          });
        }
      } else {
        // Sabah cüzdan kontrol yönergesi
        _speak('Günaydın! Cüzdanında ne kadar paran var hadi bakalım, paralarını say ve cüzdanını güncelle.');
      }
    } catch (_) {}
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
      _scannedReceiptImage = null;
      _scannedReceiptTotal = null;
      _isScanningReceipt = false;
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Yeni Ürün Ekle 🛍️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),

              // Kamerayla Fiyat Etiketi Tara Butonu
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                  label: const Text('Fiyat Etiketini Kamerayla Tara 📸', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showPriceTagScanDialog();
                  },
                ),
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
    if (_isMoneyInsufficient) {
      _speak(
        'Paramız yetmiyor! Cüzdanında $_totalWalletBalance Lira var, sepet tutarı $totalRounded Lira. $_missingMoneyAmount Lira eksik, paramız yetersiz!',
      );
    } else {
      _speak(
        'Alışveriş tamamlandı. Toplam harcamanız $totalRounded Türk Lirası. Cüzdanınızdan bu paraları vermelisiniz.',
      );
    }
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

  // ─── KAMERAYLA FİYAT ETİKETİ TARA (GÖRÜNTÜ İŞLEME - OCR) ───
  void _showPriceTagScanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fiyat Etiketi Tara 📸',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Market rafındaki fiyat etiketini veya ürün barkodundaki fiyatı kameraya göstererek okutun:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Kamerayı Başlat (Canlı Çekim) 📷', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Fiyat etiketini net görecek şekilde fotoğrafla'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                onTap: () {
                  Navigator.pop(ctx);
                  _processPriceTagFromImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Galeriden Etiket Görseli Seç 🖼️', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Daha önce çekilmiş fiyat etiketini yükle'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                onTap: () {
                  Navigator.pop(ctx);
                  _processPriceTagFromImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.label_important_rounded, color: Color(0xFFD97706)),
                ),
                title: const Text('Örnek Fiyat Etiketiyle Test Et 🏷️', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Kamera olmadan hızlı 24,90 TL etiket simülasyonu'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFFDE68A))),
                onTap: () {
                  Navigator.pop(ctx);
                  _simulatePriceTagScan();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPriceTagFromImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (photo == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('🔍 Fiyat etiketi taranıyor...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            duration: Duration(milliseconds: 1500),
            backgroundColor: Color(0xFF2563EB),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final rawText = await OcrTranslationService().recognizeText(photo.path);
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final tagData = _extractPriceFromTag(rawText);

      setState(() {
      });

      _showDetectedPriceTagConfirmation(
        imagePath: photo.path,
        rawText: rawText,
        name: tagData['name'] as String,
        rawPrice: tagData['rawPrice'] as int,
        roundedPrice: tagData['roundedPrice'] as int,
      );
    } catch (_) {
      _simulatePriceTagScan();
    }
  }

  void _simulatePriceTagScan() {
    const rawText = "DOĞAL SÜT 1L\nFİYAT: 24,90 TL\nKDV DAHİL";
    final tagData = _extractPriceFromTag(rawText);

    setState(() {
    });

    _showDetectedPriceTagConfirmation(
      imagePath: null,
      rawText: rawText,
      name: tagData['name'] as String,
      rawPrice: tagData['rawPrice'] as int,
      roundedPrice: tagData['roundedPrice'] as int,
    );
  }

  Map<String, dynamic> _extractPriceFromTag(String rawText) {
    String detectedName = 'Market Ürünü';
    int rawPrice = 0;

    if (rawText.isNotEmpty) {
      final upper = _normalizeTurkishForOcr(rawText);

      // FİŞ TESPİTİ: Eğer kullanıcı "Fiyat Tara" ile tüm fişi okuttuysa,
      // tek bir ürün yerine fişin genel toplamını (örn: 427 TL) yakala!
      final isReceipt = upper.contains('FİS NO') ||
          upper.contains('FIS NO') ||
          upper.contains('FİŞ NO') ||
          upper.contains('TOPLAM') ||
          upper.contains('TOPKDV') ||
          upper.contains('KURUMLAR V.D') ||
          upper.contains('KASİYER') ||
          upper.contains('KASIYER');

      if (isReceipt) {
        if (upper.contains('SOK') || upper.contains('ŞOK')) {
          detectedName = 'ŞOK Market Fişi 🧾';
        } else if (upper.contains('BIM') || upper.contains('BİM')) {
          detectedName = 'BİM Market Fişi 🧾';
        } else if (upper.contains('A101')) {
          detectedName = 'A101 Market Fişi 🧾';
        } else if (upper.contains('MIGROS') || upper.contains('MİGROS')) {
          detectedName = 'Migros Market Fişi 🧾';
        } else {
          detectedName = 'Market Alışveriş Fişi 🧾';
        }

        // Fişin genel toplamını (virgülün solunu) al
        final receiptTotal = _extractReceiptTotal(rawText);
        if (receiptTotal != null && receiptTotal > 0) {
          rawPrice = receiptTotal.toInt();
        }
      }

      // Eğer fiş değilse veya fiş toplamı bulunamadıysa standart raf etiketi analizi yap
      if (rawPrice <= 0) {
        final lower = rawText.toLowerCase();
        const commonItems = [
          'ekmek', 'süt', 'peynir', 'yoğurt', 'yumurta', 'zeytin', 'makarna',
          'pirinç', 'çay', 'kahve', 'şeker', 'tuz', 'yağ', 'bisküvi', 'çikolata',
          'su', 'elma', 'muz', 'domates', 'salatalık', 'patates', 'soğan', 'deterjan',
          'sabun', 'şampuan', 'diş macunu', 'peçete', 'meyve suyu', 'baget', 'piliç', 'dana'
        ];
        for (var item in commonItems) {
          if (lower.contains(item)) {
            detectedName = item[0].toUpperCase() + item.substring(1);
            break;
          }
        }

        // Fiyat tespiti (virgülün solu veya tam sayı)
        final decimalReg = RegExp(r'(\d+)[\.,](\d{1,2})');
        final matchDecimal = decimalReg.firstMatch(rawText);

        if (matchDecimal != null) {
          rawPrice = int.tryParse(matchDecimal.group(1)!) ?? 0;
        } else {
          final tlReg = RegExp(r'(\d+)\s*(?:TL|₺)');
          final matchTl = tlReg.firstMatch(rawText);
          if (matchTl != null) {
            rawPrice = int.tryParse(matchTl.group(1)!) ?? 0;
          } else {
            final numReg = RegExp(r'(\d+)');
            final matchNum = numReg.firstMatch(rawText);
            if (matchNum != null) {
              rawPrice = int.tryParse(matchNum.group(1)!) ?? 0;
            }
          }
        }
      }
    }

    if (rawPrice <= 0) {
      rawPrice = 24;
    }

    final int roundedPrice = rawPrice + 1;

    return {
      'name': detectedName,
      'rawPrice': rawPrice,
      'roundedPrice': roundedPrice,
    };
  }

  void _showDetectedPriceTagConfirmation({
    required String? imagePath,
    required String rawText,
    required String name,
    required int rawPrice,
    required int roundedPrice,
  }) {
    final isReceipt = name.contains('Fişi') || name.contains('🧾');
    _speak('$name okundu. Tutar $rawPrice lira. Bir lira yuvarlama kuralı ile $roundedPrice lira olarak hesaplandı.');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isReceipt ? Icons.receipt_long_rounded : Icons.camera_alt_rounded, color: const Color(0xFF2563EB), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isReceipt ? 'Alışveriş Fişi Okundu! 🧾' : 'Fiyat Etiketi Okundu! 📸',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!kIsWeb && imagePath != null && File(imagePath).existsSync())
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(imagePath), height: 140, fit: BoxFit.cover),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, size: 28, color: Color(0xFF2563EB)),
                        const SizedBox(height: 4),
                        Text(
                          rawText.isNotEmpty ? rawText.trim() : 'Etiket / Fiş Okundu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Ürün:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            'Virgülün Solundaki Rakam:',
                            style: TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$rawPrice TL',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            '+1 TL Yuvarlama (Kural):',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$roundedPrice TL',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: const Text('Sepete Ekle & Topla ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _cartItems.add({
                      'name': name,
                      'rawPrice': rawPrice,
                      'roundedPrice': roundedPrice,
                    });
                    if (!_isShoppingMode) {
                      _isShoppingMode = true;
                    }
                  });
                  final total = _cartItems.fold<int>(0, (sum, i) => sum + (i['roundedPrice'] as int));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF16A34A),
                      content: Text('$name sepete eklendi! Toplam Harcama: $total TL 🛒'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── KASADA FİŞİ OKUTMA / GÖRSEL İŞLEME (OCR) ───
  void _showReceiptScanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.document_scanner_rounded, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kasada Fişi Tara 🧾',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Kasiyerin verdiği alışveriş fişini okutarak harcama tutarını görsel işleme ile doğrulayabilirsiniz:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Kameradan Fiş Çek 📷', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Fişin fotoğrafını net şekilde çekin'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                onTap: () {
                  Navigator.pop(ctx);
                  _processReceiptFromImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Galeriden Fiş Seç 🖼️', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Daha önce çekilmiş fiş görselini yükleyin'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                onTap: () {
                  Navigator.pop(ctx);
                  _processReceiptFromImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706)),
                ),
                title: const Text('Örnek Fiş ile Test Et 🧾', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Kamera olmadan hızlı fiş okuma simülasyonu'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFFDE68A))),
                onTap: () {
                  Navigator.pop(ctx);
                  _simulateReceiptScan();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processReceiptFromImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (photo == null) return;

      setState(() => _isScanningReceipt = true);

      // Konumsal Bounding-Box hizalamalı fiş tanıma
      final rawText = await OcrTranslationService().recognizeReceiptText(photo.path);
      final detectedTotal = _extractReceiptTotal(rawText) ?? _totalRoundedBill.toDouble();

      setState(() {
        _isScanningReceipt = false;
        _scannedReceiptImage = photo.path;
        _scannedReceiptTotal = detectedTotal;
      });

      _recalculatePaymentPlan(detectedTotal.ceil());

      if (_isMoneyInsufficient) {
        _speak(
          'Paramız yetmiyor! Fiş tutarı ${detectedTotal.ceil()} Lira, ancak cüzdanında $_totalWalletBalance Lira var. $_missingMoneyAmount Lira eksik, paramız yetersiz!',
        );
      } else {
        _speak('Fiş başarıyla okundu. Fiş tutarı: ${detectedTotal.toStringAsFixed(2)} lira.');
      }
    } catch (_) {
      setState(() => _isScanningReceipt = false);
      _simulateReceiptScan();
    }
  }

  void _simulateReceiptScan() {
    setState(() {
      _scannedReceiptImage = null;
      _scannedReceiptTotal = _totalRoundedBill.toDouble();
    });
    _recalculatePaymentPlan(_totalRoundedBill);
    if (_isMoneyInsufficient) {
      _speak(
        'Paramız yetmiyor! Fiş tutarı $_totalRoundedBill Lira, ancak cüzdanında $_totalWalletBalance Lira var. $_missingMoneyAmount Lira eksik, paramız yetersiz!',
      );
    } else {
      _speak('Fiş başarıyla okundu. Fiş tutarı: $_totalRoundedBill lira.');
    }
  }

  /// Türk market fişlerinden (ŞOK, BİM, A101, Migros vb.) genel toplam tutarını hassas biçimde çıkarır.
  double? _extractReceiptTotal(String rawText) {
    if (rawText.trim().isEmpty) return null;

    final cleanedLines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != '---')
        .toList();
    if (cleanedLines.isEmpty) return null;

    // 1. AŞAMA: "TOPLAM" / "GENEL TOPLAM" / "ÖDENECEK" satırında doğrudan fiyat arama
    // Not: "TOPKDV" satırı KDV toplamıdır, genel toplam değildir; TOPKDV hariç tutulur!
    for (int i = cleanedLines.length - 1; i >= 0; i--) {
      final line = cleanedLines[i];
      final upper = _normalizeTurkishForOcr(line);

      // KDV toplamı satırını atla
      if (upper.contains('TOPKDV') || upper.contains('KDV TOPLAM') || upper.contains('TOP. KDV')) {
        continue;
      }

      final isTotalKeyword = upper.contains('TOPLAM') ||
          upper.contains('GENEL TOPLAM') ||
          upper.contains('T O P L A M') ||
          upper.contains('TOPL AM') ||
          upper.contains('TOP.TUTAR') ||
          upper.contains('ODENECEK') ||
          upper.contains('ÖDENECEK') ||
          upper.contains('TUTAR') ||
          upper.contains('TOTAL') ||
          upper.contains('NAKIT') ||
          upper.contains('NAKİT') ||
          upper.contains('KREDI') ||
          upper.contains('KREDİ');

      if (isTotalKeyword) {
        // Satırdaki fiyatı yakala
        final price = _findPriceInReceiptLine(line);
        if (price != null && price > 0) {
          return price;
        }

        // Eğer bu satırda fiyat yoksa (sütun ayrımı durumu), hemen altındaki 1-4 satıra bak
        for (int j = i + 1; j <= i + 4 && j < cleanedLines.length; j++) {
          final nextLine = cleanedLines[j];
          final nextUpper = _normalizeTurkishForOcr(nextLine);
          if (!nextUpper.contains('KDV') && !nextUpper.contains('TARİH') && !nextUpper.contains('SAAT')) {
            final nextPrice = _findPriceInReceiptLine(nextLine);
            if (nextPrice != null && nextPrice > 0) {
              return nextPrice;
            }
          }
        }
      }
    }

    // 2. AŞAMA: Çok satırlı Regex ile "TOPLAM ... *427,42" kalıbı
    final multiLineRegex = RegExp(
      r'(?:GENEL\s+TOPLAM|TOPLAM|T\s*O\s*P\s*L\s*A\s*M|ÖDENECEK|ODENECEK|TOTAL)[\s\S]{0,35}?[*xX+₺TLtl\s]*(\d{1,5}[\.,]\d{2})',
      caseSensitive: false,
    );
    final multiMatch = multiLineRegex.firstMatch(rawText);
    if (multiMatch != null) {
      final parsed = _parsePriceString(multiMatch.group(1));
      if (parsed != null && parsed > 0) return parsed;
    }

    // 3. AŞAMA: Fişin alt %40'ındaki sayılar arasında en mantıklı dip toplamı seç
    // Market fişlerinde en dipteki pozitif sayı genelde fiş toplamıdır.
    final allPricesWithIndices = <MapEntry<int, double>>[];
    for (int i = 0; i < cleanedLines.length; i++) {
      final line = cleanedLines[i];
      // İndirim satırlarını atla (örn: *149,00- veya -54,50)
      if (line.endsWith('-') || line.contains('-%') || line.contains('İNDİRİM') || line.contains('INDIRIM')) {
        continue;
      }
      final price = _findPriceInReceiptLine(line);
      if (price != null && price > 0) {
        allPricesWithIndices.add(MapEntry(i, price));
      }
    }

    if (allPricesWithIndices.isNotEmpty) {
      // Fişin son kısmındaki fiyatlara bak
      final thresholdIndex = (cleanedLines.length * 0.55).toInt();
      final bottomPrices = allPricesWithIndices.where((e) => e.key >= thresholdIndex).toList();

      if (bottomPrices.isNotEmpty) {
        return bottomPrices.last.value;
      }
      return allPricesWithIndices.last.value;
    }

    return null;
  }

  String _normalizeTurkishForOcr(String text) {
    return text
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
  }

  double? _findPriceInReceiptLine(String text) {
    // Eksi ile biten indirim satırlarını atla (örn: *149,00- veya -54,50)
    final trimmed = text.trim();
    if (trimmed.endsWith('-')) return null;

    // 1. Standart format: *427,42 veya 427.42 veya *46, 60
    final reg = RegExp(r'[*xX+₺TLtl~_\s]*(\d{1,5})\s*[\.,]\s*(\d{1,2})');
    final matches = reg.allMatches(text);
    if (matches.isNotEmpty) {
      final m = matches.last;
      return double.tryParse('${m.group(1)}.${m.group(2)}');
    }

    // 2. OCR gürültülü format: ~ TOPLAM *427 4; veya *104 50 (virgül boşluk olmuş, 2 yerine noktalı virgül ;)
    final noisyReg = RegExp(r'[*xX+₺TLtl~_\s]*(\d{1,5})\s+([0-9;]{1,2})');
    final noisyMatches = noisyReg.allMatches(text);
    if (noisyMatches.isNotEmpty) {
      final m = noisyMatches.last;
      final mainPart = m.group(1)!;
      String dec = m.group(2)!.replaceAll(';', '2');
      if (dec.length == 1) dec = '${dec}0';
      return double.tryParse('$mainPart.$dec');
    }

    // 3. Tamsayı formatı: *427 TL veya *427
    final intReg = RegExp(r'[*xX+₺TLtl~_\s]*(\d{1,5})');
    final intMatches = intReg.allMatches(text);
    if (intMatches.isNotEmpty) {
      return double.tryParse(intMatches.last.group(1)!);
    }

    return null;
  }

  double? _parsePriceString(String? str) {
    if (str == null || str.isEmpty) return null;
    final clean = str.replaceAll(',', '.');
    return double.tryParse(clean);
  }

  void _showEditReceiptTotalDialog() {
    final ctrl = TextEditingController(text: _scannedReceiptTotal?.toStringAsFixed(2) ?? _totalRoundedBill.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Fiş Tutarını Düzenle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fişteki Genel Toplam tutarını kontrol edin ve gerekirse düzeltin:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Fiş Toplamı (TL)',
                prefixText: '₺ ',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final parsed = double.tryParse(ctrl.text.replaceAll(',', '.').trim());
              if (parsed != null && parsed > 0) {
                setState(() => _scannedReceiptTotal = parsed);
                _recalculatePaymentPlan(parsed.ceil());
                Navigator.pop(ctx);
                if (_isMoneyInsufficient) {
                  _speak(
                    'Fiş tutarı güncellendi ancak paramız yetmiyor! Fiş ${parsed.ceil()} Lira, cüzdanda $_totalWalletBalance Lira var. $_missingMoneyAmount Lira eksik!',
                  );
                } else {
                  _speak('Fiş tutarı ${parsed.toStringAsFixed(2)} lira olarak güncellendi.');
                }
              }
            },
            child: const Text('Kaydet & Onayla'),
          ),
        ],
      ),
    );
  }

  // ─── ÖDEME VE PARA ÜSTÜ ALMA AKIŞI ───
  void _onProceedToPayment() {
    if (_isMoneyInsufficient) {
      _speak(
        'Paramız yetmiyor! Fişi ödemek için $_missingMoneyAmount Lira daha gerekiyor. Cüzdanda yeterli para yok!',
      );
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paramız Yetmiyor! ❌',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu fişi ödemek için cüzdanındaki para yeterli değil. Lütfen cüzdanına para ekle veya sepetini kontrol et.',
                style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cüzdandaki Para:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        Text('₺$_totalWalletBalance', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ödenecek Tutar:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        Text('₺$_effectiveBillAmount', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Eksik Tutar:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        Text(
                          '₺$_missingMoneyAmount Yok ❌',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anladım, Paramız Yetmiyor'),
            ),
          ],
        ),
      );
      return;
    }

    if (_changeDue > 0) {
      _showChangeDueReceivedDialog();
    } else {
      _finalizePayment(receivedNotes: {});
    }
  }

  void _showChangeDueReceivedDialog() {
    // Para üstü banknotlarını varsayılan en uygun dağılımla hesapla
    final Map<int, int> tempReceived = {
      200: 0,
      100: 0,
      50: 0,
      20: 0,
      10: 0,
      5: 0,
      1: 0,
    };

    int remainingChange = _changeDue;
    for (int val in [200, 100, 50, 20, 10, 5, 1]) {
      if (remainingChange >= val) {
        int count = remainingChange ~/ val;
        tempReceived[val] = count;
        remainingChange -= count * val;
      }
    }

    _speak('Kasiyerden $_changeDue lira para üstü almalısın. Aldığın paraları cüzdanına eklemek için işaretle.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          int currentSum = 0;
          tempReceived.forEach((v, c) => currentSum += v * c);

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.payments_rounded, color: Color(0xFF16A34A), size: 26),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Para Üstü Aldın mı? 💵',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Beklenen Para Üstü:', style: TextStyle(fontSize: 12, color: Color(0xFF166534))),
                          Text('₺$_changeDue', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF16A34A)),
                        ),
                        child: Text(
                          'Seçilen: ₺$currentSum',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kasiyerin verdiği yeni kâğıt ve madeni paraları işaretle:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _denominations.length,
                    itemBuilder: (context, index) {
                      final item = _denominations[index];
                      final val = item['val'] as int;
                      final name = item['name'] as String;
                      final isCoin = item['isCoin'] as bool;
                      final imagePath = item['image'] as String;
                      final count = tempReceived[val] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(isCoin ? 20 : 6),
                              child: Image.asset(imagePath, width: isCoin ? 38 : 60, height: 38, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 24),
                              onPressed: count > 0 ? () => setModalState(() => tempReceived[val] = count - 1) : null,
                            ),
                            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF16A34A), size: 24),
                              onPressed: () => setModalState(() => tempReceived[val] = count + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Cüzdanıma Ekle & Tamamla ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _finalizePayment(receivedNotes: tempReceived);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _finalizePayment({required Map<int, int> receivedNotes}) async {
    // Verilen paraları cüzdandan düş
    _suggestedPaymentNotes.forEach((val, count) {
      _walletCounts[val] = ((_walletCounts[val] ?? 0) - count).clamp(0, 99);
    });

    // Alınan yeni paraları cüzdana ekle
    if (receivedNotes.isNotEmpty) {
      receivedNotes.forEach((val, count) {
        _walletCounts[val] = ((_walletCounts[val] ?? 0) + count).clamp(0, 99);
      });
    } else if (_changeDue > 0) {
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
      _scannedReceiptImage = null;
      _scannedReceiptTotal = null;
      _isScanningReceipt = false;
    });

    _inactivityHelp.stop();

    _speak('Ödeme tamamlandı! Para üstü cüzdana eklendi. Güncel cüzdan bakiyeniz $_totalWalletBalance Lira. Fişini eve götürmeyi sakın unutma.');

    // Fiş Uyarısı ve Son Toplam Bakiye Diyaloğu
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Son Cüzdan Bakiyesi:', style: TextStyle(fontSize: 13, color: Color(0xFF166534), fontWeight: FontWeight.w600)),
                    ),
                    Text('₺$_totalWalletBalance', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF16A34A))),
                  ],
                ),
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
      resizeToAvoidBottomInset: false,
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
      bottomNavigationBar: _isShoppingMode && !_showPaymentGuidance && _cartItems.isNotEmpty
          ? _buildShoppingBottomBar()
          : null,
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
              if (_currentWeekLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '📅 $_currentWeekLabel',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: const Text('Alışverişi Başlat 🛒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: _startShopping,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: const Text('Fiyat Tara 📸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      _startShopping();
                      _showPriceTagScanDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Sabah Cüzdan Yönergesi Bildirim Bandı
        if (_showMorningBanner)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Cüzdanında ne kadar paran var hadi bakalım, paralarını say ve cüzdanını güncelle.',
                    style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => setState(() => _showMorningBanner = false),
                  child: const Text('Anladım', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Fiyat Tara 📸', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _showPriceTagScanDialog,
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Elle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _showAddProductModal,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sepetteki Ürünler Listesi veya Ödeme Rehberi
          if (_showPaymentGuidance)
            _buildPaymentResultCard()
          else if (_cartItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text('Fiyat Tara 📸', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _showPriceTagScanDialog,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('İlk Ürünü Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _showAddProductModal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Görüntü İşleme ile Fiyat Oku 📸',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Market rafındaki fiyat etiketini kameraya göster. Sistem virgülün solunu okur, +1 TL yuvarlar ve sepete otomatik ekler!',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E40AF),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.document_scanner_rounded, size: 18),
                            label: const Text('Kamerayı Aç ve Etiketi Tara 📷', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _showPriceTagScanDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
            ),
        ],
      ),
    );
  }

  /// Alışveriş Modu Alt Çubuğu (Scaffold bottomNavigationBar)
  Widget _buildShoppingBottomBar() {
    return Container(
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('+ Kamera ile Yeni Ürün Tara 📸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: _showPriceTagScanDialog,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
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
          ],
        ),
      ),
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
              border: Border.all(
                color: _isMoneyInsufficient
                    ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                    : const Color(0xFF16A34A).withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                if (_isMoneyInsufficient) ...[
                  // 🛑 PARAMIZ YETMİYOR UYARI BANNERI
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PARAMIZ YETMİYOR! ❌',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFB91C1C)),
                                  ),
                                  Text(
                                    'Cüzdandaki nakit para bu fişe yetmiyor!',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cüzdanda: ₺$_totalWalletBalance', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            Text('Fiş: ₺$_effectiveBillAmount', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                            Text('Eksik: ₺$_missingMoneyAmount TL', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                Text(
                  _scannedReceiptTotal != null ? 'FİŞE GÖRE ÖDENECEK TUTAR' : 'HESAPLANAN TOPLAM TUTAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isMoneyInsufficient ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₺ $_effectiveBillAmount',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: _isMoneyInsufficient ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isMoneyInsufficient ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMoneyInsufficient ? Icons.cancel_rounded : Icons.check_circle_rounded,
                        color: _isMoneyInsufficient ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isMoneyInsufficient
                              ? 'Paramız yetmiyor! Fişi ödemek için ₺$_missingMoneyAmount TL eksik.'
                              : 'Cüzdanındaki bu paraları vermelisin:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isMoneyInsufficient ? const Color(0xFFB91C1C) : const Color(0xFF166534),
                          ),
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
                    const Expanded(
                      child: Text('Kasiyere Verilen Tutar:', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ),
                    Text('₺ $_totalGivenMoney', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Alınacak Para Üstü:', style: TextStyle(fontSize: 14, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                    ),
                    Text('₺ $_changeDue', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                  ],
                ),
              ],
            ),
          ),
          // ─── KASADA FİŞİ TARA / OKUT (GÖRSEL İŞLEME - OCR) ───
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kasada Fişi Tara (Görsel İşleme) 📸',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                          ),
                          Text(
                            'Kasiyerin verdiği fişi kameraya okut',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isScanningReceipt)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Fiş okunuyor ve tutar taranıyor...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  )
                else if (_scannedReceiptTotal != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        if (!kIsWeb && _scannedReceiptImage != null && File(_scannedReceiptImage!).existsSync())
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_scannedReceiptImage!),
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 28),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fiş Başarıyla Okundu ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A))),
                              Text(
                                'Okunan Fiş Tutarı: ₺${_scannedReceiptTotal!.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF16A34A)),
                              tooltip: 'Tutarı Düzenle',
                              onPressed: _showEditReceiptTotalDialog,
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
                              tooltip: 'Yeniden Tara',
                              onPressed: _showReceiptScanDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Fişi Okut (Kamera / Galeri)'),
                      onPressed: _showReceiptScanDialog,
                    ),
                  ),
              ],
            ),
          ),

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
          const SizedBox(height: 18),

          // Ödemeyi Onayla & Cüzdanı Güncelle Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMoneyInsufficient ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(_isMoneyInsufficient ? Icons.warning_rounded : Icons.check_circle_rounded, size: 24),
              label: Text(
                _isMoneyInsufficient
                    ? 'Paramız Yetmiyor (₺$_missingMoneyAmount Eksik) ❌'
                    : 'Ödemeyi Yaptım & Cüzdanı Güncelle ✅',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: _onProceedToPayment,
            ),
          ),
        ],
      ),
    );
  }
}
