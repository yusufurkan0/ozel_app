import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Basit animasyonlu bar chart (paket gerektirmez).
class SimpleBarChart extends StatelessWidget {
  final List<int> data;
  final List<String> labels;
  final Color barColor;
  final double height;

  const SimpleBarChart({
    super.key,
    required this.data,
    required this.labels,
    this.barColor = AppColors.buttonBlue,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1 : maxVal;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (i) {
          final ratio = data[i] / effectiveMax;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Değer
                  Text(
                    '${data[i]}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: data[i] > 0 ? barColor : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: (height - 40) * ratio,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          barColor,
                          barColor.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      boxShadow: data[i] > 0
                          ? [
                              BoxShadow(
                                color: barColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Etiket
                  Text(
                    i < labels.length ? labels[i] : '',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
