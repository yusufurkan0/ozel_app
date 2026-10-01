import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/lezzet_plus_recipes.dart';
import '../../models/kitchen_recipe.dart';
import '../../theme/app_theme.dart';
import 'kitchen_recipe_detail_screen.dart';

class KitchenSafetyScreen extends StatefulWidget {
  const KitchenSafetyScreen({super.key});

  @override
  State<KitchenSafetyScreen> createState() => _KitchenSafetyScreenState();
}

class _KitchenSafetyScreenState extends State<KitchenSafetyScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late TabController _tabCtrl;
  late List<KitchenRecipe> _recipes;
  String _selectedCategory = 'Tümü';

  final List<Map<String, dynamic>> _rules = [
    {
      'rule': 'Sıcak Ocağa ve Fırına Asla Dokunma!',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.red,
      'desc': 'Ocak ve fırın çok sıcaktır, elini yakabilir. Her zaman fırın eldiveni kullan veya büyüğünden yardım al.',
    },
    {
      'rule': 'Keskin Bıçakları Dikkatli ve Yardım Alarak Kullan!',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.orange,
      'desc': 'Bıçakla bir şey doğrarken parmaklarını içe doğru kıvır ve gerekirse bir yetişkinden destek iste.',
    },
    {
      'rule': 'Islak Elle Elektrikli Mutfak Aletlerine Dokunma!',
      'icon': Icons.electric_bolt_rounded,
      'color': Colors.amber.shade800,
      'desc': 'Blender, mikser veya tost makinesi fişini takmadan önce mutlaka ellerini kurula.',
    },
    {
      'rule': 'Yemek Hazırlamadan Önce Ellerini Yıka!',
      'icon': Icons.wash_rounded,
      'color': Colors.blue,
      'desc': 'Mikroplardan korunmak ve hijyen için ellerini en az 20 saniye sabunla güzelce yıka.',
    },
    {
      'rule': 'Dökülen Sıvıları Hemen Sil ve Kurula!',
      'icon': Icons.cleaning_services_rounded,
      'color': Colors.teal,
      'desc': 'Yere su veya yağ damladığında kayıp düşmemek için hemen bez veya havlu ile kurula.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _recipes = LezzetPlusRecipes.getRecipes();
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
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  List<KitchenRecipe> get _filteredRecipes {
    if (_selectedCategory == 'Tümü') return _recipes;
    return _recipes.where((r) => r.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Tümü', 'Çorbalar', 'Makarnalar', 'Salatalar', 'Pratik Lezzetler'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.restaurant_rounded, color: Colors.orange, size: 26),
            SizedBox(width: 8),
            Text(
              'Mutfağım & Lezzet +1',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.orange.shade800,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.orange.shade800,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Lezzet +1 Kitabı'),
            Tab(icon: Icon(Icons.health_and_safety_rounded), text: 'Mutfak Güvenliği'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ─── TAB 1: LEZZET +1 TARİFLERİ ───
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Tanıtım Afişi
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.amber.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lezzet +1 Mutfak Atölyesi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'Down Sendromu Derneği & Hilton İş Birliği',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tüm materyal ve malzemeleri kontrol listesinden işaretle, adım adım kronometre desteğiyle kendi yemeğini keyifle hazırla!',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kategori Filtre Butonları
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: Colors.orange.shade700,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Tarif Kartları Listesi
              ..._filteredRecipes.map((recipe) {
                final checkedCount = recipe.ingredients.where((i) => i.isChecked).length +
                    recipe.tools.where((t) => t.isChecked).length;
                final totalItems = recipe.ingredients.length + recipe.tools.length;
                final isDone = totalItems > 0 && checkedCount == totalItems;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: recipe.themeColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KitchenRecipeDetailScreen(recipe: recipe),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: recipe.themeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: recipe.coverImagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          recipe.coverImagePath!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Icon(recipe.icon, color: recipe.themeColor, size: 30),
                                        ),
                                      )
                                    : Icon(recipe.icon, color: recipe.themeColor, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: recipe.themeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        recipe.category,
                                        style: TextStyle(
                                          color: recipe.themeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      recipe.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      recipe.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Bilgi Etiketleri ve Kontrol Listesi Durumu
                          Row(
                            children: [
                              _buildMiniBadge(Icons.people_outline_rounded, recipe.portions),
                              const SizedBox(width: 8),
                              _buildMiniBadge(Icons.timer_outlined, recipe.prepTime),
                              const SizedBox(width: 8),
                              _buildMiniBadge(Icons.format_list_numbered_rounded, '${recipe.steps.length} Adım'),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDone ? Colors.green.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDone ? Icons.check_circle_rounded : Icons.checklist_rounded,
                                      color: isDone ? Colors.green : Colors.grey.shade700,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$checkedCount/$totalItems',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDone ? Colors.green : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Başla Butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: recipe.themeColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.soup_kitchen_rounded, size: 20),
                              label: const Text(
                                'Kontrol Listesi & Adımlar ▶',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KitchenRecipeDetailScreen(recipe: recipe),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),

          // ─── TAB 2: MUTFAK GÜVENLİĞİ ───
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _rules.length,
            itemBuilder: (context, index) {
              final rule = _rules[index];
              final color = rule['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(rule['icon'] as IconData, color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule['rule'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rule['desc'] as String,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo),
                      onPressed: () => _speak('${rule['rule']}. ${rule['desc']}'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
