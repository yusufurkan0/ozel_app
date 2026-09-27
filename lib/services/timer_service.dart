import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'tts_service.dart';

/// Arka planda ve uygulama gezinmelerinde kesintisiz çalışan,
/// süre bitince titreşim ve yüksek sesli alarm çalan görsel zamanlayıcı servisi.
class VisualTimerService extends ChangeNotifier with WidgetsBindingObserver {
  static final VisualTimerService instance = VisualTimerService._internal();

  factory VisualTimerService() => instance;

  VisualTimerService._internal() {
    WidgetsBinding.instance.addObserver(this);
    loadState();
  }

  static const String _prefTotalSeconds = 'visual_timer_total_seconds';
  static const String _prefEndEpoch = 'visual_timer_end_epoch';
  static const String _prefRemainingSeconds = 'visual_timer_remaining_seconds';
  static const String _prefIsRunning = 'visual_timer_is_running';
  static const String _prefIsAlarmActive = 'visual_timer_is_alarm_active';

  AudioPlayer? _audioPlayer;

  Timer? _tickerTimer;
  Timer? _vibrationTimer;

  int _totalSeconds = 300; // Varsayılan 5 dakika
  int _remainingSeconds = 300;
  bool _isRunning = false;
  bool _isAlarmActive = false;
  DateTime? _endTime;

  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isAlarmActive => _isAlarmActive;
  DateTime? get endTime => _endTime;

  double get progress => _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0) : 0.0;

  String get formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalSeconds = prefs.getInt(_prefTotalSeconds) ?? 300;
      _isRunning = prefs.getBool(_prefIsRunning) ?? false;
      _isAlarmActive = prefs.getBool(_prefIsAlarmActive) ?? false;

      final endEpoch = prefs.getInt(_prefEndEpoch);
      if (endEpoch != null && endEpoch > 0) {
        _endTime = DateTime.fromMillisecondsSinceEpoch(endEpoch);
      }

      if (_isRunning && _endTime != null) {
        final now = DateTime.now();
        if (now.isAfter(_endTime!)) {
          // Süre arka plandayken veya uygulama kapalıyken bitmiş
          _remainingSeconds = 0;
          _isRunning = false;
          _isAlarmActive = true;
          await _saveState();
          _startAlarmLoop();
        } else {
          // Hâlâ çalışıyor
          _remainingSeconds = _endTime!.difference(now).inSeconds;
          _startTicker();
        }
      } else {
        _remainingSeconds = prefs.getInt(_prefRemainingSeconds) ?? _totalSeconds;
        if (_isAlarmActive) {
          _startAlarmLoop();
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefTotalSeconds, _totalSeconds);
      await prefs.setInt(_prefRemainingSeconds, _remainingSeconds);
      await prefs.setBool(_prefIsRunning, _isRunning);
      await prefs.setBool(_prefIsAlarmActive, _isAlarmActive);
      if (_endTime != null) {
        await prefs.setInt(_prefEndEpoch, _endTime!.millisecondsSinceEpoch);
      } else {
        await prefs.remove(_prefEndEpoch);
      }
    } catch (_) {}
  }

  void setMinutes(int minutes) {
    final clamped = minutes.clamp(1, 60);
    stopAlarm();
    _tickerTimer?.cancel();
    _totalSeconds = clamped * 60;
    _remainingSeconds = _totalSeconds;
    _isRunning = false;
    _endTime = null;
    _saveState();
    _speak('$clamped dakika ayarlandı.');
    notifyListeners();
  }

  void adjustMinutes(int delta) {
    final currentMins = (_totalSeconds ~/ 60) + delta;
    setMinutes(currentMins);
  }

  void startTimer() {
    stopAlarm();
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _totalSeconds;
    }
    _isRunning = true;
    _endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    _saveState();
    _startTicker();

    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    if (mins > 0) {
      _speak('$mins dakika süre başladı!');
    } else {
      _speak('$secs saniye süre başladı!');
    }
    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _tickerTimer?.cancel();
    _isRunning = false;
    _endTime = null;
    _saveState();
    _speak('Sayaç duraklatıldı.');
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void resetTimer() {
    stopAlarm();
    _tickerTimer?.cancel();
    _remainingSeconds = _totalSeconds;
    _isRunning = false;
    _endTime = null;
    _saveState();
    _speak('Sayaç sıfırlandı.');
    notifyListeners();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning || _endTime == null) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final diff = _endTime!.difference(now).inSeconds;

      if (diff > 0) {
        _remainingSeconds = diff;
        if (_remainingSeconds == 60) {
          _speak('Son 1 dakika kaldı!');
        } else if (_remainingSeconds == 10) {
          _speak('Son 10 saniye!');
        }
        notifyListeners();
      } else {
        // Süre Doldu!
        timer.cancel();
        _remainingSeconds = 0;
        _isRunning = false;
        _isAlarmActive = true;
        _endTime = null;
        _saveState();
        _startAlarmLoop();
        notifyListeners();
      }
    });
  }

  /// Süre bitince yüksek sesli alarm öter ve cihaz sürekli titrer.
  void _startAlarmLoop() {
    _vibrationTimer?.cancel();
    _vibrateStep();

    // Sürekli aralıklarla titreşim ve haptik titreşim darbesi
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!_isAlarmActive) {
        _vibrationTimer?.cancel();
        return;
      }
      _vibrateStep();
    });

    // Sesli alarm ve uyarı
    _playAlarmSound();

    _speak('Süre doldu! Zaman tamamlandı.');
  }

  void _vibrateStep() {
    try {
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> _playAlarmSound() async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);
      await _audioPlayer!.play(AssetSource('sounds/alarm_buzzer.wav'));
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  /// Kullanıcı "Alarmı Durdur" butonuna bastığında çağrılır.
  void stopAlarm() {
    _isAlarmActive = false;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulamaya geri dönüldüğünde süreyi anında kontrol et
      if (_isRunning && _endTime != null) {
        final now = DateTime.now();
        if (now.isAfter(_endTime!)) {
          _tickerTimer?.cancel();
          _remainingSeconds = 0;
          _isRunning = false;
          _isAlarmActive = true;
          _endTime = null;
          _saveState();
          _startAlarmLoop();
          notifyListeners();
        } else {
          _remainingSeconds = _endTime!.difference(now).inSeconds;
          notifyListeners();
        }
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
    } catch (_) {}
    super.dispose();
  }
}
