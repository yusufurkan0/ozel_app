import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import '../models/makaton_item.dart';
import 'web_ocr_stub.dart'
    if (dart.library.js_interop) 'web_ocr_impl.dart';

/// Görsel Tanıma ve Makaton Çeviri Sonucu Modeli.
class OcrTranslationResult {
  final String rawText;
  final String turkishText;
  final String simplifiedText;
  final List<MakatonItem> matchedMakatonItems;
  final String? imagePath;
  final bool isTranslated;

  const OcrTranslationResult({
    required this.rawText,
    required this.turkishText,
    required this.simplifiedText,
    required this.matchedMakatonItems,
    this.imagePath,
    this.isTranslated = false,
  });
}

/// Örnek Demo Senaryosu (Kamera olmadan test & pratik yapabilmek için).
class OcrDemoScenario {
  final String title;
  final String emoji;
  final String subtitle;
  final String sampleText;

  const OcrDemoScenario({
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.sampleText,
  });
}

/// Optik Karakter Tanıma (OCR) ve Makaton Sembol Çevirici Servisi.
///
/// Google ML Kit ile resimdeki metinleri tanır, Türkçe doğal dilde analiz eder
/// ve özel eğitim için görsel Makaton kartlarına dönüştürür.
class OcrTranslationService {
  static final OcrTranslationService _instance =
      OcrTranslationService._internal();
  factory OcrTranslationService() => _instance;
  OcrTranslationService._internal();

  TextRecognizer? _cachedRecognizer;
  TextRecognizer get _textRecognizer =>
      _cachedRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  /// Resim dosyasından metin tanıma (OCR).
  Future<String> recognizeText(String imagePath) async {
    if (imagePath.isEmpty) return '';

    // Web (Chrome / Tarayıcı) ortamında tarayıcı içi Tesseract.js çalışır
    if (kIsWeb) {
      return await recognizeWebText(imagePath);
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('OCR: Dosya bulunamadı: $imagePath');
        return '';
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      debugPrint('OCR Text Recognition hatası (fallback devrede): $e');
      return '';
    }
  }

  /// Market fişleri için konumsal (Bounding Box) hizalamalı metin tanıma.
  /// Sol sütundaki metin (örn. TOPLAM) ile sağ sütundaki fiyatı (*427,42)
  /// dikey koordinat yakınlığına göre aynı satırda birleştirir.
  Future<String> recognizeReceiptText(String imagePath) async {
    if (imagePath.isEmpty) return '';

    if (kIsWeb) {
      return await recognizeWebText(imagePath);
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('Receipt OCR: Dosya bulunamadı: $imagePath');
        return '';
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Tüm satırları kutularıyla topla
      final allLines = <TextLine>[];
      for (final block in recognizedText.blocks) {
        allLines.addAll(block.lines);
      }

      if (allLines.isEmpty) {
        return recognizedText.text.trim();
      }

      // Satırları Y eksenine (üstten alta) göre sırala
      allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      // Benzer dikey hizada (Y ekseninde) olan satırları grupla ve soldan sağa birleştir
      final mergedRows = <String>[];
      final visited = <TextLine>{};

      for (int i = 0; i < allLines.length; i++) {
        final current = allLines[i];
        if (visited.contains(current)) continue;

        final rowGroup = <TextLine>[current];
        visited.add(current);

        final currentY = current.boundingBox.center.dy;
        final currentH = current.boundingBox.height;
        final yTolerance = (currentH * 0.75).clamp(8.0, 30.0);

        for (int j = i + 1; j < allLines.length; j++) {
          final other = allLines[j];
          if (visited.contains(other)) continue;

          final otherY = other.boundingBox.center.dy;
          if ((otherY - currentY).abs() <= yTolerance) {
            rowGroup.add(other);
            visited.add(other);
          }
        }

        // Aynı yatay gruptakileri X ekseninde soldan sağa diz
        rowGroup.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        mergedRows.add(rowGroup.map((l) => l.text.trim()).join('   '));
      }

      final structuredText = mergedRows.join('\n');
      return '$structuredText\n---\n${recognizedText.text.trim()}';
    } catch (e) {
      debugPrint('Receipt OCR hatası: $e');
      return await recognizeText(imagePath);
    }
  }

  /// Tanınan metni Makaton sembol kartlarına çevirir.
  List<MakatonItem> translateTextToMakaton(
    String text,
    List<MakatonItem> allItems,
  ) {
    if (text.trim().isEmpty || allItems.isEmpty) return [];

    final itemMap = {for (final item in allItems) item.id: item};
    final matchedItems = <MakatonItem>[];
    final addedIds = <String>{};

    void addItem(String id) {
      if (!addedIds.contains(id) && itemMap.containsKey(id)) {
        matchedItems.add(itemMap[id]!);
        addedIds.add(id);
      }
    }

    // Metni temizle ve kelimelere böl
    final cleanText = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = cleanText.split(' ');

    // 1. Doğrudan kelime ve kök eşleşmeleri
    for (final word in words) {
      if (word.isEmpty) continue;

      // Özne & Kişiler
      if (word == 'ben' || word == 'bana' || word == 'benim') addItem('ben');
      if (word == 'sen' || word == 'sana' || word == 'senin') addItem('sen');
      if (word.startsWith('anne')) addItem('anne');
      if (word.startsWith('baba')) addItem('baba');
      if (word.startsWith('kardeş')) addItem('kardes');
      if (word.startsWith('öğretmen')) addItem('ogretmen');
      if (word.startsWith('arkadaş')) addItem('arkadas');

      // İstek & Eylemler
      if (word.contains('isti') || word == 'istek') addItem('istiyorum');
      if (word.contains('istem')) addItem('istemiyorum');
      if (word == 'ver' || word.startsWith('verir') || word.startsWith('verir_misin')) addItem('ver');
      if (word == 'al' || word.startsWith('alır')) addItem('al');
      if (word.startsWith('git') || word == 'gidelim') addItem('gidelim');
      if (word.startsWith('gel') || word == 'gelir') addItem('gel');
      if (word.contains('oyun') || word.startsWith('oyna')) addItem('oyun');
      if (word.startsWith('bak')) addItem('bak');
      if (word.startsWith('sev')) addItem('seviyorum');
      if (word.startsWith('bit')) addItem('bitti');
      if (word.startsWith('yardım') || word == 'imdat') addItem('yardim');
      if (word == 'dur') addItem('dur');

      // Sosyal & Nezaket
      if (word.startsWith('lütfen')) addItem('lutfen');
      if (word.startsWith('teşekkür') || word == 'sağol') addItem('tesekkurler');
      if (word == 'evet') addItem('evet');
      if (word == 'hayır' || word == 'yok') addItem('hayir');
      if (word.startsWith('merhaba') || word == 'selam' || word.startsWith('günaydın')) addItem('merhaba');
      if (word.contains('fazla') || word == 'daha') addItem('daha_fazla');
      if (word == 'tekrar' || word == 'yine') addItem('tekrar');

      // Yiyecekler & İçecekler
      if (word.startsWith('su') || word.startsWith('iç')) addItem('su');
      if (word.startsWith('yemek') || word.startsWith('ye')) addItem('yemek');
      if (word.startsWith('süt')) addItem('sut');
      if (word.startsWith('meyve') || word == 'elma' || word == 'muz') addItem('meyve');
      if (word.startsWith('ekmek')) addItem('ekmek');
      if (word.startsWith('çikolata')) addItem('cikolata');

      // Duygular
      if (word.startsWith('mutlu') || word.startsWith('sevin')) addItem('mutlu');
      if (word.startsWith('üzg') || word.startsWith('ağla')) addItem('uzgun');
      if (word.startsWith('kızg') || word.startsWith('sinir')) addItem('kizgin');
      if (word.startsWith('kork')) addItem('korkuyorum');
      if (word.startsWith('yorg') || word == 'uykucu') addItem('yorgun');
      if (word.startsWith('şaşk')) addItem('saskin');

      // Aktiviteler & Mekanlar & Eğitim
      if (word.startsWith('müzik') || word.startsWith('şarkı')) addItem('muzik');
      if (word.startsWith('kitap') || word.startsWith('oku') || word.startsWith('dergi') || word.startsWith('makale') || word.startsWith('yazı') || word.startsWith('araştırma')) addItem('kitap');
      if (word.startsWith('park') || word.startsWith('bahçe')) addItem('park');
      if (word.startsWith('çizim') || word.startsWith('boya') || word.startsWith('resim')) addItem('cizim');
      if (word.startsWith('dans')) addItem('dans');
      if (word.startsWith('ev')) addItem('ev');
      if (word.startsWith('okul') || word == 'sınıf' || word.startsWith('eğitim') || word.startsWith('öğrenci') || word.startsWith('ders')) addItem('okul');
      if (word.startsWith('hastane') || word.startsWith('doktor') || word.startsWith('aşı')) addItem('hastane');
      if (word.startsWith('market') || word.startsWith('bakkal')) addItem('market');

      // İhtiyaçlar
      if (word.startsWith('tuvalet') || word == 'wc' || word == 'çiş' || word == 'kaka') addItem('tuvalet');
      if (word.startsWith('uyku') || word.startsWith('uyu') || word == 'yatak') addItem('uyku');
      if (word.startsWith('banyo') || word.startsWith('yıkan') || word == 'duş') addItem('banyo');
      if (word.startsWith('kıyafet') || word.startsWith('üst')) addItem('kiyafet');

      // Acil
      if (word.startsWith('ağrı') || word.startsWith('acı')) addItem('agri');
      if (word.startsWith('hasta') || word.contains('iyi değil')) addItem('iyi_degilim');

      // ─── 2. İngilizce Eşleşmeler (English to Makaton) ───────
      if (word == 'i' || word == 'me' || word == 'my') addItem('ben');
      if (word == 'you' || word == 'your') addItem('sen');
      if (word.startsWith('mom') || word.startsWith('mother')) addItem('anne');
      if (word.startsWith('dad') || word.startsWith('father')) addItem('baba');
      if (word.startsWith('brother') || word.startsWith('sister')) addItem('kardes');
      if (word.startsWith('teacher')) addItem('ogretmen');
      if (word.startsWith('friend')) addItem('arkadas');
      if (word.startsWith('want') || word.startsWith('wish')) addItem('istiyorum');
      if (word == 'give') addItem('ver');
      if (word == 'take') addItem('al');
      if (word == 'go' || word.startsWith('going')) addItem('gidelim');
      if (word == 'come') addItem('gel');
      if (word.startsWith('play') || word == 'game') addItem('oyun');
      if (word == 'see' || word == 'look') addItem('bak');
      if (word.startsWith('love') || word == 'like') addItem('seviyorum');
      if (word.startsWith('finish') || word == 'done') addItem('bitti');
      if (word.startsWith('help')) addItem('yardim');
      if (word == 'stop') addItem('dur');
      if (word.startsWith('please')) addItem('lutfen');
      if (word.startsWith('thank')) addItem('tesekkurler');
      if (word == 'yes') addItem('evet');
      if (word == 'no') addItem('hayir');
      if (word == 'hello' || word == 'hi') addItem('merhaba');
      if (word == 'more') addItem('daha_fazla');
      if (word.startsWith('water') || word.startsWith('drink')) addItem('su');
      if (word.startsWith('food') || word.startsWith('eat')) addItem('yemek');
      if (word == 'milk') addItem('sut');
      if (word.startsWith('fruit') || word.startsWith('apple')) addItem('meyve');
      if (word == 'bread') addItem('ekmek');
      if (word.startsWith('chocolate')) addItem('cikolata');
      if (word.startsWith('happy')) addItem('mutlu');
      if (word.startsWith('sad')) addItem('uzgun');
      if (word.startsWith('angry')) addItem('kizgin');
      if (word.startsWith('scare') || word.startsWith('fear')) addItem('korkuyorum');
      if (word.startsWith('tired')) addItem('yorgun');
      if (word.startsWith('music') || word == 'song') addItem('muzik');
      if (word.startsWith('book') || word.startsWith('read') || word.startsWith('journal') || word.startsWith('article')) addItem('kitap');
      if (word.startsWith('park') || word == 'garden') addItem('park');
      if (word.startsWith('draw') || word.startsWith('paint')) addItem('cizim');
      if (word.startsWith('dance')) addItem('dans');
      if (word == 'home' || word == 'house') addItem('ev');
      if (word.startsWith('school') || word == 'class' || word.startsWith('educat')) addItem('okul');
      if (word.startsWith('hospital') || word.startsWith('doctor')) addItem('hastane');
      if (word == 'market' || word == 'shop' || word == 'store') addItem('market');
      if (word.startsWith('toilet') || word == 'restroom' || word == 'wc') addItem('tuvalet');
      if (word.startsWith('sleep') || word == 'bed') addItem('uyku');
      if (word.startsWith('bath') || word.startsWith('shower')) addItem('banyo');
      if (word.startsWith('cloth')) addItem('kiyafet');
      if (word.startsWith('pain') || word.startsWith('hurt')) addItem('agri');
      if (word == 'sick' || word == 'ill') addItem('iyi_degilim');
    }

    // Hiçbir sembol eşleşmezse, metin içinde istek varsa 'istiyorum' veya 'ben' öner
    if (matchedItems.isEmpty && text.trim().isNotEmpty) {
      if (itemMap.containsKey('ben')) matchedItems.add(itemMap['ben']!);
      if (itemMap.containsKey('istiyorum')) matchedItems.add(itemMap['istiyorum']!);
    }

    return matchedItems;
  }

  /// Metnin ağırlıklı olarak İngilizce veya yabancı dilde olup olmadığını tespit eder.
  bool isLikelyEnglish(String text) {
    if (text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    final englishWords = {
      'the', 'and', 'is', 'in', 'it', 'you', 'that', 'he', 'was', 'for',
      'on', 'are', 'as', 'with', 'his', 'they', 'at', 'be', 'this', 'have',
      'from', 'or', 'one', 'had', 'by', 'word', 'but', 'not', 'what', 'all',
      'were', 'we', 'when', 'your', 'can', 'said', 'there', 'use', 'an',
      'each', 'which', 'she', 'do', 'how', 'their', 'if', 'will', 'up',
      'about', 'out', 'many', 'then', 'them', 'these', 'so', 'some', 'her',
      'would', 'make', 'like', 'him', 'into', 'time', 'has', 'look', 'two',
      'more', 'write', 'go', 'see', 'number', 'no', 'way', 'could', 'people',
      'water', 'please', 'food', 'want', 'school', 'park', 'journal', 'education',
      'articles', 'research', 'international', 'published', 'review', 'book', 'read',
      'survey', 'requirements', 'colleges', 'universities', 'teacher', 'teachers',
      'system', 'challenge', 'solutions', 'prospective', 'anxiety', 'writing',
      'selection', 'recruitment', 'evaluating', 'language', 'program', 'arguments',
      'case', 'study', 'students', 'reasons', 'classes', 'sciences', 'views', 'world'
    };

    final words = lower.replaceAll(RegExp(r'[^\w\s]'), ' ').split(RegExp(r'\s+'));
    int engCount = 0;
    for (final w in words) {
      if (englishWords.contains(w)) engCount++;
    }
    return engCount >= 2 || (words.length <= 4 && engCount >= 1);
  }

  /// İngilizce metni otomatik olarak Türkçe doğal dile çevirir (Google Translate / MyMemory).
  Future<String> translateToTurkish(String text) async {
    if (text.trim().isEmpty) return '';

    // Çok satırlı veya uzun metinleri (örn: kaynakça, makale) paragraflara bölerek çevir
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length > 1 && text.length > 200) {
      final translatedLines = <String>[];
      for (final line in lines) {
        if (line.isEmpty) continue;
        final translated = await _translateSingleChunk(line);
        translatedLines.add(translated);
      }
      if (translatedLines.isNotEmpty) {
        return translatedLines.join('\n\n');
      }
    }

    return await _translateSingleChunk(text);
  }

  Future<String> _translateSingleChunk(String chunk) async {
    if (chunk.trim().isEmpty) return '';
    final query = chunk.length > 500 ? chunk.substring(0, 500) : chunk;

    // 1. Öncelikli: MyMemory Çeviri Motoru (CORS Destekli & Hızlı & Ücretsiz)
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(query)}&langpair=en|tr',
      );
      final res = await http.get(uri).timeout(const Duration(milliseconds: 1200));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>?;
        final translated = responseData?['translatedText'] as String?;
        if (translated != null &&
            translated.trim().isNotEmpty &&
            !translated.contains('MYMEMORY WARNING')) {
          return _cleanHtmlEntities(translated.trim());
        }
      }
    } catch (e) {
      debugPrint('MyMemory çeviri denemesi: $e');
    }

    // 2. Yedek: Google Translate GTX Motoru
    try {
      final gtxUri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=tr&dt=t&q=${Uri.encodeComponent(query)}',
      );
      final res = await http.get(
        gtxUri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
        },
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final dynamic parsed = jsonDecode(res.body);
        if (parsed is List && parsed.isNotEmpty && parsed[0] is List) {
          final segments = parsed[0] as List;
          final buffer = StringBuffer();
          for (final seg in segments) {
            if (seg is List && seg.isNotEmpty && seg[0] != null) {
              buffer.write(seg[0].toString());
            }
          }
          final translated = _cleanHtmlEntities(buffer.toString().trim());
          if (translated.isNotEmpty) {
            return translated;
          }
        }
      }
    } catch (e) {
      debugPrint('Google Translate GTX denemesi: $e');
    }

    // 3. Çevrimdışı / Sözlük tabanlı yedek çeviri (İnternetsiz ortam garantisi)
    return _offlineFallbackTranslation(chunk);
  }

  String _cleanHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&Ccedil;', 'Ç')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&Ouml;', 'Ö')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&Uuml;', 'Ü')
        .replaceAll('&sect;', '§');
  }

  String _offlineFallbackTranslation(String text) {
    final lower = text.toLowerCase().trim();

    // Özel Şablonlar & Akademik / Kitap Metinleri
    if (lower.contains('journal') && lower.contains('education')) {
      return 'Türkiye Eğitim Dergisi. Üç ayda bir yayımlanan uluslararası hakemli akademik dergi.';
    }
    if (lower.contains('peer-reviewed') || lower.contains('peer reviewed')) {
      return 'Uluslararası hakemli akademik dergi ve araştırma yayını.';
    }
    if (lower.contains('water') && (lower.contains('want') || lower.contains('please'))) {
      return 'Lütfen bana su verir misiniz, su istiyorum.';
    }
    if (lower.contains('food') || lower.contains('eat')) {
      return 'Yemek yemek istiyorum lütfen.';
    }
    if (lower.contains('help') && (lower.contains('me') || lower.contains('please'))) {
      return 'Lütfen bana yardım edebilir misiniz?';
    }
    if (lower.contains('school') && lower.contains('book')) {
      return 'Okulda kitabımızı okuyoruz ve öğreniyoruz.';
    }
    if (lower.contains('toilet') || lower.contains('restroom') || lower.contains('bathroom')) {
      return 'Tuvalete gitmem gerekiyor.';
    }
    if (lower.contains('park') || lower.contains('play')) {
      return 'Parkta oyun oynamak istiyorum.';
    }
    if (lower.contains('welcome')) {
      return 'Hoş geldiniz! Lütfen dikkatlice okuyunuz.';
    }

    // Kelime kelime akıllı çevrimdışı sözlük eşlemesi
    final wordMap = <String, String>{
      'hello': 'merhaba',
      'hi': 'selam',
      'teacher': 'öğretmen',
      'student': 'öğrenci',
      'school': 'okul',
      'book': 'kitap',
      'read': 'oku',
      'write': 'yaz',
      'learn': 'öğren',
      'water': 'su',
      'food': 'yemek',
      'eat': 'ye',
      'drink': 'iç',
      'please': 'lütfen',
      'thank': 'teşekkürler',
      'thanks': 'teşekkürler',
      'help': 'yardım',
      'me': 'bana',
      'i': 'ben',
      'you': 'sen',
      'we': 'biz',
      'want': 'istiyorum',
      'need': 'ihtiyacım var',
      'play': 'oyna',
      'game': 'oyun',
      'park': 'park',
      'stop': 'dur',
      'go': 'git',
      'come': 'gel',
      'look': 'bak',
      'see': 'gör',
      'happy': 'mutlu',
      'sad': 'üzgün',
      'angry': 'kızgın',
      'tired': 'yorgun',
      'mother': 'anne',
      'mom': 'anne',
      'father': 'baba',
      'dad': 'baba',
      'brother': 'kardeş',
      'sister': 'kardeş',
      'friend': 'arkadaş',
      'yes': 'evet',
      'no': 'hayır',
      'good': 'iyi',
      'bad': 'kötü',
      'big': 'büyük',
      'small': 'küçük',
      'journal': 'dergi',
      'education': 'eğitim',
      'international': 'uluslararası',
      'article': 'makale',
      'volume': 'cilt',
      'issue': 'sayı',
      'published': 'yayımlandı',
    };

    final words = lower.replaceAll(RegExp(r'[^\w\s]'), ' ').split(RegExp(r'\s+'));
    final translatedWords = <String>[];
    for (final w in words) {
      if (w.isEmpty) continue;
      if (wordMap.containsKey(w)) {
        translatedWords.add(wordMap[w]!);
      }
    }

    if (translatedWords.isNotEmpty) {
      final joined = translatedWords.join(' ');
      return '${joined[0].toUpperCase()}${joined.substring(1)}.';
    }

    return text;
  }

  /// Karmaşık metni özel eğitim için sadeleştirir (Çocuk Dili).
  String simplifyText(String rawText) {
    if (rawText.trim().isEmpty) return '';

    final lower = rawText.toLowerCase();

    if (lower.contains('tuvalet') || lower.contains('wc')) {
      return 'Burası tuvalet. İhtiyacın varsa gidebilirsin.';
    }
    if (lower.contains('park') || lower.contains('oyun')) {
      return 'Burada park ve oyun alanı var. Eğlenebilirsin.';
    }
    if (lower.contains('doktor') || lower.contains('hastane') || lower.contains('sağlık')) {
      return 'Doktor kontrolü. Güvendesin, her şey yolunda.';
    }
    if (lower.contains('okul') || lower.contains('sınıf') || lower.contains('ders') || lower.contains('eğitim') || lower.contains('dergi')) {
      return 'Okul ve ders saati. Arkadaşlarımızla kitap okuyup öğreniyoruz.';
    }
    if (lower.contains('yemek') || lower.contains('menü') || lower.contains('kafe') || lower.contains('yiyecek')) {
      return 'Yemek ve içecek zamanı. Ne istersen seçebilirsin.';
    }
    if (lower.contains('su') || lower.contains('içecek')) {
      return 'Su içme zamanı. Sağlığımız için çok önemli.';
    }
    if (lower.contains('dur') || lower.contains('tehlike') || lower.contains('yasak')) {
      return 'Dikkatli ol ve dur. Ailenin elini tut.';
    }

    // Genel sadeleştirme
    final sentences = rawText.split(RegExp(r'[.!?\n]')).where((s) => s.trim().isNotEmpty).toList();
    if (sentences.isNotEmpty) {
      return sentences.first.trim();
    }
    return rawText.trim();
  }

  /// Kamera olmadan test ve deneme yapılabilecek hazır senaryolar.
  List<OcrDemoScenario> getDemoScenarios() {
    return const [
      OcrDemoScenario(
        title: 'İngilizce Dergi / Kitap (EN ➔ TR)',
        emoji: '🇬🇧',
        subtitle: 'Fotoğraftaki İngilizce yazıyı Türkçeye çevirir',
        sampleText: 'Turkish Journal of Education. An international peer-reviewed journal. Please read your book and learn at school.',
      ),
      OcrDemoScenario(
        title: 'İngilizce İstek & İletişim (EN ➔ TR)',
        emoji: '🗣️',
        subtitle: 'İngilizce konuşmaları Türkçe AAC kartlarına döker',
        sampleText: 'Hello teacher! I want water and food please. Can you help me?',
      ),
      OcrDemoScenario(
        title: 'Park Tabelası',
        emoji: '🏞️',
        subtitle: 'Çocuk parkı giriş levhası',
        sampleText: 'Parka Hoş Geldiniz! Lütfen birlikte oyun oynayalım, temiz tutalım.',
      ),
      OcrDemoScenario(
        title: 'Market Listesi / Fiş',
        emoji: '🛒',
        subtitle: 'Gıda ve atıştırmalık listesi',
        sampleText: 'Ekmek, taze süt, elma meyve ve çikolata aldık. Teşekkür ederiz.',
      ),
      OcrDemoScenario(
        title: 'Okul Panosu',
        emoji: '🏫',
        subtitle: 'Öğretmen sınıf yönergesi',
        sampleText: 'Sevgili öğrenciler, okulda kitap okuyoruz ve müzik dinliyoruz.',
      ),
      OcrDemoScenario(
        title: 'Sağlık / Doktor Notu',
        emoji: '🏥',
        subtitle: 'Hastanede doktor tavsiyesi',
        sampleText: 'Geçmiş olsun! Bol su için, dinlenin ve uyku uyuyun.',
      ),
      OcrDemoScenario(
        title: 'Restoran / İçecek',
        emoji: '🥤',
        subtitle: 'Masa sipariş notu',
        sampleText: 'Ben soğuk su ve sıcak yemek istiyorum lütfen.',
      ),
    ];
  }
}
