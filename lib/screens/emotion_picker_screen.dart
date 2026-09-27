import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/emotion_card.dart';

/// Duygu seçici ekranı — 6 duygu kartı.
class EmotionPickerScreen extends StatelessWidget {
  const EmotionPickerScreen({super.key});

  static const List<Map<String, dynamic>> _emotions = [
    {'id': 'mutlu', 'emoji': '😊', 'label': 'Mutluyum', 'color': Color(0xFFFFD54F)},
    {'id': 'uzgun', 'emoji': '😢', 'label': 'Üzgünüm', 'color': Color(0xFF90CAF9)},
    {'id': 'kizgin', 'emoji': '😠', 'label': 'Kızgınım', 'color': Color(0xFFEF9A9A)},
    {'id': 'korkmus', 'emoji': '😨', 'label': 'Korktum', 'color': Color(0xFFCE93D8)},
    {'id': 'yorgun', 'emoji': '😴', 'label': 'Yorgunum', 'color': Color(0xFFB0BEC5)},
    {'id': 'saskin', 'emoji': '😲', 'label': 'Şaşkınım', 'color': Color(0xFFFFAB91)},
  ];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nasıl Hissediyorsun?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lavender, AppColors.cream],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Başlık
                Text('Bugün kendini nasıl hissediyorsun? 💭',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                if (game.todayEmotion.isNotEmpty) ...[
                  _currentEmotionBadge(game.todayEmotion),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 16),
                // Duygu grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _emotions.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, i) {
                      final e = _emotions[i];
                      return EmotionCard(
                        emoji: e['emoji'] as String,
                        label: e['label'] as String,
                        color: e['color'] as Color,
                        isSelected: game.todayEmotion == e['id'],
                        onTap: () {
                          game.setEmotion(e['id'] as String);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${e['emoji']} ${e['label']} — kaydedildi!',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: (e['color'] as Color).withValues(alpha: 0.85),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _currentEmotionBadge(String emotionId) {
    final e = _emotions.firstWhere(
      (m) => m['id'] == emotionId,
      orElse: () => _emotions.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (e['color'] as Color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: e['color'] as Color, width: 2),
      ),
      child: Text(
        'Şu an: ${e['emoji']} ${e['label']}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: e['color'] as Color,
        ),
      ),
    );
  }
}
