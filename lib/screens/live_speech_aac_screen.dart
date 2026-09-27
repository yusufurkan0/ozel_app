import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../services/ocr_translation_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'sentence_builder_screen.dart';

/// 🎙️ Canlı Konuşma Dinleyici (Speech-to-AAC)
///
/// Ebeveyn veya öğretmen konuştuğunda, konuşmayı anında gerçek zamanlı olarak
/// algılar ve çocuğun anlayabilmesi için canlı Makaton iletişim kartlarına dönüştürür.
class LiveSpeechAacScreen extends StatefulWidget {
  const LiveSpeechAacScreen({super.key});

  @override
  State<LiveSpeechAacScreen> createState() => _LiveSpeechAacScreenState();
}

class _LiveSpeechAacScreenState extends State<LiveSpeechAacScreen>
    with SingleTickerProviderStateMixin {
  final OcrTranslationService _ocrService = OcrTranslationService();
  late stt.SpeechToText _speech;
  late AnimationController _pulseController;

  bool _isListening = false;
  bool _speechAvailable = false;
  String _spokenText = '';
  List<MakatonItem> _liveMakatonItems = [];

  // Mikrofonsuz hızlı deneme senaryoları
  final List<String> _sampleSpeeches = [
    'Hadi montunu giy, bahçeye çıkıp oyun oynayalım.',
    'Ellerini sabunla yıka, sıcak yemek hazır!',
    'Lütfen biraz su iç ve dinlen.',
    'Okulda kitabımızı okuyoruz ve müzik dinliyoruz.',
    'Dişlerini fırçala, uyku vakti geldi iyi geceler.',
    'Büyük bir elma ve süt ister misin?',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (val) => debugPrint('STT onError: $val'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) {
        setState(() => _speechAvailable = available);
      }
    } catch (e) {
      debugPrint('Speech initialize hatası: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = _speechAvailable;
      if (!available) {
        available = await _speech.initialize();
      }

      if (available) {
        setState(() {
          _isListening = true;
          _spokenText = '';
          _liveMakatonItems = [];
        });

        _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
          ),
          onResult: (result) {
            if (mounted) {
              _onSpeechRecognized(result.recognizedWords);
            }
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mikrofon erişimi sağlanamadı. Aşağıdaki hazır cümleleri deneyebilirsiniz.'),
            ),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _onSpeechRecognized(String text) {
    final game = Provider.of<GameProgressService>(context, listen: false);
    final matched = _ocrService.translateTextToMakaton(text, game.allItems);

    setState(() {
      _spokenText = text;
      _liveMakatonItems = matched;
    });
  }

  void _applySampleSpeech(String sample) {
    _speech.stop();
    setState(() => _isListening = false);
    _onSpeechRecognized(sample);
  }

  void _sendToSentenceBuilder() {
    if (_liveMakatonItems.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SentenceBuilderScreen(initialItems: _liveMakatonItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🎙️ Canlı Konuşma Dinleyici'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Bilgilendirici Neumorphic Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: Neu.elevated(radius: 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.record_voice_over_rounded,
                          color: AppColors.buttonIndigo, size: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Siz Konuşun, Çocuk Görsün',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Söylediğiniz Türkçe cümleler anında çocuğun anlayacağı Makaton kartlarına çevrilir.',
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
            const SizedBox(height: 24),

            // Canlı Mikrofon Butonu & Animasyon
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _listen,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = _isListening ? _pulseController.value : 0.0;
                        return Container(
                          width: 110 + (pulse * 16),
                          height: 110 + (pulse * 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? AppColors.accentRed
                                : AppColors.buttonIndigo,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? AppColors.accentRed
                                        : AppColors.buttonIndigo)
                                    .withValues(alpha: 0.3 + (pulse * 0.3)),
                                blurRadius: 20 + (pulse * 15),
                                spreadRadius: 4 + (pulse * 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isListening ? 'Sizi Dinliyorum... Konuşun' : 'Dinlemek İçin Dokunun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isListening ? AppColors.accentRed : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isListening
                        ? 'Türkçe konuşmanızı otomatik algılıyorum...'
                        : 'Mikrofona konuşun veya aşağıdaki hazır cümlelere tıklayın',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Algılanan Konuşma Metni
            if (_spokenText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: Neu.inset(radius: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        color: AppColors.buttonIndigo, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _spokenText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded,
                          color: AppColors.buttonIndigo, size: 22),
                      tooltip: 'Sesli Tekrar Et',
                      onPressed: () => TtsService().speak(_spokenText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Canlı Makaton Sembolleri
            if (_liveMakatonItems.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🧩 Canlı Makaton Kartları',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_liveMakatonItems.length} Kart',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonIndigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _sendToSentenceBuilder,
                    icon: const Icon(Icons.auto_stories_rounded,
                        size: 18, color: AppColors.buttonIndigo),
                    label: const Text(
                      'Cümleye Aktar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonIndigo,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _liveMakatonItems.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _liveMakatonItems[index];
                    return Container(
                      width: 105,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: Neu.elevated(radius: 18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Hazır Örnek Konuşmalar (Test Kolaylığı)
            Row(
              children: const [
                Icon(Icons.touch_app_rounded,
                    size: 20, color: AppColors.buttonTeal),
                SizedBox(width: 6),
                Text(
                  'Hızlı Deneme Cümleleri (Tıklayın):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sampleSpeeches.map((sample) {
                return ActionChip(
                  label: Text(sample),
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppColors.buttonTeal.withValues(alpha: 0.3),
                    ),
                  ),
                  onPressed: () => _applySampleSpeech(sample),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
