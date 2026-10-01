import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/social_story_book.dart';
import '../../services/social_story_service.dart';
import 'social_story_reader_screen.dart';
import '../../theme/app_theme.dart';

class SocialStoryBookEditorScreen extends StatefulWidget {
  final SocialStoryBook book;

  const SocialStoryBookEditorScreen({
    super.key,
    required this.book,
  });

  @override
  State<SocialStoryBookEditorScreen> createState() => _SocialStoryBookEditorScreenState();
}

class _SocialStoryBookEditorScreenState extends State<SocialStoryBookEditorScreen> {
  final SocialStoryService _service = SocialStoryService();
  late SocialStoryBook _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  void _openPageEditorDialog({SocialStoryPage? existingPage}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PageEditorModal(
        book: _book,
        existingPage: existingPage,
        onSaved: (page) async {
          if (existingPage == null) {
            await _service.addPageToBook(_book.id, page, _book.type);
          } else {
            await _service.updatePage(_book.id, page, _book.type);
          }
          setState(() {
            _book = _service.getBooks(_book.type).firstWhere(
                  (b) => b.id == _book.id,
                  orElse: () => _book,
                );
          });
        },
      ),
    );
  }

  void _deletePage(String pageId) async {
    await _service.deletePage(_book.id, pageId, _book.type);
    setState(() {
      _book = _service.getBooks(_book.type).firstWhere(
            (b) => b.id == _book.id,
            orElse: () => _book,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _book.pages;
    final themeColor = Color(_book.coverColorValue);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _book.title,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '${pages.length} Sayfa • ${_book.type == "task_list" ? "Görev Kitabı" : "Sosyal Öykü"}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (pages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('Kitabı Oku', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SocialStoryReaderScreen(book: _book),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: pages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_stories_rounded, size: 48, color: themeColor),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bu Kitapta Henüz Sayfa Yok',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kendi çektiğin fotoğrafları ekleyerek, metnini yazarak ve sesini kaydederek ilk sayfanı oluşturabilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
                      label: const Text('İlk Sayfayı Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () => _openPageEditorDialog(),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Sayfa Görseli
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildThumbnail(page.imagePath),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Bilgiler
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Sayfa ${index + 1}',
                                      style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                  if (page.audioPath != null && page.audioPath!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.mic_rounded, size: 12, color: Colors.green.shade700),
                                          const SizedBox(width: 3),
                                          Text('Ses Kayıtlı', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                page.text.isNotEmpty ? page.text : '(Metin eklenmedi)',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),

                        // Düzenle & Sil Menüsü
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                          tooltip: 'Düzenle',
                          onPressed: () => _openPageEditorDialog(existingPage: page),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Sil',
                          onPressed: () => _deletePage(page.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sayfa Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openPageEditorDialog(),
      ),
    );
  }

  Widget _buildThumbnail(String? path) {
    if (path == null || path.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 30));
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey));
  }
}

// ==========================================
// SAYFA DÜZENLEME & SES/FOTOĞRAF KAYDI MODALI
// ==========================================
class _PageEditorModal extends StatefulWidget {
  final SocialStoryBook book;
  final SocialStoryPage? existingPage;
  final Function(SocialStoryPage) onSaved;

  const _PageEditorModal({
    required this.book,
    this.existingPage,
    required this.onSaved,
  });

  @override
  State<_PageEditorModal> createState() => _PageEditorModalState();
}

class _PageEditorModalState extends State<_PageEditorModal> {
  late TextEditingController _textCtrl;
  String? _imagePath;
  String? _audioPath;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.existingPage?.text ?? '');
    _imagePath = widget.existingPage?.imagePath;
    _audioPath = widget.existingPage?.audioPath;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/story_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_recordSeconds >= 60) {
            _stopRecording();
          } else {
            setState(() => _recordSeconds++);
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni verilmedi!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ses kaydı başlatılamadı: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _audioPath = path;
        }
      });
    } catch (_) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _playRecording() async {
    if (_audioPath != null) {
      try {
        if (kIsWeb) {
          await _audioPlayer.play(UrlSource(_audioPath!));
        } else {
          await _audioPlayer.play(DeviceFileSource(_audioPath!));
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(widget.book.coverColorValue);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingPage == null ? 'Yeni Sayfa Ekle' : 'Sayfayı Düzenle',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FOTOĞRAF ALANI
                  const Text('1. Sayfa Fotoğrafı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: _imagePath != null
                        ? Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: _imagePath!.startsWith('assets/')
                                      ? Image.asset(_imagePath!, fit: BoxFit.cover)
                                      : Image.file(File(_imagePath!), fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 18,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                                    onPressed: () => setState(() => _imagePath = null),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                                  label: const Text('Fotoğraf Çek'),
                                  onPressed: () => _pickImage(ImageSource.camera),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: themeColor,
                                    side: BorderSide(color: themeColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                                  label: const Text('Galeriden Seç'),
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),

                  // 2. METİN ALANI
                  const Text('2. Sayfa Metni / Cümlesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Örn: Okul servisi geldiğinde sırayla kapıdan binerim.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. SES KAYDI ALANI
                  const Text('3. Kendi Sesinle Kayıt Yap (İsteğe Bağlı)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red.shade50 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _isRecording ? Colors.red : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                          label: Text(_isRecording ? 'Durdur (${_recordSeconds}s)' : 'Ses Kaydet'),
                          onPressed: () {
                            if (_isRecording) {
                              _stopRecording();
                            } else {
                              _startRecording();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        if (_audioPath != null) ...[
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.green, size: 36),
                            tooltip: 'Dinle',
                            onPressed: _playRecording,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
                            tooltip: 'Kaydı Sil',
                            onPressed: () => setState(() => _audioPath = null),
                          ),
                        ] else
                          const Expanded(
                            child: Text(
                              'Ses kaydı yapılmazsa metin otomatik seslendirilir.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // KAYDET BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        final text = _textCtrl.text.trim();
                        final pageId = widget.existingPage?.id ?? 'page_${DateTime.now().millisecondsSinceEpoch}';
                        final pageNum = widget.existingPage?.pageNumber ?? widget.book.pages.length + 1;

                        final page = SocialStoryPage(
                          id: pageId,
                          text: text,
                          imagePath: _imagePath,
                          audioPath: _audioPath,
                          isDone: widget.existingPage?.isDone ?? false,
                          pageNumber: pageNum,
                        );

                        widget.onSaved(page);
                        Navigator.pop(context);
                      },
                      child: const Text('Sayfayı Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
