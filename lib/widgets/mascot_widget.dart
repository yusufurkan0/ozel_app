import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Doğru tıklamalara tepki veren Lottie maskot bileşeni.
///
/// [isHappy] true olduğunda mutlu animasyon, false olduğunda
/// sakin idle animasyonu gösterir.
class MascotWidget extends StatelessWidget {
  final bool isHappy;
  final double size;

  const MascotWidget({
    super.key,
    required this.isHappy,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: SizedBox(
        key: ValueKey(isHappy),
        width: size,
        height: size,
        child: Lottie.asset(
          isHappy
              ? 'assets/lottie/mascot_happy.json'
              : 'assets/lottie/mascot_idle.json',
          repeat: true,
          animate: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
