import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/calendar_activity.dart';
import '../../models/free_time_plan.dart';
import '../../services/inactivity_help_service.dart';
import '../../services/routine_calendar_service.dart';
import '../../theme/app_theme.dart';
import 'calendar_screen.dart';

class FreeTimePlannerScreen extends StatefulWidget {
  const FreeTimePlannerScreen({super.key});

  @override
  State<FreeTimePlannerScreen> createState() => _FreeTimePlannerScreenState();
}

class _FreeTimePlannerScreenState extends State<FreeTimePlannerScreen> {
  final FlutterTts _tts = FlutterTts();
  late InactivityHelpService _inactivityHelp;

  bool _isLoading = true;
  List<Map<String, dynamic>> _calendarSzActivities = [];
  List<FreeTimePlan> _savedPlans = [];

  // Aktif planlama durumu
  bool _isWizardActive = false;
  int _currentStep = 0; // 0..12 (1..13. soru)
  String _selectedActivityTitle = '';
  String _selectedActivityEmoji = '🎉';
  String _selectedDayTitle = '';
  final Map<int, String> _currentAnswers = {};

  // Kitapçık okuma modu (13 sayfalık adım adım rehber)
  FreeTimePlan? _activeBookletPlan;
  int _bookletPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _inactivityHelp = InactivityHelpService();
    _loadInitialData();
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

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final monday = RoutineCalendarService.getMondayOfWeek(DateTime.now());
    final calSz = await RoutineCalendarService.getFreeTimeActivitiesForWeek(monday);
    final plans = await FreeTimePlan.loadSavedPlans();

    if (mounted) {
      setState(() {
        _calendarSzActivities = calSz;
        _savedPlans = plans;
        _isLoading = false;
      });

      if (calSz.isNotEmpty && plans.isEmpty) {
        _speak('Haftalık takviminde planladığın serbest zaman etkinliklerin var. Bir tanesini seçip detaylı planlamak ister misin?');
      } else if (calSz.isEmpty && plans.isEmpty) {
        _speak('Haftalık takviminde henüz bir serbest zaman etkinliği planlamamışsın. Şimdi takvime serbest zaman etkinliği ekleyebilir veya buradan yeni bir plan başlatabilirsin.');
      }
    }
  }

  void _startPlanning({required String title, required String emoji, required String dayTitle}) {
    setState(() {
      _selectedActivityTitle = title;
      _selectedActivityEmoji = emoji;
      _selectedDayTitle = dayTitle;
      _currentAnswers.clear();
      _currentAnswers[1] = title;
      _currentStep = 1; // 2. sorudan devam et (1. soru etkinlik adı zaten seçildi)
      _isWizardActive = true;
      _activeBookletPlan = null;
    });

    _inactivityHelp.start(context);
    _speakStep();
  }

  void _speakStep() {
    if (_currentStep < FreeTimePlan.questions.length) {
      final q = FreeTimePlan.questions[_currentStep]['question'] as String;
      _speak(q);
    }
  }

  void _answerCurrentQuestion(String answer) {
    _inactivityHelp.reset(context);
    setState(() {
      _currentAnswers[_currentStep + 1] = answer;
    });
    _speak('$answer seçildi.');

    if (_currentStep < FreeTimePlan.questions.length - 1) {
      setState(() {
        _currentStep++;
      });
      _speakStep();
    }
  }

  void _finishWizard() async {
    // Boş kalan soru kontrolü
    final missing = <int>[];
    for (int i = 1; i <= 13; i++) {
      if (!_currentAnswers.containsKey(i) || _currentAnswers[i]!.trim().isEmpty) {
        missing.add(i);
      }
    }

    if (missing.isNotEmpty) {
      _speak('Planı tamamlamak için henüz cevaplanmamış sorular var. Lütfen boş soruları tamamla.');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen ${missing.join(", ")}. soruları da cevaplayın.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _currentStep = missing.first - 1;
      });
      _speakStep();
      return;
    }

    _inactivityHelp.stop();

    final newPlan = FreeTimePlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityTitle: _selectedActivityTitle,
      activityEmoji: _selectedActivityEmoji,
      dayTitle: _selectedDayTitle,
      answers: Map<int, String>.from(_currentAnswers),
      createdAt: DateTime.now(),
    );

    _savedPlans.insert(0, newPlan);
    await FreeTimePlan.savePlans(_savedPlans);

    setState(() {
      _isWizardActive = false;
      _activeBookletPlan = newPlan;
      _bookletPageIndex = 0;
    });

    _speak('Tebrikler! 13 sayfalık serbest zaman planlama kitapçığın hazırlandı. Şimdi başla diyerek adım adım uygulayabilirsin.');
  }

  void _deletePlan(String id) async {
    setState(() {
      _savedPlans.removeWhere((p) => p.id == id);
      if (_activeBookletPlan?.id == id) {
        _activeBookletPlan = null;
      }
    });
    await FreeTimePlan.savePlans(_savedPlans);
    _speak('Etkinlik planı silindi.');
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
            if (_isWizardActive) {
              setState(() => _isWizardActive = false);
              _inactivityHelp.stop();
            } else if (_activeBookletPlan != null) {
              setState(() => _activeBookletPlan = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, color: Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _isWizardActive
                    ? 'Etkinlik Planlama'
                    : (_activeBookletPlan != null ? 'Rehber Kitapçık' : 'Serbest Zaman Planlama'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          if (!_isWizardActive && _activeBookletPlan == null)
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded, color: AppColors.buttonIndigo),
              tooltip: 'Takvime Git',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())).then((_) => _loadInitialData());
              },
            ),
          if (_isWizardActive)
            TextButton.icon(
              icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
              label: const Text('Bitir', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _finishWizard,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isWizardActive
              ? _buildWizardView()
              : (_activeBookletPlan != null ? _buildBookletReaderView() : _buildMainListView()),
    );
  }

  /// Ana Görünüm: Takvim Entegrasyon Kartı + Kayıtlı Kitapçıklar + Yeni Ekle Butonu
  Widget _buildMainListView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── 1. BÖLÜM: TAKVİM ENTEGRASYON BİLGİ KUTUSU ───
        if (_calendarSzActivities.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: Colors.white, size: 26),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Takviminde Planladığın Etkinlikler',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Haftalık takviminde serbest zaman etkinliklerin var. Bir tanesini seçip 13 adımlık detaylı rehberini oluşturmak ister misin?',
                  style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 14),
                ..._calendarSzActivities.map((item) {
                  final act = item['activity'] as CalendarActivity;
                  final dayStr = item['dayTitle'] as String;
                  final slotStr = item['slotTitle'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(act.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(act.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                              Text('$dayStr • $slotStr', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _startPlanning(title: act.title, emoji: act.emoji, dayTitle: dayStr),
                          child: const Text('Planla ✍️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFF7C3AED), size: 32),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Takviminde Serbest Zaman Yok',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Haftalık takviminde henüz bir serbest zaman etkinliği planlamamışsın. Takvimine yeşil kutulara etkinlik ekleyebilir veya doğrudan aşağıdan yeni bir etkinlik seçebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.buttonIndigo,
                    side: const BorderSide(color: AppColors.buttonIndigo),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: const Text('Takvime Git & Ekle'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())).then((_) => _loadInitialData());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ─── 2. BÖLÜM: YENİ ETKİNLİK EKLE BUTONU ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Kitapçıklarım',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Yeni Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _showAddNewActivityModal,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── 3. BÖLÜM: HAZIR KİTAPÇIKLAR LİSTESİ ───
        if (_savedPlans.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.auto_stories_rounded, size: 48, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 12),
                  const Text(
                    'Henüz Oluşturulmuş Kitapçık Yok',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bir etkinlik seçip 13 soruyu cevaplayarak adım adım rehber kitapçığını oluşturabilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Etkinlik Ekle & Planla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    onPressed: _showAddNewActivityModal,
                  ),
                ],
              ),
            ),
          )
        else
          ..._savedPlans.map((plan) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(child: Text(plan.activityEmoji, style: const TextStyle(fontSize: 26))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.activityTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                              ),
                              if (plan.dayTitle.isNotEmpty)
                                Text(
                                  plan.dayTitle,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                          tooltip: 'Kitapçığı Sil',
                          onPressed: () => _deletePlan(plan.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Color(0xFF7C3AED), size: 20),
                          const SizedBox(width: 8),
                          const Text('13 Sayfalık Adım Adım Rehber Hazır', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF475569))),
                          const Spacer(),
                          Text('${plan.answers.length}/13 Tamamlandı', style: const TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text('Başla (Adım Adım Yönlendir)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () {
                          setState(() {
                            _activeBookletPlan = plan;
                            _bookletPageIndex = 0;
                          });
                          _speak('${plan.activityTitle} rehberi açıldı. 1. sayfa.');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAddNewActivityModal() {
    // 12 Serbest Zaman Etkinliği (SZ listesi)
    final szActivities = CalendarActivity.predefinedActivities.where((a) => a.isFreeTime).toList();
    _speak('Hangi serbest zaman etkinliğini yapmak istiyorsun? Listeden bir etkinlik seç.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Color(0xFF7C3AED), size: 26),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Serbest Zaman Etkinliği Seç',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: szActivities.length,
                itemBuilder: (context, idx) {
                  final act = szActivities[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    color: const Color(0xFFF8FAFC),
                    child: ListTile(
                      leading: Text(act.emoji, style: const TextStyle(fontSize: 26)),
                      title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF7C3AED)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showWeekSlotPickerModal(act);
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

  /// İçinde bulunulan haftanın takvim slot seçicisi:
  /// - Uygun boşluklar YEŞİL renktedir.
  /// - Banner ve sesli uyarı: "Yeşil renkli yerlerden seç"
  /// - Dolu veya yemek slotuna basılırsa: "Burası dolu, yeşillerden seç!" uyarısı.
  /// - Yeşil slot seçilince takvim güncellenir ve 13 adımlık soru sihirbazına geçilir.
  Future<void> _showWeekSlotPickerModal(CalendarActivity selectedActivity) async {
    final currentMonday = RoutineCalendarService.getMondayOfWeek(DateTime.now());
    final weekSchedule = await RoutineCalendarService.loadWeekSchedule(currentMonday);

    // Varsayılan olarak bugünün gününü seçelim (0: Pazartesi .. 6: Pazar)
    int selectedDayIndex = (DateTime.now().weekday - 1).clamp(0, 6);

    _speak('Yeşil renkli yerlerden seç. Takvimde uygun boşluklar yeşil renkle gösterilmiştir.');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final dayName = RoutineCalendarService.dayNames[selectedDayIndex];
          final dayFormatted = RoutineCalendarService.formatDayHeader(currentMonday, selectedDayIndex);

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tutamaç
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                // Başlık & Kapat Butonu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(selectedActivity.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedActivity.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                            const Text(
                              'Haftalık Takvimde Zaman Seç',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // 🟢 ZORUNLU REHBER BANNER: "Yeşil renkli yerlerden seç"
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF22C55E), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeşil renkli yerlerden seç',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Bu hafta için boş ve uygun zamanlar yeşil renktedir. Dolu yerler seçilemez.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // GÜN SEÇİCİ (Haftanın 7 Günü - Sadece İçinde Bulunulan Hafta)
                Container(
                  height: 64,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 7,
                    itemBuilder: (context, dIdx) {
                      final isSelected = dIdx == selectedDayIndex;
                      final dayDate = currentMonday.add(Duration(days: dIdx));
                      final dayShortName = RoutineCalendarService.dayNames[dIdx].substring(0, 3);

                      // Günün uygun boşluğu var mı kontrolü
                      bool hasGreenSlot = false;
                      for (int s in [0, 2, 4]) {
                        if ((weekSchedule[dIdx]?[s]?.length ?? 0) < 3) {
                          hasGreenSlot = true;
                          break;
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedDayIndex = dIdx;
                          });
                          _speak('${RoutineCalendarService.dayNames[dIdx]} günü seçildi.');
                        },
                        child: Container(
                          width: 68,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7C3AED)
                                  : (hasGreenSlot ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayShortName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dayDate.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : (hasGreenSlot ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dayFormatted,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '🟢 Boş / Seçilebilir',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 12),

                // 5 ZAMAN DİLİMİ (SLOTLAR) LİSTESİ
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: 5,
                    itemBuilder: (context, slotIdx) {
                      final slotTitle = RoutineCalendarService.slotTitles[slotIdx];
                      final isMeal = RoutineCalendarService.isMealSlot(slotIdx);
                      final currentTasks = weekSchedule[selectedDayIndex]?[slotIdx] ?? [];
                      final isFull = isMeal || currentTasks.length >= 3;

                      if (!isFull) {
                        // 🟢 YEŞİL RENKTE UYGUN BOŞLUK
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF22C55E), width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              // YEŞİL SLOT SEÇİLDİ!
                              // 1. Etkinliği takvime ekle
                              weekSchedule[selectedDayIndex]![slotIdx]!.add(selectedActivity);
                              await RoutineCalendarService.saveWeekSchedule(currentMonday, weekSchedule);

                              // 2. Takvim senkronizasyonunu yenile
                              await _loadInitialData();

                              // 3. Modalı kapat
                              if (mounted && Navigator.canPop(ctx)) {
                                Navigator.pop(ctx);
                              }

                              // 4. Sesli ve görsel bildirim
                              _speak('$dayName $slotTitle seçildi. Şimdi soruları cevaplayalım.');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 ${selectedActivity.title}, $dayName takvimine eklendi!'),
                                    backgroundColor: const Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }

                              // 5. 13 Adımlık Soru Sihirbazını Başlat
                              final fullDayTitle = '${RoutineCalendarService.formatDayHeader(currentMonday, selectedDayIndex)} • $slotTitle';
                              _startPlanning(
                                title: selectedActivity.title,
                                emoji: selectedActivity.emoji,
                                dayTitle: fullDayTitle,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slotTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF14532D),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          currentTasks.isEmpty
                                              ? '🟢 Tamamen Boş • Buraya Ekle'
                                              : '🟢 ${3 - currentTasks.length} Boşluk Kaldı • Buraya Ekle',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'SEÇ 🟢',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        // ⛔ DOLU / KİLİTLİ SLOT
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              // DOLU YERE BASILDI!
                              _speak('Burası dolu, yeşillerden seç!');
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Burası dolu, yeşillerden seç!',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFFEF4444),
                                  duration: Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isMeal ? Icons.lock_clock_rounded : Icons.do_not_disturb_on_rounded,
                                      color: const Color(0xFF94A3B8),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slotTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isMeal ? '⛔ Yemek Zamanı (Sabit ve Kilitli)' : '⛔ Burası Dolu (3/3 Etkinlik)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'DOLU ⛔',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
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

  /// 13 Adımlık Soru Sihirbazı Görünümü
  Widget _buildWizardView() {
    final qData = FreeTimePlan.questions[_currentStep];
    final qTitle = qData['question'] as String;
    final qIcon = qData['icon'] as String;
    final qHint = qData['hint'] as String;
    final options = qData['options'] as List<String>;
    final existingAnswer = _currentAnswers[_currentStep + 1] ?? '';

    final textCtrl = TextEditingController(text: existingAnswer);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Adım İlerleme Çubuğu (1..13)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentStep + 1} / 13',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_selectedActivityEmoji $_selectedActivityTitle',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / 13,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF7C3AED),
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 24),

          // Soru Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(qIcon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        qTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B), height: 1.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(qHint, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seçenekler Listesi
          const Text('Hazır Seçeneklerden Dokunarak Seç:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
          const SizedBox(height: 10),
          ...options.map((opt) {
            final isSel = existingAnswer == opt;
            return GestureDetector(
              onTap: () => _answerCurrentQuestion(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF7C3AED).withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 15,
                          color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          // Veya Kendi Yanıtını Yaz
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Veya Kendi Yanıtını Yaz:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cevabını buraya yaz...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onPressed: () {
                        final val = textCtrl.text.trim();
                        if (val.isNotEmpty) {
                          _answerCurrentQuestion(val);
                        }
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // İleri / Geri & Bitir Butonları
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      setState(() => _currentStep--);
                      _speakStep();
                    },
                    child: const Text('Önceki Soru'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStep == 12 ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_currentStep == 12) {
                      _finishWizard();
                    } else {
                      setState(() => _currentStep++);
                      _speakStep();
                    }
                  },
                  child: Text(
                    _currentStep == 12 ? 'Planlamayı Bitir ✅' : 'Sonraki Soru ➡️',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 13 Sayfalık Sıralı Rehber Kitapçık Okuyucu Görünümü ("Başla" modu)
  Widget _buildBookletReaderView() {
    final plan = _activeBookletPlan!;
    final totalPages = 13;
    final currentQ = FreeTimePlan.questions[_bookletPageIndex];
    final answerText = plan.answers[_bookletPageIndex + 1] ?? 'Belirtilmedi';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Sayfa Başlığı & İlerleme
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sayfa ${_bookletPageIndex + 1} / $totalPages',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7C3AED)),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF7C3AED), size: 28),
                tooltip: 'Sesli Oku',
                onPressed: () => _speak('${currentQ['question']}. Cevabın: $answerText'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_bookletPageIndex + 1) / totalPages,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF7C3AED),
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 24),

          // Büyük Kitapçık Sayfası Kartı
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(currentQ['icon'] as String, style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentQ['question'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SENİN PLÂNIN:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7C3AED), letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          answerText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sayfa Gezgini Butonları
          Row(
            children: [
              if (_bookletPageIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Önceki Sayfa'),
                    onPressed: () {
                      setState(() => _bookletPageIndex--);
                      _speak('${FreeTimePlan.questions[_bookletPageIndex]['question']}. Cevabın: ${plan.answers[_bookletPageIndex + 1]}');
                    },
                  ),
                ),
              if (_bookletPageIndex > 0) const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bookletPageIndex == totalPages - 1 ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(_bookletPageIndex == totalPages - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded),
                  label: Text(
                    _bookletPageIndex == totalPages - 1 ? 'Kitapçığı Tamamla' : 'Sonraki Sayfa',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () {
                    if (_bookletPageIndex == totalPages - 1) {
                      _speak('Harika! Serbest zaman planı kitapçığını başarıyla tamamladın. İyi eğlenceler!');
                      setState(() => _activeBookletPlan = null);
                    } else {
                      setState(() => _bookletPageIndex++);
                      _speak('${FreeTimePlan.questions[_bookletPageIndex]['question']}. Cevabın: ${plan.answers[_bookletPageIndex + 1]}');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
