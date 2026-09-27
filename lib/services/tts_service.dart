import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Doğal Türkçe ses sentezi motoru (Text-to-Speech).
/// Cümleleri ve kart isimlerini çocuk dostu bir tonlamayla seslendirir.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Türkçe dil seçimi
      await _flutterTts.setLanguage('tr-TR');
      // Çocuk dostu konuşma hızı ve perdesi
      await _flutterTts.setSpeechRate(0.45); // Hafif yavaş ve anlaşılır
      await _flutterTts.setPitch(1.2); // Biraz daha canlı/tatlı perde
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Hatası: $msg');
      });

      _initialized = true;
    } catch (e) {
      debugPrint('TTS Başlatılamadı: $e');
    }
  }

  /// Metni Türkçe doğal sesle oku
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      if (!_initialized) {
        await initialize();
      }
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Seslendirmeyi durdur
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  /// Hız ve perde ayarlarını güncelle
  Future<void> updateSettings({double rate = 0.45, double pitch = 1.2}) async {
    try {
      if (!_initialized) await initialize();
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setPitch(pitch);
    } catch (_) {}
  }
}
