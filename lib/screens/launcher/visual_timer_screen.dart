import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/timer_service.dart';

/// Temiz, aydınlık ve beyaz temalı; tekli veya çift sayaçlı,
/// görsel azalan süreli (Dairesel Saat ve Dikey Sütun) ve seçilebilir müzikli zamanlayıcı ekranı.
class VisualTimerScreen extends StatefulWidget {
  const VisualTimerScreen({super.key});

  @override
  State<VisualTimerScreen> createState() => _VisualTimerScreenState();
}

class _VisualTimerScreenState extends State<VisualTimerScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Hızlı Seçim Süreleri (Dakika)
  final List<int> _quickPresets = [1, 3, 5, 10, 15, 20, 25, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getTimerColor(double progress) {
    if (progress > 0.5) {
      return const Color(0xFF16A34A); // Canlı Yeşil
    } else if (progress > 0.2) {
      return const Color(0xFFEA580C); // Canlı Turuncu
    } else {
      return const Color(0xFFDC2626); // Kırmızı
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerService = VisualTimerService.instance;

    return AnimatedBuilder(
      animation: timerService,
      builder: (context, _) {
        final isAlarm = timerService.isAlarmActive;
        final isDual = timerService.isDualMode;
        final isSideBySide = timerService.isSideBySideLayout;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC), // Ferah beyaz tema arka planı
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sayaçlar',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Kronometre & Görsel Süre',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              // 2. Sayaç Ekle / Çıkar Butonu
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: isDual
                      ? const Color(0xFFFFEDD5)
                      : const Color(0xFFF1F5F9),
                  foregroundColor: isDual ? const Color(0xFFEA580C) : const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDual ? const Color(0xFFFDBA74) : const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: Icon(isDual ? Icons.timer_off_rounded : Icons.more_time_rounded, size: 18),
                label: Text(
                  isDual ? 'Tek Sayaç' : '+ 2. Sayaç',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => timerService.toggleDualMode(),
              ),
              const SizedBox(width: 6),

              // Yan Yana / Alt Alta Yerleşim Değiştirici (Çift modda)
              if (isDual)
                IconButton(
                  tooltip: isSideBySide ? 'Alt Alta Yerleşim' : 'Yan Yana Yerleşim',
                  icon: Icon(
                    isSideBySide ? Icons.view_agenda_rounded : Icons.view_column_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                  onPressed: () => timerService.setSideBySideLayout(!isSideBySide),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ─── Genel Alarm Durum Bandı (Eğer Çalıyorsa) ───
                if (isAlarm) _buildGlobalAlarmBanner(timerService),

                // ─── Hızlı Seçim Ön Ayar Çipleri ───
                _buildPresetChipsBar(timerService),

                // ─── Sayaç Alanları (Tekli veya Çift) ───
                Expanded(
                  child: isDual
                      ? (isSideBySide
                          ? _buildSideBySideLayout(timerService)
                          : _buildStackedLayout(timerService))
                      : _buildSingleLayout(timerService),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Hızlı Ön Ayar Butonları Barı (5 dk, 10 dk, vb.) ───
  Widget _buildPresetChipsBar(VisualTimerService service) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final mins = _quickPresets[i];
          final isSelected = service.timer1.totalSeconds == mins * 60;
          return ActionChip(
            label: Text(
              '$mins dk',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            backgroundColor: isSelected ? const Color(0xFF16A34A) : Colors.white,
            side: BorderSide(
              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () {
              service.setMinutes(mins);
            },
          );
        },
      ),
    );
  }

  // ─── Alarm Çalma Uyarı Bandı ───
  Widget _buildGlobalAlarmBanner(VisualTimerService service) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1ADB2777),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm_on_rounded, color: Color(0xFFDC2626), size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SÜRE DOLDU! ⏰',
                  style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  'Belirlenen zaman tamamlandı. Alarm çalıyor...',
                  style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => service.stopAllAlarms(),
            child: const Text('Durdur', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── TEKLİ SAYAÇ GÖRÜNÜMÜ ───
  Widget _buildSingleLayout(VisualTimerService service) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: _buildTimerCard(service.timer1, service, isPrimary: true),
    );
  }

  // ─── ÇİFT SAYAÇ - ALT ALTA YERLEŞİM ───
  Widget _buildStackedLayout(VisualTimerService service) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildTimerCard(service.timer1, service, isPrimary: true),
          const SizedBox(height: 20),
          _buildTimerCard(service.timer2, service, isPrimary: false),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── ÇİFT SAYAÇ - YAN YANA YERLEŞİM ───
  Widget _buildSideBySideLayout(VisualTimerService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildTimerCard(service.timer1, service, isPrimary: true, isCompact: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildTimerCard(service.timer2, service, isPrimary: false, isCompact: true),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SAYAÇ KARTI (BEYAZ TEMA, MODERN & ERGONOMİK)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTimerCard(
    TimerItemModel timer,
    VisualTimerService service, {
    required bool isPrimary,
    bool isCompact = false,
  }) {
    final bool isRunningOrPaused = timer.isRunning || (timer.remainingSeconds < timer.totalSeconds && timer.remainingSeconds > 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: timer.isAlarmActive
              ? const Color(0xFFEF4444)
              : (timer.isRunning ? const Color(0xFF22C55E).withValues(alpha: 0.6) : const Color(0xFFE2E8F0)),
          width: timer.isAlarmActive ? 2.0 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 16 : 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık Satırı & Görsel Stil Değiştirici
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: timer.isRunning ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timer.label,
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      timer.formattedTime,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF64748B), size: 16),
                    tooltip: 'İsim Değiştir',
                    onPressed: () => _showLabelEditDialog(timer, service),
                  ),
                ],
              ),

              // Görsel Mod Butonu (Saat / Dikey Sütun)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.timelapse_rounded,
                        size: 18,
                        color: timer.visualStyle == 'circle'
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                      ),
                      tooltip: 'Dairesel Saat Görünümü',
                      onPressed: () => service.setTimerVisualStyle(timer, 'circle'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.view_headline_rounded,
                        size: 18,
                        color: timer.visualStyle == 'column'
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                      ),
                      tooltip: 'Dikey Sütun Görünümü',
                      onPressed: () => service.setTimerVisualStyle(timer, 'column'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── 1. BÖLÜM: YA BEYAZ ÇARK SEÇİCİ YA DA GÖRSEL GERİ SAYIM ───
          if (!isRunningOrPaused)
            _buildIosWheelPicker(timer, service, isCompact: isCompact)
          else
            _buildVisualCountDown(timer, service, isCompact: isCompact),

          const SizedBox(height: 24),

          // ─── 2. BÖLÜM: YUVARLAK KONTROL BUTONLARI (Vazgeç & Başlat/Duraklat) ───
          _buildIosCircularButtons(timer, service, isCompact: isCompact),

          const SizedBox(height: 20),

          // ─── 3. BÖLÜM: BEYAZ AYARLAR GRUBU (Etiket & Sayaç Bitince) ───
          _buildIosSettingsGroup(timer, service),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BEYAZ ÇARK SEÇİCİ (saat - dk. - sn.)
  // ─────────────────────────────────────────────────────────────
  Widget _buildIosWheelPicker(TimerItemModel timer, VisualTimerService service, {bool isCompact = false}) {
    return Container(
      height: isCompact ? 160 : 190,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orta Seçim Vurgu Çubuğu
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // 3 Kolonlu Çark
          Row(
            children: [
              // Kolon 1: Saat (0 - 23)
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: timer.hours),
                  onSelectedItemChanged: (h) {
                    service.setTimer1Time(h, timer.minutes, timer.seconds);
                  },
                  selectionOverlay: const SizedBox.shrink(),
                  children: List.generate(24, (i) {
                    return Center(
                      child: Text(
                        '$i saat',
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontSize: isCompact ? 16 : 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Kolon 2: Dakika (0 - 59)
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: timer.minutes),
                  onSelectedItemChanged: (m) {
                    service.setTimer1Time(timer.hours, m, timer.seconds);
                  },
                  selectionOverlay: const SizedBox.shrink(),
                  children: List.generate(60, (i) {
                    return Center(
                      child: Text(
                        '$i dk.',
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontSize: isCompact ? 16 : 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Kolon 3: Saniye (0 - 59)
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: timer.seconds),
                  onSelectedItemChanged: (s) {
                    service.setTimer1Time(timer.hours, timer.minutes, s);
                  },
                  selectionOverlay: const SizedBox.shrink(),
                  children: List.generate(60, (i) {
                    return Center(
                      child: Text(
                        '$i sn.',
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontSize: isCompact ? 16 : 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GÖRSEL GERİ SAYIM ALANI (Dairesel Saat veya Dikey Sütun)
  // ─────────────────────────────────────────────────────────────
  Widget _buildVisualCountDown(TimerItemModel timer, VisualTimerService service, {bool isCompact = false}) {
    final progress = timer.progress;
    final primaryColor = _getTimerColor(progress);
    final size = isCompact ? 180.0 : 220.0;

    if (timer.visualStyle == 'column') {
      // 🧪 DİKEY SÜTUN GÖRÜNÜMÜ
      return Container(
        height: size,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dikey Sütun / Tüp
            SizedBox(
              width: 55,
              height: size - 16,
              child: CustomPaint(
                painter: VisualColumnPainter(
                  progress: progress,
                  primaryColor: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Dijital Sayaç & Bilgiler
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timer.formattedTime,
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: isCompact ? 32 : 40,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Kalan: %${(progress * 100).toInt()}',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (timer.endTime != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Bitiş: ${timer.endTime!.hour.toString().padLeft(2, '0')}:${timer.endTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    // 🕒 DAİRESEL SAAT GÖRÜNÜMÜ (Analog Disk ve Radyal İlerleme)
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final isPulsing = timer.remainingSeconds <= 10 && timer.isRunning;
          return Transform.scale(
            scale: isPulsing ? _pulseAnimation.value : 1.0,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: VisualClockPainter(
                      progress: progress,
                      primaryColor: primaryColor,
                      isAlarm: timer.isAlarmActive,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timer.formattedTime,
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontSize: isCompact ? 30 : 38,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '%${(progress * 100).toInt()}',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (timer.endTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Bitiş: ${timer.endTime!.hour.toString().padLeft(2, '0')}:${timer.endTime!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // YUVARLAK KONTROL BUTONLARI (Vazgeç & Başlat)
  // ─────────────────────────────────────────────────────────────
  Widget _buildIosCircularButtons(TimerItemModel timer, VisualTimerService service, {bool isCompact = false}) {
    final isRunning = timer.isRunning;
    final isPaused = !timer.isRunning && timer.remainingSeconds < timer.totalSeconds && timer.remainingSeconds > 0;
    final buttonSize = isCompact ? 64.0 : 76.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // SOL BUTON: Vazgeç / Sıfırla (Beyaz / Açık Gri Yuvarlak Buton)
        GestureDetector(
          onTap: () {
            service.resetTimerItem(timer);
          },
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF1F5F9),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Vazgeç',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Sıfırla',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // SAĞ BUTON: Başlat / Duraklat / Sürdür (Yeşil veya Turuncu Yuvarlak Buton)
        GestureDetector(
          onTap: () {
            service.toggleTimerItem(timer);
          },
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning
                  ? const Color(0xFFFFEDD5) // Açık Turuncu (Duraklat arka planı)
                  : const Color(0xFFDCFCE7), // Açık Yeşil (Başlat arka planı)
              border: Border.all(
                color: isRunning
                    ? const Color(0xFFFB923C)
                    : const Color(0xFF4ADE80),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                isRunning ? 'Duraklat' : (isPaused ? 'Sürdür' : 'Başlat'),
                style: TextStyle(
                  color: isRunning ? const Color(0xFFC2410C) : const Color(0xFF15803D),
                  fontSize: isCompact ? 13 : 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AYARLAR KUTUSU (Etiket & Sayaç Bitince)
  // ─────────────────────────────────────────────────────────────
  Widget _buildIosSettingsGroup(TimerItemModel timer, VisualTimerService service) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // 1. Satır: Etiket
          InkWell(
            onTap: () => _showLabelEditDialog(timer, service),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Etiket',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Text(
                        timer.label,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 16),

          // 2. Satır: Sayaç Bitince (Müzik Seçimi)
          InkWell(
            onTap: () => _showSoundPickerSheet(timer, service),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sayaç Bitince',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Text(
                        timer.soundTitle,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MODAL VE DİYALOGLAR (Etiket & Müzik Seçimi)
  // ─────────────────────────────────────────────────────────────

  void _showLabelEditDialog(TimerItemModel timer, VisualTimerService service) {
    final controller = TextEditingController(text: timer.label);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sayaç Etiketi', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Color(0xFF0F172A)),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Örn: Ders, Mola, Oyun...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: ['Ders', 'Mola', 'Oyun', 'Ödev', 'Diş', 'Yemek'].map((sug) {
                return ActionChip(
                  label: Text(sug, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  onPressed: () {
                    controller.text = sug;
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              service.setTimerLabel(timer, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showSoundPickerSheet(TimerItemModel timer, VisualTimerService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sayaç Bitince Çalacak Müzik',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
                          onPressed: () {
                            service.stopPreviewSound();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: kAvailableSounds.length,
                      separatorBuilder: (_, _) => const Divider(color: Color(0xFFE2E8F0), height: 1),
                      itemBuilder: (context, index) {
                        final sound = kAvailableSounds[index];
                        final isSelected = timer.soundKey == sound.key;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            foregroundColor: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                            child: Icon(sound.icon, size: 20),
                          ),
                          title: Text(
                            sound.title,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            sound.description,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF2563EB), size: 28),
                                tooltip: 'Dinle / Önizle',
                                onPressed: () {
                                  service.previewSound(sound);
                                },
                              ),
                              if (isSelected)
                                const Icon(Icons.check_rounded, color: Color(0xFF16A34A)),
                            ],
                          ),
                          onTap: () {
                            service.setTimerSound(timer, sound.key, sound.title);
                            setSheetState(() {});
                            service.previewSound(sound);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      service.stopPreviewSound();
    });
  }
}

// ─────────────────────────────────────────────────────────────
// DAİRESEL SAAT ÇİZİCİ (CUSTOM PAINTER - BEYAZ TEMA)
// ─────────────────────────────────────────────────────────────
class VisualClockPainter extends CustomPainter {
  final double progress; // 1.0 -> 0.0
  final Color primaryColor;
  final bool isAlarm;

  VisualClockPainter({
    required this.progress,
    required this.primaryColor,
    this.isAlarm = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Kadran Çizgileri (60 dakika / saniye çentikleri)
    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 8.0 : 4.0;
      tickPaint.strokeWidth = isMajor ? 2.0 : 1.0;
      tickPaint.color = isMajor ? const Color(0xFF64748B) : const Color(0xFFCBD5E1);

      final outer = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      final inner = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );
      canvas.drawLine(outer, inner, tickPaint);
    }

    // 2. Arka Plan Rayı (Açık gri ray)
    final trackRadius = radius - 16;
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    canvas.drawCircle(center, trackRadius, trackPaint);

    // 3. Azalan Radyal Süpürme (İlerleme Yayı ve İçi)
    if (progress > 0) {
      const startAngle = -pi / 2; // Saat 12 yönünden başla
      final sweepAngle = 2 * pi * progress;

      // İç yumuşak renkli pasta dilimi
      final sectorPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius - 6),
        startAngle,
        sweepAngle,
        true,
        sectorPaint,
      );

      // Ana renkli çember yayı
      final arcPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12.0;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VisualClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isAlarm != isAlarm;
  }
}

// ─────────────────────────────────────────────────────────────
// DİKEY SÜTUN ÇİZİCİ (CUSTOM PAINTER - BEYAZ TEMA)
// ─────────────────────────────────────────────────────────────
class VisualColumnPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  VisualColumnPainter({
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2));

    // Tüp Arka Planı (Açık Gri)
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRRect(rrect, bgPaint);

    // Dış Çerçeve
    final borderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // Sıvı Seviyesi (Alttan Yukarıya Doğru Dolar/Boşalır)
    if (progress > 0) {
      final fillHeight = size.height * progress;
      final fillRect = Rect.fromLTWH(
        0,
        size.height - fillHeight,
        size.width,
        fillHeight,
      );
      final fillRRect = RRect.fromRectAndCorners(
        fillRect,
        bottomLeft: Radius.circular(size.width / 2),
        bottomRight: Radius.circular(size.width / 2),
        topLeft: progress >= 0.98 ? Radius.circular(size.width / 2) : const Radius.circular(6),
        topRight: progress >= 0.98 ? Radius.circular(size.width / 2) : const Radius.circular(6),
      );

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
        ).createShader(fillRect);

      canvas.drawRRect(fillRRect, fillPaint);
    }

    // Seviye Çentikleri
    final tickPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.5;

    for (int p = 1; p <= 3; p++) {
      final y = size.height * (p / 4);
      canvas.drawLine(
        Offset(size.width - 10, y),
        Offset(size.width - 2, y),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VisualColumnPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.primaryColor != primaryColor;
  }
}
