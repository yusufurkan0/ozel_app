import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/kitchen_recipe.dart';
import '../../theme/app_theme.dart';
import 'cooking_step_by_step_screen.dart';

class KitchenRecipeDetailScreen extends StatefulWidget {
  final KitchenRecipe recipe;

  const KitchenRecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<KitchenRecipeDetailScreen> createState() => _KitchenRecipeDetailScreenState();
}

class _KitchenRecipeDetailScreenState extends State<KitchenRecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.5);
    } catch (_) {}
  }

  void _speak(String text) async {
    try {
      setState(() => _isSpeaking = true);
      await _tts.speak(text);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _stopTts() async {
    try {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } catch (_) {}
  }

  void _speakList(bool isIngredients) {
    if (isIngredients) {
      final text = 'Malzemeler kontrol listesi: ' +
          widget.recipe.ingredients.map((i) => '${i.amount ?? ''} ${i.name}').join(', ');
      _speak(text);
    } else {
      final text = 'Araç ve materyaller kontrol listesi: ' +
          widget.recipe.tools.map((t) => '${t.amount ?? ''} ${t.name}').join(', ');
      _speak(text);
    }
  }

  void _toggleAll(bool selectAll) {
    setState(() {
      for (final item in widget.recipe.ingredients) {
        item.isChecked = selectAll;
      }
      for (final item in widget.recipe.tools) {
        item.isChecked = selectAll;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final totalCount = recipe.ingredients.length + recipe.tools.length;
    final checkedCount = recipe.ingredients.where((i) => i.isChecked).length +
        recipe.tools.where((t) => t.isChecked).length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Özel Renkli App Bar & Başlık
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: recipe.themeColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (recipe.coverImagePath != null)
                    Image.asset(
                      recipe.coverImagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          recipe.themeColor.withValues(alpha: recipe.coverImagePath != null ? 0.85 : 1.0),
                          recipe.themeColor.withValues(alpha: recipe.coverImagePath != null ? 0.95 : 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '📖 Lezzet +1 Kitabı',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildHeaderBadge(Icons.people_outline_rounded, recipe.portions),
                            const SizedBox(width: 8),
                            _buildHeaderBadge(Icons.timer_outlined, '${recipe.prepTime} Hazırlık'),
                            const SizedBox(width: 8),
                            _buildHeaderBadge(Icons.soup_kitchen_outlined, '${recipe.steps.length} Adım'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

          // Kontrol Listesi İlerleme Çubuğu ve Butonlar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            progress >= 1.0 ? Icons.check_circle_rounded : Icons.checklist_rounded,
                            color: progress >= 1.0 ? Colors.green : recipe.themeColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kontrol Listesi: $checkedCount / $totalCount Hazır',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '%${(progress * 100).toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: progress >= 1.0 ? Colors.green : recipe.themeColor,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Colors.green : recipe.themeColor,
                      ),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('Hepsini Seç'),
                        style: TextButton.styleFrom(
                          foregroundColor: recipe.themeColor,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _toggleAll(true),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        label: const Text('Temizle'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _toggleAll(false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Malzeme ve Araçlar Sekmesi (TabBar)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: recipe.themeColor,
                indicatorWeight: 3,
                labelColor: recipe.themeColor,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.local_grocery_store_outlined),
                    text: 'Malzemeler (${recipe.ingredients.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.kitchen_rounded),
                    text: 'Araçlar (${recipe.tools.length})',
                  ),
                ],
              ),
            ),
          ),

          // Kontrol Listesi İçeriği
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final isIngredients = _tabController.index == 0;
                  final list = isIngredients ? recipe.ingredients : recipe.tools;

                  return Column(
                    children: [
                      // Sesli Oku & Bilgi Başlığı
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isIngredients ? 'Gerekli Malzemeler' : 'Gerekli Araç & Gereçler',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              icon: Icon(
                                _isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                size: 18,
                              ),
                              label: Text(_isSpeaking ? 'Durdur' : 'Sesli Dinle'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.buttonIndigo),
                              onPressed: _isSpeaking ? _stopTts : () => _speakList(isIngredients),
                            ),
                          ],
                        ),
                      ),

                      // İşaretlenebilir Liste
                      ...list.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: item.isChecked
                                ? recipe.themeColor.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isChecked
                                  ? recipe.themeColor.withValues(alpha: 0.4)
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                item.isChecked = !item.isChecked;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  // Kontrol Kutusu
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: item.isChecked ? recipe.themeColor : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: item.isChecked ? recipe.themeColor : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: item.isChecked
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),

                                  // Öğe İkonu veya Fotoğrafı
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: recipe.themeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: recipe.themeColor.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: item.imagePath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(11),
                                            child: Image.asset(
                                              item.imagePath!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(item.icon, color: recipe.themeColor, size: 24),
                                            ),
                                          )
                                        : Icon(item.icon, color: recipe.themeColor, size: 24),
                                  ),
                                  const SizedBox(width: 14),

                                  // İsim ve Miktar
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: item.isChecked ? Colors.grey.shade700 : AppColors.textPrimary,
                                            decoration: item.isChecked
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                          ),
                                        ),
                                        if (item.amount != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.amount!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  if (item.isChecked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Hazır 👍',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
                      // Açıklama Kutusu
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                recipe.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Alt Sabit Aksiyon Butonu (Adım Adım Başla)
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: recipe.themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.soup_kitchen_rounded, size: 24),
                  label: Text(
                    'Adım Adım Pişirmeye Başla (${recipe.steps.length} Adım) ▶',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    _stopTts();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CookingStepByStepScreen(recipe: recipe),
                      ),
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

  Widget _buildHeaderBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
