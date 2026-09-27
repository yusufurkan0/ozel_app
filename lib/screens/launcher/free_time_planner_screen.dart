import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import 'visual_timer_screen.dart';

class FreeTimePlannerScreen extends StatefulWidget {
  const FreeTimePlannerScreen({super.key});

  @override
  State<FreeTimePlannerScreen> createState() => _FreeTimePlannerScreenState();
}

class _FreeTimePlannerScreenState extends State<FreeTimePlannerScreen> {
  final FlutterTts _tts = FlutterTts();

  final List<Map<String, dynamic>> _activities = [
    {'title': 'Müzik Dinlemek', 'icon': Icons.headphones_rounded, 'color': Colors.purple, 'desc': 'Sakinleştirici şarkılar dinle'},
    {'title': 'Resim ve Boyama', 'icon': Icons.palette_rounded, 'color': Colors.pink, 'desc': 'Renkli boyalarla resim yap'},
    {'title': 'Lego ve Bloklar', 'icon': Icons.extension_rounded, 'color': Colors.orange, 'desc': 'Kule veya ev inşa et'},
    {'title': 'Bahçede Yürüyüş', 'icon': Icons.nature_people_rounded, 'color': Colors.green, 'desc': 'Temiz hava al ve çiçeklere bak'},
    {'title': 'Kitap İnceleme', 'icon': Icons.menu_book_rounded, 'color': Colors.blue, 'desc': 'Resimli hikayelere göz at'},
    {'title': 'Dans Etmek', 'icon': Icons.music_note_rounded, 'color': Colors.teal, 'desc': 'Neşeli hareketlerle dans et'},
    {'title': 'Sessiz Dinlenme', 'icon': Icons.hotel_rounded, 'color': Colors.indigo, 'desc': 'Gözlerini kapat ve nefes al'},
    {'title': 'Çizgi Film İzleme', 'icon': Icons.tv_rounded, 'color': Colors.redAccent, 'desc': 'Eğlenceli bir bölüm izle'},
  ];

  @override
  void initState() {
    super.initState();
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

  void _selectActivity(Map<String, dynamic> act) {
    _speak('${act['title']} seçildi. Şimdi süreyi başlatabilirsin!');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(act['icon'] as IconData, color: act['color'] as Color, size: 28),
            const SizedBox(width: 8),
            Text(act['title'] as String),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(act['desc'] as String, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 14),
            const Text('Bu etkinlik için bir zamanlayıcı başlatmak ister misin?', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: act['color'] as Color,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.timer_rounded),
            label: const Text('Süre Başlat'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VisualTimerScreen()));
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
            Icon(Icons.beach_access_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Serbest Zaman Planım', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Tanıtım Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.amber.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Text('🏖️', style: TextStyle(fontSize: 42)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dinlenme ve Eğlence Vakti!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Şimdi ne yapmak istersin? Bir etkinlik seç ve keyfini çıkar.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Aktivite Seçenekleri:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            // Aktivite Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final act = _activities[index];
                final color = act['color'] as Color;

                return GestureDetector(
                  onTap: () => _selectActivity(act),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(act['icon'] as IconData, color: color, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          act['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
