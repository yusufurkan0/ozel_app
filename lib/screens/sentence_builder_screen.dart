import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sentence_strip.dart';
import '../widgets/category_tab_bar.dart';
import '../services/tts_service.dart';
import '../services/ai_aac_service.dart';
import '../services/parent_child_sync_service.dart';

/// Profesyonel AAC Cümle Oluşturucu Ekranı.
/// - Cümle şeridi ve canlı Türkçe cümle önizlemesi
/// - "İstiyorum", "İstemiyorum", "Ver", "Lütfen" gibi hızlı eylem/bağlaç çipleri
/// - Hazır iletişim kalıpları (şablonlar)
/// - Kategori sekmeli Makaton sembol ızgarası
/// - Sıralı sesli cümle okuma
class SentenceBuilderScreen extends StatefulWidget {
  final List<MakatonItem>? initialItems;
  const SentenceBuilderScreen({super.key, this.initialItems});

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final List<MakatonItem> _sentence = [];
  MakatonCategory? _category = MakatonCategory.actions;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  int _currentlyPlayingIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      _sentence.addAll(widget.initialItems!.take(8));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  List<MakatonItem> _getFilteredItems(GameProgressService game) {
    final all = game.allItems.where((i) => !i.isEmergency).toList();
    if (_category == null) return all;
    return all.where((i) => i.category == _category).toList();
  }

  String get _sentenceText {
    if (_sentence.isEmpty) return '';
    return _sentence.map((e) => e.label).join(' ');
  }

  void _addItem(MakatonItem item) {
    if (_sentence.length < 8) {
      setState(() => _sentence.add(item));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cümleye en fazla 8 sembol ekleyebilirsiniz.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _addQuickAction(String id) {
    final game = Provider.of<GameProgressService>(context, listen: false);
    final item = game.allItems.firstWhere(
      (element) => element.id == id,
      orElse: () => MakatonItem(
        id: id,
        label: id,
        icon: Icons.star_rounded,
        color: AppColors.buttonPurple,
        category: MakatonCategory.actions,
      ),
    );
    _addItem(item);
  }

  void _loadTemplate(List<String> ids) {
    final game = Provider.of<GameProgressService>(context, listen: false);
    setState(() {
      _sentence.clear();
      for (final id in ids) {
        final item = game.allItems.firstWhere((e) => e.id == id);
        _sentence.add(item);
      }
    });
  }

  Future<void> _playSentence() async {
    if (_sentence.isEmpty || _isPlaying) return;
    final game = Provider.of<GameProgressService>(context, listen: false);

    setState(() {
      _isPlaying = true;
      _currentlyPlayingIndex = 0;
    });

    if (game.soundEnabled) {
      // Gerçek Türkçe doğal insan sesiyle cümleyi oku
      await TtsService().speak(_sentenceText);
    }

    for (int i = 0; i < _sentence.length; i++) {
      if (!mounted) break;
      setState(() => _currentlyPlayingIndex = i);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentlyPlayingIndex = -1;
      });
      // İlerleme kaydet
      game.recordPress(_sentence.first.id);

      // Ebeveyn paneline kurulan tam cümleyi ve sembolleri ilet
      ParentChildSyncService().dispatchSpeechEvent(
        childName: game.childName.isNotEmpty ? game.childName : 'Öğrenci',
        words: _sentence.map((s) => s.label).toList(),
        emoji: _sentence.first.emoji,
        fullSentence: _sentenceText,
      );
    }
  }

  void _showTemplatesModal() {
    final templates = [
      {'title': '💧 Su İstiyorum Lütfen', 'ids': ['su', 'istiyorum', 'lutfen']},
      {'title': '🍽️ Yemek İstiyorum', 'ids': ['yemek', 'istiyorum']},
      {'title': '🎮 Oyun Oynamak İstiyorum', 'ids': ['oyun', 'oynamak_istiyorum']},
      {'title': '🚶 Parka Gidelim Lütfen', 'ids': ['park', 'gidelim', 'lutfen']},
      {'title': '🛁 Banyo Yapmak İstiyorum', 'ids': ['banyo', 'istiyorum']},
      {'title': '😴 Uyumak İstiyorum', 'ids': ['uyku', 'istiyorum']},
      {'title': '❤️ Seni Seviyorum', 'ids': ['sen', 'seviyorum']},
      {'title': '🤲 Bana Ver Lütfen', 'ids': ['ben', 'ver', 'lutfen']},
      {'title': '🤝 Yardım Et Lütfen', 'ids': ['yardim_et', 'lutfen']},
      {'title': '🏁 Oyun Bitti', 'ids': ['oyun', 'bitti']},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
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
                Icon(Icons.auto_stories_rounded, color: AppColors.buttonIndigo),
                SizedBox(width: 8),
                Text(
                  'Hazır İletişim Kalıpları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: templates.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final t = templates[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadTemplate(t['ids'] as List<String>);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: Neu.elevated(radius: 16, blur: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.add_circle_outline_rounded,
                              color: AppColors.buttonTeal, size: 22),
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

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();
    final displayItems = _getFilteredItems(game);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cümle Oluşturucu',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories_rounded),
            tooltip: 'Hazır Kalıplar',
            onPressed: _showTemplatesModal,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(game.themeIndex),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Cümle Şeridi ve Metin Alanı ───────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    SentenceStrip(
                      selectedItems: _sentence,
                      onRemove: (i) => setState(() => _sentence.removeAt(i)),
                      onClear: () => setState(() => _sentence.clear()),
                      playingIndex: _currentlyPlayingIndex,
                    ),
                    const SizedBox(height: 10),

                    // Cümle Yazılı Hali (Canlı Doğal Cümle)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: Neu.inset(radius: 16),
                      child: Row(
                        children: [
                          Icon(
                            _sentence.isEmpty
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.record_voice_over_rounded,
                            color: _sentence.isEmpty
                                ? AppColors.textSecondary
                                : AppColors.buttonIndigo,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _sentence.isEmpty
                                  ? 'Aşağıdan sembol ve eylemleri seçerek cümle kur...'
                                  : _sentenceText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _sentence.isEmpty
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: _sentence.isEmpty
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_sentence.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _sentence.clear()),
                              child: const Icon(Icons.close_rounded,
                                  color: AppColors.textSecondary, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Oynat ve Hazır Kalıplar Butonları ─────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: _playSentence,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: Neu.colored(
                            color: _sentence.isEmpty
                                ? AppColors.textSecondary.withValues(alpha: 0.5)
                                : AppColors.positiveGreen,
                            radius: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isPlaying
                                    ? '${_sentence[_currentlyPlayingIndex.clamp(0, _sentence.length - 1)].label}...'
                                    : 'Cümleyi Seslendir',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _showTemplatesModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: Neu.elevated(radius: 16, blur: 6),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lightbulb_outline_rounded,
                                  color: AppColors.buttonAmber, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Kalıplar',
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ─── 🤖 AI Sıradaki Kelime / Sembol Tahminleri ──────────
              _buildAiPredictionsStrip(context, game),
              const SizedBox(height: 6),

              // ─── Hızlı Eylem & Bağlaç Çipleri ──────────────
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _QuickActionChip(
                        emoji: '🙋',
                        label: 'İstiyorum',
                        color: AppColors.buttonPurple,
                        onTap: () => _addQuickAction('istiyorum'),
                      ),
                      _QuickActionChip(
                        emoji: '🙅',
                        label: 'İstemiyorum',
                        color: const Color(0xFFEF5350),
                        onTap: () => _addQuickAction('istemiyorum'),
                      ),
                      _QuickActionChip(
                        emoji: '🤲',
                        label: 'Ver',
                        color: const Color(0xFF81C784),
                        onTap: () => _addQuickAction('ver'),
                      ),
                      _QuickActionChip(
                        emoji: '🙏',
                        label: 'Lütfen',
                        color: AppColors.buttonTeal,
                        onTap: () => _addQuickAction('lutfen'),
                      ),
                      _QuickActionChip(
                        emoji: '🏁',
                        label: 'Bitti',
                        color: const Color(0xFF90A4AE),
                        onTap: () => _addQuickAction('bitti'),
                      ),
                      _QuickActionChip(
                        emoji: '➕',
                        label: 'Daha Fazla',
                        color: const Color(0xFF26A69A),
                        onTap: () => _addQuickAction('daha_fazla'),
                      ),
                      _QuickActionChip(
                        emoji: '👍',
                        label: 'Evet',
                        color: AppColors.positiveGreen,
                        onTap: () => _addQuickAction('evet'),
                      ),
                      _QuickActionChip(
                        emoji: '👎',
                        label: 'Hayır',
                        color: const Color(0xFFEF5350),
                        onTap: () => _addQuickAction('hayir'),
                      ),
                      _QuickActionChip(
                        emoji: '❤️',
                        label: 'Seviyorum',
                        color: AppColors.buttonPink,
                        onTap: () => _addQuickAction('seviyorum'),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Kategori Sekmeleri ────────────────────────
              CategoryTabBar(
                selected: _category,
                onSelected: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 6),

              // ─── Makaton Grid ──────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    return _SentenceGridItem(
                      item: item,
                      onTap: () => _addItem(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiPredictionsStrip(BuildContext context, GameProgressService game) {
    final predictions = AiAacService().predictNextItems(_sentence, game.allItems);
    if (predictions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.buttonPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.buttonPurple),
                    SizedBox(width: 4),
                    Text(
                      'AI Sıradaki Kelime Önerileri',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: predictions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = predictions[i];
                return GestureDetector(
                  onTap: () => _addItem(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: Neu.colored(
                      color: item.color,
                      radius: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.add_rounded, color: Colors.white70, size: 14),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🖼️ Profesyonel Görsel AAC İletişim Kartı
class _SentenceGridItem extends StatefulWidget {
  final MakatonItem item;
  final VoidCallback onTap;
  const _SentenceGridItem({required this.item, required this.onTap});

  @override
  State<_SentenceGridItem> createState() => _SentenceGridItemState();
}

class _SentenceGridItemState extends State<_SentenceGridItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.item.resolvedImagePath;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.item.color,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.item.color.withValues(alpha: 0.15),
                blurRadius: _pressed ? 2 : 8,
                offset: _pressed ? const Offset(0, 1) : const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🖼️ Görsel Alanı (Özel Makaton İllüstrasyonu veya Zengin Emoji Piktogramı)
              if (imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    height: 52,
                    width: 52,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.item.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              const SizedBox(height: 6),
              // 📝 Kelime Etiketi (AAC Yüksek Kontrastlı Okunabilir Metin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  widget.item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
