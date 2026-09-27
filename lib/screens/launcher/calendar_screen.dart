import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

/// Kullanıcının yüklediği görseldeki haftalık zaman planlayıcı:
/// - 3 Renk Kategorisi:
///   1) Kırmızı: İş, okul, kurs zamanı (💼 📚)
///   2) Mavi: Evdeki zamanım - Dinlenme zamanı (🏠 🛏️)
///   3) Yeşil: Serbest zamanım - Eğlence zamanı (🎭 🕺 🎵)
/// - Tablo:
///   HAFTANIN GÜNLERİ | SABAH 🌅 | ÖĞLEN ☀️ | AKŞAM 🌙
///   Pazartesi .. Pazar (7 Gün)
/// - 52 Hafta Sayfaları (İleri / Geri)
/// - Dokunarak boyama & Seslendirme & Kalıcı kayıt
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

enum ScheduleColor { none, red, blue, green }

class _CalendarScreenState extends State<CalendarScreen> {
  final FlutterTts _tts = FlutterTts();
  late PageController _pageController;
  late int _currentWeekIndex; // 0..51 (1. Hafta .. 52. Hafta)
  SharedPreferences? _prefs;
  bool _isLoading = true;

  // Seçili fırça (varsayılan kırmızı)
  ScheduleColor _activeBrush = ScheduleColor.red;

  final List<String> _dayNames = [
    'PAZARTESİ',
    'SALI',
    'ÇARŞAMBA',
    'PERŞEMBE',
    'CUMA',
    'CUMARTESİ',
    'PAZAR',
  ];

  // Renk tanımları ve metinleri
  final Map<ScheduleColor, Map<String, dynamic>> _colorInfo = {
    ScheduleColor.red: {
      'title': 'İş, okul, kurs zamanı',
      'icons': '💼 📚',
      'iconData': Icons.school_rounded,
      'color': const Color(0xFFEF4444),
      'lightColor': const Color(0xFFFEE2E2),
      'key': 'red',
    },
    ScheduleColor.blue: {
      'title': 'Evdeki zamanım (Dinlenme zamanı)',
      'icons': '🏠 🛏️',
      'iconData': Icons.home_rounded,
      'color': const Color(0xFF3B82F6),
      'lightColor': const Color(0xFFDBEAFE),
      'key': 'blue',
    },
    ScheduleColor.green: {
      'title': 'Serbest zamanım (Eğlence zamanı)',
      'icons': '🎭 🕺 🎵',
      'iconData': Icons.celebration_rounded,
      'color': const Color(0xFF22C55E),
      'lightColor': const Color(0xFFDCFCE7),
      'key': 'green',
    },
  };

  // Haftalık hücre verileri: '${weekIndex}_${dayIndex}_${slotIndex}' -> 'red' | 'blue' | 'green'
  // 0: Sabah, 1: Öğlen, 2: Akşam
  // Kesinlikle otomatik doldurulmaz, boş başlar.
  final Map<String, ScheduleColor> _cellColors = {};
  final Map<String, String> _cellNotes = {};

  @override
  void initState() {
    super.initState();
    _initTts();

    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(firstDayOfYear).inDays;
    _currentWeekIndex = (dayOfYear ~/ 7).clamp(0, 51);

    _pageController = PageController(initialPage: _currentWeekIndex);
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith('sch_cell_col_')) {
          final cellKey = key.replaceFirst('sch_cell_col_', '');
          final val = _prefs?.getString(key);
          if (val == 'red') _cellColors[cellKey] = ScheduleColor.red;
          if (val == 'blue') _cellColors[cellKey] = ScheduleColor.blue;
          if (val == 'green') _cellColors[cellKey] = ScheduleColor.green;
        } else if (key.startsWith('sch_cell_not_')) {
          final cellKey = key.replaceFirst('sch_cell_not_', '');
          final val = _prefs?.getString(key);
          if (val != null && val.isNotEmpty) {
            _cellNotes[cellKey] = val;
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCell(String cellKey, ScheduleColor color, [String? note]) async {
    setState(() {
      if (color == ScheduleColor.none) {
        _cellColors.remove(cellKey);
        _prefs?.remove('sch_cell_col_$cellKey');
      } else {
        _cellColors[cellKey] = color;
        _prefs?.setString('sch_cell_col_$cellKey', _colorInfo[color]!['key'] as String);
      }

      if (note != null) {
        if (note.trim().isEmpty) {
          _cellNotes.remove(cellKey);
          _prefs?.remove('sch_cell_not_$cellKey');
        } else {
          _cellNotes[cellKey] = note.trim();
          _prefs?.setString('sch_cell_not_$cellKey', note.trim());
        }
      }
    });
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

  void _goToWeek(int index) {
    if (index >= 0 && index < 52) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCellTap(int weekIdx, int dayIdx, int slotIdx) {
    final cellKey = '${weekIdx}_${dayIdx}_$slotIdx';
    final currentColor = _cellColors[cellKey] ?? ScheduleColor.none;

    // Eğer zaten fırça rengindeyse temizle (toggle), değilse seçili fırçayı uygula
    if (currentColor == _activeBrush) {
      _saveCell(cellKey, ScheduleColor.none);
      _speak('Kutu temizlendi');
    } else {
      _saveCell(cellKey, _activeBrush);
      final title = _colorInfo[_activeBrush]!['title'] as String;
      final slotName = slotIdx == 0 ? 'Sabah' : (slotIdx == 1 ? 'Öğlen' : 'Akşam');
      final dayName = _dayNames[dayIdx];
      _speak('$dayName $slotName: $title boyandı');
    }
  }

  void _onCellLongPress(int weekIdx, int dayIdx, int slotIdx) {
    final cellKey = '${weekIdx}_${dayIdx}_$slotIdx';
    final currentColor = _cellColors[cellKey] ?? ScheduleColor.none;
    final currentNote = _cellNotes[cellKey] ?? '';
    final textCtrl = TextEditingController(text: currentNote);
    final dayName = _dayNames[dayIdx];
    final slotName = slotIdx == 0 ? 'Sabah' : (slotIdx == 1 ? 'Öğlen' : 'Akşam');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.palette_rounded, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 12),
                Text(
                  '$dayName - $slotName Kutusu',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Rengi Seç:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 10),
            // Renk Seçenekleri
            ...ScheduleColor.values.where((c) => c != ScheduleColor.none).map((col) {
              final info = _colorInfo[col]!;
              final isSelected = (currentColor == col);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? info['lightColor'] as Color : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? info['color'] as Color : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: info['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(info['iconData'] as IconData, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    info['title'] as String,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  trailing: Text(info['icons'] as String, style: const TextStyle(fontSize: 18)),
                  onTap: () {
                    _saveCell(cellKey, col, textCtrl.text);
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
            // Kutuyu Temizle Butonu
            if (currentColor != ScheduleColor.none)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: const Text('Bu Kutuyu Temizle (Beyaz Yap)'),
                onPressed: () {
                  _saveCell(cellKey, ScheduleColor.none, '');
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 10),
            // İsteğe bağlı not yazma alanı
            TextField(
              controller: textCtrl,
              decoration: InputDecoration(
                hintText: 'İsteğe bağlı not yaz (Örn: Matematik, Park)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              onSubmitted: (val) {
                _saveCell(cellKey, currentColor, val);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _saveCell(cellKey, currentColor, textCtrl.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Kaydet ve Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _speakDay(int weekIdx, int dayIdx) {
    final dayName = _dayNames[dayIdx];
    final morningCol = _cellColors['${weekIdx}_${dayIdx}_0'];
    final noonCol = _cellColors['${weekIdx}_${dayIdx}_1'];
    final nightCol = _cellColors['${weekIdx}_${dayIdx}_2'];

    final List<String> parts = [];
    if (morningCol != null) {
      parts.add('Sabah: ${_colorInfo[morningCol]!['title']}');
    }
    if (noonCol != null) {
      parts.add('Öğlen: ${_colorInfo[noonCol]!['title']}');
    }
    if (nightCol != null) {
      parts.add('Akşam: ${_colorInfo[nightCol]!['title']}');
    }

    if (parts.isEmpty) {
      _speak('$dayName günü için henüz bir boyama yapılmamış.');
    } else {
      _speak('$dayName programın: ${parts.join(', ')}');
    }
  }

  void _clearCurrentWeek(int weekIdx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Haftayı Temizle'),
        content: Text('${weekIdx + 1}. haftadaki tüm boyamaları silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                for (int d = 0; d < 7; d++) {
                  for (int s = 0; s < 3; s++) {
                    final key = '${weekIdx}_${d}_$s';
                    _cellColors.remove(key);
                    _cellNotes.remove(key);
                    _prefs?.remove('sch_cell_col_$key');
                    _prefs?.remove('sch_cell_not_$key');
                  }
                }
              });
              Navigator.pop(ctx);
              _speak('Haftalık program temizlendi.');
            },
            child: const Text('Evet, Temizle'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1: Pazartesi .. 7: Pazar
    final currentYearWeek = ((now.difference(DateTime(now.year, 1, 1)).inDays) ~/ 7).clamp(0, 51);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
            Icon(Icons.calendar_month_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Haftalık Planlayıcı',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Bu Hafta',
            onPressed: () => _goToWeek(currentYearWeek),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF64748B)),
            tooltip: 'Haftayı Temizle',
            onPressed: () => _clearCurrentWeek(_currentWeekIndex),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
            : Column(
                children: [
                  // ─── Hafta Navigasyonu (1 / 52) ───
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B)),
                          tooltip: 'Önceki Hafta',
                          onPressed: _currentWeekIndex > 0 ? () => _goToWeek(_currentWeekIndex - 1) : null,
                        ),
                        Column(
                          children: [
                            Text(
                              'Hafta ${_currentWeekIndex + 1} / 52',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '${now.year} Yılı Planlama Sayfası',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1E293B)),
                          tooltip: 'Sonraki Hafta',
                          onPressed: _currentWeekIndex < 51 ? () => _goToWeek(_currentWeekIndex + 1) : null,
                        ),
                      ],
                    ),
                  ),

                  // ─── Sayfalar (PageView) ───
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 52,
                      onPageChanged: (idx) => setState(() => _currentWeekIndex = idx),
                      itemBuilder: (context, weekIdx) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ─── 1) ÜST KISIM: Dinlenme zamanım mı? (Renk Tablosu / Fırça Seçimi) ───
                                  _buildLegendCard(),

                                  const SizedBox(height: 12),

                                  // ─── 2) TALİMAT YAZISI (Görseldeki Gibi) ───
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.brush_rounded, size: 16, color: Color(0xFF0F172A)),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Aşağıdaki kutuları programına uygun olarak yukarıdaki renklere boya:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // ─── 3) HAFTALIK MATRİS TABLOSU (Görseldeki Gibi) ───
                                  _buildScheduleTable(weekIdx, todayWeekday, currentYearWeek),

                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Üst kısımdaki 3 renkli gösterge kutusu (Görseldeki "Dinlenme zamanım mı?")
  Widget _buildLegendCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
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
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Row(
              children: [
                Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 18),
                SizedBox(width: 6),
                Text(
                  'Dinlenme zamanım mı?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E293B)),
                ),
                Spacer(),
                Text(
                  '(Renge dokunup boya)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // 3 Satır: Kırmızı, Mavi, Yeşil
          _buildLegendRow(ScheduleColor.red),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildLegendRow(ScheduleColor.blue),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildLegendRow(ScheduleColor.green),
        ],
      ),
    );
  }

  Widget _buildLegendRow(ScheduleColor color) {
    final info = _colorInfo[color]!;
    final isSelected = (_activeBrush == color);

    return InkWell(
      onTap: () {
        setState(() => _activeBrush = color);
        _speak('${info['title']} seçildi. Şimdi kutulara dokunarak boyayabilirsin.');
      },
      child: Container(
        color: isSelected ? (info['lightColor'] as Color).withValues(alpha: 0.35) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Sol: Renk Bloğu
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: info['color'] as Color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
                  width: isSelected ? 2.5 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (info['color'] as Color).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Center(child: Icon(Icons.check_rounded, color: Colors.white, size: 20))
                  : null,
            ),
            const SizedBox(width: 12),

            // Orta: Metin
            Expanded(
              child: Text(
                info['title'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),

            // Sağ: İkonlar (💼 📚 vs.)
            Text(
              info['icons'] as String,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  /// Görseldeki Haftalık Tablo:
  /// Sütunlar: HAFTANIN GÜNLERİ | SABAH | ÖĞLEN | AKŞAM
  /// Satırlar: Pazartesi .. Pazar
  Widget _buildScheduleTable(int weekIdx, int todayWeekday, int currentYearWeek) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          border: TableBorder.all(
            color: const Color(0xFFCBD5E1),
            width: 1.2,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.2), // HAFTANIN GÜNLERİ
            1: FlexColumnWidth(1.0), // SABAH
            2: FlexColumnWidth(1.0), // ÖĞLEN
            3: FlexColumnWidth(1.0), // AKŞAM
          },
          children: [
            // ─── BAŞLIK SATIRI ───
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                // HAFTANIN GÜNLERİ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  alignment: Alignment.center,
                  child: const Text(
                    'HAFTANIN\nGÜNLERİ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),

                // SABAH (Güneş doğuşu ikonu)
                _buildHeaderTimeCell(
                  title: 'SABAH',
                  icon: Icons.wb_twilight_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  bgBadgeColor: const Color(0xFFFEF3C7),
                ),

                // ÖĞLEN (Öğle güneşi ikonu)
                _buildHeaderTimeCell(
                  title: 'ÖĞLEN',
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFFEAB308),
                  bgBadgeColor: const Color(0xFFFEF9C3),
                ),

                // AKŞAM (Gece/Ay ikonu)
                _buildHeaderTimeCell(
                  title: 'AKŞAM',
                  icon: Icons.nightlight_round,
                  iconColor: const Color(0xFF6366F1),
                  bgBadgeColor: const Color(0xFFE0E7FF),
                ),
              ],
            ),

            // ─── 7 GÜNÜN SATIRLARI (PAZARTESİ .. PAZAR) ───
            ...List.generate(7, (dayIdx) {
              final dayName = _dayNames[dayIdx];
              final isToday = (dayIdx + 1 == todayWeekday && weekIdx == currentYearWeek);

              return TableRow(
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFFFFF1F2) : Colors.white,
                ),
                children: [
                  // Gün İsmi Hücresi
                  InkWell(
                    onTap: () => _speakDay(weekIdx, dayIdx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: isToday ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.volume_up_rounded,
                            size: 15,
                            color: isToday ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sabah Kutusu (slot 0)
                  _buildInteractiveCell(weekIdx, dayIdx, 0),

                  // Öğlen Kutusu (slot 1)
                  _buildInteractiveCell(weekIdx, dayIdx, 1),

                  // Akşam Kutusu (slot 2)
                  _buildInteractiveCell(weekIdx, dayIdx, 2),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTimeCell({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgBadgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgBadgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }

  /// Tablodaki her bir etkileşimli kutu (Dokun boya / Uzun bas detay)
  Widget _buildInteractiveCell(int weekIdx, int dayIdx, int slotIdx) {
    final cellKey = '${weekIdx}_${dayIdx}_$slotIdx';
    final color = _cellColors[cellKey] ?? ScheduleColor.none;
    final note = _cellNotes[cellKey] ?? '';
    final hasColor = color != ScheduleColor.none;
    final info = hasColor ? _colorInfo[color]! : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onCellTap(weekIdx, dayIdx, slotIdx),
        onLongPress: () => _onCellLongPress(weekIdx, dayIdx, slotIdx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          decoration: BoxDecoration(
            color: hasColor ? (info!['color'] as Color) : Colors.white,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hasColor) ...[
                Icon(
                  info!['iconData'] as IconData,
                  color: Colors.white,
                  size: 20,
                ),
                if (note.isNotEmpty)
                  Positioned(
                    bottom: 2,
                    right: 3,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ] else ...[
                // Boş kutu göstergesi
                const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFE2E8F0),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


