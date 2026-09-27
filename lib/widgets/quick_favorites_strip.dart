import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../screens/custom_card_creator_screen.dart';

/// Ana ekran için tek dokunuşluk Hızlı Favoriler şeridi.
class QuickFavoritesStrip extends StatelessWidget {
  const QuickFavoritesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();
    final items = game.favoriteItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.star_rounded, color: AppColors.buttonAmber, size: 22),
                  SizedBox(width: 6),
                  Text(
                    'Hızlı İletişim',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CustomCardCreatorScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: Neu.elevated(radius: 12, blur: 4),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.buttonIndigo),
                      SizedBox(width: 4),
                      Text(
                        'Özel Kart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonIndigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              if (i == items.length) {
                // Özel Kart Ekle butonu
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomCardCreatorScreen()),
                    );
                  },
                  child: Container(
                    width: 86,
                    decoration: Neu.elevated(radius: 20, blur: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: AppColors.buttonIndigo, size: 24),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Yeni Ekle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final item = items[i];
              return _QuickFavoriteCard(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickFavoriteCard extends StatefulWidget {
  final MakatonItem item;
  const _QuickFavoriteCard({required this.item});

  @override
  State<_QuickFavoriteCard> createState() => _QuickFavoriteCardState();
}

class _QuickFavoriteCardState extends State<_QuickFavoriteCard> {
  bool _pressed = false;

  void _onTap() {
    final game = context.read<GameProgressService>();
    game.recordPress(widget.item.id);
    TtsService().speak(widget.item.label);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(widget.item.icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              '${widget.item.label} 👍',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: widget.item.color,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 86,
        decoration: _pressed
            ? Neu.inset(radius: 20)
            : Neu.colored(color: widget.item.color, radius: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.item.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
