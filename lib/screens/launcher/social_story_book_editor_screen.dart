import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/social_story_book.dart';
import '../../services/social_story_service.dart';
import '../../widgets/safe_image_widget.dart';
import 'social_story_reader_screen.dart';
import '../../theme/app_theme.dart';

/// Sosyal Öykü Kitabı Düzenleyicisi
/// (Sayfa ekleme, fotoğraf çekme/yükleme, ses kaydı yapma ve sayfaları yönetme)
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
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: themeColor, size: 26),
            tooltip: 'Sayfa Ekle',
            onPressed: () => _openPageEditorDialog(),
          ),
          if (pages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('Kitabı Oku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      'Kendi çektiğin fotoğrafları ekleyerek, metnini yazarak ve sesini kaydederek istediğin kadar sayfa oluşturabilirsin.',
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
                            child: buildSafeImage(page.imagePath, fit: BoxFit.cover),
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
                                  const SizedBox(width: 6),
                                  if (page.audioPath != null && page.audioPath!.isNotEmpty) ...[
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
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.volume_up_rounded, size: 12, color: Colors.blue.shade700),
                                          const SizedBox(width: 3),
                                          Text('TTS Okuma', style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
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
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _imagePath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          });
        } else {
          setState(() {
            _imagePath = picked.path;
          });
        }
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
        String filePath = '';
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          filePath = '${dir.path}/story_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

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
      height: MediaQuery.of(context).size.height * 0.92,
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FOTOĞRAF ALANI (Kendi çektiği veya telefonunda olan fotoğraflar)
                  const Text('1. Sayfa Fotoğrafı (Tek Bir Resim) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),

                  if (_imagePath != null)
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: buildSafeImage(_imagePath, fit: BoxFit.contain),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                              onPressed: () => setState(() => _imagePath = null),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('Fotoğraf Çek'),
                                onPressed: () => _pickImage(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.photo_library_rounded),
                                label: const Text('Galeriden Seç'),
                                onPressed: () => _pickImage(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // 2. METİN ALANI (Her sayfada bir metin)
                  const Text('2. Sayfa Cümlesi / Metni *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Örn: Parkta salıncakta sırayla sallanırız ve birbirimize gülümseriz.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. SES KAYDI ALANI (Ses kaydı yapma veya TTS dinleme)
                  const Text('3. Seslendirme (Kendi Sesinle Kaydet veya TTS) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        if (_isRecording) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Kayıt Yapılıyor: 00:${_recordSeconds.toString().padLeft(2, '0')} / 01:00',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Kaydı Durdur'),
                            onPressed: _stopRecording,
                          ),
                        ] else if (_audioPath != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('Özel Ses Kaydı Alındı! 🎙️', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.blue, size: 30),
                                tooltip: 'Dinle',
                                onPressed: _playRecording,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                                tooltip: 'Kaydı Sil',
                                onPressed: () => setState(() => _audioPath = null),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Row(
                            children: [
                              Icon(Icons.mic_none_rounded, color: Color(0xFF64748B), size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kendi sesinle okumak istersen kaydet, kaydetmezsen metin otomatik seslendirilecektir.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              foregroundColor: themeColor,
                              side: BorderSide(color: themeColor),
                            ),
                            icon: const Icon(Icons.mic_rounded),
                            label: const Text('Mikrofon ile Sesini Kaydet'),
                            onPressed: _startRecording,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Sayfayı Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () {
                final text = _textCtrl.text.trim();
                if (text.isEmpty && _imagePath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen sayfaya en az bir metin veya fotoğraf ekleyiniz.')),
                  );
                  return;
                }

                final newPage = SocialStoryPage(
                  id: widget.existingPage?.id ?? 'page_${DateTime.now().millisecondsSinceEpoch}',
                  text: text,
                  imagePath: _imagePath,
                  audioPath: _audioPath,
                  pageNumber: widget.existingPage?.pageNumber ?? (widget.book.pages.length + 1),
                );

                widget.onSaved(newPage);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
