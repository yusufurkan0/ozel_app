import 'package:flutter/material.dart';
import '../models/makaton_item.dart';
import '../theme/app_theme.dart';

/// Kategori seçim sekmeleri — yatay kaydırılabilir, emoji ikonlu.
class CategoryTabBar extends StatelessWidget {
  final MakatonCategory? selected;
  final ValueChanged<MakatonCategory?> onSelected;

  const CategoryTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [null, ...MakatonCategory.values.where((c) => c != MakatonCategory.emergency)];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (ctx, index) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isAll = cat == null;
          final sel = selected == cat;
          final label = isAll ? 'Hepsi' : cat.label;
          final emoji = isAll ? '🌐' : cat.emoji;
          final color = isAll ? AppColors.buttonBlue : cat.color;

          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: sel
                  ? Neu.colored(color: color, radius: 16)
                  : Neu.elevated(radius: 16, blur: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.textPrimary,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
