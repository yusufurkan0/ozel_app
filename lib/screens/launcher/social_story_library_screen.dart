import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/social_story_book.dart';
import '../../services/social_story_service.dart';
import '../../widgets/safe_image_widget.dart';
import 'social_story_book_editor_screen.dart';
import 'social_story_reader_screen.dart';
import '../../theme/app_theme.dart';

/// Özel Gereksinimli Çocuklar İçin Sosyal Öykü Kütüphanesi Ekranı
/// (Special Stories uyumlu, boş kütüphane, kitap oluşturma, sayfa ekleme)
class SocialStoryLibraryScreen extends StatefulWidget {
  final String type; // 'social_story' veya 'task_list'
  final bool isEmbedded;

  const SocialStoryLibraryScreen({
    super.key,
    this.type = 'social_story',
    this.isEmbedded = false,
  });

  @override
  State<SocialStoryLibraryScreen> createState() => _SocialStoryLibraryScreenState();
}

class _SocialStoryLibraryScreenState extends State<SocialStoryLibraryScreen> {
  final SocialStoryService _service = SocialStoryService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.loadBooks(type: widget.type);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<String?> _processPickedImage(XFile picked) async {
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
    return picked.path;
  }

  void _openCreateBookDialog() {
    final titleCtrl = TextEditingController();
    int selectedColor = 0xFF7C3AED;
    String? coverImagePath;

    final List<int> colorPalette = [
      0xFF7C3AED, // Mor
      0xFF2563EB, // Mavi
      0xFF0D9488, // Teal
      0xFFD97706, // Amber
      0xFFE11D48, // Gül
      0xFF4F46E5, // İndigo
      0xFF059669, // Zümrüt
      0xFFDB2777, // Pembe
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: Color(selectedColor)),
              const SizedBox(width: 10),
              Text(
                widget.type == 'task_list' ? 'Yeni Görev Kitabı' : 'Yeni Sosyal Öykü Kitabı',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kitap Başlığı
                const Text('Kitap Adı / Konusu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.type == 'task_list'
                        ? 'Örn: Sabah Hazırlanma Görevleri'
                        : 'Örn: Dişlerimi Fırçalıyorum',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 16),

                // Kapak Rengi Seçimi
                const Text('Kapak Rengi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorPalette.map((c) {
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: isSel
                              ? [BoxShadow(color: Color(c).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                        child: isSel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Kapak Fotoğrafı
                const Text('Kapak Fotoğrafı (İsteğe Bağlı):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                if (coverImagePath != null)
                  Stack(
                    children: [
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: buildSafeImage(coverImagePath, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 14,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            onPressed: () => setDialogState(() => coverImagePath = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Foto Çek', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final p = await ImagePicker().pickImage(source: ImageSource.camera);
                            if (p != null) {
                              final path = await _processPickedImage(p);
                              setDialogState(() => coverImagePath = path);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.photo_library_rounded, size: 18),
                          label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final p = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (p != null) {
                              final path = await _processPickedImage(p);
                              setDialogState(() => coverImagePath = path);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(selectedColor),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final newBook = SocialStoryBook(
                  id: 'book_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  coverColorValue: selectedColor,
                  coverImagePath: coverImagePath,
                  type: widget.type,
                );

                await _service.saveBook(newBook);
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});

                // Kitap oluştuktan sonra doğrudan sayfa ekleme ekranını aç
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SocialStoryBookEditorScreen(book: newBook),
                    ),
                  ).then((_) => setState(() {}));
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBook(SocialStoryBook book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kitabı Sil'),
        content: Text('"${book.title}" kitabını ve içindeki tüm sayfaları silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _service.deleteBook(book.id, widget.type);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTask = widget.type == 'task_list';
    final books = _service.getBooks(widget.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Icon(
                    isTask ? Icons.checklist_rounded : Icons.auto_stories_rounded,
                    color: isTask ? Colors.amber.shade800 : const Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isTask ? 'Görev Kitaplarım' : 'Sosyal Öykü Kütüphanem',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF7C3AED), size: 28),
                  tooltip: 'Yeni Kitap Ekle',
                  onPressed: _openCreateBookDialog,
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
              // Kullanıcı İsteği: Boş kütüphane olacak, ana ekranda kitap ekle tuşu
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTask ? Icons.playlist_add_rounded : Icons.menu_book_rounded,
                            size: 52,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isTask ? 'Görev Kütüphaneniz Boş' : 'Kütüphaneniz Henüz Boş',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isTask
                              ? 'Kendi fotoğraflarınla adım adım görev kitapları oluşturmak için aşağıdaki butona dokun.'
                              : 'Kendi çektiğin fotoğraflarla sosyal öykü kitapları oluşturmak için aşağıdaki butona dokun.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.45),
                        ),
                        const SizedBox(height: 26),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 3,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 24),
                          label: Text(
                            isTask ? 'Yeni Görev Kitabı Ekle' : 'Yeni Kitap Ekle',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: _openCreateBookDialog,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final themeColor = Color(book.coverColorValue);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: themeColor.withValues(alpha: 0.25), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            if (book.pages.isEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SocialStoryBookEditorScreen(book: book),
                                ),
                              ).then((_) => setState(() {}));
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SocialStoryReaderScreen(book: book),
                                ),
                              ).then((_) => setState(() {}));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Kitap Kapağı Kartı
                                Container(
                                  width: 84,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: book.coverImagePath != null
                                        ? buildSafeImage(book.coverImagePath, fit: BoxFit.cover)
                                        : Center(
                                            child: Icon(
                                              isTask ? Icons.task_alt_rounded : Icons.auto_stories_rounded,
                                              color: Colors.white,
                                              size: 38,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Kitap Bilgileri
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: themeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${book.pages.length} Sayfa',
                                          style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(60, 30),
                                              foregroundColor: themeColor,
                                            ),
                                            icon: const Icon(Icons.edit_rounded, size: 16),
                                            label: const Text('Sayfalar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => SocialStoryBookEditorScreen(book: book),
                                                ),
                                              ).then((_) => setState(() {}));
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(60, 30),
                                              foregroundColor: Colors.redAccent,
                                            ),
                                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                            label: const Text('Sil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            onPressed: () => _deleteBook(book),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isTask ? Colors.amber.shade800 : const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          isTask ? 'Yeni Görev Kitabı Ekle' : 'Yeni Kitap Ekle',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _openCreateBookDialog,
      ),
    );
  }
}
