import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import 'social_story_library_screen.dart';

class GamesSocialStoriesScreen extends StatefulWidget {
  const GamesSocialStoriesScreen({super.key});

  @override
  State<GamesSocialStoriesScreen> createState() => _GamesSocialStoriesScreenState();
}

class _GamesSocialStoriesScreenState extends State<GamesSocialStoriesScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late TabController _tabCtrl;

  // Sosyal Öyküler Listesi
  final List<Map<String, dynamic>> _stories = [
    {
      'title': 'Okula Hazırlanıyorum',
      'icon': Icons.backpack_rounded,
      'color': Colors.blue,
      'steps': [
        '1. Sabah uyanınca yüzümü yıkarım ve dişlerimi fırçalarım.',
        '2. Kıyafetlerimi giyer ve çantamı kontrol ederim.',
        '3. Kahvaltımı yapıp aileme "Görüşürüz" derim.',
        '4. Okulda öğretmenime ve arkadaşlarıma gülümserim.',
      ],
    },
    {
      'title': 'Sıramı Bekliyorum',
      'icon': Icons.hourglass_bottom_rounded,
      'color': Colors.orange,
      'steps': [
        '1. Bir etkinlik veya oyun için sıraya girerim.',
        '2. Sıra bana gelene kadar sakin ve sabırlı beklerim.',
        '3. Kimseyi itmem, başkasının önüne geçmem.',
        '4. Sıram gelince neşeyle oyunumu oynarım.',
      ],
    },
    {
      'title': 'Arkadaşımla Paylaşıyorum',
      'icon': Icons.favorite_rounded,
      'color': Colors.pink,
      'steps': [
        '1. Oyuncaklarımı arkadaşlarımla birlikte oynamak güzeldir.',
        '2. "Birlikte oynayalım mı?" diye sorarım.',
        '3. Birbirimize teşekkür eder ve sırayla oynarız.',
        '4. Paylaşmak bizi mutlu birer dost yapar.',
      ],
    },
    {
      'title': 'Doktora Gidiyorum',
      'icon': Icons.medical_services_rounded,
      'color': Colors.teal,
      'steps': [
        '1. Doktorlar sağlığımızı korumak için bize yardımcı olur.',
        '2. Doktor kalbimi dinlerken derin nefes alırım.',
        '3. Sakin durduğumda muayene hemen biter.',
        '4. Muayene bittiğinde kendimle gurur duyarım.',
      ],
    },
  ];

  // Eğitici Mini Oyunlar Listesi
  final List<Map<String, dynamic>> _games = [
    {
      'title': 'Kart Eşleştirme',
      'desc': 'Aynı sembolleri ve duyguları bulma oyunu.',
      'icon': Icons.grid_view_rounded,
      'color': Colors.purple,
      'tag': 'Hafıza & Dikkat',
    },
    {
      'title': 'Renk ve Şekil Bulmaca',
      'desc': 'Doğru renk ve şekilleri eşleştir.',
      'icon': Icons.category_rounded,
      'color': Colors.indigo,
      'tag': 'Görsel Algı',
    },
    {
      'title': 'Duygu Tahmin Etme',
      'desc': 'Yüz ifadelerinden duyguyu tahmin et.',
      'icon': Icons.sentiment_satisfied_alt_rounded,
      'color': Colors.amber.shade800,
      'tag': 'Sosyal Gelişim',
    },
    {
      'title': 'Sesli Kelime Yakalama',
      'desc': 'Duyduğun kelimenin resmine dokun.',
      'icon': Icons.volume_up_rounded,
      'color': Colors.green,
      'tag': 'İşitsel Dikkat',
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

  void _openStory(Map<String, dynamic> story) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (story['color'] as Color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(story['icon'] as IconData, color: story['color'] as Color, size: 28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                story['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...((story['steps'] as List<String>).map((step) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(step, style: const TextStyle(fontSize: 14, height: 1.3)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF1E3A8A), size: 20),
                      onPressed: () => _speak(step),
                    ),
                  ],
                ),
              ))),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _launchMiniGame(Map<String, dynamic> game) {
    _speak('${game['title']} oyunu başlatılıyor.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(game['icon'] as IconData, color: game['color'] as Color, size: 28),
            const SizedBox(width: 10),
            Text(game['title'] as String),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(game['desc'] as String, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (game['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars_rounded, color: Colors.amber, size: 30),
                  SizedBox(width: 8),
                  Text('Tebrikler! Oyuna Hazırsın 🌟', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: game['color'] as Color,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Oyna'),
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
            Icon(Icons.sports_esports_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text(
              'Oyun ve Sosyal Öyküler',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories_rounded), text: 'Sosyal Öyküler'),
            Tab(icon: Icon(Icons.sports_esports_rounded), text: 'Eğitici Oyunlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ─── 1. Sosyal Öyküler Kütüphanesi (Kullanıcı İsteği: Boş Kütüphane, Kendi Fotoğrafları, Ses Kaydı, Yatay Büyüme) ───
          const SocialStoryLibraryScreen(type: 'social_story', isEmbedded: true),

          // ─── 2. Eğitici Mini Oyunlar Listesi ───
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _games.length,
            itemBuilder: (context, index) {
              final g = _games[index];
              final color = g['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
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
                      child: Icon(g['icon'] as IconData, color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                g['title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  g['tag'] as String,
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            g['desc'] as String,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _launchMiniGame(g),
                      child: const Text('Başlat'),
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
