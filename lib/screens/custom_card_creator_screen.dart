import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// Ebeveyn ve uzmanlar için Özel Makaton Kartı Oluşturma Stüdyosu.
///
/// Özellikler:
/// - Kart adı & kategori seçimi
/// - Kamera veya Galeriden gerçek fotoğraf yükleme
/// - 16 sembol ikon seçimi
/// - Ebeveyn / Terapist mikrofon ses kaydı (Kendi sesiyle kart seslendirme)
/// - 8 Neumorphic renk paleti
/// - Anında önizleme, TTS veya ses kaydı testi
/// - Eklenen kartları silme ve yönetme
class CustomCardCreatorScreen extends StatefulWidget {
  const CustomCardCreatorScreen({super.key});

  @override
  State<CustomCardCreatorScreen> createState() =>
      _CustomCardCreatorScreenState();
}

class _CustomCardCreatorScreenState extends State<CustomCardCreatorScreen> {
  final TextEditingController _labelCtrl = TextEditingController();
  MakatonCategory _selectedCategory = MakatonCategory.activities;
  Color _selectedColor = AppColors.buttonBlue;
  IconData _selectedIcon = Icons.pets_rounded;

  // Fotoğraf ve Ses Kaydı Durumları
  String? _pickedImagePath;
  String? _recordedAudioPath;
  bool _isRecording = false;
  int _recordDurationSec = 0;
  Timer? _recordTimer;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();

  static const List<IconData> _availableIcons = [
    Icons.pets_rounded, // Evcil hayvan / Kedi / Köpek
    Icons.toys_rounded, // Oyuncak
    Icons.family_restroom_rounded, // Aile / Akraba
    Icons.star_rounded, // Özel eşya
    Icons.favorite_rounded, // Sevilen şey
    Icons.sports_soccer_rounded, // Top
    Icons.car_rental_rounded, // Araba
    Icons.music_note_rounded, // Enstrüman
    Icons.local_cafe_rounded, // İçecek
    Icons.fastfood_rounded, // Özel atıştırmalık
    Icons.park_rounded, // Park / Doğa
    Icons.bed_rounded, // Yatak / Dinlenme
    Icons.brush_rounded, // Boyama
    Icons.videogame_asset_rounded, // Konsol
    Icons.tv_rounded, // Çizgi film / TV
    Icons.phone_android_rounded, // Tablet / Telefon
  ];

  static const List<Color> _availableColors = [
    AppColors.buttonBlue,
    AppColors.buttonGreen,
    AppColors.buttonPink,
    AppColors.buttonOrange,
    AppColors.buttonPurple,
    AppColors.buttonTeal,
    AppColors.buttonIndigo,
    AppColors.buttonAmber,
  ];

  @override
  void dispose() {
    _recordTimer?.cancel();
    _labelCtrl.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ─── Fotoğraf Seçimi ──────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (photo != null) {
        if (kIsWeb) {
          setState(() {
            _pickedImagePath = photo.path;
          });
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'card_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = await File(photo.path).copy('${appDir.path}/$fileName');
          setState(() {
            _pickedImagePath = savedImage.path;
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

  // ─── Mikrofon Ses Kaydı ──────────────────────────────────────
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final appDir = await getApplicationDocumentsDirectory();
        final filePath =
            '${appDir.path}/card_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordDurationSec = 0;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_recordDurationSec >= 15) {
            _stopRecording();
          } else {
            setState(() => _recordDurationSec++);
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni gerekli!')),
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
          _recordedAudioPath = path;
        }
      });
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedAudioPath != null &&
        (kIsWeb || File(_recordedAudioPath!).existsSync())) {
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource(_recordedAudioPath!));
      } else {
        await _audioPlayer.play(DeviceFileSource(_recordedAudioPath!));
      }
    }
  }

  void _saveCard() {
    final text = _labelCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kart için bir isim girin!')),
      );
      return;
    }

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = MakatonItem(
      id: id,
      label: text,
      icon: _selectedIcon,
      color: _selectedColor,
      category: _selectedCategory,
      imagePath: _pickedImagePath,
      customAudioPath: _recordedAudioPath,
      preferredSlots: TimeSlot.values,
    );

    context.read<GameProgressService>().addCustomItem(newItem);

    setState(() {
      _labelCtrl.clear();
      _pickedImagePath = null;
      _recordedAudioPath = null;
      _recordDurationSec = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$text" sembolü başarıyla eklendi! ✨'),
        backgroundColor: AppColors.positiveGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Özel Kart Oluşturucu'),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(game.themeIndex),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Kart Oluşturma Formu ────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: Neu.elevated(radius: 28, blur: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yeni Sembol Bilgileri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // İsim Girişi
                      TextField(
                        controller: _labelCtrl,
                        decoration: InputDecoration(
                          hintText: 'Kart İsmi (Örn: Pamuk, Arabam, Anneanne)',
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.edit_note_rounded,
                              color: AppColors.buttonBlue),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Kategori Seçimi
                      const Text(
                        'Kategori:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<MakatonCategory>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: MakatonCategory.values
                            .where((c) => c != MakatonCategory.emergency)
                            .map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(cat.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (cat) {
                          if (cat != null) setState(() => _selectedCategory = cat);
                        },
                      ),
                      const SizedBox(height: 20),

                      // ─── Fotoğraf Seçeneği (Kamera & Galeri) ─────────
                      const Text(
                        '📸 Gerçek Fotoğraf Ekle (Tavsiye Edilir):',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Çocuğun kendi bardağı, oyuncağı veya aile bireyinin fotoğrafı algılamayı hızlandırır.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),

                      if (_pickedImagePath != null &&
                          (kIsWeb || File(_pickedImagePath!).existsSync()))
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: kIsWeb
                                  ? Image.network(
                                      _pickedImagePath!,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image_rounded),
                                      ),
                                    )
                                  : Image.file(
                                      File(_pickedImagePath!),
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image_rounded),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fotoğraf Seçildi ✅',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  TextButton.icon(
                                    onPressed: () => setState(() => _pickedImagePath = null),
                                    icon: const Icon(Icons.delete_outline_rounded,
                                        size: 18, color: Colors.redAccent),
                                    label: const Text('Fotoğrafı Kaldır',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                label: const Text('Kamera', style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded, size: 18),
                                label: const Text('Galeri', style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 18),

                      // Fotoğraf yoksa İkon Seçimi
                      if (_pickedImagePath == null) ...[
                        const Text(
                          'Veya Sembol İkonu Seçin:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 54,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableIcons.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final icon = _availableIcons[i];
                              final sel = _selectedIcon == icon;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedIcon = icon),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 50,
                                  decoration: sel
                                      ? Neu.colored(color: _selectedColor, radius: 14)
                                      : Neu.elevated(radius: 14, blur: 4),
                                  child: Icon(
                                    icon,
                                    color: sel ? Colors.white : AppColors.textPrimary,
                                    size: 26,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // ─── Mikrofon Ses Kaydı ─────────────────────────
                      const Text(
                        '🎙️ Kendi Sesinizle Kaydedin (Opsiyonel):',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Anne, baba veya terapistin sıcak sesi çocukta konuşma taklidini güçlendirir.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: Neu.inset(radius: 16),
                        child: Row(
                          children: [
                            if (_isRecording) ...[
                              const Icon(Icons.fiber_manual_record_rounded,
                                  color: Colors.red, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Kaydediliyor: $_recordDurationSec sn / 15 sn',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: _stopRecording,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Durdur'),
                              ),
                            ] else if (_recordedAudioPath != null) ...[
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.positiveGreen, size: 24),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('Sesiniz Kaydedildi! 🎙️',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                              IconButton(
                                onPressed: _playRecordedAudio,
                                icon: const Icon(Icons.play_circle_fill_rounded,
                                    color: AppColors.buttonBlue, size: 30),
                                tooltip: 'Dinle',
                              ),
                              IconButton(
                                onPressed: () => setState(() => _recordedAudioPath = null),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 22),
                                tooltip: 'Sil',
                              ),
                            ] else ...[
                              const Expanded(
                                child: Text(
                                  'Henüz ses kaydı yok. TTS (robot sesi) kullanılır.',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _startRecording,
                                icon: const Icon(Icons.mic_rounded, size: 18),
                                label: const Text('Ses Kaydet'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonTeal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Renk Seçimi
                      const Text(
                        'Kart Rengi:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _availableColors.map((col) {
                          final sel = _selectedColor == col;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = col),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                                border: sel
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: col.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Önizleme & Ses Testi
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            if (_recordedAudioPath != null) {
                              _playRecordedAudio();
                            } else {
                              final txt = _labelCtrl.text.trim();
                              if (txt.isNotEmpty) {
                                TtsService().speak(txt);
                              } else {
                                TtsService().speak('Örnek kart');
                              }
                            }
                          },
                          icon: Icon(
                            _recordedAudioPath != null
                                ? Icons.record_voice_over_rounded
                                : Icons.volume_up_rounded,
                            color: AppColors.buttonIndigo,
                          ),
                          label: Text(
                            _recordedAudioPath != null
                                ? 'Kaydettiğiniz Sesi Dinle'
                                : 'Telaffuzu Dinle (TTS)',
                            style: const TextStyle(color: AppColors.buttonIndigo),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Kaydet Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _saveCard,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Kartı Kaydet ve Ekle',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Eklenen Özel Kartlar Listesi ─────────
                const Text(
                  'Eklediğiniz Özel Kartlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (game.customItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: Neu.elevated(radius: 20, blur: 6),
                    child: const Column(
                      children: [
                        Text('📦', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          'Henüz özel bir kart oluşturulmadı.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Yukarıdaki formu doldurarak çocuğunuzun sevdiği eşyaları ekleyebilirsiniz.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: game.customItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = game.customItems[i];
                      final hasPhoto = item.imagePath != null &&
                          (kIsWeb
                              ? (item.imagePath!.startsWith('http') ||
                                  item.imagePath!.startsWith('blob:') ||
                                  item.imagePath!.startsWith('data:'))
                              : File(item.imagePath!).existsSync());
                      final hasVoice = item.customAudioPath != null &&
                          (kIsWeb || File(item.customAudioPath!).existsSync());

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: Neu.elevated(radius: 18, blur: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: hasPhoto
                                  ? (kIsWeb
                                      ? Image.network(
                                          item.imagePath!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(item.imagePath!),
                                          fit: BoxFit.cover,
                                        ))
                                  : Icon(item.icon,
                                      color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '${item.category.emoji} ${item.category.label}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (hasPhoto) ...[
                                        const SizedBox(width: 6),
                                        const Text('• 📸 Fotoğraflı',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.buttonIndigo,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                      if (hasVoice) ...[
                                        const SizedBox(width: 6),
                                        const Text('• 🎙️ Sesli',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.buttonTeal,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Dinle butonu
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded,
                                  color: AppColors.buttonBlue),
                              onPressed: () {
                                if (hasVoice) {
                                  _audioPlayer.play(
                                      DeviceFileSource(item.customAudioPath!));
                                } else {
                                  TtsService().speak(item.label);
                                }
                              },
                            ),
                            // Sil butonu
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                              onPressed: () {
                                game.removeCustomItem(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"${item.label}" silindi.'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
