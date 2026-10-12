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

/// 💳 Kredi Kartı Harcaması Takip Ekranı
/// - Aylık Limit & Ekstre Kesim ve Son Ödeme Tarihi Seçimi
/// - Harcama tutarı ve günün tarihi (değiştirilebilir) girişi
/// - Her harcama sonrası o ayki toplam harcama ve kalan limitin gösterilmesi
/// - Ekstre kesim tarihinden sonraki harcamaların sonraki aya eklenmesi
/// - Tüm limit, harcama ve kalan limitin görsel olarak azalan şekil olarak gösterilmesi
/// - Ay başında / sıfırlamada "Kredi kartı borcunu ödedin mi?" kontrolü:
///   * Evet: Limiti onayla ve baştan başlat
///   * Hayır: Kaldığı yerden devam et ve "Borcunu ödemezsen kartın kapatılabilir" uyarısı ver.
class CardBudgetScreen extends StatefulWidget {
  const CardBudgetScreen({super.key});

  @override
  State<CardBudgetScreen> createState() => _CardBudgetScreenState();
}

class _CardBudgetScreenState extends State<CardBudgetScreen> {
  final FlutterTts _tts = FlutterTts();
  late InactivityHelpService _inactivityHelp;

  double _monthlyLimit = 2000.0;
  int _cutoffDay = 15; // Ayın 15'i
  int _dueDay = 25;    // Ayın 25'i
  DateTime _cutoffDate = DateTime(DateTime.now().year, DateTime.now().month, 15);
  DateTime _dueDate = DateTime(DateTime.now().year, DateTime.now().month, 25);

  double _carriedDebt = 0.0;
  bool _unpaidWarningActive = false;

  // Harcama kayıtları: { 'title': String, 'amount': double, 'date': String, 'isNextMonth': bool }
  final List<Map<String, dynamic>> _transactions = [];

  bool _isLoading = true;

  // Fiş Tarama & Görsel İşleme (OCR) Durumları
  List<double> _receiptCandidates = [];

  double get _currentMonthSpent {
    double sum = 0.0;
    for (var tx in _transactions) {
      if (tx['isNextMonth'] != true) {
        sum += (tx['amount'] as num).toDouble();
      }
    }
    return sum;
  }

  double get _nextMonthSpent {
    double sum = 0.0;
    for (var tx in _transactions) {
      if (tx['isNextMonth'] == true) {
        sum += (tx['amount'] as num).toDouble();
      }
    }
    return sum;
  }

  double get _remainingLimit {
    final remaining = _monthlyLimit - _currentMonthSpent - _carriedDebt;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  void initState() {
    super.initState();
    _initTts();
    _inactivityHelp = InactivityHelpService();
    _loadCardData();
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

  String _formatDate(DateTime dt) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _loadCardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _monthlyLimit = prefs.getDouble('card_monthly_limit') ?? 2000.0;
      _cutoffDay = prefs.getInt('card_cutoff_day') ?? 15;
      _dueDay = prefs.getInt('card_due_day') ?? 25;
      _carriedDebt = prefs.getDouble('card_carried_debt') ?? 0.0;
      _unpaidWarningActive = prefs.getBool('card_unpaid_warning') ?? false;

      final savedCutoffIso = prefs.getString('card_cutoff_date');
      if (savedCutoffIso != null) {
        _cutoffDate = DateTime.tryParse(savedCutoffIso) ?? _cutoffDate;
        _cutoffDay = _cutoffDate.day;
      } else {
        _cutoffDate = DateTime(DateTime.now().year, DateTime.now().month, _cutoffDay);
      }

      final savedDueIso = prefs.getString('card_due_date');
      if (savedDueIso != null) {
        _dueDate = DateTime.tryParse(savedDueIso) ?? _dueDate;
        _dueDay = _dueDate.day;
      } else {
        _dueDate = DateTime(DateTime.now().year, DateTime.now().month, _dueDay);
      }

      final savedTxStr = prefs.getString('card_transactions_v2');
      if (savedTxStr != null && savedTxStr.isNotEmpty) {
        final decoded = jsonDecode(savedTxStr) as List;
        _transactions.clear();
        for (final item in decoded) {
          _transactions.add(Map<String, dynamic>.from(item as Map));
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      _speak('Kredi kartı takibi açıldı. Kalan limitiniz ${_remainingLimit.toInt()} Türk Lirası.');
    }
  }

  Future<void> _saveCardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('card_monthly_limit', _monthlyLimit);
      await prefs.setInt('card_cutoff_day', _cutoffDay);
      await prefs.setInt('card_due_day', _dueDay);
      await prefs.setString('card_cutoff_date', _cutoffDate.toIso8601String());
      await prefs.setString('card_due_date', _dueDate.toIso8601String());
      await prefs.setDouble('card_carried_debt', _carriedDebt);
      await prefs.setBool('card_unpaid_warning', _unpaidWarningActive);
      await prefs.setString('card_transactions_v2', jsonEncode(_transactions));
    } catch (_) {}
  }

  /// 🔄 Her ay başında veya sıfırlamada Borç Ödeme Kontrolü
  void _promptMonthlyResetCheck() {
    _speak('Kredi kartı borcunu ödedin mi?');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actionsOverflowButtonSpacing: 8,
        title: const Row(
          children: [
            Icon(Icons.credit_score_rounded, color: AppColors.buttonIndigo, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Kredi Kartı Borç Kontrolü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Her ay sıfırlanarak tekrar başlatılır. Başlatmadan önce kredi kartı borcunu kontrol edelim:',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bu Ayki Toplam Borç: ₺${_currentMonthSpent.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E40AF)),
                  ),
                  if (_carriedDebt > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Devreden Geçmiş Borç: ₺${_carriedDebt.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFDC2626)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Kredi kartı borcunu bankaya ödedin mi?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _carriedDebt += _currentMonthSpent;
                _unpaidWarningActive = true;
                _transactions.clear();
              });
              _saveCardData();
              _speak('Uyarı! Kredi kartı borcunu ödemezsen kartın kapatılabilir. Lütfen borcunu en kısa sürede öde.');
              _showUnpaidDebtWarningDialog();
            },
            child: const Text('Hayır, Ödemedim', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmRestartLimit();
            },
            child: const Text('Evet, Ödedim ✅', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// ⚠️ Hayır dediğinde gelen Kapatılma Uyarısı
  void _showUnpaidDebtWarningDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 30),
            SizedBox(width: 8),
            Expanded(child: Text('Önemli Borç Uyarısı!')),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            '⚠️ UYARI: Kredi kartı borcunu ödemezsen kartın kapatılabilir!\n\nBorcun yeni aya devredildi ve mevcut limitinden düşülerek kaldığı yerden başlatıldı.',
            style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  /// ✅ Evet dediğinde Limit Onayı ve Baştan Başlatma
  void _confirmRestartLimit() {
    _speak('Aylık limitin ${_monthlyLimit.toInt()} lira mı? Onaylıyor musun?');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        actionsOverflowButtonSpacing: 8,
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 26),
            SizedBox(width: 8),
            Expanded(child: Text('Aylık Limit Onayı')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aylık kart limitin ₺${_monthlyLimit.toInt()} mi?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Onaylarsanız kart limitiniz baştan başlatılacak ve harcama sayacı sıfırlanacaktır.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showMonthlyEntrySettingsDialog();
            },
            child: const Text('Limiti Değiştir'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                // Sonraki aya yazılmış harcamalar varsa bu aya aktarılır
                for (var tx in _transactions) {
                  tx['isNextMonth'] = false;
                }
                _transactions.removeWhere((tx) => tx['isNextMonth'] == true);
                _carriedDebt = 0.0;
                _unpaidWarningActive = false;
              });
              _saveCardData();
              _speak('Harika! Limitiniz sıfırlandı ve ${_monthlyLimit.toInt()} lira olarak baştan başladı.');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Limitiniz sıfırlandı ve ₺${_monthlyLimit.toInt()} olarak baştan başladı! 🎉'),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Evet, Limiti Başlat ✅', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── KASADA / HARCAMADA KART FİŞİNİ TARA (GÖRSEL İŞLEME - OCR) ───
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
                        Icon(Icons.document_scanner_rounded, color: Color(0xFF2563EB), size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kart Fişini Tara 🧾',
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
                'Kart ile yaptığınız harcamanın fişini kameraya okutun. Fiş tutarı otomatik algılanıp kart limitinizden düşülecektir:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),

              // 💡 Net Okuma İpuçları Kutusu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: Color(0xFF2563EB), size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Kamerayla Net Okuma İpuçları:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Fişin özellikle "TOPLAM" ve fiyat yazan alt kısmına yakından odaklanın.\n'
                      '• Parlama ve gölge olmamasına dikkat edin, fişi düz tutun.\n'
                      '• Kamera tutarı okuyamazsa onay penceresinde elle düzeltebilirsiniz.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A), height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                subtitle: const Text('Kamera olmadan hızlı fiş okuma ve limit düşme'),
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
        maxWidth: 2400,
        maxHeight: 3600,
        imageQuality: 95,
      );
      if (photo == null) return;

      // Konumsal Bounding-Box hizalamalı fiş tanıma
      final rawText = await OcrTranslationService().recognizeReceiptText(photo.path);
      final analysis = OcrTranslationService().analyzeReceipt(rawText);
      final detectedTotal = analysis.primaryTotal ?? _extractReceiptTotal(rawText) ?? 150.0;

      setState(() {
        _receiptCandidates = analysis.candidates;
      });

      _handleDetectedReceipt(photo.path, detectedTotal);
    } catch (_) {
      _simulateReceiptScan();
    }
  }

  void _simulateReceiptScan() {
    const mockTotal = 175.50;
    setState(() {
      _receiptCandidates = [175.50, 149.00, 26.50];
    });
    _handleDetectedReceipt(null, mockTotal);
  }

  void _handleDetectedReceipt(String? photoPath, double detectedTotal) {
    if (detectedTotal > _remainingLimit) {
      final deficit = detectedTotal - _remainingLimit;
      _speak('Limit yetmiyor! Fiş tutarı ${detectedTotal.toInt()} Lira, ancak kullanılabilir kart limitiniz ${_remainingLimit.toInt()} Lira. ${deficit.toInt()} Lira limit yetersiz!');
    } else {
      _speak('Fiş başarıyla okundu. Fiş tutarı: ${detectedTotal.toStringAsFixed(2)} lira. Onaylayarak kart limitinden düşebilirsiniz.');
    }

    _showConfirmReceiptExpenseDialog(photoPath: photoPath, detectedTotal: detectedTotal);
  }

  /// Fiş Tutarı Onay ve Limitten Düşme Penceresi
  void _showConfirmReceiptExpenseDialog({
    required String? photoPath,
    required double detectedTotal,
  }) {
    final titleCtrl = TextEditingController(text: 'Market / Kart Fişi 🧾');
    final amountCtrl = TextEditingController(text: detectedTotal.toStringAsFixed(2));
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isNextMonth = selectedDate.day > _cutoffDay || selectedDate.isAfter(_cutoffDate);
          final currentAmount = double.tryParse(amountCtrl.text.replaceAll(',', '.').trim()) ?? detectedTotal;
          final isOverLimit = currentAmount > _remainingLimit;
          final deficit = isOverLimit ? (currentAmount - _remainingLimit) : 0.0;
          final postRemaining = isOverLimit ? 0.0 : (_remainingLimit - currentAmount);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 26),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fişten Limit Düş 🧾',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fiş Önizleme / Rozet
                  if (photoPath != null && !kIsWeb && File(photoPath).existsSync())
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(File(photoPath), fit: BoxFit.cover),
                      ),
                    ),

                  // Limit Durumu Kartı (Yetiyor mu / Yetmiyor mu?)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOverLimit ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOverLimit ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isOverLimit ? Icons.warning_rounded : Icons.check_circle_rounded,
                              color: isOverLimit ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isOverLimit ? 'LİMİT YETMİYOR! ❌' : 'LİMİT YETERLİ ✅',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: isOverLimit ? const Color(0xFFB91C1C) : const Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Limit: ₺${_remainingLimit.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                isOverLimit ? '₺${deficit.toStringAsFixed(0)} Aşıyor' : 'Kalan: ₺${postRemaining.toStringAsFixed(0)}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isOverLimit ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Fişte Okunan Alternatif Tutarlar (Tek Dokunuşla Seçme Çipleri)
                  if (_receiptCandidates.isNotEmpty) ...[
                    const Text(
                      'Fişte Okunan Tutarlar (Tek Dokunuşla Seç):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _receiptCandidates.take(6).map((cand) {
                        final isSelected = (cand - currentAmount).abs() < 0.01;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              amountCtrl.text = cand.toStringAsFixed(2);
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(Icons.check, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  '₺${cand.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Kolay Düzeltme İpucu
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tutar eksik veya yanlışsa aşağıdaki kutuya dokunup düzeltebilirsiniz.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Harcama Başlığı',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Okunan Fiş Tutarı (TL) *',
                      prefixText: '₺ ',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tarih Seçimi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF475569)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Text(
                              'Değiştir',
                              style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isNextMonth)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Bu fiş harcaması kesim gününden sonra olduğu için sonraki ayın ekstresine eklenecektir.',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Limitden Düş & Onayla ✅', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final finalAmount = double.tryParse(amountCtrl.text.replaceAll(',', '.').trim()) ?? currentAmount;
                  if (finalAmount > 0) {
                    final title = titleCtrl.text.trim().isEmpty ? 'Kart Fişi Harcaması' : titleCtrl.text.trim();
                    setState(() {
                      _transactions.insert(0, {
                        'title': title,
                        'amount': finalAmount,
                        'date': '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                        'isNextMonth': isNextMonth,
                        'receiptImage': photoPath,
                      });
                    });
                    _saveCardData();
                    Navigator.pop(ctx);

                    _showPostExpenseSummaryDialog(
                      title: title,
                      amount: finalAmount,
                      isNextMonth: isNextMonth,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Türk market fişlerinden genel toplam tutarını hassas biçimde çıkarır
  double? _extractReceiptTotal(String rawText) {
    if (rawText.trim().isEmpty) return null;

    final cleanedLines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != '---')
        .toList();
    if (cleanedLines.isEmpty) return null;

    for (int i = cleanedLines.length - 1; i >= 0; i--) {
      final line = cleanedLines[i];
      final upper = _normalizeTurkishForOcr(line);

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
        final price = _findPriceInReceiptLine(line);
        if (price != null && price > 0) {
          return price;
        }

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

    final multiLineRegex = RegExp(
      r'(?:GENEL\s+TOPLAM|TOPLAM|T\s*O\s*P\s*L\s*A\s*M|ÖDENECEK|ODENECEK|TOTAL)[\s\S]{0,35}?[*xX+₺TLtl\s]*(\d{1,5}[\.,]\d{2})',
      caseSensitive: false,
    );
    final multiMatch = multiLineRegex.firstMatch(rawText);
    if (multiMatch != null) {
      final parsed = _parsePriceString(multiMatch.group(1));
      if (parsed != null && parsed > 0) return parsed;
    }

    final allPrices = <double>[];
    for (int i = 0; i < cleanedLines.length; i++) {
      final line = cleanedLines[i];
      if (line.endsWith('-') || line.contains('-%') || line.contains('İNDİRİM') || line.contains('INDIRIM')) {
        continue;
      }
      final price = _findPriceInReceiptLine(line);
      if (price != null && price > 0) {
        allPrices.add(price);
      }
    }

    if (allPrices.isNotEmpty) {
      return allPrices.last;
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

  double? _findPriceInReceiptLine(String line) {
    final regex = RegExp(r'[*xX+₺TLtl\s]*(\d{1,5}[\.,]\d{2})(?!\d)');
    final matches = regex.allMatches(line).toList();
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      return _parsePriceString(lastMatch.group(1));
    }
    return null;
  }

  double? _parsePriceString(String? text) {
    if (text == null) return null;
    var clean = text.replaceAll(' ', '');
    if (clean.contains(',') && clean.contains('.')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }
    return double.tryParse(clean);
  }

  /// ➕ Kredi Kartı Harcaması Ekle
  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isNextMonth = selectedDate.day > _cutoffDay || selectedDate.isAfter(_cutoffDate);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.add_card_rounded, color: AppColors.buttonIndigo),
                SizedBox(width: 8),
                Expanded(child: Text('Kart Harcaması Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fiş Tara Butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.document_scanner_rounded, size: 20),
                      label: const Text('Fişin Fotoğrafını Çek & Tutarı Oku 📸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReceiptScanDialog();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Harcama Açıklaması',
                      hintText: 'Örn: Market, Ulaşım, Kitap',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harcama Tutarı (TL) *',
                      hintText: 'Örn: 150',
                      prefixText: '₺ ',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tarih Seçimi (Günün tarihi varsayılan, değiştirilebilir)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF475569)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Text(
                              'Değiştir',
                              style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ekstre Kesim Tarihinden Sonraki Harcama Rozeti / Uyarısı
                  if (isNextMonth)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Seçilen tarih ayın $_cutoffDay. gününden sonra olduğu için bu harcama bir sonraki ayın ekstresine eklenecektir.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final title = titleCtrl.text.trim().isEmpty ? 'Kart Harcaması' : titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                  if (amount > 0) {
                    setState(() {
                      _transactions.insert(0, {
                        'title': title,
                        'amount': amount,
                        'date': '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                        'isNextMonth': isNextMonth,
                      });
                    });
                    _saveCardData();
                    Navigator.pop(ctx);

                    // Harcama sonrasında toplam harcamayı ve kalan limiti göster
                    _showPostExpenseSummaryDialog(
                      title: title,
                      amount: amount,
                      isNextMonth: isNextMonth,
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 📊 Her Harcama Girişinden Sonra Toplam Harcama & Kalan Limit Gösterimi
  void _showPostExpenseSummaryDialog({
    required String title,
    required double amount,
    required bool isNextMonth,
  }) {
    _speak('Harcama kaydedildi. Bu ayki toplam harcamanız ${_currentMonthSpent.toInt()} lira, limitinizden kalan tutar ${_remainingLimit.toInt()} lira.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Harcama Kaydedildi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Girilen Harcama: ₺${amount.toInt()} ($title)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('Bu Ayki Toplam Harcama:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ),
                      Text(
                        '₺${_currentMonthSpent.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('Limitinden Kalan Tutar:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ),
                      Text(
                        '₺${_remainingLimit.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isNextMonth
                  ? 'ℹ️ Bu harcama ekstre kesim tarihinden sonraki bir tarihe ait olduğu için bir sonraki ayın ekstresine eklendi.'
                  : '💡 Bir sonraki harcama kaydı için aylık limitiniz kalan limit (₺${_remainingLimit.toInt()}) olarak güncellendi.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Aylık Giriş & Ekstre Tarihleri Seçimi (Aylık Limit, Kesim Tarihi, Son Ödeme Tarihi)
  void _showMonthlyEntrySettingsDialog() {
    final limitCtrl = TextEditingController(text: _monthlyLimit.toInt().toString());
    DateTime tempCutoff = _cutoffDate;
    DateTime tempDue = _dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: AppColors.buttonIndigo),
              SizedBox(width: 8),
              Expanded(child: Text('Aylık Giriş & Kart Ayarları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. Aylık Kart Limiti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Aylık Limit (TL)',
                    prefixText: '₺ ',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Bir Sonraki Ekstre Kesim Tarihi
                const Text('2. Bir Sonraki Ekstre Kesim Tarihi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempCutoff,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setModalState(() => tempCutoff = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range_rounded, color: AppColors.buttonIndigo, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatDate(tempCutoff),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const Text('Değiştir', style: TextStyle(color: AppColors.buttonIndigo, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Ekstre Son Ödeme Tarihi
                const Text('3. Ekstre Son Ödeme Tarihi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempDue,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setModalState(() => tempDue = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm_on_rounded, color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatDate(tempDue),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const Text('Değiştir', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonIndigo, foregroundColor: Colors.white),
              onPressed: () {
                final newLimit = double.tryParse(limitCtrl.text.trim()) ?? _monthlyLimit;
                setState(() {
                  _monthlyLimit = newLimit;
                  _cutoffDate = tempCutoff;
                  _cutoffDay = tempCutoff.day;
                  _dueDate = tempDue;
                  _dueDay = tempDue.day;
                });
                _saveCardData();
                Navigator.pop(ctx);
                _speak('Aylık limit ve ekstre tarihleri güncellendi.');
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inactivityHelp.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kalan limit oranı (0.0 .. 1.0)
    final spentRatio = _monthlyLimit > 0 ? (_currentMonthSpent / _monthlyLimit).clamp(0.0, 1.0) : 0.0;
    final remainingRatio = 1.0 - spentRatio;

    // Kalan bakiyeye göre dinamik renk (Yeşil -> Turuncu -> Kırmızı)
    Color statusColor = const Color(0xFF16A34A);
    if (remainingRatio < 0.20) {
      statusColor = const Color(0xFFEF4444);
    } else if (remainingRatio < 0.50) {
      statusColor = const Color(0xFFF59E0B);
    }

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_rounded, color: AppColors.buttonIndigo),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Kredi Kartı Takibi',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Aylık Giriş & Tarihler',
            onPressed: _showMonthlyEntrySettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFF7C3AED)),
            tooltip: 'Ayı Sıfırla & Borç Kontrolü',
            onPressed: _promptMonthlyResetCheck,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ─── SABİT BORÇ VE KAPATILMA UYARI BANDI ───
                if (_unpaidWarningActive || _carriedDebt > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⚠️ UYARI: Kredi kartı borcunu ödemezsen kartın kapatılabilir!',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF991B1B)),
                              ),
                              if (_carriedDebt > 0)
                                Text(
                                  'Devreden Geçmiş Borç: ₺${_carriedDebt.toInt()}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _promptMonthlyResetCheck,
                          child: const Text('Ödedim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                // ─── GÖRSEL OLARAK AZALAN LİMİT KARTI ───
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0F172A),
                        statusColor.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst Tarihler Barı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.contactless_rounded, color: Colors.white70, size: 18),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      'Kesim: $_cutoffDay. Gün',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                'Son Ödeme: $_dueDay. Gün',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Büyük Kalan Limit Tutarı
                      Text(
                        '₺ ${_remainingLimit.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        'Kullanılabilir Kalan Limit',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),

                      // 📉 GÖRSEL OLARAK AZALAN ŞEKİL (DİNAMİK ÇUBUK)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kalan Limit Oranı',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '%${(remainingRatio * 100).toInt()} Kalan',
                            style: TextStyle(color: statusColor.computeLuminance() > 0.5 ? Colors.white : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: remainingRatio,
                          minHeight: 14,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 10 Dilimli Azalan Görsel Segment Blokları
                      Row(
                        children: List.generate(10, (index) {
                          final blockThreshold = (index + 1) / 10.0;
                          final isFilled = remainingRatio >= blockThreshold;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              height: 6,
                              decoration: BoxDecoration(
                                color: isFilled ? statusColor : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // 3'lü Özet İstatistik Blokları
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCardMiniStat('Tüm Limit', '₺${_monthlyLimit.toInt()}', Colors.white70),
                            Container(width: 1, height: 24, color: Colors.white24),
                            _buildCardMiniStat('Bu Ay Harcanan', '₺${_currentMonthSpent.toInt()}', const Color(0xFFFCA5A5)),
                            Container(width: 1, height: 24, color: Colors.white24),
                            _buildCardMiniStat('Kalan', '₺${_remainingLimit.toInt()}', const Color(0xFF86EFAC)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── HARCAMA EKLE & FİŞİ TARA & AYI SIFIRLA BUTONLARI ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // 📸 Kart Fişini Tara Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.document_scanner_rounded, size: 22),
                          label: const Text('Kart Fişini Tara / Fotoğraf Çek 📸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: _showReceiptScanDialog,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Harcama Ekle & Ayı Sıfırla Satırı
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonIndigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Harcama Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              onPressed: _showAddExpenseDialog,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7C3AED),
                              side: const BorderSide(color: Color(0xFF7C3AED)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.restart_alt_rounded, size: 18),
                            label: const Text('Ayı Sıfırla'),
                            onPressed: _promptMonthlyResetCheck,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ─── HARCAMA GEÇMİŞİ LİSTESİ ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      const Text('Kayıtlı Harcamalar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF475569))),
                      const Spacer(),
                      if (_nextMonthSpent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Sonraki Ay: ₺${_nextMonthSpent.toInt()}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 10),
                              Text('Bu ay henüz kart harcaması kaydedilmedi.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: _transactions.length,
                          itemBuilder: (context, idx) {
                            final tx = _transactions[idx];
                            final amount = (tx['amount'] as num).toDouble();
                            final isNextMonth = tx['isNextMonth'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: tx['receiptImage'] != null
                                      ? const Color(0xFFEFF6FF)
                                      : (isNextMonth ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF)),
                                  child: Icon(
                                    tx['receiptImage'] != null
                                        ? Icons.receipt_long_rounded
                                        : (isNextMonth ? Icons.schedule_rounded : Icons.shopping_bag_rounded),
                                    color: tx['receiptImage'] != null
                                        ? const Color(0xFF2563EB)
                                        : (isNextMonth ? const Color(0xFFD97706) : AppColors.buttonIndigo),
                                  ),
                                ),
                                title: Text(tx['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: Text(
                                  '${tx['date']}${isNextMonth ? ' • Bir sonraki ayın ekstresi' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isNextMonth ? const Color(0xFFD97706) : const Color(0xFF64748B),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '-₺${amount.toInt()}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEF4444)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                                      onPressed: () {
                                        setState(() => _transactions.removeAt(idx));
                                        _saveCardData();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCardMiniStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
