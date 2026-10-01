import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/inactivity_help_service.dart';
import '../../theme/app_theme.dart';

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
  double _carriedDebt = 0.0;

  // Harcama kayıtları: { 'title': String, 'amount': double, 'date': String, 'isNextMonth': bool }
  final List<Map<String, dynamic>> _transactions = [];

  bool _isLoading = true;

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

  Future<void> _loadCardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _monthlyLimit = prefs.getDouble('card_monthly_limit') ?? 2000.0;
      _cutoffDay = prefs.getInt('card_cutoff_day') ?? 15;
      _dueDay = prefs.getInt('card_due_day') ?? 25;
      _carriedDebt = prefs.getDouble('card_carried_debt') ?? 0.0;

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
      await prefs.setDouble('card_carried_debt', _carriedDebt);
      await prefs.setString('card_transactions_v2', jsonEncode(_transactions));
    } catch (_) {}
  }

  /// Her ay başında veya sıfırlamada Borç Ödeme Kontrolü
  void _promptMonthlyResetCheck() {
    _speak('Kredi kartı borcunu ödedin mi?');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              'Yeni aya başlamadan önce geçmiş ekstre borcunu kontrol edelim:',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Bu Ayki Toplam Borç: ${_currentMonthSpent.toInt()} TL',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E40AF)),
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
          // Hayır derse
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _carriedDebt += _currentMonthSpent;
                _transactions.clear();
              });
              _saveCardData();
              _speak('Uyarı! Kredi kartı borcunu ödemezsen kartın kapatılabilir. Lütfen borcunu en kısa sürede öde.');
              _showUnpaidDebtWarningDialog();
            },
            child: const Text('Hayır, Ödemedim', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),

          // Evet derse
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmRestartLimit();
            },
            child: const Text('Evet, Ödedim ✅'),
          ),
        ],
      ),
    );
  }

  void _showUnpaidDebtWarningDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 30),
            SizedBox(width: 8),
            Text('Önemli Borç Uyarısı!'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            '⚠️ DİKKAT: Kredi kartı borcunu ödemezsen kartın banka tarafından kullanıma kapatılabilir!\n\nBorcun yeni aya devredildi ve mevcut limitinden düşüldü.',
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

  void _confirmRestartLimit() {
    _speak('Aylık limitin ${_monthlyLimit.toInt()} lira mı? Onaylıyor musun?');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Limit Onayı'),
        content: Text('Aylık kart limitin ${_monthlyLimit.toInt()} TL olarak baştan başlatılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _transactions.clear();
                _carriedDebt = 0.0;
              });
              _saveCardData();
              _speak('Harika! Limitiniz sıfırlandı ve ${_monthlyLimit.toInt()} lira olarak baştan başladı.');
            },
            child: const Text('Evet, Başlat'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.add_card_rounded, color: AppColors.buttonIndigo),
              SizedBox(width: 8),
              Text('Kart Harcaması Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    labelText: 'Harcama Tutarı (TL)',
                    hintText: 'Örn: 150',
                    prefixText: '₺ ',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),

                // Tarih Seçimi (Günün tarihi varsayılan, değiştirilebilir)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      'Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Değiştir'),
                    ),
                  ],
                ),

                // Ekstre Kesim Tarihi Kontrolü Bilgisi
                if (selectedDate.day > _cutoffDay)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seçilen tarih ayın ${_cutoffDay}. gününden sonra olduğu için bir sonraki ayın ekstresine eklenecektir.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
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
                final isNextMonth = selectedDate.day > _cutoffDay;

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
                  _speak('$title için ${amount.toInt()} lira harcama kaydedildi. Kalan limitiniz ${_remainingLimit.toInt()} lira.');
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    final limitCtrl = TextEditingController(text: _monthlyLimit.toInt().toString());
    int tempCutoff = _cutoffDay;
    int tempDue = _dueDay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.settings_rounded, color: AppColors.buttonIndigo),
              SizedBox(width: 8),
              Text('Kart & Ekstre Ayarları'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Aylık Toplam Limit (TL)',
                    prefixText: '₺ ',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Ekstre Kesim Günü: Ayın $tempCutoff. günü', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Slider(
                  value: tempCutoff.toDouble(),
                  min: 1,
                  max: 28,
                  divisions: 27,
                  activeColor: AppColors.buttonIndigo,
                  label: '$tempCutoff',
                  onChanged: (val) => setModalState(() => tempCutoff = val.toInt()),
                ),
                const SizedBox(height: 8),
                Text('Son Ödeme Günü: Ayın $tempDue. günü', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Slider(
                  value: tempDue.toDouble(),
                  min: 1,
                  max: 28,
                  divisions: 27,
                  activeColor: const Color(0xFF16A34A),
                  label: '$tempDue',
                  onChanged: (val) => setModalState(() => tempDue = val.toInt()),
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
                  _cutoffDay = tempCutoff;
                  _dueDay = tempDue;
                });
                _saveCardData();
                Navigator.pop(ctx);
                _speak('Kart ayarları güncellendi.');
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
    if (remainingRatio < 0.25) {
      statusColor = const Color(0xFFEF4444);
    } else if (remainingRatio < 0.5) {
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
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF64748B)),
            tooltip: 'Kart Ayarları',
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFF7C3AED)),
            tooltip: 'Yeni Ayı Başlat / Borç Kontrolü',
            onPressed: _promptMonthlyResetCheck,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ─── GÖRSEL OLARAK AZALAN LİMİT KARTI ───
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E293B),
                        statusColor.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.contactless_rounded, color: Colors.white70, size: 20),
                              SizedBox(width: 6),
                              Text('KART LİMİTİ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'Kesim: $_cutoffDay',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        '₺ ${_remainingLimit.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        'Kullanılabilir Kalan Limit',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),

                      // Azalan Dinamik Şekil (Progress Bar)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: remainingRatio,
                          minHeight: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // İstatistik Satırı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Limit: ₺${_monthlyLimit.toInt()}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Harcama: ₺${_currentMonthSpent.toInt()}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                      if (_carriedDebt > 0) ...[
                        const SizedBox(height: 6),
                        Text('Devreden Geçmiş Borç: ₺${_carriedDebt.toInt()}', style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 11.5)),
                      ],
                    ],
                  ),
                ),

                // Harcama Ekle & Yeni Ay Butonları
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Harcama Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: _showAddExpenseDialog,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded, size: 20),
                        label: const Text('Ayı Sıfırla'),
                        onPressed: _promptMonthlyResetCheck,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Harcama Geçmişi Listesi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      const Text('Kayıtlı Harcamalar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF475569))),
                      const Spacer(),
                      if (_nextMonthSpent > 0)
                        Text(
                          'Sonraki Ay: ${_nextMonthSpent.toInt()} TL',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
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
                                  backgroundColor: isNextMonth ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                                  child: Icon(
                                    isNextMonth ? Icons.schedule_rounded : Icons.shopping_bag_rounded,
                                    color: isNextMonth ? const Color(0xFFD97706) : AppColors.buttonIndigo,
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
}
