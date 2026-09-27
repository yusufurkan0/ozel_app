import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/timer_service.dart';
import '../../theme/app_theme.dart';

/// Arka planda ve uygulama kapatılsa dahi saymaya devam eden,
/// bitince titreşim ve yüksek sesle alarm çalan görsel zamanlayıcı ekranı.
class VisualTimerScreen extends StatefulWidget {
  const VisualTimerScreen({super.key});

  @override
  State<VisualTimerScreen> createState() => _VisualTimerScreenState();
}

class _VisualTimerScreenState extends State<VisualTimerScreen> with SingleTickerProviderStateMixin {
  // 1'den 60 dakikaya kadar hızlı seçim butonları
  final List<int> _presetMinutes = [1, 3, 5, 10, 15, 20, 25, 30, 45, 60];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: VisualTimerService.instance,
      builder: (context, _) {
        final timerService = VisualTimerService.instance;
        final totalMins = timerService.totalSeconds ~/ 60;
        final isAlarm = timerService.isAlarmActive;
        final isRunning = timerService.isRunning;
        final progress = timerService.progress;
        final timeStr = timerService.formattedTime;

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
                Icon(Icons.timer_rounded, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text(
                  'Kronometre & Görsel Süre',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // ─── Arka Plan Çalışma Bilgilendirme Notu ───
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isAlarm
                          ? const Color(0xFFFEE2E2)
                          : (isRunning ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAlarm
                            ? const Color(0xFFEF4444)
                            : (isRunning ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0)),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAlarm
                              ? Icons.alarm_on_rounded
                              : (isRunning ? Icons.schedule_rounded : Icons.info_outline_rounded),
                          color: isAlarm
                              ? const Color(0xFFDC2626)
                              : (isRunning ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isAlarm
                                ? '⏰ SÜRE DOLDU! Cihaz titriyor ve ses çalıyor!'
                                : (isRunning
                                    ? '⏳ Süre sayıyor... Uygulamadan çıksanız bile geri sayım devam eder, bitince titrer ve sesle uyarır.'
                                    : 'Süre bittiğinde cihaz otomatik olarak titrer ve yüksek sesli alarm çalar.'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isAlarm
                                  ? const Color(0xFF991B1B)
                                  : (isRunning ? const Color(0xFF1E40AF) : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Görsel Zamanlayıcı Kadranı ───
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final scale = isAlarm ? _pulseAnimation.value : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              color: isAlarm ? const Color(0xFFFEF2F2) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isAlarm ? const Color(0xFFEF4444) : Colors.transparent,
                                width: isAlarm ? 4 : 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isAlarm
                                      ? const Color(0x3DEF4444)
                                      : const Color(0x0F0F172A),
                                  blurRadius: isAlarm ? 28 : 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Arka Plan İlerleme Çemberi
                                SizedBox(
                                  width: 210,
                                  height: 210,
                                  child: CircularProgressIndicator(
                                    value: isAlarm ? 1.0 : progress,
                                    strokeWidth: 18,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    color: isAlarm
                                        ? const Color(0xFFDC2626)
                                        : (progress > 0.25 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                // Dijital Süre ve Durum
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAlarm
                                          ? Icons.alarm_rounded
                                          : (isRunning ? Icons.hourglass_top_rounded : Icons.alarm_rounded),
                                      size: 32,
                                      color: isAlarm ? const Color(0xFFDC2626) : const Color(0xFFEF4444),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isAlarm ? '00:00' : timeStr,
                                      style: TextStyle(
                                        fontSize: 46,
                                        fontWeight: FontWeight.w800,
                                        color: isAlarm ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      isAlarm
                                          ? 'SÜRE BİTTİ! ⏰'
                                          : (isRunning ? 'Süre Akıyor...' : '$totalMins Dakika Ayarlı'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isAlarm
                                            ? const Color(0xFFDC2626)
                                            : (isRunning ? Colors.green.shade600 : const Color(0xFF64748B)),
                                      ),
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

                  const SizedBox(height: 20),

                  // ─── Alarm Çalıyorsa Özel "Alarmı Durdur" Butonu ───
                  if (isAlarm) ...[
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 6,
                            ),
                            onPressed: () {
                              timerService.stopAlarm();
                            },
                            icon: const Icon(Icons.stop_circle_rounded, size: 30),
                            label: const Text(
                              'ALARMI DURDUR (KAPAT)',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ─── İnce Ayar Butonları (+1 dk, -1 dk, +5 dk) ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _adjustButton(
                        label: '-5 dk',
                        onTap: isAlarm ? null : () => timerService.adjustMinutes(-5),
                      ),
                      const SizedBox(width: 8),
                      _adjustButton(
                        label: '-1 dk',
                        onTap: isAlarm ? null : () => timerService.adjustMinutes(-1),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalMins dk / 60 dk',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      _adjustButton(
                        label: '+1 dk',
                        onTap: isAlarm ? null : () => timerService.adjustMinutes(1),
                      ),
                      const SizedBox(width: 8),
                      _adjustButton(
                        label: '+5 dk',
                        onTap: isAlarm ? null : () => timerService.adjustMinutes(5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ─── Başlat / Durdur / Sıfırla ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sıfırla
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E8F0),
                          foregroundColor: const Color(0xFF334155),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () => timerService.resetTimer(),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 20),
                            SizedBox(width: 6),
                            Text('Sıfırla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Başlat / Durdur
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRunning ? const Color(0xFFEA580C) : const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                        ),
                        onPressed: () => timerService.toggleTimer(),
                        child: Row(
                          children: [
                            Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              isRunning ? 'Durdur' : 'Başlat',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ─── Hızlı Seçim Butonları (1 dk - 60 dk) ───
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hızlı Süre Seç (1 - 60 Dakika):',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetMinutes.map((m) {
                      final isSelected = (totalMins == m);
                      return GestureDetector(
                        onTap: isAlarm ? null : () => timerService.setMinutes(m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEF4444) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$m dk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              fontSize: 14,
                            ),
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
      },
    );
  }

  Widget _adjustButton({required String label, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
        ),
      ),
    );
  }
}
