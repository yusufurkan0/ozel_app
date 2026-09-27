import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../services/pdf_generator_service.dart';
import '../theme/app_theme.dart';

/// 📄 PECS & Makaton Kart Yazdırıcı Ekranı
class PecsPrinterScreen extends StatefulWidget {
  const PecsPrinterScreen({super.key});

  @override
  State<PecsPrinterScreen> createState() => _PecsPrinterScreenState();
}

class _PecsPrinterScreenState extends State<PecsPrinterScreen> {
  final PdfGeneratorService _pdfService = PdfGeneratorService();
  final Set<String> _selectedItemIds = {};
  String _selectedCategory = 'tumu';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Başlangıçta tüm kartları seçili getir
    final game = Provider.of<GameProgressService>(context, listen: false);
    for (final item in game.allItems) {
      _selectedItemIds.add(item.id);
    }
  }

  void _selectAll(List<MakatonItem> items) {
    setState(() {
      for (final item in items) {
        _selectedItemIds.add(item.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItemIds.clear();
    });
  }

  Future<void> _printOrPreviewPdf() async {
    final game = Provider.of<GameProgressService>(context, listen: false);
    final itemsToPrint = game.allItems
        .where((item) => _selectedItemIds.contains(item.id))
        .toList();

    if (itemsToPrint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yazdırmak için en az bir kart seçin.')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final pdfData = await _pdfService.generatePecsPdf(itemsToPrint);
      await Printing.layoutPdf(
        onLayout: (_) => pdfData,
        name: 'Makaton_PECS_Kartlari.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yazdırma hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _sharePdf() async {
    final game = Provider.of<GameProgressService>(context, listen: false);
    final itemsToPrint = game.allItems
        .where((item) => _selectedItemIds.contains(item.id))
        .toList();

    if (itemsToPrint.isEmpty) return;

    setState(() => _isGenerating = true);
    try {
      final pdfData = await _pdfService.generatePecsPdf(itemsToPrint);
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'Makaton_PECS_Kartlari.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paylaşma hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProgressService>(context);
    final allItems = game.allItems;

    final categories = [
      {'id': 'tumu', 'label': 'Tümü'},
      {'id': 'ihtiyac', 'label': 'İhtiyaç'},
      {'id': 'yiyecek', 'label': 'Yiyecek'},
      {'id': 'duygu', 'label': 'Duygular'},
      {'id': 'eylem', 'label': 'Eylemler'},
      {'id': 'sosyal', 'label': 'Sosyal'},
      {'id': 'ozel', 'label': 'Özel Kartlar'},
    ];

    final filteredItems = _selectedCategory == 'tumu'
        ? allItems
        : allItems.where((i) => i.category.name == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📄 PDF & PECS Kart Yazdırıcı'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.buttonIndigo),
            tooltip: 'PDF Olarak Paylaş',
            onPressed: _isGenerating ? null : _sharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Üst Kontrol & Bilgi Barı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: Neu.elevated(radius: 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seçili: ${_selectedItemIds.length} / ${allItems.length} Kart',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _selectAll(allItems),
                          child: const Text('Tümünü Seç'),
                        ),
                        TextButton(
                          onPressed: _clearSelection,
                          child: const Text('Temizle'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Kategori Filtre Çipleri
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSel = _selectedCategory == cat['id'];
                      return FilterChip(
                        selected: isSel,
                        label: Text(cat['label']!),
                        selectedColor: AppColors.buttonIndigo.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.buttonIndigo,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? AppColors.buttonIndigo : AppColors.textPrimary,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedCategory = cat['id']!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Kartlar Listesi / Izgarası
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isSelected = _selectedItemIds.contains(item.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedItemIds.remove(item.id);
                      } else {
                        _selectedItemIds.add(item.id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.positiveGreen
                            : AppColors.neumorphicDark.withValues(alpha: 0.5),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.positiveGreen.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? AppColors.positiveGreen
                                : AppColors.textSecondary.withValues(alpha: 0.4),
                            size: 20,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 36)),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Alt Buton: Yazdır ve Önizle
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: Neu.elevated(radius: 0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print_rounded),
                label: Text(
                  _isGenerating
                      ? 'PDF Hazırlanıyor...'
                      : 'A4 Kart Çıktısı Al (${_selectedItemIds.length} Kart)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isGenerating ? null : _printOrPreviewPdf,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
