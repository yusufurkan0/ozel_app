import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/kitchen_recipe.dart';
import '../../theme/app_theme.dart';

class CookingStepByStepScreen extends StatefulWidget {
  final KitchenRecipe recipe;
  final int initialStep;

  const CookingStepByStepScreen({
    super.key,
    required this.recipe,
    this.initialStep = 0,
  });

  @override
  State<CookingStepByStepScreen> createState() => _CookingStepByStepScreenState();
}

class _CookingStepByStepScreenState extends State<CookingStepByStepScreen> {
  late int _currentStepIndex;
  final FlutterTts _tts = FlutterTts();
  bool _autoTts = true;
  bool _isSpeaking = false;

  // Kronometre Durumu
  Timer? _stepTimer;
  int _timerRemainingSeconds = 0;
  int _timerTotalSeconds = 0;
  bool _isTimerRunning = false;
  bool _timerCompleted = false;

  @override
  void initState() {
    super.initState();
    _currentStepIndex = widget.initialStep.clamp(0, widget.recipe.steps.length - 1);
    _initTts();
    _setupStepTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoTts) {
        _speakCurrentStep();
      }
    });
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  void _setupStepTimer() {
    _stepTimer?.cancel();
    final step = widget.recipe.steps[_currentStepIndex];
    if (step.timerSeconds != null && step.timerSeconds! > 0) {
      setState(() {
        _timerTotalSeconds = step.timerSeconds!;
        _timerRemainingSeconds = step.timerSeconds!;
        _isTimerRunning = false;
        _timerCompleted = false;
      });
    } else {
      setState(() {
        _timerTotalSeconds = 0;
        _timerRemainingSeconds = 0;
        _isTimerRunning = false;
        _timerCompleted = false;
      });
    }
  }

  void _startTimer() {
    if (_timerRemainingSeconds <= 0) return;
    _stepTimer?.cancel();
    setState(() {
      _isTimerRunning = true;
      _timerCompleted = false;
    });

    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerRemainingSeconds > 1) {
        setState(() {
          _timerRemainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _timerRemainingSeconds = 0;
          _isTimerRunning = false;
          _timerCompleted = true;
        });
        _onTimerFinished();
      }
    });
  }

  void _pauseTimer() {
    _stepTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _stepTimer?.cancel();
    final step = widget.recipe.steps[_currentStepIndex];
    setState(() {
      _timerRemainingSeconds = step.timerSeconds ?? 0;
      _isTimerRunning = false;
      _timerCompleted = false;
    });
  }

  void _addTimerTime(int seconds) {
    setState(() {
      _timerRemainingSeconds += seconds;
      _timerTotalSeconds += seconds;
      _timerCompleted = false;
    });
  }

  void _onTimerFinished() async {
    _speak('Süre doldu! Harika, şimdi sıradaki adıma geçebilirsin.');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.alarm_on_rounded, color: Colors.green, size: 32),
            SizedBox(width: 10),
            Text('Süre Doldu!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Tebrikler! Belirlenen süre tamamlandı. Bir sonraki adıma geçmeye hazırsın.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _nextStep();
            },
            child: const Text('Sıradaki Adıma Geç ▶'),
          ),
        ],
      ),
    );
  }

  void _speak(String text) async {
    try {
      setState(() => _isSpeaking = true);
      await _tts.speak(text);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _speakCurrentStep() {
    final step = widget.recipe.steps[_currentStepIndex];
    String text = 'Adım ${step.stepNumber}. ${step.instruction}';
    if (step.tip != null && step.tip!.isNotEmpty) {
      text += ' İpucu: ${step.tip}';
    }
    if (step.timerSeconds != null) {
      final mins = (step.timerSeconds! / 60).round();
      text += ' Bu adım için $mins dakika bekleme sayacı bulunmaktadır.';
    }
    _speak(text);
  }

  void _stopTts() async {
    try {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } catch (_) {}
  }

  void _nextStep() {
    _stopTts();
    _stepTimer?.cancel();
    if (_currentStepIndex < widget.recipe.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _setupStepTimer();
      if (_autoTts) {
        _speakCurrentStep();
      }
    } else {
      _showRecipeCompletedDialog();
    }
  }

  void _prevStep() {
    _stopTts();
    _stepTimer?.cancel();
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _setupStepTimer();
      if (_autoTts) {
        _speakCurrentStep();
      }
    }
  }

  void _showRecipeCompletedDialog() {
    _speak('Tebrikler! Tarifin tüm adımlarını başarıyla tamamladın! Afiyet olsun!');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/lezzet/crouton_bread.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Afiyet Olsun! 🌟',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: widget.recipe.themeColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.recipe.title} başarıyla hazırlandı!',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (widget.recipe.chefTips.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Aklınızda Bulunsun (Püf Noktaları)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...widget.recipe.chefTips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(tip, style: const TextStyle(fontSize: 13, height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _currentStepIndex = 0;
                      });
                      _setupStepTimer();
                    },
                    child: const Text('Baştan Başla 🔄'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.recipe.themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('Tamamla & Çık 👏'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.recipe.steps.length;
    final currentStep = widget.recipe.steps[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipe.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Lezzet +1 Adım Adım Rehberi',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _autoTts ? 'Otomatik Seslendirme Açık' : 'Otomatik Seslendirme Kapalı',
            icon: Icon(
              _autoTts ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
              color: _autoTts ? widget.recipe.themeColor : Colors.grey,
            ),
            onPressed: () {
              setState(() => _autoTts = !_autoTts);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(widget.recipe.themeColor),
            minHeight: 6,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Üst Sayaç ve Bilgi Şeridi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.recipe.themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.directions_walk_rounded, color: widget.recipe.themeColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Adım ${_currentStepIndex + 1} / $totalSteps',
                          style: TextStyle(
                            color: widget.recipe.themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '%${(progress * 100).toInt()} Tamamlandı',
                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Adım Detay Kartı
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ana Adım Kartı
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Adım Görseli / Fotoğrafı (Görsel Anlatım)
                          if (currentStep.imagePath != null) ...[
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 260),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.recipe.themeColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  currentStep.imagePath!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 120,
                                    alignment: Alignment.center,
                                    color: widget.recipe.themeColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      currentStep.icon,
                                      color: widget.recipe.themeColor,
                                      size: 56,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ] else ...[
                            // Büyük İkon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: widget.recipe.themeColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                currentStep.icon,
                                color: widget.recipe.themeColor,
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Talimat Metni
                          Text(
                            currentStep.instruction,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),

                          // İpucu veya Güvenlik Uyarısı Varsa
                          if (currentStep.tip != null && currentStep.tip!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      currentStep.tip!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Zamanlayıcı (Timer) Varsa Kart
                    if (currentStep.timerSeconds != null && currentStep.timerSeconds! > 0) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _timerCompleted
                                ? Colors.green.shade400
                                : _isTimerRunning
                                    ? Colors.orange.shade400
                                    : Colors.blue.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _timerCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.timer_outlined,
                                  color: _timerCompleted
                                      ? Colors.green
                                      : _isTimerRunning
                                          ? Colors.orange
                                          : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentStep.timerLabel ?? 'Bu Adım İçin Sayaç',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                if (_timerCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Tamamlandı 🎉',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Geri Sayım Süre Göstergesi
                            Text(
                              _formatTime(_timerRemainingSeconds),
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: _timerCompleted
                                    ? Colors.green
                                    : _isTimerRunning
                                        ? Colors.orange.shade800
                                        : Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isTimerRunning
                                  ? 'Geri sayım devam ediyor...'
                                  : _timerCompleted
                                      ? 'Süre doldu! Sıradaki adıma geçebilirsin.'
                                      : 'Sayacı başlatmak için butona bas',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),

                            // Sayaç Butonları
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!_isTimerRunning && !_timerCompleted) ...[
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                                    label: const Text('Sayacı Başlat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    onPressed: _startTimer,
                                  ),
                                ] else if (_isTimerRunning) ...[
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.pause_rounded, size: 22),
                                    label: const Text('Duraklat'),
                                    onPressed: _pauseTimer,
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.restart_alt_rounded, size: 20),
                                    label: const Text('Sıfırla'),
                                    onPressed: _resetTimer,
                                  ),
                                ] else ...[
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.replay_rounded),
                                    label: const Text('Yeniden Başlat'),
                                    onPressed: _resetTimer,
                                  ),
                                ],
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: '+1 Dakika Ekle',
                                  icon: const Icon(Icons.add_alarm_rounded, color: Colors.blueGrey),
                                  onPressed: () => _addTimerTime(60),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Alt Navigasyon Çubuğu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              child: Row(
                children: [
                  // Önceki Adım
                  if (_currentStepIndex > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                        label: const Text('Önceki', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _prevStep,
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  if (_currentStepIndex > 0) const SizedBox(width: 10),

                  // Sesli Oku Butonu
                  Container(
                    decoration: BoxDecoration(
                      color: _isSpeaking ? Colors.orange.shade100 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: _isSpeaking ? Colors.orange.shade800 : AppColors.buttonIndigo,
                        size: 26,
                      ),
                      tooltip: 'Sesli Dinle',
                      onPressed: _isSpeaking ? _stopTts : _speakCurrentStep,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Sonraki / Tamamla Butonu
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.recipe.themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(
                        _currentStepIndex == totalSteps - 1
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _currentStepIndex == totalSteps - 1 ? 'Tarifi Tamamla 🎉' : 'Sıradaki Adım ▶',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _nextStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
