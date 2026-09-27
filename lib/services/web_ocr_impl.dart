import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('ocrRecognizeImage')
external JSPromise<JSString>? _ocrRecognizeImage(JSString url);

/// Web (Tarayıcı / Chrome) üzerinde Tesseract.js motoruyla çalışan OCR fonksiyonu.
Future<String> recognizeWebText(String imagePath) async {
  if (imagePath.isEmpty) return '';

  try {
    debugPrint('Web OCR Tesseract başlatılıyor: $imagePath');
    final promise = _ocrRecognizeImage(imagePath.toJS);
    if (promise == null) {
      debugPrint('Web OCR: ocrRecognizeImage fonksiyonu henüz yüklenmedi.');
      return '';
    }
    final jsString = await promise.toDart;
    final text = jsString.toDart.trim();
    debugPrint('Web OCR Tesseract başarıyla tamamlandı: ${text.length} karakter.');
    return text;
  } catch (e) {
    debugPrint('Web OCR hatası: $e');
    return '';
  }
}
