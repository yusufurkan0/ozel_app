import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/calendar_activity.dart';
import '../../services/routine_calendar_service.dart';
import '../../theme/app_theme.dart';
import 'free_time_planner_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FlutterTts _tts = FlutterTts();
  late DateTime _currentMonday;
  bool _isLoading = true;

  // dayIndex (0..6) -> slotIndex (0..4) -> List<CalendarActivity> (en fazla 3)
  Map<int, Map<int, List<CalendarActivity>>> _schedule = {};

  // Seçili gün indeksi (0: Pazartesi .. 6: Pazar)
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _currentMonday = RoutineCalendarService.getMondayOfWeek(DateTime.now());
    // Bugünün gününe odaklan
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
    _speak('${RoutineCalendarService.monthNamesTr[_currentMonday.month]} haftası açıldı.');
  }

  void _onMealSlotTapped(String mealName) {
    _speak('$mealName otomatik dolu ve sabittir. Buraya yeni görev eklenemez.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$mealName otomatik renklidir ve değiştirilemez.'),
        backgroundColor: const Color(0xFFF97316),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActivityPicker(int dayIndex, int slotIndex) {
    final existingTasks = _schedule[dayIndex]?[slotIndex] ?? [];
    if (existingTasks.length >= 3) {
      _speak('Bu zaman kutusuna en fazla 3 görev ekleyebilirsin. Önce birini silmelisin.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu kutu dolu! En fazla 3 görev ekleyebilirsin (Önce, Sonra, Daha Sonra).'),
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
                itemBuilder: (context, idx) {
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
                // Hafta Gezgini & Tarih Aralığı
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          const Text(
                            'HAFTALIK PLANLAYICI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.buttonIndigo, letterSpacing: 0.8),
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

                // Gün Seçici Tab Bar (Pazartesi .. Pazar)
                Container(
                  height: 56,
                  color: Colors.white,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.buttonIndigo.withValues(alpha: 0.08),
                    border: Border(bottom: BorderSide(color: AppColors.buttonIndigo.withValues(alpha: 0.15))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.today_rounded, color: AppColors.buttonIndigo, size: 22),
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
                      const Text(
                        'Maks. 3 Görev',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                // 5 Zaman Dilimi Listesi
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Slot: Öğle yemeğinden önce
                      _buildEditableSlotCard(
                        dayIndex: _selectedDayIndex,
                        slotIndex: 0,
                        title: '1. Öğle Yemeğinden Önce',
                        icon: Icons.wb_sunny_rounded,
                        color: const Color(0xFFF59E0B),
                      ),

                      // 2. Slot: Öğle yemeği (Yemek Görseli - Renkli & Kilitli)
                      _buildMealLockedSlotCard(
                        title: '2. Öğle Yemeği',
                        subtitle: 'Otomatik dolu ve kilitli zaman dilimi',
                        imageEmoji: '🍲',
                        color: const Color(0xFFF97316),
                      ),

                      // 3. Slot: Öğle yemeğinden sonra
                      _buildEditableSlotCard(
                        dayIndex: _selectedDayIndex,
                        slotIndex: 2,
                        title: '3. Öğle Yemeğinden Sonra',
                        icon: Icons.wb_twilight_rounded,
                        color: const Color(0xFF3B82F6),
                      ),

                      // 4. Slot: Akşam yemeği (Yemek Görseli - Renkli & Kilitli)
                      _buildMealLockedSlotCard(
                        title: '4. Akşam Yemeği',
                        subtitle: 'Otomatik dolu ve kilitli zaman dilimi',
                        imageEmoji: '🥗',
                        color: const Color(0xFF10B981),
                      ),

                      // 5. Slot: Akşam yemeğinden sonra
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
            ),
    );
  }

  /// Düzenlenebilir slot kutusu (1., 2., 3. görev sıralı)
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
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                  ),
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

            // 3'lü Slot Görev Yuvaları
            for (int i = 0; i < 3; i++) ...[
              if (i < tasks.length)
                // Dolu Görev Kartı
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
                        decoration: BoxDecoration(
                          color: tasks[i].color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          orderNames[i],
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tasks[i].emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tasks[i].title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tasks[i].color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tasks[i].group,
                          style: TextStyle(color: tasks[i].color, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Görevi Kaldır',
                        onPressed: () => _removeTask(dayIndex, slotIndex, i),
                      ),
                    ],
                  ),
                )
              else
                // Boş Görev Yuvası
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
                        Text(
                          '${orderNames[i]}:',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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

  /// Kilitli Yemek Kutusu (Öğle / Akşam Yemeği)
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
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(imageEmoji, style: const TextStyle(fontSize: 28)),
                ),
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
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('KİLİTLİ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: color.withValues(alpha: 0.85)),
                    ),
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
