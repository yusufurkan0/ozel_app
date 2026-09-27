import 'package:flutter/material.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';

/// Duolingo tarzı yatay ilerleme haritası.
class ProgressPath extends StatelessWidget {
  final List<ProgressStep> steps;
  final int dailyGoal;

  const ProgressPath({
    super.key,
    required this.steps,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = MakatonItem.all();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: steps.isEmpty
          ? Center(
              child: Text(
                'Bugün henüz bir buton basılmadı 💭',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dailyGoal,
              itemBuilder: (context, index) {
                final isCompleted = index < steps.length;
                final step = isCompleted ? steps[index] : null;

                // Tamamlanan adımın rengini ve ikonunu bul
                Color color = AppColors.neumorphicDark;
                IconData icon = Icons.circle_outlined;
                if (step != null) {
                  final item = allItems.firstWhere(
                    (m) => m.id == step.itemId,
                    orElse: () => allItems.first,
                  );
                  color = item.color;
                  icon = item.icon;
                }

                return Row(
                  children: [
                    // Bağlantı çizgisi
                    if (index > 0)
                      Container(
                        width: 20,
                        height: 3,
                        color: index < steps.length
                            ? AppColors.positiveGreen
                            : AppColors.neumorphicDark.withValues(alpha: 0.3),
                      ),
                    // Adım dairesi
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCompleted ? 56 : 40,
                      height: isCompleted ? 56 : 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? color
                            : AppColors.background,
                        shape: BoxShape.circle,
                        border: isCompleted
                            ? null
                            : Border.all(
                                color: AppColors.neumorphicDark
                                    .withValues(alpha: 0.3),
                                width: 2,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCompleted ? icon : Icons.circle,
                        size: isCompleted ? 28 : 12,
                        color: isCompleted
                            ? Colors.white
                            : AppColors.neumorphicDark.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
