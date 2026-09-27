import 'package:flutter/material.dart';
import '../models/makaton_item.dart';
import '../theme/app_theme.dart';

/// 💬 Yatay kaydırılabilir görsel PECS Cümle Şeridi.
/// Seçilen semboller zengin görselleri, piktogramları ve etiketleriyle gerçek bir görsel iletişim şeridine dizilir.
class SentenceStrip extends StatelessWidget {
  final List<MakatonItem> selectedItems;
  final ValueChanged<int> onRemove;
  final VoidCallback onClear;
  final int playingIndex;

  const SentenceStrip({
    super.key,
    required this.selectedItems,
    required this.onRemove,
    required this.onClear,
    this.playingIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 106,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: Neu.elevated(radius: 22, blur: 8),
      child: selectedItems.isEmpty
          ? const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🖼️', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Text(
                    'Aşağıdan görsel sembol seçerek cümle kur 💬',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedItems.length,
                    separatorBuilder: (ctx, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.buttonIndigo.withValues(alpha: 0.4),
                      ),
                    ),
                    itemBuilder: (ctx, i) {
                      final item = selectedItems[i];
                      final isSpeaking = i == playingIndex;
                      final imagePath = item.resolvedImagePath;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 74,
                            height: 88,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSpeaking
                                    ? AppColors.positiveGreen
                                    : item.color,
                                width: isSpeaking ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSpeaking
                                      ? AppColors.positiveGreen.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: isSpeaking ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🖼️ Görsel / Piktogram Alanı
                                if (imagePath != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      imagePath,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: item.color.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      item.emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                // 📝 Kelime Başlığı
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSpeaking
                                        ? AppColors.positiveGreen
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          // ❌ Silme Butonu
                          Positioned(
                            top: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: () => onRemove(i),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (selectedItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: onClear,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: Neu.colored(color: Colors.red.shade400, radius: 19),
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
