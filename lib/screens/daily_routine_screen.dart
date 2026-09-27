import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_step.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// 📅 Görsel Günlük Rutin Çizelgesi Ekranı
class DailyRoutineScreen extends StatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  State<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends State<DailyRoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RoutineStep> _steps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSteps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('daily_routines_v1');
    if (jsonString != null) {
      try {
        final List list = jsonDecode(jsonString);
        _steps = list.map((e) => RoutineStep.fromJson(e)).toList();
      } catch (e) {
        _steps = RoutineStep.defaultSteps();
      }
    } else {
      _steps = RoutineStep.defaultSteps();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_steps.map((e) => e.toJson()).toList());
    await prefs.setString('daily_routines_v1', jsonString);
  }

  void _toggleStep(RoutineStep step) {
    setState(() {
      step.isCompleted = !step.isCompleted;
    });
    _saveSteps();

    if (step.isCompleted) {
      TtsService().speak('Harikasın! ${step.title} adımını tamamladın!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Tebrikler! "${step.title}" tamamlandı!'),
          backgroundColor: AppColors.positiveGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetCurrentTab(String timeSlot) {
    setState(() {
      for (final s in _steps) {
        if (s.timeSlot == timeSlot) {
          s.isCompleted = false;
        }
      }
    });
    _saveSteps();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rutin adımları sıfırlandı, yeni gün başladı!')),
    );
  }

  void _showTimerDialog(RoutineStep step) {
    int remainingSeconds = step.durationMinutes * 60;
    Timer? countdownTimer;
    bool isRunning = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
            if (isRunning) {
              if (remainingSeconds > 0) {
                setDialogState(() => remainingSeconds--);
              } else {
                timer.cancel();
                TtsService().speak('Süre doldu! Tebrikler.');
              }
            }
          });

          final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
          final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
          final totalSec = step.durationMinutes * 60;
          final progress = totalSec > 0 ? (totalSec - remainingSeconds) / totalSec : 1.0;

          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Row(
              children: [
                Text(step.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: AppColors.neumorphicDark.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation(AppColors.buttonTeal),
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(Icons.hourglass_bottom_rounded,
                            size: 32, color: AppColors.buttonTeal),
                        const SizedBox(height: 6),
                        Text(
                          '$minutes:$seconds',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  step.audioPrompt ?? 'Bu aktiviteyi tamamlama süresi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text('Kapat'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.positiveGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Tamamlandı'),
                onPressed: () {
                  countdownTimer?.cancel();
                  Navigator.pop(ctx);
                  if (!step.isCompleted) {
                    _toggleStep(step);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddStepDialog(String timeSlot) {
    final titleCtrl = TextEditingController();
    String selectedEmoji = '⭐';
    int duration = 10;

    final emojiList = ['☀️', '🧼', '🪥', '👕', '🥞', '🎒', '🚌', '✏️', '🍎', '🤹', '🛋️', '🍲', '📦', '🩳', '🌙', '⭐', '🎨', '🧩', '⚽'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Yeni Rutin Adımı Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adım Başlığı (Örn: Çiçekleri Sula)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Simge Seçin:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: emojiList.map((em) {
                    final isSel = em == selectedEmoji;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedEmoji = em),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.buttonIndigo.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isSel ? Border.all(color: AppColors.buttonIndigo, width: 2) : null,
                        ),
                        child: Text(em, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Süre (dakika):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (duration > 1) setModalState(() => duration--);
                      },
                    ),
                    Text('$duration dk', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setModalState(() => duration++),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonIndigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  final newStep = RoutineStep(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    emoji: selectedEmoji,
                    timeSlot: timeSlot,
                    durationMinutes: duration,
                    audioPrompt: titleCtrl.text.trim(),
                  );
                  setState(() => _steps.add(newStep));
                  _saveSteps();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📅 Görsel Günlük Rutin'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.buttonIndigo,
          labelColor: AppColors.buttonIndigo,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: '🌅 Sabah', icon: Icon(Icons.wb_sunny_rounded)),
            Tab(text: '🏫 Okul', icon: Icon(Icons.school_rounded)),
            Tab(text: '🌙 Akşam', icon: Icon(Icons.nightlight_round)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRoutineList('sabah'),
                _buildRoutineList('okul'),
                _buildRoutineList('aksam'),
              ],
            ),
    );
  }

  Widget _buildRoutineList(String timeSlot) {
    final list = _steps.where((s) => s.timeSlot == timeSlot).toList();
    final completedCount = list.where((s) => s.isCompleted).length;
    final totalCount = list.length;
    final ratio = totalCount > 0 ? completedCount / totalCount : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // İlerleme Kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Neu.elevated(radius: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rutin İlerlemesi: $completedCount / $totalCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '%${(ratio * 100).toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.buttonTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 12,
                    backgroundColor: AppColors.neumorphicDark.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(AppColors.positiveGreen),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Günü Sıfırla'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      onPressed: () => _resetCurrentTab(timeSlot),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Adım Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonIndigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showAddStepDialog(timeSlot),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Rutin Adımları
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Bu zaman dilimi için henüz adım eklenmedi.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final step = list[index];
                return GestureDetector(
                  onTap: () => _toggleStep(step),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: step.isCompleted
                        ? BoxDecoration(
                            color: AppColors.positiveGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.positiveGreen.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          )
                        : Neu.elevated(radius: 20),
                    child: Row(
                      children: [
                        Text(step.emoji, style: const TextStyle(fontSize: 34)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: step.isCompleted
                                      ? AppColors.positiveGreen
                                      : AppColors.textPrimary,
                                  decoration: step.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${step.durationMinutes} dakika',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Sesli Dinle Butonu
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded,
                              color: AppColors.buttonIndigo, size: 24),
                          tooltip: 'Sesli Dinle',
                          onPressed: () {
                            if (step.audioPrompt != null) {
                              TtsService().speak(step.audioPrompt!);
                            } else {
                              TtsService().speak(step.title);
                            }
                          },
                        ),
                        // Görsel Kum Saati Butonu
                        IconButton(
                          icon: const Icon(Icons.hourglass_top_rounded,
                              color: AppColors.buttonTeal, size: 24),
                          tooltip: 'Zamanlayıcıyı Başlat',
                          onPressed: () => _showTimerDialog(step),
                        ),
                        // Tamamlandı Checkbox
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: step.isCompleted
                                ? AppColors.positiveGreen
                                : Colors.transparent,
                            border: Border.all(
                              color: step.isCompleted
                                  ? AppColors.positiveGreen
                                  : AppColors.neumorphicDark,
                              width: 2,
                            ),
                          ),
                          child: step.isCompleted
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
