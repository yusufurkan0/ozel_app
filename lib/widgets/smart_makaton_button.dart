import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

/// Soft Neumorphism stilinde akıllı Makaton butonu.
///
/// Basıldığında:
/// 1. Neumorphic inset efekti (derinlik)
/// 2. Scale bounce animasyonu
/// 3. Özel ses kaydı, .mp3 ses dosyası veya Türkçe TTS seslendirmesi
class SmartMakatonButton extends StatefulWidget {
  final MakatonItem item;
  final VoidCallback onTap;

  const SmartMakatonButton({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<SmartMakatonButton> createState() => _SmartMakatonButtonState();
}

class _SmartMakatonButtonState extends State<SmartMakatonButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _controller;
  late Animation<double> _scale;
  final AudioPlayer _player = AudioPlayer();
  DateTime? _touchStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final game = Provider.of<GameProgressService>(context, listen: false);

    // Titreşim (erişilebilirlik)
    if (game.vibrationEnabled) {
      HapticFeedback.lightImpact();
    }

    // Özel kayıtlı ses varsa önce onu çal
    if (widget.item.customAudioPath != null) {
      try {
        await _player.play(DeviceFileSource(widget.item.customAudioPath!));
      } catch (e) {
        debugPrint('Özel ses çalma hatası: $e');
      }
    } else if (game.soundEnabled) {
      // Makaton ön tanımlı ses veya Türkçe TTS
      if (widget.item.soundPath != null) {
        try {
          await _player.play(AssetSource(widget.item.soundPath!));
        } catch (_) {
          // Ses dosyası yoksa veya hata verirse doğal Türkçe ses motoru konuşsun
          await TtsService().speak(widget.item.label);
        }
      } else {
        await TtsService().speak(widget.item.label);
      }
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProgressService>(context, listen: true);
    final sizeMode = game.buttonSize; // 0: S, 1: M, 2: L
    final double iconSize = sizeMode == 0 ? 32.0 : (sizeMode == 2 ? 48.0 : 40.0);
    final double circleSize = sizeMode == 0 ? 54.0 : (sizeMode == 2 ? 78.0 : 66.0);
    final double fontSize = sizeMode == 0 ? 18.0 : (sizeMode == 2 ? 25.0 : 21.0);
    final double minHeight = sizeMode == 0 ? 130.0 : (sizeMode == 2 ? 165.0 : 148.0);

    return Semantics(
      label: '${widget.item.label} iletişim butonu',
      button: true,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: GestureDetector(
          onTapDown: (_) {
            _touchStartTime = DateTime.now();
            setState(() => _pressed = true);
            _controller.forward();
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            _controller.reverse();
            final elapsed = DateTime.now().difference(_touchStartTime ?? DateTime.now()).inMilliseconds;
            if (elapsed >= game.holdDurationMs) {
              _handleTap();
            }
          },
          onTapCancel: () {
            setState(() => _pressed = false);
            _controller.reverse();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: Neu.colored(
              color: widget.item.color,
              isPressed: _pressed,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildButtonIcon(circleSize, iconSize),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonIcon(double circleSize, double iconSize) {
    if (widget.item.imagePath != null && widget.item.imagePath!.isNotEmpty) {
      if (kIsWeb) {
        if (widget.item.imagePath!.startsWith('http') ||
            widget.item.imagePath!.startsWith('blob:') ||
            widget.item.imagePath!.startsWith('data:')) {
          return Image.network(
            widget.item.imagePath!,
            width: circleSize,
            height: circleSize,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(
              widget.item.icon,
              size: iconSize,
              color: AppColors.textOnDark,
            ),
          );
        }
      } else {
        try {
          final file = File(widget.item.imagePath!);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: circleSize,
              height: circleSize,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                widget.item.icon,
                size: iconSize,
                color: AppColors.textOnDark,
              ),
            );
          }
        } catch (_) {}
      }
    }

    return Icon(
      widget.item.icon,
      size: iconSize,
      color: AppColors.textOnDark,
    );
  }
}
