import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';

class KitchenSafetyScreen extends StatefulWidget {
  const KitchenSafetyScreen({super.key});

  @override
  State<KitchenSafetyScreen> createState() => _KitchenSafetyScreenState();
}

class _KitchenSafetyScreenState extends State<KitchenSafetyScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late TabController _tabCtrl;

  final List<Map<String, dynamic>> _recipes = [
    {
      'title': 'Lezzetli Peynirli Sandviç',
      'icon': Icons.lunch_dining_rounded,
      'time': '5 Dk',
      'steps': [
        '1. Önce ellerini 20 saniye sabunla güzelce yıka.',
        '2. İki dilim ekmeği tabağa koy.',
        '3. Üzerine beyaz peynir veya kaşar dilimi yerleştir.',
        '4. İstersen domates veya salatalık dilimi ekle.',
        '5. Diğer ekmeği üstüne kapat. Afiyet olsun!',
      ],
    },
    {
      'title': 'Vitaminli Meyve Tabağı',
      'icon': Icons.apple_rounded,
      'time': '7 Dk',
      'steps': [
        '1. Ellerini yıka.',
        '2. Elma ve muzu temiz suyla iyice yıka.',
        '3. Muzu soyup dilimle (Gerekirse büyüğünden yardım iste).',
        '4. Renkli meyveleri tabağına diz ve keyifle ye.',
      ],
    },
    {
      'title': 'Ilık Ballı Süt',
      'icon': Icons.local_cafe_rounded,
      'time': '4 Dk',
      'steps': [
        '1. Temiz bir bardağa süt doldur.',
        '2. Isıtmak için mutlaka anne veya babandan yardım iste.',
        '3. Bir kaşık bal ekle ve yavaşça karıştır.',
      ],
    },
  ];

  final List<Map<String, dynamic>> _rules = [
    {
      'rule': 'Sıcak Ocağa ve Fırına Dokunma!',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.red,
      'desc': 'Ocak çok sıcaktır ve elini yakabilir.',
    },
    {
      'rule': 'Keskin Bıçakları Tek Başına Kullanma!',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.orange,
      'desc': 'Bir şey keserken her zaman büyüklerinden yardım iste.',
    },
    {
      'rule': 'Islak Elle Elektrik Prizine Dokunma!',
      'icon': Icons.electric_bolt_rounded,
      'color': Colors.amber.shade800,
      'desc': 'Elektrik aletlerini kullanmadan önce ellerini kurula.',
    },
    {
      'rule': 'Yemekten Önce Mutlaka Ellerini Yıka!',
      'icon': Icons.wash_rounded,
      'color': Colors.blue,
      'desc': 'Mikroplardan korunmak için sabunla yıka.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(recipe['icon'] as IconData, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(recipe['title'] as String, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...((recipe['steps'] as List<String>).map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.buttonIndigo),
                      onPressed: () => _speak(s),
                    ),
                  ],
                ),
              ))),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonIndigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Mutfak & Tarifler', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.orange.shade800,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange.shade800,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Kolay Tarifler'),
            Tab(icon: Icon(Icons.health_and_safety_rounded), text: 'Mutfak Güvenliği'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tarifler Listesi
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _recipes.length,
            itemBuilder: (context, index) {
              final r = _recipes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(r['icon'] as IconData, color: Colors.orange.shade800, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Süre: ${r['time']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showRecipeDetails(r),
                      child: const Text('Tarif'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Güvenlik Kuralları Listesi
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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(rule['icon'] as IconData, color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rule['rule'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(rule['desc'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
}
