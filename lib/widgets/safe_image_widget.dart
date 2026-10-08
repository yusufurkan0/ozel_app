import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web, Desktop ve Mobil platformlarda fotoğraf dosyalarını (Dosya, Data URI, Asset, Network, Blob)
/// hiçbir platform çökmesi yaşanmadan güvenle render eden yardımcı widget.
Widget buildSafeImage(
  String? path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? placeholder,
}) {
  if (path == null || path.isEmpty) {
    return placeholder ??
        Center(
          child: Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
        );
  }

  // 1. Data URI (Base64) - Web ve mobilde kalıcı yerel veri
  if (path.startsWith('data:image')) {
    try {
      final commaIndex = path.indexOf(',');
      if (commaIndex != -1) {
        final base64String = path.substring(commaIndex + 1);
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _errorWidget(),
        );
      }
    } catch (_) {}
  }

  // 2. Web veya Network / Blob URL
  if (kIsWeb || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => _errorWidget(),
    );
  }

  // 3. Assets
  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => _errorWidget(),
    );
  }

  // 4. Yerel Dosya (Sadece Native platformlarda)
  if (!kIsWeb) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _errorWidget(),
        );
      }
    } catch (_) {}
  }

  return placeholder ?? _errorWidget();
}

Widget _errorWidget() {
  return const Center(
    child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
  );
}
