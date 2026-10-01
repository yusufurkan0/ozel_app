import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/social_story_book.dart';
import '../../services/social_story_service.dart';

class SocialStoryReaderScreen extends StatefulWidget {
  final SocialStoryBook book;
  final int initialPage;

  const SocialStoryReaderScreen({
    super.key,
    required this.book,
    this.initialPage = 0,
  });

  @override
  State<SocialStoryReaderScreen> createState() => _SocialStoryReaderScreenState();
}

class _SocialStoryReaderScreenState extends State<SocialStoryReaderScreen> {
  late PageController _pageController;
  late int _currentPage;
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isAudioEnabled = true; // "Ses kaydını dinlemek için açma kapama seçeneği olacak"
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage);
    _initTts();
    _playPageAudio(_currentPage);
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _playPageAudio(int index) async {
    if (!_isAudioEnabled) return;
    if (widget.book.pages.isEmpty) return;
    if (index >= widget.book.pages.length) return;

    final page = widget.book.pages[index];

    // Önceki sesleri durdur
    try {
      await _audioPlayer.stop();
      await _tts.stop();
    } catch (_) {}

    setState(() => _isPlayingAudio = true);

    // 1. Kullanıcının kaydettiği özel ses varsa onu çal
    if (page.audioPath != null && page.audioPath!.isNotEmpty) {
      try {
        if (kIsWeb) {
          await _audioPlayer.play(UrlSource(page.audioPath!));
        } else {
          final file = File(page.audioPath!);
          if (file.existsSync()) {
            await _audioPlayer.play(DeviceFileSource(page.audioPath!));
          } else if (page.text.isNotEmpty) {
            await _tts.speak(page.text);
          }
        }
      } catch (_) {
        if (page.text.isNotEmpty) {
          await _tts.speak(page.text);
        }
      }
    } else if (page.text.isNotEmpty) {
      // 2. Özel ses kaydı yoksa TTS ile metni oku
      await _tts.speak(page.text);
    }

    if (mounted) setState(() => _isPlayingAudio = false);
  }

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });
    if (!_isAudioEnabled) {
      _audioPlayer.stop();
      _tts.stop();
    } else {
      _playPageAudio(_currentPage);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final pages = book.pages;

    if (pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(book.title),
          backgroundColor: Color(book.coverColorValue),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Bu kitapta henüz sayfa bulunmuyor.'),
        ),
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: isLandscape ? Colors.black : const Color(0xFFF8FAFC),
          appBar: isLandscape
              ? null // Yatay modda tam ekran sürükleyicilik için üst bar gizlenir
              : AppBar(
                  elevation: 0,
                  backgroundColor: Color(book.coverColorValue),
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  actions: [
                    // Ses Açma / Kapama Seçeneği (Kullanıcı İsteği)
                    IconButton(
                      icon: Icon(
                        _isAudioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: Colors.white,
                      ),
                      tooltip: _isAudioEnabled ? 'Sesi Kapat' : 'Sesi Aç',
                      onPressed: _toggleAudio,
                    ),
                  ],
                ),
          body: Stack(
            children: [
              // Sayfalar Arası Kaydırma (PageView)
              PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                  _playPageAudio(idx);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];

                  if (isLandscape) {
                    return _buildLandscapePage(page, index, pages.length);
                  } else {
                    return _buildPortraitPage(page, index, pages.length);
                  }
                },
              ),

              // Yatay mod için hızlı çıkış ve ses kontrolleri
              if (isLandscape)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${book.title} • ${_currentPage + 1} / ${pages.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isAudioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: _toggleAudio,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          bottomNavigationBar: isLandscape ? null : _buildBottomNavigation(pages.length),
        );
      },
    );
  }

  // --- DİKEY (PORTRAIT) SAYFA GÖRÜNÜMÜ ---
  Widget _buildPortraitPage(SocialStoryPage page, int index, int total) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          // Sayfa Numarası
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Sayfa ${index + 1} / $total',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(height: 16),

          // Tek Büyük Resim
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x0A0F172A), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _buildImageWidget(page.imagePath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 20),

          // Tek Metin Kutusu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              page.text.isNotEmpty ? page.text : '(Bu sayfa için metin yazılmadı)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.45,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ses Tekrar Dinle & Görev Tamamlandı Butonları
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(widget.book.coverColorValue),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: const Text('Tekrar Dinle', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _playPageAudio(index),
              ),
              if (widget.book.type == 'task_list') ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: page.isDone ? Colors.green.shade600 : Colors.grey.shade200,
                    foregroundColor: page.isDone ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(page.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
                  label: Text(
                    page.isDone ? 'Tamamlandı [✓]' : 'Tamamla',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await SocialStoryService().toggleStepDone(widget.book.id, page.id, widget.book.type);
                    setState(() {
                      page.isDone = !page.isDone;
                    });
                    if (page.isDone) {
                      _tts.speak('Harika! Bu adımı tamamladın.');
                    }
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- YATAY (LANDSCAPE) SAYFA GÖRÜNÜMÜ: TAM EKRAN BÜYÜME ---
  Widget _buildLandscapePage(SocialStoryPage page, int index, int total) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dev Tam Boy Büyüyen Resim (Kullanıcı İsteği: "Yatay tutunca sayfa büyüyecek")
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 80),
              child: _buildImageWidget(page.imagePath, fit: BoxFit.contain),
            ),
          ),

          // Altta Net Altyazı / Metin Çubuğu
          Positioned(
            bottom: 14,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                page.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Önceki Sayfa
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
            label: const Text('Önceki'),
            onPressed: _currentPage > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),

          // Nokta İndikatörleri
          Row(
            children: List.generate(
              total,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i ? Color(widget.book.coverColorValue) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Sonraki Sayfa
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(widget.book.coverColorValue),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(_currentPage == total - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded, size: 16),
            label: Text(_currentPage == total - 1 ? 'Bitir' : 'Sonraki'),
            onPressed: () {
              if (_currentPage < total - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String? path, {required BoxFit fit}) {
    if (path == null || path.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_size_select_actual_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Fotoğraf Eklenmedi', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
        ),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
        ),
      );
    }

    return Center(
      child: Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade400),
    );
  }
}
