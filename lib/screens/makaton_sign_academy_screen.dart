import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/makaton_gesture.dart';
import '../services/game_progress_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// 🤲 Makaton El İşaretleri & Kart Öğrenme Akademisi
class MakatonSignAcademyScreen extends StatefulWidget {
  const MakatonSignAcademyScreen({super.key});

  @override
  State<MakatonSignAcademyScreen> createState() => _MakatonSignAcademyScreenState();
}

class _MakatonSignAcademyScreenState extends State<MakatonSignAcademyScreen> {
  late final List<MakatonGesture> _allGestures;
  String _selectedCategory = 'Tümü';
  MakatonGesture? _activeGesture;
  final Set<String> _learnedGestureIds = {};

  @override
  void initState() {
    super.initState();
    _allGestures = MakatonGesture.allGestures();
    _activeGesture = _allGestures.first;
    _loadLearnedGestures();
  }

  Future<void> _loadLearnedGestures() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('learned_gestures_v1') ?? [];
    if (mounted) {
      setState(() {
        _learnedGestureIds.addAll(list);
      });
    }
  }

  Future<void> _toggleLearned(MakatonGesture gesture) async {
    final prefs = await SharedPreferences.getInstance();
    final isLearned = _learnedGestureIds.contains(gesture.id);

    setState(() {
      if (isLearned) {
        _learnedGestureIds.remove(gesture.id);
      } else {
        _learnedGestureIds.add(gesture.id);
      }
    });

    await prefs.setStringList('learned_gestures_v1', _learnedGestureIds.toList());

    if (!isLearned && mounted) {
      final game = Provider.of<GameProgressService>(context, listen: false);
      game.recordSuccess();

      TtsService().speak('Tebrikler! ${gesture.word} el işaretini başarıyla öğrendin!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🌟 Harika! "${gesture.word}" el işaretini öğrendin!'),
          backgroundColor: AppColors.positiveGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Tümü', 'İhtiyaçlar', 'Sosyal', 'Eylemler'];
    final filtered = _selectedCategory == 'Tümü'
        ? _allGestures
        : _allGestures.where((g) => g.category == _selectedCategory).toList();

    final learnedCount = _learnedGestureIds.length;
    final totalCount = _allGestures.length;
    final progress = totalCount > 0 ? (learnedCount / totalCount) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🤲 El İşaretleri Akademisi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: Neu.inset(radius: 12),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$learnedCount / $totalCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme Özeti
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: Neu.elevated(radius: 16, blur: 6),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Öğrenilen El İşaretleri',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              '%${(progress * 100).toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.buttonIndigo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.neumorphicDark.withValues(alpha: 0.3),
                            color: AppColors.positiveGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kategori Çipleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: categories.map((cat) {
                final isSel = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: AppColors.buttonIndigo,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: AppColors.background,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Yatay Kart Seçim Şeridi
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final g = filtered[i];
                final isSelected = g.id == _activeGesture?.id;
                final isLearned = _learnedGestureIds.contains(g.id);

                return GestureDetector(
                  onTap: () {
                    setState(() => _activeGesture = g);
                    TtsService().speak(g.word);
                  },
                  child: Container(
                    width: 76,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: isSelected
                        ? Neu.colored(color: AppColors.buttonIndigo)
                        : Neu.elevated(radius: 16, blur: 4),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(g.emoji, style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 2),
                              Text(
                                g.word,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isLearned)
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Aktif İşaret Detay ve Öğrenme Paneli
          Expanded(
            child: _activeGesture == null
                ? const Center(child: Text('Lütfen bir kart seçiniz'))
                : _buildDetailPanel(_activeGesture!),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(MakatonGesture g) {
    final isLearned = _learnedGestureIds.contains(g.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Büyük Kart & Hareket Vitrini
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: Neu.elevated(radius: 24, blur: 10),
            child: Column(
              children: [
                // Başlık & Kategori
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: Neu.inset(radius: 10),
                      child: Text(
                        g.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonIndigo,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo, size: 28),
                      tooltip: 'Sesli Dinle',
                      onPressed: () => TtsService().speak('${g.word}. ${g.speechText}'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Kart Emojisi & Kelime
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(g.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.word,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          g.gestureTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 🖼️ Adım Adım Resimli Görsel Rehber
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.buttonIndigo.withValues(alpha: 0.25),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      g.imageAssetPath,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // "Hareketi Yap & Seslendir" Dinleme Butonu
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  icon: const Icon(Icons.record_voice_over_rounded, size: 20),
                  label: Text('Örnek Cümleyi Dinle: "${g.speechText}"'),
                  onPressed: () => TtsService().speak(g.speechText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 📖 Adım Adım Nasıl Yapılır? Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: Neu.elevated(radius: 20, blur: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_walk_rounded, color: AppColors.buttonTeal, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Adım Adım El Hareketi Rehberi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(g.steps.length, (idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.buttonIndigo,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            g.steps[idx],
                            style: const TextStyle(fontSize: 13, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 💡 Ebeveyn / Terapist İpucu Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ebeveyn & Öğretmen İpucu',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        g.parentTip,
                        style: TextStyle(fontSize: 12, color: Colors.brown.shade800, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ⭐ "Öğrendim!" Tamamlama Butonu
          GestureDetector(
            onTap: () => _toggleLearned(g),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: isLearned
                  ? Neu.colored(color: AppColors.positiveGreen)
                  : Neu.colored(color: AppColors.buttonPurple),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLearned ? Icons.check_circle_rounded : Icons.star_border_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isLearned ? 'Bu Hareketi Öğrendim! (Kazanıldı ⭐)' : 'Hareketi Yaptım & Öğrendim! ⭐',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
