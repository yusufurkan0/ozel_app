import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../services/ocr_translation_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'sentence_builder_screen.dart';

/// 📸 Görsel Çevirmen Ekranı — Google Lens & Translate Tarzı Metin ve Makaton Çevirici.
///
/// Bir kitap sayfası, sokak tabelası veya ürün etiketi fotoğraflandığında:
/// 1. Metni algılar (OCR)
/// 2. Çocuk dostu Türkçe ses ile okur (TTS)
/// 3. Metni otomatik olarak Makaton iletişim sembollerine çevirir
/// 4. Tek tıkla Cümle Oluşturucuya aktarır.
class VisualTranslatorScreen extends StatefulWidget {
  const VisualTranslatorScreen({super.key});

  @override
  State<VisualTranslatorScreen> createState() => _VisualTranslatorScreenState();
}

class _VisualTranslatorScreenState extends State<VisualTranslatorScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final OcrTranslationService _ocrService = OcrTranslationService();

  String? _imagePath;
  String _recognizedText = '';
  String _turkishTranslation = '';
  String _simplifiedText = '';
  List<MakatonItem> _matchedItems = [];
  bool _isProcessing = false;
  bool _isTranslating = false;
  late AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    TtsService().stop();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (photo != null) {
        setState(() {
          _imagePath = photo.path;
          _isProcessing = true;
          _isTranslating = false;
          _recognizedText = '';
          _turkishTranslation = '';
          _simplifiedText = '';
          _matchedItems = [];
        });

        await _processImage(photo.path);
      }
    } catch (e) {
      debugPrint('Fotoğraf seçme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf açılamadı: $e')),
        );
      }
    }
  }

  Future<void> _processImage(String path) async {
    final game = Provider.of<GameProgressService>(context, listen: false);

    // 1. OCR ile metin tanı
    final text = await _ocrService.recognizeText(path);

    // 2. Metin boş dönerse, bilgilendirici mesaj oluştur
    final effectiveText = text.isNotEmpty
        ? text
        : 'Fotoğraftaki metin ayrıştırılamadı. Lütfen yazının net ve aydınlık olduğundan emin olun ya da aşağıdaki hazır senaryoları deneyin.';

    final isEng = text.isNotEmpty && _ocrService.isLikelyEnglish(effectiveText);
    String trTranslation = '';

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isTranslating = isEng;
        _recognizedText = effectiveText;
      });
    }

    // 3. İngilizce ise Google Translate / Çeviri motoruyla Türkçeye çevir
    if (isEng) {
      trTranslation = await _ocrService.translateToTurkish(effectiveText);
    }

    // 4. Makaton sembollerine çevir (hem orijinal hem çevrilmiş kelimeler taranır)
    final textForMakaton = trTranslation.isNotEmpty
        ? '$effectiveText $trTranslation'
        : effectiveText;
    final matched = _ocrService.translateTextToMakaton(textForMakaton, game.allItems);
    final baseForSimplify = trTranslation.isNotEmpty ? trTranslation : effectiveText;
    final simplified = _ocrService.simplifyText(baseForSimplify);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isTranslating = false;
        _turkishTranslation = trTranslation;
        _simplifiedText = simplified;
        _matchedItems = matched;
      });

      // Otomatik Sesli Okuma:
      // İngilizce çevirisi varsa Türkçesini oku, yoksa orijinal metni oku!
      if (text.isNotEmpty) {
        if (trTranslation.isNotEmpty) {
          TtsService().speak(trTranslation);
        } else {
          TtsService().speak(effectiveText);
        }
      }
    }
  }

  Future<void> _translateCurrentText() async {
    if (_recognizedText.isEmpty) return;
    final game = Provider.of<GameProgressService>(context, listen: false);

    setState(() => _isTranslating = true);
    final trTranslation = await _ocrService.translateToTurkish(_recognizedText);
    final textForMakaton = trTranslation.isNotEmpty
        ? '$_recognizedText $trTranslation'
        : _recognizedText;
    final matched = _ocrService.translateTextToMakaton(textForMakaton, game.allItems);
    final baseForSimplify = trTranslation.isNotEmpty ? trTranslation : _recognizedText;
    final simplified = _ocrService.simplifyText(baseForSimplify);

    if (mounted) {
      setState(() {
        _isTranslating = false;
        _turkishTranslation = trTranslation;
        _simplifiedText = simplified;
        _matchedItems = matched;
      });

      if (trTranslation.isNotEmpty) {
        TtsService().speak(trTranslation);
      }
    }
  }

  Future<void> _applyDemoScenario(OcrDemoScenario scenario) async {
    final game = Provider.of<GameProgressService>(context, listen: false);
    final isEng = _ocrService.isLikelyEnglish(scenario.sampleText);

    setState(() {
      _imagePath = null;
      _isProcessing = false;
      _isTranslating = isEng;
      _recognizedText = scenario.sampleText;
      _turkishTranslation = '';
      _simplifiedText = '';
      _matchedItems = [];
    });

    String trTranslation = '';
    if (isEng) {
      trTranslation = await _ocrService.translateToTurkish(scenario.sampleText);
    }

    final textForMakaton = trTranslation.isNotEmpty
        ? '${scenario.sampleText} $trTranslation'
        : scenario.sampleText;
    final matched = _ocrService.translateTextToMakaton(textForMakaton, game.allItems);
    final baseForSimplify = trTranslation.isNotEmpty ? trTranslation : scenario.sampleText;
    final simplified = _ocrService.simplifyText(baseForSimplify);

    if (mounted) {
      setState(() {
        _isTranslating = false;
        _turkishTranslation = trTranslation;
        _simplifiedText = simplified;
        _matchedItems = matched;
      });

      if (trTranslation.isNotEmpty) {
        TtsService().speak(trTranslation);
      } else {
        TtsService().speak(scenario.sampleText);
      }
    }
  }

  void _showDemoScenariosModal() {
    final scenarios = _ocrService.getDemoScenarios();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neumorphicDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.buttonIndigo),
                SizedBox(width: 8),
                Text(
                  'Hazır Deneme Senaryoları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Kamera çekmeden önce bu örnek metinleri test edebilirsiniz:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: scenarios.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final s = scenarios[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _applyDemoScenario(s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: Neu.elevated(radius: 16, blur: 4),
                      child: Row(
                        children: [
                          Text(s.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  s.sampleText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16, color: AppColors.buttonIndigo),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendToSentenceBuilder() {
    if (_matchedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktarılacak sembol bulunamadı.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SentenceBuilderScreen(initialItems: _matchedItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_rounded, color: AppColors.buttonIndigo, size: 24),
            SizedBox(width: 8),
            Text(
              'Görsel Çevirmen',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.buttonAmber),
            tooltip: 'Hazır Senaryolar',
            onPressed: _showDemoScenariosModal,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(game.themeIndex),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Bilgi Başlığı ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: Neu.elevated(radius: 20, blur: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.translate_rounded,
                            color: AppColors.buttonIndigo, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Translate & Lens Modeli',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Yazıyı çek, sesli dinle ve Makaton kartlarına çevir!',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Kamera & Galeri & Örnek Butonları ─────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.camera_alt_rounded,
                        label: 'Fotoğraf Çek',
                        color: AppColors.buttonIndigo,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeriden Seç',
                        color: AppColors.buttonTeal,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Örnek Dene',
                        color: AppColors.buttonPurple,
                        onTap: _showDemoScenariosModal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── Resim Önizleme & Tarama Alanı ───────────────
                if (_imagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: kIsWeb
                              ? Image.network(
                                  _imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.image_rounded,
                                        size: 60, color: AppColors.textSecondary),
                                  ),
                                )
                              : Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.image_rounded,
                                        size: 60, color: AppColors.textSecondary),
                                  ),
                                ),
                        ),
                        // Lazer Tarama Çizgisi (Google Lens Animasyonu)
                        if (_isProcessing)
                          AnimatedBuilder(
                            animation: _scanAnimController,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanAnimController.value * 190,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.buttonIndigo,
                                        Colors.cyanAccent,
                                        AppColors.buttonIndigo,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.buttonIndigo.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Yükleniyor Durumu (OCR Tarama)
                if (_isProcessing) ...[
                  Center(
                    child: Column(
                      children: const [
                        CircularProgressIndicator(color: AppColors.buttonIndigo),
                        SizedBox(height: 12),
                        Text(
                          'Yazılar taranıyor ve analiz ediliyor...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Yükleniyor Durumu (İngilizce ➔ Türkçe Çeviri)
                if (_isTranslating) ...[
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: Neu.elevated(radius: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.buttonTeal,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '🌐 İngilizce metin Türkçeye çevriliyor...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ─── 1. Çeviri & Okunan Metin Kartları ─────────
                if (_recognizedText.isNotEmpty) ...[
                  // A) Türkçe Çeviri Kartı (Eğer İngilizce metin algılandıysa)
                  if (_turkishTranslation.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.buttonTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.buttonTeal.withValues(alpha: 0.35),
                          width: 1.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text('🇹🇷', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Türkçe Çeviri',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.buttonTeal.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Google Çeviri',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.buttonTeal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.volume_up_rounded,
                                        color: AppColors.positiveGreen, size: 26),
                                    tooltip: 'Türkçe Sesli Oku',
                                    onPressed: () =>
                                        TtsService().speak(_turkishTranslation),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded,
                                        color: AppColors.buttonIndigo, size: 20),
                                    tooltip: 'Çeviriyi Kopyala',
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: _turkishTranslation));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Türkçe çeviri panoya kopyalandı!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: Neu.inset(radius: 16),
                            child: Text(
                              _turkishTranslation,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // B) Fotoğraftan Okunan Orijinal İngilizce Metin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('🇬🇧', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text(
                              'Fotoğraftaki Orijinal Metin (OCR)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded,
                                  color: AppColors.buttonTeal, size: 20),
                              tooltip: 'Tekrar Çevir',
                              onPressed: _translateCurrentText,
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded,
                                  color: AppColors.textSecondary, size: 20),
                              tooltip: 'İngilizce Oku',
                              onPressed: () =>
                                  TtsService().speak(_recognizedText),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded,
                                  color: AppColors.textSecondary, size: 18),
                              tooltip: 'Metni Kopyala',
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: _recognizedText));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Metin panoya kopyalandı!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: Neu.inset(radius: 16),
                      child: Text(
                        _recognizedText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // C) Standart Metin Kartı (Türkçe metinler için)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📝 Fotoğraftan Okunan Yazı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.translate_rounded,
                                  size: 18, color: AppColors.buttonTeal),
                              label: const Text(
                                'Çevir',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonTeal,
                                ),
                              ),
                              onPressed: _translateCurrentText,
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded,
                                  color: AppColors.positiveGreen, size: 24),
                              tooltip: 'Sesli Oku',
                              onPressed: () =>
                                  TtsService().speak(_recognizedText),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded,
                                  color: AppColors.buttonIndigo, size: 20),
                              tooltip: 'Metni Kopyala',
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: _recognizedText));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Metin panoya kopyalandı!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: Neu.inset(radius: 18),
                      child: Text(
                        _recognizedText,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── 2. Çocuk Diline Sadeleştirme ──────────────
                  if (_simplifiedText.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.buttonAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.buttonAmber.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('👶', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sadeleştirilmiş Çocuk Dili:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _simplifiedText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded,
                                color: AppColors.buttonAmber, size: 22),
                            onPressed: () => TtsService().speak(_simplifiedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ─── 3. Makaton Sembol Çevirisi (AAC Kartları) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '🧩 Makaton Sembol Çevirisi',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.buttonPurple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_matchedItems.length} Kart',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.buttonPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_matchedItems.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: Neu.elevated(radius: 16, blur: 4),
                      child: const Center(
                        child: Text(
                          'Bu metinle doğrudan eşleşen Makaton sembolü bulunamadı.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Yatay kaydırılabilir kart dizilimi
                    SizedBox(
                      height: 125,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _matchedItems.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final item = _matchedItems[i];
                          return GestureDetector(
                            onTap: () {
                              TtsService().speak(item.label);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Kart: ${item.label}'),
                                  duration: const Duration(milliseconds: 900),
                                ),
                              );
                            },
                            child: Container(
                              width: 100,
                              padding: const EdgeInsets.all(10),
                              decoration: Neu.colored(color: item.color, radius: 18),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(item.icon,
                                        size: 26, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cümle Oluşturucuya Aktar Butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sendToSentenceBuilder,
                        icon: const Icon(Icons.auto_stories_rounded,
                            color: Colors.white),
                        label: const Text(
                          'Bu Kartları Cümle Oluşturucuya Aktar 📝',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonIndigo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: Neu.elevated(radius: 18, blur: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
