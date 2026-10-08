import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/calendar_activity.dart';
import '../../services/inactivity_help_service.dart';
import '../../services/routine_calendar_service.dart';
import '../../theme/app_theme.dart';
import 'free_time_planner_screen.dart';

enum CalendarViewMode { table, daily }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FlutterTts _tts = FlutterTts();
  late InactivityHelpService _inactivityHelp;

  late DateTime _currentMonday;
  bool _isLoading = true;

  // Görünüm modu: Tablo Görünümü (Haftalık Tam Tablo) vs Günlük Detay
  CalendarViewMode _viewMode = CalendarViewMode.table;

  // dayIndex (0..6) -> slotIndex (0..4) -> List<CalendarActivity> (en fazla 3)
  Map<int, Map<int, List<CalendarActivity>>> _schedule = {};

  // Seçili gün indeksi (0: Pazartesi .. 6: Pazar)
  int _selectedDayIndex = 0;

  // Kategori Bilgileri & Renkleri (Eski sevilen şema)
  final List<Map<String, dynamic>> _categoryLegends = [
    {'tag': 'EĞ', 'name': 'Eğitim', 'emoji': '🎒', 'color': const Color(0xFF2563EB), 'bg': const Color(0xFFDBEAFE)},
    {'tag': 'İŞ', 'name': 'İş', 'emoji': '💼', 'color': const Color(0xFF0F766E), 'bg': const Color(0xFFCCFBF1)},
    {'tag': 'KG', 'name': 'Kişisel Gelişim', 'emoji': '🏃', 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)},
    {'tag': 'SĞ', 'name': 'Sağlık', 'emoji': '🩺', 'color': const Color(0xFFDC2626), 'bg': const Color(0xFFFEE2E2)},
    {'tag': 'EV', 'name': 'Ev Zamanı', 'emoji': '🏠', 'color': const Color(0xFF475569), 'bg': const Color(0xFFF1F5F9)},
    {'tag': 'SZ', 'name': 'Serbest Zaman', 'emoji': '🎭', 'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFF3E8FF)},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _inactivityHelp = InactivityHelpService();
    _currentMonday = RoutineCalendarService.getMondayOfWeek(DateTime.now());
    final todayWeekday = DateTime.now().weekday; // 1: Pazartesi .. 7: Pazar
    _selectedDayIndex = (todayWeekday - 1).clamp(0, 6);
    _loadSchedule();
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

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    final data = await RoutineCalendarService.loadWeekSchedule(_currentMonday);
    if (mounted) {
      setState(() {
        _schedule = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeWeek(int delta) async {
    setState(() {
      _currentMonday = _currentMonday.add(Duration(days: delta * 7));
    });
    await _loadSchedule();
    final mondayStr = '${_currentMonday.day} ${RoutineCalendarService.monthNamesTr[_currentMonday.month]}';
    _speak('$mondayStr haftası açıldı.');
  }

  void _onMealSlotTapped(String mealName) {
    _speak('$mealName otomatik renklidir ve sabittir. Buraya yeni görev girilmez.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$mealName otomatik renklidir ve sabittir.'),
        backgroundColor: const Color(0xFFF97316),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActivityPicker(int dayIndex, int slotIndex) {
    _inactivityHelp.start(context);
    final existingTasks = _schedule[dayIndex]?[slotIndex] ?? [];
    if (existingTasks.length >= 3) {
      _speak('Bu zaman kutusuna en fazla 3 görev ekleyebilirsin. Önce birini silmelisin.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu kutu dolu! En fazla 3 görev ekleyebilirsin (1. Önce, 2. Sonra, 3. Daha Sonra).'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dayTitle = RoutineCalendarService.formatDayHeader(_currentMonday, dayIndex);
    final slotTitle = RoutineCalendarService.slotTitles[slotIndex];
    _speak('$dayTitle günü $slotTitle için etkinlik seç.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Görev Seç (${existingTasks.length + 1}. Görev)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    '$dayTitle • $slotTitle',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: CalendarActivity.predefinedActivities.length,
                itemBuilder: (_, idx) {
                  final act = CalendarActivity.predefinedActivities[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: act.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: act.color.withValues(alpha: 0.25)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: act.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(act.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      title: Text(
                        act.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: act.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          act.group,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        setState(() {
                          _schedule[dayIndex]![slotIndex]!.add(act);
                        });
                        await RoutineCalendarService.saveWeekSchedule(_currentMonday, _schedule);
                        if (!mounted) return;
                        _inactivityHelp.reset(context);
                        _speak('${act.title} eklendi.');
                      },
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

  void _showSlotDetailsDialog(int dayIndex, int slotIndex) {
    _inactivityHelp.reset(context);
    final dayTitle = RoutineCalendarService.formatDayHeader(_currentMonday, dayIndex);
    final slotTitle = RoutineCalendarService.slotTitles[slotIndex];
    final tasks = _schedule[dayIndex]?[slotIndex] ?? [];
    final orderNames = ['1. Önce', '2. Sonra', '3. Daha Sonra'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.event_note_rounded, color: AppColors.buttonIndigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  slotTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dayTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.buttonIndigo, fontSize: 13.5)),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Bu zaman diliminde henüz görev yok.', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              else
                ...tasks.asMap().entries.map((entry) {
                  final i = entry.key;
                  final task = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: task.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: task.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: task.color, borderRadius: BorderRadius.circular(6)),
                          child: Text(orderNames[i], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text(task.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            setState(() {
                              _schedule[dayIndex]?[slotIndex]?.removeAt(i);
                            });
                            setModalState(() {});
                            await RoutineCalendarService.saveWeekSchedule(_currentMonday, _schedule);
                            _speak('${task.title} silindi.');
                          },
                        ),
                      ],
                    ),
                  );
                }),
              if (tasks.length < 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text('${tasks.length + 1}. Görevi Ekle (Maks. 3)'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showActivityPicker(dayIndex, slotIndex);
                      },
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeTask(int dayIndex, int slotIndex, int taskIndex) async {
    final removed = _schedule[dayIndex]?[slotIndex]?[taskIndex].title ?? 'Görev';
    setState(() {
      _schedule[dayIndex]?[slotIndex]?.removeAt(taskIndex);
    });
    await RoutineCalendarService.saveWeekSchedule(_currentMonday, _schedule);
    _speak('$removed silindi.');
  }

  @override
  void dispose() {
    _inactivityHelp.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mondayStr = '${_currentMonday.day} ${RoutineCalendarService.monthNamesTr[_currentMonday.month]}';
    final sundayDate = _currentMonday.add(const Duration(days: 6));
    final sundayStr = '${sundayDate.day} ${RoutineCalendarService.monthNamesTr[sundayDate.month]}';

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
            Icon(Icons.calendar_month_rounded, color: AppColors.buttonIndigo),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Takvimim',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        actions: [
          // Görünüm Değiştirici: Tablo (Tüm Hafta) vs Günlük Detay
          IconButton(
            icon: Icon(
              _viewMode == CalendarViewMode.table ? Icons.view_agenda_rounded : Icons.table_chart_rounded,
              color: AppColors.buttonIndigo,
            ),
            tooltip: _viewMode == CalendarViewMode.table ? 'Günlük Görünüme Geç' : 'Haftalık Tabloya Geç',
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == CalendarViewMode.table ? CalendarViewMode.daily : CalendarViewMode.table;
              });
              _speak(_viewMode == CalendarViewMode.table ? 'Haftalık tablo görünümü açıldı.' : 'Günlük detay görünümü açıldı.');
            },
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.celebration_rounded, size: 18),
            label: const Text('SZ Planla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FreeTimePlannerScreen()),
              ).then((_) => _loadSchedule());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Hafta Gezgini
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 28),
                        onPressed: () => _changeWeek(-1),
                        tooltip: 'Önceki Hafta',
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _viewMode == CalendarViewMode.table ? 'HAFTALIK PLAN TABLOSU' : 'GÜNLÜK DETAY PLANI',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.buttonIndigo, letterSpacing: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Icon(_viewMode == CalendarViewMode.table ? Icons.grid_view_rounded : Icons.view_day_rounded, size: 13, color: AppColors.buttonIndigo),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$mondayStr - $sundayStr',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 28),
                        onPressed: () => _changeWeek(1),
                        tooltip: 'Sonraki Hafta',
                      ),
                    ],
                  ),
                ),

                // 2. Kategori Rozetleri (Eski sevilen görsel rehber)
                Container(
                  height: 44,
                  color: Colors.white,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _categoryLegends.length,
                    itemBuilder: (context, idx) {
                      final cat = _categoryLegends[idx];
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (cat['bg'] as Color),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (cat['color'] as Color).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Text(cat['emoji'] as String, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '${cat['tag']}: ${cat['name']}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: cat['color'] as Color),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),

                // 3. İçerik Görünümü: A) Eski Sevilen HAFTALIK TABLO, B) Günlük Detay
                Expanded(
                  child: _viewMode == CalendarViewMode.table
                      ? _buildWeeklyTableView()
                      : _buildDailyListView(),
                ),
              ],
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // A) ESKİ SEVİLEN HAFTALIK TABLO GÖRÜNÜMÜ (Weekly Grid Table)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWeeklyTableView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Haftalık Tablo: Kutuya dokunarak görevleri görebilir veya ekleyebilirsin (Maks. 3)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _viewMode = CalendarViewMode.daily);
                  _speak('Günlük listeye geçildi.');
                },
                child: const Text('Günlük Liste ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Yatay kaydırılabilir tablo konteyneri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                borderRadius: BorderRadius.circular(18),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  columnWidths: const {
                    0: FixedColumnWidth(130), // Gün & Tarih
                    1: FixedColumnWidth(110), // 1. Öğle Öncesi
                    2: FixedColumnWidth(90),  // 2. Öğle Yemeği (Kilitli)
                    3: FixedColumnWidth(110), // 3. Öğle Sonrası
                    4: FixedColumnWidth(90),  // 4. Akşam Yemeği (Kilitli)
                    5: FixedColumnWidth(110), // 5. Akşam Sonrası
                  },
                  children: [
                    // ─── BAŞLIK SATIRI ───
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                      children: [
                        _buildTableHeaderCell('HAFTANIN\nGÜNLERİ', Icons.calendar_today_rounded, const Color(0xFF334155)),
                        _buildTableHeaderCell('1. ÖĞLE\nÖNCESİ', Icons.wb_sunny_rounded, const Color(0xFFF59E0B)),
                        _buildTableHeaderCell('2. ÖĞLE\nYEMEĞİ', Icons.restaurant_rounded, const Color(0xFFF97316), isLocked: true),
                        _buildTableHeaderCell('3. ÖĞLE\nSONRASI', Icons.wb_twilight_rounded, const Color(0xFF3B82F6)),
                        _buildTableHeaderCell('4. AKŞAM\nYEMEĞİ', Icons.dinner_dining_rounded, const Color(0xFF10B981), isLocked: true),
                        _buildTableHeaderCell('5. AKŞAM\nSONRASI', Icons.nightlight_round, const Color(0xFF6366F1)),
                      ],
                    ),

                    // ─── 7 GÜN SATIRLARI (PAZARTESİ .. PAZAR) ───
                    ...List.generate(7, (dIdx) {
                      final dayHeader = RoutineCalendarService.formatDayHeader(_currentMonday, dIdx);
                      final isToday = (dIdx + 1 == DateTime.now().weekday &&
                          _currentMonday.day <= DateTime.now().day &&
                          DateTime.now().day <= _currentMonday.day + 6);

                      return TableRow(
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFFEFF6FF) : (dIdx % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC)),
                        ),
                        children: [
                          // 0. Hücre: Gün & Tarih (Örn: Perşembe: 24 Eylül)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDayIndex = dIdx;
                                _viewMode = CalendarViewMode.daily;
                              });
                              _speak('$dayHeader detayları açıldı.');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dayHeader,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isToday ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  if (isToday)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('BUGÜN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // 1. Slot: Öğle Öncesi
                          _buildTableSlotCell(dIdx, 0),

                          // 2. Slot: Öğle Yemeği (Otomatik Dolu & Kilitli)
                          _buildTableMealCell('Öğle Yemeği 🍲', '🍲', const Color(0xFFF97316)),

                          // 3. Slot: Öğle Sonrası
                          _buildTableSlotCell(dIdx, 2),

                          // 4. Slot: Akşam Yemeği (Otomatik Dolu & Kilitli)
                          _buildTableMealCell('Akşam Yemeği 🥗', '🥗', const Color(0xFF10B981)),

                          // 5. Slot: Akşam Sonrası
                          _buildTableSlotCell(dIdx, 4),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, IconData icon, Color color, {bool isLocked = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: color, height: 1.2),
          ),
          if (isLocked)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              child: const Text('KİLİTLİ', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  /// Tablodaki Görev Yuvası Hücresi (Maks. 3 Görev yuvası görünür)
  Widget _buildTableSlotCell(int dayIndex, int slotIndex) {
    final tasks = _schedule[dayIndex]?[slotIndex] ?? [];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (tasks.isEmpty) {
            _showActivityPicker(dayIndex, slotIndex);
          } else {
            _showSlotDetailsDialog(dayIndex, slotIndex);
          }
        },
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(4),
          child: tasks.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasks.asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text('${i + 1}.', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: t.color)),
                          const SizedBox(width: 2),
                          Text(t.emoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: t.color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }

  /// Tablodaki Kilitli Yemek Hücresi (Öğle / Akşam Yemeği)
  Widget _buildTableMealCell(String name, String emoji, Color color) {
    return Material(
      color: color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () => _onMealSlotTapped(name),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 11, color: color),
                  const SizedBox(width: 2),
                  Text('SABİT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // B) GÜNLÜK DETAY GÖRÜNÜMÜ (Tek Günlük 5 Zaman Dilimi Kartları)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDailyListView() {
    return Column(
      children: [
        // Gün Seçici Tab Bar
        Container(
          height: 52,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: 7,
            itemBuilder: (context, dIndex) {
              final isSel = dIndex == _selectedDayIndex;
              final dayDate = _currentMonday.add(Duration(days: dIndex));
              final dayNameShort = RoutineCalendarService.dayNames[dIndex].substring(0, 3);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDayIndex = dIndex);
                  _speak(RoutineCalendarService.formatDayHeader(_currentMonday, dIndex));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.buttonIndigo : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: AppColors.buttonIndigo.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNameShort ${dayDate.day}',
                      style: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Seçili Gün Başlığı (Örn: "Perşembe: 24 Eylül")
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.buttonIndigo.withValues(alpha: 0.08),
            border: Border(bottom: BorderSide(color: AppColors.buttonIndigo.withValues(alpha: 0.15))),
          ),
          child: Row(
            children: [
              const Icon(Icons.today_rounded, color: AppColors.buttonIndigo, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  RoutineCalendarService.formatDayHeader(_currentMonday, _selectedDayIndex),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonIndigo,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Maks. 3 Görev', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        // 5 Zaman Dilimi Kartları
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildEditableSlotCard(
                dayIndex: _selectedDayIndex,
                slotIndex: 0,
                title: '1. Öğle Yemeğinden Önce',
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFF59E0B),
              ),
              _buildMealLockedSlotCard(
                title: '2. Öğle Yemeği',
                subtitle: 'Otomatik dolu ve kilitli zaman dilimi',
                imageEmoji: '🍲',
                color: const Color(0xFFF97316),
              ),
              _buildEditableSlotCard(
                dayIndex: _selectedDayIndex,
                slotIndex: 2,
                title: '3. Öğle Yemeğinden Sonra',
                icon: Icons.wb_twilight_rounded,
                color: const Color(0xFF3B82F6),
              ),
              _buildMealLockedSlotCard(
                title: '4. Akşam Yemeği',
                subtitle: 'Otomatik dolu ve kilitli zaman dilimi',
                imageEmoji: '🥗',
                color: const Color(0xFF10B981),
              ),
              _buildEditableSlotCard(
                dayIndex: _selectedDayIndex,
                slotIndex: 4,
                title: '5. Akşam Yemeğinden Sonra',
                icon: Icons.nightlight_round,
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableSlotCard({
    required int dayIndex,
    required int slotIndex,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final tasks = _schedule[dayIndex]?[slotIndex] ?? [];
    final orderNames = ['1. Önce', '2. Sonra', '3. Daha Sonra'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                ),
                if (tasks.length < 3)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showActivityPicker(dayIndex, slotIndex),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < 3; i++) ...[
              if (i < tasks.length)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: tasks[i].color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tasks[i].color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: tasks[i].color, borderRadius: BorderRadius.circular(6)),
                        child: Text(orderNames[i], style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(tasks[i].emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tasks[i].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: tasks[i].color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(tasks[i].group, style: TextStyle(color: tasks[i].color, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _removeTask(dayIndex, slotIndex, i),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _showActivityPicker(dayIndex, slotIndex),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Row(
                      children: [
                        Text('${orderNames[i]}:', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Boş Görev (Dokunup Görev Ekle)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealLockedSlotCard({
    required String title,
    required String subtitle,
    required String imageEmoji,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: color.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onMealSlotTapped(title),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.25), shape: BoxShape.circle),
                child: Center(child: Text(imageEmoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                          child: const Text('KİLİTLİ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12.5, color: color.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              Icon(Icons.lock_rounded, color: color.withValues(alpha: 0.7), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
