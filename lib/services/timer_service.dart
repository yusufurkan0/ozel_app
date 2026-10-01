import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'tts_service.dart';

/// Tek bir sayacın durumunu ve ayarlarını tutan sınıf.
class TimerItemModel {
  final String id;
  String label;
  int hours;
  int minutes;
  int seconds;
  int totalSeconds;
  int remainingSeconds;
  bool isRunning;
  bool isAlarmActive;
  DateTime? endTime;
  String soundKey;
  String soundTitle;
  String? customAudioPath;
  String visualStyle; // 'circle' veya 'column'

  TimerItemModel({
    required this.id,
    this.label = 'Sayaç',
    this.hours = 0,
    this.minutes = 5,
    this.seconds = 0,
    int? totalSeconds,
    int? remainingSeconds,
    this.isRunning = false,
    this.isAlarmActive = false,
    this.endTime,
    this.soundKey = 'radial',
    this.soundTitle = 'Radyal',
    this.customAudioPath,
    this.visualStyle = 'circle',
  })  : totalSeconds = totalSeconds ?? ((hours * 3600) + (minutes * 60) + seconds),
        remainingSeconds = remainingSeconds ?? (totalSeconds ?? ((hours * 3600) + (minutes * 60) + seconds));

  double get progress => totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

  String get formattedTime {
    final h = remainingSeconds ~/ 3600;
    final m = (remainingSeconds % 3600) ~/ 60;
    final s = remainingSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void setTime(int h, int m, int s) {
    hours = h;
    minutes = m;
    seconds = s;
    totalSeconds = (h * 3600) + (m * 60) + s;
    if (totalSeconds <= 0) totalSeconds = 60; // minimum 1 dakika
    remainingSeconds = totalSeconds;
    isRunning = false;
    isAlarmActive = false;
    endTime = null;
  }
}

/// Kullanılabilir Alarm / Müzik Seçenekleri
class SoundOption {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final String? assetPath;

  const SoundOption({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    this.assetPath,
  });
}

const List<SoundOption> kAvailableSounds = [
  SoundOption(
    key: 'radial',
    title: 'Radyal (Klasik Melodi)',
    description: 'Yumuşak ve net modern melodi',
    icon: Icons.graphic_eq_rounded,
    assetPath: 'sounds/muzik.wav',
  ),
  SoundOption(
    key: 'buzzer',
    title: 'Buzzer (Zil Sesi)',
    description: 'Yüksek sesli dikkat çekici alarm',
    icon: Icons.notifications_active_rounded,
    assetPath: 'sounds/alarm_buzzer.wav',
  ),
  SoundOption(
    key: 'game',
    title: 'Neşeli Oyun Müziği',
    description: 'Eğlenceli ve çocuk dostu müzik',
    icon: Icons.sports_esports_rounded,
    assetPath: 'sounds/oyun.wav',
  ),
  SoundOption(
    key: 'chime',
    title: 'Ding & Çan Sesi',
    description: 'Berrak çan uyarısı',
    icon: Icons.music_note_rounded,
    assetPath: 'sounds/tuvalet.wav',
  ),
  SoundOption(
    key: 'sleep',
    title: 'Sakin Melodi',
    description: 'Huzurlu ve sakinleştirici tını',
    icon: Icons.bedtime_rounded,
    assetPath: 'sounds/uyku.wav',
  ),
];

/// Arka planda ve uygulama gezinmelerinde kesintisiz çalışan,
/// 1 veya 2 bağımsız sayacı yönetebilen görsel zamanlayıcı servisi.
class VisualTimerService extends ChangeNotifier with WidgetsBindingObserver {
  static final VisualTimerService instance = VisualTimerService._internal();

  factory VisualTimerService() => instance;

  VisualTimerService._internal() {
    WidgetsBinding.instance.addObserver(this);
    loadState();
  }

  // Sayaç 1 (Ana Sayaç)
  final TimerItemModel timer1 = TimerItemModel(
    id: 'timer_1',
    label: 'Sayaç 1',
    hours: 0,
    minutes: 5,
    seconds: 0,
  );

  // Sayaç 2 (İsteğe bağlı İkincil Sayaç)
  final TimerItemModel timer2 = TimerItemModel(
    id: 'timer_2',
    label: 'Sayaç 2',
    hours: 0,
    minutes: 10,
    seconds: 0,
  );

  bool _isDualMode = false;
  bool _isSideBySideLayout = false;

  bool get isDualMode => _isDualMode;
  bool get isSideBySideLayout => _isSideBySideLayout;

  AudioPlayer? _audioPlayer;
  AudioPlayer? _audioPlayerPreview;
  Timer? _tickerTimer;
  Timer? _vibrationTimer;

  // ─── Geriye Dönük Uyumluluk (VisualTimerService.instance erişimleri için) ───
  int get totalSeconds => timer1.totalSeconds;
  int get remainingSeconds => timer1.remainingSeconds;
  bool get isRunning => timer1.isRunning;
  bool get isAlarmActive => timer1.isAlarmActive || timer2.isAlarmActive;
  DateTime? get endTime => timer1.endTime;
  double get progress => timer1.progress;
  String get formattedTime => timer1.formattedTime;

  void setDualMode(bool enabled) {
    _isDualMode = enabled;
    _saveState();
    notifyListeners();
  }

  void toggleDualMode() {
    setDualMode(!_isDualMode);
  }

  void setSideBySideLayout(bool sideBySide) {
    _isSideBySideLayout = sideBySide;
    _saveState();
    notifyListeners();
  }

  // ─── Sayaç 1 Ayarlama ve Kontrol ───
  void setMinutes(int minutes) {
    final clamped = minutes.clamp(1, 1440);
    stopAlarm();
    timer1.setTime(clamped ~/ 60, clamped % 60, 0);
    _saveState();
    _speak('${timer1.label} için $clamped dakika ayarlandı.');
    notifyListeners();
  }

  void adjustMinutes(int delta) {
    final currentMins = (timer1.totalSeconds ~/ 60) + delta;
    setMinutes(currentMins);
  }

  void setTimer1Time(int h, int m, int s) {
    stopAlarmForTimer(timer1);
    timer1.setTime(h, m, s);
    _saveState();
    notifyListeners();
  }

  void setTimer2Time(int h, int m, int s) {
    stopAlarmForTimer(timer2);
    timer2.setTime(h, m, s);
    _saveState();
    notifyListeners();
  }

  void startTimer() => startTimerItem(timer1);
  void pauseTimer() => pauseTimerItem(timer1);
  void toggleTimer() => toggleTimerItem(timer1);
  void resetTimer() => resetTimerItem(timer1);

  void startTimer2() => startTimerItem(timer2);
  void pauseTimer2() => pauseTimerItem(timer2);
  void toggleTimer2() => toggleTimerItem(timer2);
  void resetTimer2() => resetTimerItem(timer2);

  void startTimerItem(TimerItemModel timer) {
    stopAlarmForTimer(timer);
    if (timer.remainingSeconds <= 0) {
      timer.remainingSeconds = timer.totalSeconds;
    }
    timer.isRunning = true;
    timer.endTime = DateTime.now().add(Duration(seconds: timer.remainingSeconds));
    _saveState();
    _ensureTickerRunning();

    final mins = timer.remainingSeconds ~/ 60;
    final secs = timer.remainingSeconds % 60;
    if (mins > 0) {
      _speak('${timer.label} $mins dakika süre başladı!');
    } else {
      _speak('${timer.label} $secs saniye süre başladı!');
    }
    notifyListeners();
  }

  void pauseTimerItem(TimerItemModel timer) {
    if (!timer.isRunning) return;
    timer.isRunning = false;
    timer.endTime = null;
    _saveState();
    _checkTickerNeeded();
    _speak('${timer.label} duraklatıldı.');
    notifyListeners();
  }

  void toggleTimerItem(TimerItemModel timer) {
    if (timer.isRunning) {
      pauseTimerItem(timer);
    } else {
      startTimerItem(timer);
    }
  }

  void resetTimerItem(TimerItemModel timer) {
    stopAlarmForTimer(timer);
    timer.remainingSeconds = timer.totalSeconds;
    timer.isRunning = false;
    timer.endTime = null;
    _saveState();
    _checkTickerNeeded();
    _speak('${timer.label} sıfırlandı.');
    notifyListeners();
  }

  void setTimerSound(TimerItemModel timer, String soundKey, String soundTitle, {String? customPath}) {
    timer.soundKey = soundKey;
    timer.soundTitle = soundTitle;
    timer.customAudioPath = customPath;
    _saveState();
    notifyListeners();
  }

  void setTimerLabel(TimerItemModel timer, String newLabel) {
    timer.label = newLabel.trim().isEmpty ? 'Sayaç' : newLabel.trim();
    _saveState();
    notifyListeners();
  }

  void setTimerVisualStyle(TimerItemModel timer, String style) {
    timer.visualStyle = style;
    _saveState();
    notifyListeners();
  }

  // ─── Ticker ve Süre Takibi ───
  void _ensureTickerRunning() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _checkTickerNeeded() {
    if (!timer1.isRunning && !timer2.isRunning) {
      _tickerTimer?.cancel();
      _tickerTimer = null;
    }
  }

  void _tick() {
    final now = DateTime.now();
    bool stateChanged = false;

    for (final t in [timer1, timer2]) {
      if (t.isRunning && t.endTime != null) {
        final diff = t.endTime!.difference(now).inSeconds;
        if (diff > 0) {
          t.remainingSeconds = diff;
          stateChanged = true;
          if (t.remainingSeconds == 60) {
            _speak('${t.label} son 1 dakika kaldı!');
          } else if (t.remainingSeconds == 10) {
            _speak('${t.label} son 10 saniye!');
          }
        } else {
          // Süre Doldu!
          t.remainingSeconds = 0;
          t.isRunning = false;
          t.isAlarmActive = true;
          t.endTime = null;
          stateChanged = true;
          _triggerAlarm(t);
        }
      }
    }

    if (stateChanged) {
      _saveState();
      notifyListeners();
    }
    _checkTickerNeeded();
  }

  // ─── Alarm & Müzik Çalma ───
  void _triggerAlarm(TimerItemModel timer) {
    _startAlarmLoop(timer);
    _speak('${timer.label} süresi doldu! Zaman tamamlandı.');
  }

  void _startAlarmLoop(TimerItemModel timer) {
    _vibrationTimer?.cancel();
    _vibrateStep();

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!isAlarmActive) {
        _vibrationTimer?.cancel();
        return;
      }
      _vibrateStep();
    });

    _playAlarmSound(timer);
  }

  void _vibrateStep() {
    try {
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> _playAlarmSound(TimerItemModel timer) async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);

      if (timer.customAudioPath != null && timer.customAudioPath!.isNotEmpty) {
        await _audioPlayer!.play(DeviceFileSource(timer.customAudioPath!));
        return;
      }

      final matched = kAvailableSounds.firstWhere(
        (s) => s.key == timer.soundKey,
        orElse: () => kAvailableSounds.first,
      );

      if (matched.assetPath != null) {
        await _audioPlayer!.play(AssetSource(matched.assetPath!));
      } else {
        await _audioPlayer!.play(AssetSource('sounds/alarm_buzzer.wav'));
      }
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  Future<void> previewSound(SoundOption sound) async {
    try {
      _audioPlayerPreview?.stop();
      _audioPlayerPreview = AudioPlayer();
      await _audioPlayerPreview!.setReleaseMode(ReleaseMode.release);
      await _audioPlayerPreview!.setVolume(1.0);
      if (sound.assetPath != null) {
        await _audioPlayerPreview!.play(AssetSource(sound.assetPath!));
      }
    } catch (_) {}
  }

  void stopPreviewSound() {
    try {
      _audioPlayerPreview?.stop();
    } catch (_) {}
  }

  void stopAlarmForTimer(TimerItemModel timer) {
    timer.isAlarmActive = false;
    if (!isAlarmActive) {
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
      try {
        _audioPlayer?.stop();
      } catch (_) {}
      try {
        TtsService().stop();
      } catch (_) {}
    }
    _saveState();
    notifyListeners();
  }

  void stopAlarm() => stopAllAlarms();

  void stopAllAlarms() {
    timer1.isAlarmActive = false;
    timer2.isAlarmActive = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      _audioPlayer?.stop();
    } catch (_) {}
    try {
      TtsService().stop();
    } catch (_) {}
    _saveState();
    notifyListeners();
  }

  void _speak(String text) {
    try {
      TtsService().speak(text);
    } catch (_) {}
  }

  // ─── Kalıcılık (SharedPreferences) ───
  Future<void> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDualMode = prefs.getBool('visual_timer_dual_mode') ?? false;
      _isSideBySideLayout = prefs.getBool('visual_timer_side_by_side') ?? false;

      // Timer 1
      timer1.label = prefs.getString('timer1_label') ?? 'Sayaç 1';
      timer1.totalSeconds = prefs.getInt('visual_timer_total_seconds') ?? 300;
      timer1.soundKey = prefs.getString('timer1_sound_key') ?? 'radial';
      timer1.soundTitle = prefs.getString('timer1_sound_title') ?? 'Radyal';
      timer1.visualStyle = prefs.getString('timer1_visual_style') ?? 'circle';
      timer1.hours = timer1.totalSeconds ~/ 3600;
      timer1.minutes = (timer1.totalSeconds % 3600) ~/ 60;
      timer1.seconds = timer1.totalSeconds % 60;

      final endEpoch1 = prefs.getInt('visual_timer_end_epoch');
      if (endEpoch1 != null && endEpoch1 > 0) {
        timer1.endTime = DateTime.fromMillisecondsSinceEpoch(endEpoch1);
        final now = DateTime.now();
        if (now.isAfter(timer1.endTime!)) {
          timer1.remainingSeconds = 0;
          timer1.isRunning = false;
          timer1.isAlarmActive = true;
          _triggerAlarm(timer1);
        } else {
          timer1.remainingSeconds = timer1.endTime!.difference(now).inSeconds;
          timer1.isRunning = true;
          _ensureTickerRunning();
        }
      } else {
        timer1.remainingSeconds = prefs.getInt('visual_timer_remaining_seconds') ?? timer1.totalSeconds;
        timer1.isRunning = prefs.getBool('visual_timer_is_running') ?? false;
      }

      // Timer 2
      timer2.label = prefs.getString('timer2_label') ?? 'Sayaç 2';
      timer2.totalSeconds = prefs.getInt('timer2_total_seconds') ?? 600;
      timer2.soundKey = prefs.getString('timer2_sound_key') ?? 'buzzer';
      timer2.soundTitle = prefs.getString('timer2_sound_title') ?? 'Buzzer';
      timer2.visualStyle = prefs.getString('timer2_visual_style') ?? 'circle';
      timer2.hours = timer2.totalSeconds ~/ 3600;
      timer2.minutes = (timer2.totalSeconds % 3600) ~/ 60;
      timer2.seconds = timer2.totalSeconds % 60;

      final endEpoch2 = prefs.getInt('timer2_end_epoch');
      if (endEpoch2 != null && endEpoch2 > 0) {
        timer2.endTime = DateTime.fromMillisecondsSinceEpoch(endEpoch2);
        final now = DateTime.now();
        if (now.isAfter(timer2.endTime!)) {
          timer2.remainingSeconds = 0;
          timer2.isRunning = false;
          timer2.isAlarmActive = true;
          _triggerAlarm(timer2);
        } else {
          timer2.remainingSeconds = timer2.endTime!.difference(now).inSeconds;
          timer2.isRunning = true;
          _ensureTickerRunning();
        }
      } else {
        timer2.remainingSeconds = prefs.getInt('timer2_remaining_seconds') ?? timer2.totalSeconds;
        timer2.isRunning = prefs.getBool('timer2_is_running') ?? false;
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('visual_timer_dual_mode', _isDualMode);
      await prefs.setBool('visual_timer_side_by_side', _isSideBySideLayout);

      // Timer 1
      await prefs.setString('timer1_label', timer1.label);
      await prefs.setInt('visual_timer_total_seconds', timer1.totalSeconds);
      await prefs.setInt('visual_timer_remaining_seconds', timer1.remainingSeconds);
      await prefs.setBool('visual_timer_is_running', timer1.isRunning);
      await prefs.setBool('visual_timer_is_alarm_active', timer1.isAlarmActive);
      await prefs.setString('timer1_sound_key', timer1.soundKey);
      await prefs.setString('timer1_sound_title', timer1.soundTitle);
      await prefs.setString('timer1_visual_style', timer1.visualStyle);
      if (timer1.endTime != null) {
        await prefs.setInt('visual_timer_end_epoch', timer1.endTime!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('visual_timer_end_epoch');
      }

      // Timer 2
      await prefs.setString('timer2_label', timer2.label);
      await prefs.setInt('timer2_total_seconds', timer2.totalSeconds);
      await prefs.setInt('timer2_remaining_seconds', timer2.remainingSeconds);
      await prefs.setBool('timer2_is_running', timer2.isRunning);
      await prefs.setBool('timer2_is_alarm_active', timer2.isAlarmActive);
      await prefs.setString('timer2_sound_key', timer2.soundKey);
      await prefs.setString('timer2_sound_title', timer2.soundTitle);
      await prefs.setString('timer2_visual_style', timer2.visualStyle);
      if (timer2.endTime != null) {
        await prefs.setInt('timer2_end_epoch', timer2.endTime!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('timer2_end_epoch');
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      bool changed = false;

      for (final t in [timer1, timer2]) {
        if (t.isRunning && t.endTime != null) {
          if (now.isAfter(t.endTime!)) {
            t.remainingSeconds = 0;
            t.isRunning = false;
            t.isAlarmActive = true;
            t.endTime = null;
            changed = true;
            _triggerAlarm(t);
          } else {
            t.remainingSeconds = t.endTime!.difference(now).inSeconds;
            changed = true;
          }
        }
      }
      if (changed) {
        _saveState();
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    _vibrationTimer?.cancel();
    try {
      _audioPlayer?.dispose();
      _audioPlayerPreview?.dispose();
    } catch (_) {}
    super.dispose();
  }
}
