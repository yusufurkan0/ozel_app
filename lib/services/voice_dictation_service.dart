import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Sesle Yazdırma (Speech-to-Text / Dikte) Servisi
///
/// Kendini değerlendirme formunda ve tüm metin alanlarında kullanıcının
/// Türkçe sesli konuşmasını anlık olarak algılayıp yazıya döker.
class VoiceDictationService {
  static final VoiceDictationService _instance = VoiceDictationService._internal();
  factory VoiceDictationService() => _instance;
  VoiceDictationService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isAvailable = false;
  String _selectedLocaleId = 'tr_TR';

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  /// Servisi başlatır ve Türkçe dil desteğini kontrol eder
  Future<bool> initialize() async {
    if (_isInitialized && _isAvailable) return true;

    try {
      _isAvailable = await _speech.initialize(
        onError: (val) {
          debugPrint('STT Hata Bildirimi: ${val.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('STT Durum: $status');
        },
        debugLogging: false,
      );

      _isInitialized = true;

      if (_isAvailable) {
        // Cihazdaki desteklenen dilleri kontrol et ve en uygun Türkçe yereli seç
        try {
          final locales = await _speech.locales();
          final trLocale = locales.firstWhere(
            (l) => l.localeId.toLowerCase().startsWith('tr'),
            orElse: () => locales.first,
          );
          _selectedLocaleId = trLocale.localeId;
        } catch (_) {
          _selectedLocaleId = 'tr_TR';
        }
      }
      return _isAvailable;
    } catch (e) {
      debugPrint('VoiceDictationService initialize hatası: $e');
      _isAvailable = false;
      return false;
    }
  }

  /// Sesle dinlemeyi başlatır
  Future<bool> startListening({
    required Function(String recognizedWords) onResult,
    required Function(bool isListening) onListeningChanged,
    Function(String error)? onError,
  }) async {
    final available = await initialize();
    if (!available) {
      onError?.call('Mikrofon erişimi sağlanamadı. Lütfen cihaz izinlerini kontrol edin.');
      onListeningChanged(false);
      return false;
    }

    try {
      onListeningChanged(true);

      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            onListeningChanged(false);
          }
        },
        localeId: _selectedLocaleId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 40),
        pauseFor: const Duration(seconds: 4),
      );
      return true;
    } catch (e) {
      debugPrint('STT listen başlatma hatası: $e');
      onListeningChanged(false);
      onError?.call('Dinleme başlatılamadı: $e');
      return false;
    }
  }

  /// Dinlemeyi durdurur
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }
}
