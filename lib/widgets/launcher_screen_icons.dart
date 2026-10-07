import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 12 Modülün her biri için ekran görüntüsündeki sevimli, vektörel
/// ve yumuşak çizimli özel illüstrasyon ikonları.

/// 1. Takvim İkonu (Kırmızı/pembe şirin takvim yaprağı, spiralli ve noktalı)
class CalendarIllustrationIcon extends StatelessWidget {
  const CalendarIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _CalendarPainter(),
    );
  }
}

class _CalendarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ana gövde ölçüleri
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.20, w * 0.72, h * 0.68),
      const Radius.circular(10),
    );

    // Hafif gölge
    final shadowPaint = Paint()
      ..color = const Color(0x22DC2626)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(bodyRect.shift(const Offset(0, 2)), shadowPaint);

    // Beyaz gövde
    final bodyPaint = Paint()..color = const Color(0xFFFFF7F7);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Kenarlık
    final borderPaint = Paint()
      ..color = const Color(0xFFF87171)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bodyRect, borderPaint);

    // Kırmızı Üst Başlık Şeridi
    final headerPath = Path();
    headerPath.moveTo(w * 0.14 + 10, h * 0.20);
    headerPath.lineTo(w * 0.86 - 10, h * 0.20);
    headerPath.arcToPoint(
      Offset(w * 0.86, h * 0.20 + 10),
      radius: const Radius.circular(10),
    );
    headerPath.lineTo(w * 0.86, h * 0.44);
    headerPath.lineTo(w * 0.14, h * 0.44);
    headerPath.lineTo(w * 0.14, h * 0.20 + 10);
    headerPath.arcToPoint(
      Offset(w * 0.14 + 10, h * 0.20),
      radius: const Radius.circular(10),
    );
    headerPath.close();

    final headerPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawPath(headerPath, headerPaint);

    // 2 Spiral Halka (Üstte)
    final ringPaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    // Sol halka
    canvas.drawLine(Offset(w * 0.32, h * 0.12), Offset(w * 0.32, h * 0.26), ringPaint);
    // Sağ halka
    canvas.drawLine(Offset(w * 0.68, h * 0.12), Offset(w * 0.68, h * 0.26), ringPaint);

    // Takvim Izgarası Noktaları (6 adet sevimli yuvarlak)
    final dotPinks = Paint()..color = const Color(0xFFFDA4AF);
    final dotRed = Paint()..color = const Color(0xFFEF4444);

    final dotXs = [w * 0.32, w * 0.50, w * 0.68];
    final dotYs = [h * 0.56, h * 0.72];

    for (int r = 0; r < dotYs.length; r++) {
      for (int c = 0; c < dotXs.length; c++) {
        final isHighlight = (r == 1 && c == 1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(dotXs[c], dotYs[r]), width: 7.5, height: 6.5),
            const Radius.circular(2.5),
          ),
          isHighlight ? dotRed : dotPinks,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Kronometre İkonu (Turuncu sevimli analog kronometre)
class TimerIllustrationIcon extends StatelessWidget {
  const TimerIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _TimerPainter(),
    );
  }
}

class _TimerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.56);
    final radius = w * 0.36;

    // Üst basma düğmesi ve halkası
    final pusherPaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Üst halka
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.15), width: w * 0.22, height: h * 0.14),
      math.pi,
      math.pi,
      false,
      pusherPaint,
    );
    // Üst basma pimi
    final topPinPaint = Paint()
      ..color = const Color(0xFFC2410C)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.19), width: 9, height: 6),
        const Radius.circular(2),
      ),
      topPinPaint,
    );

    // Dış Turuncu Gövde
    final outerPaint = Paint()..color = const Color(0xFFFB923C);
    canvas.drawCircle(center, radius, outerPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFC2410C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, radius, borderPaint);

    // Beyaz / Krem Kadran
    final innerPaint = Paint()..color = const Color(0xFFFFFBEB);
    canvas.drawCircle(center, radius * 0.78, innerPaint);

    // Çentikler (Saat 12, 3, 6, 9)
    final tickPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    canvas.drawLine(center + Offset(0, -radius * 0.68), center + Offset(0, -radius * 0.52), tickPaint);
    canvas.drawLine(center + Offset(radius * 0.68, 0), center + Offset(radius * 0.52, 0), tickPaint);
    canvas.drawLine(center + Offset(0, radius * 0.68), center + Offset(0, radius * 0.52), tickPaint);
    canvas.drawLine(center + Offset(-radius * 0.68, 0), center + Offset(-radius * 0.52, 0), tickPaint);

    // İbreler (Siyah / Koyu Kahve)
    final handPaint = Paint()
      ..color = const Color(0xFF431407)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    // Saat ibresi (Yukarı)
    canvas.drawLine(center, center + Offset(0, -radius * 0.48), handPaint);
    // Dakika ibresi (Sağa çapraz)
    canvas.drawLine(center, center + Offset(radius * 0.36, radius * 0.18), handPaint);

    // Merkez Pimi
    final centerPin = Paint()..color = const Color(0xFFEA580C);
    canvas.drawCircle(center, 3.2, centerPin);

    // Hız / Titreşim Çizgileri (Sol ve sağda küçük yaylar)
    final wavePaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 2.45, height: radius * 2.45),
      math.pi * 0.78,
      math.pi * 0.22,
      false,
      wavePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 2.45, height: radius * 2.45),
      math.pi * 1.95,
      math.pi * 0.25,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Görev Listesi İkonu (Sarı pano, gümüş klips, yeşil onay tikleri)
class TaskListIllustrationIcon extends StatelessWidget {
  const TaskListIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _TaskListPainter(),
    );
  }
}

class _TaskListPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pano Arka Tahtası (Açık Altın / Ahşap Pano)
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.74),
      const Radius.circular(8),
    );
    final boardPaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawRRect(boardRect, boardPaint);

    final boardBorder = Paint()
      ..color = const Color(0xFFCA8A04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(boardRect, boardBorder);

    // Beyaz Kağıt
    final paperRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.24, w * 0.52, h * 0.62),
      const Radius.circular(5),
    );
    final paperPaint = Paint()..color = Colors.white;
    canvas.drawRRect(paperRect, paperPaint);

    // Üst Metal Klips
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.17), width: w * 0.32, height: h * 0.11),
      const Radius.circular(4),
    );
    final clipPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawRRect(clipRect, clipPaint);

    final clipHole = Paint()..color = const Color(0xFF475569);
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), 2.5, clipHole);

    // 3 Satır: Yeşil Onay Tikleri ve Görev Çizgileri
    final checkPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.2;

    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    final rowYs = [h * 0.38, h * 0.54, h * 0.70];

    for (final y in rowYs) {
      // Tik işareti
      final path = Path();
      path.moveTo(w * 0.30, y);
      path.lineTo(w * 0.35, y + 4);
      path.lineTo(w * 0.44, y - 5);
      canvas.drawPath(path, checkPaint);

      // Görev Çizgisi
      canvas.drawLine(Offset(w * 0.49, y), Offset(w * 0.69, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Kendini Değerlendirme İkonu (Mavi liste kağıdı, gülen surat ve yeşil onay rozeti)
class SelfEvalIllustrationIcon extends StatelessWidget {
  const SelfEvalIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _SelfEvalPainter(),
    );
  }
}

class _SelfEvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Doküman Kağıdı (Açık Mavi/Cyan)
    final docRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.14, w * 0.58, h * 0.72),
      const Radius.circular(9),
    );
    final docPaint = Paint()..color = const Color(0xFFE0F2FE);
    canvas.drawRRect(docRect, docPaint);

    final docBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(docRect, docBorder);

    // Üstte Sarı Gülen Surat 🙂
    final faceCenter = Offset(w * 0.34, h * 0.31);
    final facePaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(faceCenter, 8.5, facePaint);

    // Gözler
    final eyePaint = Paint()..color = const Color(0xFF78350F);
    canvas.drawCircle(faceCenter + const Offset(-3, -2), 1.2, eyePaint);
    canvas.drawCircle(faceCenter + const Offset(3, -2), 1.2, eyePaint);

    // Gülümseme
    final smilePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3;
    canvas.drawArc(
      Rect.fromCenter(center: faceCenter + const Offset(0, 1.5), width: 7, height: 6),
      0,
      math.pi,
      false,
      smilePaint,
    );

    // Üstteki Çizgi
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(w * 0.50, h * 0.31), Offset(w * 0.65, h * 0.31), linePaint);

    // Orta Çizgiler
    canvas.drawLine(Offset(w * 0.26, h * 0.48), Offset(w * 0.65, h * 0.48), linePaint);
    canvas.drawLine(Offset(w * 0.26, h * 0.62), Offset(w * 0.46, h * 0.62), linePaint);
    canvas.drawLine(Offset(w * 0.26, h * 0.74), Offset(w * 0.42, h * 0.74), linePaint);

    // Sağ Alt Yeşil Onay Rozeti (Daire içinde tik)
    final badgeCenter = Offset(w * 0.68, h * 0.69);
    final badgePaint = Paint()..color = const Color(0xFF22C55E);
    canvas.drawCircle(badgeCenter, 11, badgePaint);

    final badgeBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(badgeCenter, 11, badgeBorder);

    final badgeCheck = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.2;

    final checkPath = Path();
    checkPath.moveTo(badgeCenter.dx - 4.5, badgeCenter.dy);
    checkPath.lineTo(badgeCenter.dx - 1.2, badgeCenter.dy + 3.8);
    checkPath.lineTo(badgeCenter.dx + 4.8, badgeCenter.dy - 3.5);
    canvas.drawPath(checkPath, badgeCheck);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Nakit Para Defteri İkonu (Yeşil spiralli defter, ortasında ₺ madeni para)
class CashLedgerIllustrationIcon extends StatelessWidget {
  const CashLedgerIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _CashLedgerPainter(),
    );
  }
}

class _CashLedgerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Yeşil Defter Gövdesi
    final bookRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.16, w * 0.64, h * 0.70),
      const Radius.circular(8),
    );
    final bookPaint = Paint()..color = const Color(0xFF4ADE80);
    canvas.drawRRect(bookRect, bookPaint);

    final bookBorder = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bookRect, bookBorder);

    // Sol Spiraller (5 adet tel halka)
    final ringPaint = Paint()
      ..color = const Color(0xFF166534)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    final ringYs = [h * 0.25, h * 0.38, h * 0.51, h * 0.64, h * 0.77];
    for (final y in ringYs) {
      canvas.drawLine(Offset(w * 0.16, y), Offset(w * 0.28, y), ringPaint);
    }

    // Ortada ₺ Madeni Para Rozeti
    final coinCenter = Offset(w * 0.57, h * 0.51);
    final coinPaint = Paint()..color = const Color(0xFFBBF7D0);
    canvas.drawCircle(coinCenter, 14, coinPaint);

    final coinBorder = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(coinCenter, 14, coinBorder);

    // ₺ Sembolü Metin Çizimi
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '₺',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Color(0xFF14532D),
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(coinCenter.dx - textPainter.width / 2, coinCenter.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. Kredi Kartı Defteri İkonu (Mavi POS terminali & Kredi kartı)
class CardBudgetIllustrationIcon extends StatelessWidget {
  const CardBudgetIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _CardBudgetPainter(),
    );
  }
}

class _CardBudgetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Arkadaki Mavi POS Terminali
    final posRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.44, h * 0.15, w * 0.44, h * 0.68),
      const Radius.circular(8),
    );
    final posPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawRRect(posRect, posPaint);

    final posBorder = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(posRect, posBorder);

    // POS Ekranı
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.50, h * 0.22, w * 0.32, h * 0.20),
      const Radius.circular(3),
    );
    final screenPaint = Paint()..color = const Color(0xFFE0F2FE);
    canvas.drawRRect(screenRect, screenPaint);

    // POS Tuşları (Tuş takımı noktaları)
    final keyPaint = Paint()..color = const Color(0xFF0369A1);
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 3; c++) {
        canvas.drawCircle(
          Offset(w * 0.54 + c * 7.5, h * 0.50 + r * 7.5),
          1.8,
          keyPaint,
        );
      }
    }

    // Öndeki Kredi Kartı (Yatay Mavi Kart)
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.34, w * 0.54, h * 0.36),
      const Radius.circular(6),
    );
    final cardPaint = Paint()..color = const Color(0xFF2563EB);
    canvas.drawRRect(cardRect, cardPaint);

    final cardBorder = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(cardRect, cardBorder);

    // Kart manyetik şerit / çizgisi
    final linePaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(w * 0.16, h * 0.45), Offset(w * 0.58, h * 0.45), linePaint);

    // Kırmızı/Sarı Kart Logosu (Mastercard stili iki daire)
    final redCircle = Paint()..color = const Color(0xFFEF4444);
    final yellowCircle = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(w * 0.50, h * 0.58), 4.5, redCircle);
    canvas.drawCircle(Offset(w * 0.55, h * 0.58), 4.5, yellowCircle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7. Kaybolma İkonu (Kırmızı SOS balonu, harita ve kırmızı konum pimi)
class LostSosIllustrationIcon extends StatelessWidget {
  const LostSosIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _LostSosPainter(),
    );
  }
}

class _LostSosPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Alttaki Katlanmış Harita
    final mapPath = Path();
    mapPath.moveTo(w * 0.22, h * 0.62);
    mapPath.lineTo(w * 0.44, h * 0.56);
    mapPath.lineTo(w * 0.66, h * 0.64);
    mapPath.lineTo(w * 0.86, h * 0.58);
    mapPath.lineTo(w * 0.86, h * 0.82);
    mapPath.lineTo(w * 0.66, h * 0.88);
    mapPath.lineTo(w * 0.44, h * 0.80);
    mapPath.lineTo(w * 0.22, h * 0.86);
    mapPath.close();

    final mapPaint = Paint()..color = const Color(0xFF7DD3FC);
    canvas.drawPath(mapPath, mapPaint);

    final mapBorder = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(mapPath, mapBorder);

    // Katlama çizgileri
    canvas.drawLine(Offset(w * 0.44, h * 0.56), Offset(w * 0.44, h * 0.80), mapBorder);
    canvas.drawLine(Offset(w * 0.66, h * 0.64), Offset(w * 0.66, h * 0.88), mapBorder);

    // Sol Üst Kırmızı SOS Konuşma Baloncuğu
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.18, w * 0.48, h * 0.32),
      const Radius.circular(8),
    );
    final bubblePaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(bubbleRect, bubblePaint);

    // SOS Metni
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'SOS',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(w * 0.34 - textPainter.width / 2, h * 0.34 - textPainter.height / 2),
    );

    // Sağ Üst Kırmızı Konum Pimi (Harita İğnesi) 📍
    final pinCenter = Offset(w * 0.72, h * 0.34);
    final pinPaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(pinCenter, 8.5, pinPaint);

    // İğne ucu
    final tipPath = Path();
    tipPath.moveTo(pinCenter.dx - 7, pinCenter.dy + 3);
    tipPath.lineTo(pinCenter.dx, pinCenter.dy + 16);
    tipPath.lineTo(pinCenter.dx + 7, pinCenter.dy + 3);
    tipPath.close();
    canvas.drawPath(tipPath, pinPaint);

    // İğne ortasındaki beyaz nokta
    final centerDot = Paint()..color = Colors.white;
    canvas.drawCircle(pinCenter, 3.2, centerDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 8. Afet ve Acil Durum İkonu (Kırmızı ilk yardım çantası ve itfaiyeci kaskı)
class DisasterIllustrationIcon extends StatelessWidget {
  const DisasterIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _DisasterPainter(),
    );
  }
}

class _DisasterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sol Kırmızı İlk Yardım Çantası 🧰
    final bagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.30, w * 0.46, h * 0.50),
      const Radius.circular(8),
    );
    final bagPaint = Paint()..color = const Color(0xFFE11D48);
    canvas.drawRRect(bagRect, bagPaint);

    final bagBorder = Paint()
      ..color = const Color(0xFF881337)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(bagRect, bagBorder);

    // Çanta Kulpu
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.18, h * 0.12),
      const Radius.circular(3),
    );
    final handlePaint = Paint()
      ..color = const Color(0xFF881337)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(handleRect, handlePaint);

    // Beyaz İlk Yardım Artı (+) İşareti
    final crossPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.6;
    final crossCenter = Offset(w * 0.31, h * 0.55);
    canvas.drawLine(crossCenter + const Offset(-6, 0), crossCenter + const Offset(6, 0), crossPaint);
    canvas.drawLine(crossCenter + const Offset(0, -6), crossCenter + const Offset(0, 6), crossPaint);

    // Sağ İtfaiyeci / Kurtarma Kaskı ⛑️
    final helmetCenter = Offset(w * 0.68, h * 0.50);

    // Kask kubbesi
    final helmetPath = Path();
    helmetPath.moveTo(helmetCenter.dx - 16, helmetCenter.dy + 8);
    helmetPath.arcToPoint(
      Offset(helmetCenter.dx + 16, helmetCenter.dy + 8),
      radius: const Radius.circular(16),
      clockwise: true,
    );
    helmetPath.close();

    final helmetPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawPath(helmetPath, helmetPaint);

    final helmetBorder = Paint()
      ..color = const Color(0xFF991B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(helmetPath, helmetBorder);

    // Kask Siperliği (Alt Çizgi)
    final brimRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(helmetCenter.dx, helmetCenter.dy + 8), width: 36, height: 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(brimRect, helmetPaint);
    canvas.drawRRect(brimRect, helmetBorder);

    // Kask Üstü Reflektör / Rozet
    final badgePaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawCircle(Offset(helmetCenter.dx, helmetCenter.dy - 3), 3.5, badgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 9. Serbest Zaman Planı İkonu (Kum saati, tatil şemsiyesi ve takvim)
class FreeTimeIllustrationIcon extends StatelessWidget {
  const FreeTimeIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _FreeTimePainter(),
    );
  }
}

class _FreeTimePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sol Kum Saati ⏳
    final glassPath = Path();
    glassPath.moveTo(w * 0.14, h * 0.22);
    glassPath.lineTo(w * 0.40, h * 0.22);
    glassPath.lineTo(w * 0.28, h * 0.48);
    glassPath.lineTo(w * 0.40, h * 0.74);
    glassPath.lineTo(w * 0.14, h * 0.74);
    glassPath.lineTo(w * 0.26, h * 0.48);
    glassPath.close();

    final glassPaint = Paint()..color = const Color(0xFFE0F2FE);
    canvas.drawPath(glassPath, glassPaint);

    final glassBorder = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(glassPath, glassBorder);

    // Kum (Sarı)
    final sandPaint = Paint()..color = const Color(0xFFFBBF24);
    final sandBottom = Path();
    sandBottom.moveTo(w * 0.17, h * 0.74);
    sandBottom.lineTo(w * 0.37, h * 0.74);
    sandBottom.lineTo(w * 0.27, h * 0.58);
    sandBottom.close();
    canvas.drawPath(sandBottom, sandPaint);

    // Kum saati ahşap kapakları
    final capPaint = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;
    canvas.drawLine(Offset(w * 0.12, h * 0.22), Offset(w * 0.42, h * 0.22), capPaint);
    canvas.drawLine(Offset(w * 0.12, h * 0.74), Offset(w * 0.42, h * 0.74), capPaint);

    // Sağdaki Takvim & Şemsiye ⛱️
    // Takvim gövdesi
    final calRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.48, h * 0.38, w * 0.44, h * 0.44),
      const Radius.circular(6),
    );
    final calPaint = Paint()..color = Colors.white;
    canvas.drawRRect(calRect, calPaint);

    final calBorder = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(calRect, calBorder);

    // Takvim renkli kutuları
    final boxColors = [
      const Color(0xFFF87171),
      const Color(0xFF34D399),
      const Color(0xFFFBBF24),
      const Color(0xFF60A5FA),
    ];
    final boxOffsets = [
      Offset(w * 0.55, h * 0.54),
      Offset(w * 0.75, h * 0.54),
      Offset(w * 0.55, h * 0.68),
      Offset(w * 0.75, h * 0.68),
    ];
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: boxOffsets[i], width: 7, height: 6),
          const Radius.circular(2),
        ),
        Paint()..color = boxColors[i],
      );
    }

    // Üstte Tatil Şemsiyesi Kubbesi ⛱️
    final umbrellaCenter = Offset(w * 0.72, h * 0.30);
    final umbrellaPath = Path();
    umbrellaPath.moveTo(umbrellaCenter.dx - 14, umbrellaCenter.dy);
    umbrellaPath.arcToPoint(
      Offset(umbrellaCenter.dx + 14, umbrellaCenter.dy),
      radius: const Radius.circular(14),
      clockwise: true,
    );
    umbrellaPath.close();

    final umbrellaPaint = Paint()..color = const Color(0xFFF43F5E);
    canvas.drawPath(umbrellaPath, umbrellaPaint);

    // Şemsiye sapı
    final stickPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawLine(umbrellaCenter, Offset(umbrellaCenter.dx, umbrellaCenter.dy + 14), stickPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 10. Mutfak İkonu (Çatal, kaşık ve aşçı şapkalı servis tabağı cloche)
class KitchenIllustrationIcon extends StatelessWidget {
  const KitchenIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _KitchenPainter(),
    );
  }
}

class _KitchenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sol Çatal & Kaşık 🍴
    // Çatal (Açık Mavi / Gümüş)
    final cutleryPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    // Çatal sapı
    canvas.drawLine(Offset(w * 0.16, h * 0.40), Offset(w * 0.16, h * 0.76), cutleryPaint);
    // Çatal dişleri
    canvas.drawLine(Offset(w * 0.12, h * 0.30), Offset(w * 0.12, h * 0.42), cutleryPaint);
    canvas.drawLine(Offset(w * 0.16, h * 0.30), Offset(w * 0.16, h * 0.42), cutleryPaint);
    canvas.drawLine(Offset(w * 0.20, h * 0.30), Offset(w * 0.20, h * 0.42), cutleryPaint);
    canvas.drawLine(Offset(w * 0.12, h * 0.42), Offset(w * 0.20, h * 0.42), cutleryPaint);

    // Kaşık
    final spoonPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(w * 0.30, h * 0.44), Offset(w * 0.30, h * 0.76), spoonPaint);
    // Kaşık başı
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.30, h * 0.34), width: 9, height: 13),
      cutleryPaint,
    );

    // Sağ Servis Kapağı Cloche 🍽️
    final clocheCenter = Offset(w * 0.68, h * 0.68);

    // Tepsi tabanı
    final trayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(clocheCenter.dx, clocheCenter.dy + 7), width: 34, height: 5),
      const Radius.circular(2.5),
    );
    final trayPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawRRect(trayRect, trayPaint);

    // Kubbe kapak
    final domePath = Path();
    domePath.moveTo(clocheCenter.dx - 14, clocheCenter.dy + 5);
    domePath.arcToPoint(
      Offset(clocheCenter.dx + 14, clocheCenter.dy + 5),
      radius: const Radius.circular(14),
      clockwise: true,
    );
    domePath.close();

    final domePaint = Paint()..color = const Color(0xFFFDE68A);
    canvas.drawPath(domePath, domePaint);

    final domeBorder = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(domePath, domeBorder);

    // Üstteki Aşçı Şapkası 👨‍🍳
    final hatCenter = Offset(clocheCenter.dx, clocheCenter.dy - 16);
    final hatPaint = Paint()..color = Colors.white;
    final hatBorder = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Şapka kabarık daireleri
    canvas.drawCircle(hatCenter + const Offset(-6, 0), 6, hatPaint);
    canvas.drawCircle(hatCenter + const Offset(-6, 0), 6, hatBorder);
    canvas.drawCircle(hatCenter + const Offset(6, 0), 6, hatPaint);
    canvas.drawCircle(hatCenter + const Offset(6, 0), 6, hatBorder);
    canvas.drawCircle(hatCenter + const Offset(0, -6), 7, hatPaint);
    canvas.drawCircle(hatCenter + const Offset(0, -6), 7, hatBorder);

    // Şapka alt bandı
    final bandRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: hatCenter + const Offset(0, 6), width: 16, height: 5),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(bandRect, hatPaint);
    canvas.drawRRect(bandRect, hatBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 11. Oyun ve Sosyal Öyküler İkonu (Mor el konsolu ve arkasında açık kitap)
class GamesStoriesIllustrationIcon extends StatelessWidget {
  const GamesStoriesIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _GamesStoriesPainter(),
    );
  }
}

class _GamesStoriesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Arkadaki Açık Kitap 📖 (Sağ Üstte)
    final bookCenter = Offset(w * 0.72, h * 0.36);
    final pagePaint = Paint()..color = const Color(0xFFFFFBEB);
    final pageBorder = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Sol sayfa
    final leftPage = Path();
    leftPage.moveTo(bookCenter.dx, bookCenter.dy + 12);
    leftPage.lineTo(bookCenter.dx - 16, bookCenter.dy + 8);
    leftPage.lineTo(bookCenter.dx - 16, bookCenter.dy - 12);
    leftPage.lineTo(bookCenter.dx, bookCenter.dy - 8);
    leftPage.close();
    canvas.drawPath(leftPage, pagePaint);
    canvas.drawPath(leftPage, pageBorder);

    // Sağ sayfa
    final rightPage = Path();
    rightPage.moveTo(bookCenter.dx, bookCenter.dy + 12);
    rightPage.lineTo(bookCenter.dx + 16, bookCenter.dy + 8);
    rightPage.lineTo(bookCenter.dx + 16, bookCenter.dy - 12);
    rightPage.lineTo(bookCenter.dx, bookCenter.dy - 8);
    rightPage.close();
    canvas.drawPath(rightPage, pagePaint);
    canvas.drawPath(rightPage, pageBorder);

    // Öndeki Mor Oyun Konsolu 🎮 (Switch / Gameboy stili)
    final consoleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.66, h * 0.38),
      const Radius.circular(10),
    );
    final consolePaint = Paint()..color = const Color(0xFF8B5CF6);
    canvas.drawRRect(consoleRect, consolePaint);

    final consoleBorder = Paint()
      ..color = const Color(0xFF581C87)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(consoleRect, consoleBorder);

    // Konsol Ekranı (Koyu cam)
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.49, w * 0.36, h * 0.28),
      const Radius.circular(4),
    );
    final screenPaint = Paint()..color = const Color(0xFF2E1065);
    canvas.drawRRect(screenRect, screenPaint);

    // Sol Yön Tuşu D-Pad (+)
    final dpadPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 3.0;
    final dpadCenter = Offset(w * 0.15, h * 0.63);
    canvas.drawLine(dpadCenter + const Offset(-4, 0), dpadCenter + const Offset(4, 0), dpadPaint);
    canvas.drawLine(dpadCenter + const Offset(0, -4), dpadCenter + const Offset(0, 4), dpadPaint);

    // Sağ Aksiyon Tuşları (İki nokta)
    final btnPaint = Paint()..color = const Color(0xFFF43F5E);
    canvas.drawCircle(Offset(w * 0.64, h * 0.58), 2.2, btnPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.66), 2.2, btnPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 12. Destek Kişilerim İkonu (Pembe kalp, destek eli ve sarılan kişiler)
class SupportContactsIllustrationIcon extends StatelessWidget {
  const SupportContactsIllustrationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 54),
      painter: _SupportContactsPainter(),
    );
  }
}

class _SupportContactsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sol Üst Pembe Kalp 💖
    final heartCenter = Offset(w * 0.32, h * 0.32);
    final heartPath = Path();
    heartPath.moveTo(heartCenter.dx, heartCenter.dy + 8);
    heartPath.cubicTo(
      heartCenter.dx - 12, heartCenter.dy + 1,
      heartCenter.dx - 12, heartCenter.dy - 10,
      heartCenter.dx, heartCenter.dy - 3,
    );
    heartPath.cubicTo(
      heartCenter.dx + 12, heartCenter.dy - 10,
      heartCenter.dx + 12, heartCenter.dy + 1,
      heartCenter.dx, heartCenter.dy + 8,
    );
    heartPath.close();

    final heartPaint = Paint()..color = const Color(0xFFEC4899);
    canvas.drawPath(heartPath, heartPaint);

    final heartBorder = Paint()
      ..color = const Color(0xFF9D174D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(heartPath, heartBorder);

    // Sağ Sarılan İki Kişi 👥 (Sarı/Turuncu sevimli figürler)
    final head1 = Offset(w * 0.68, h * 0.28);
    final head2 = Offset(w * 0.82, h * 0.32);

    final personPaint = Paint()..color = const Color(0xFFFDE047);
    final personBorder = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Başlar
    canvas.drawCircle(head1, 6.5, personPaint);
    canvas.drawCircle(head1, 6.5, personBorder);
    canvas.drawCircle(head2, 6.0, personPaint);
    canvas.drawCircle(head2, 6.0, personBorder);

    // Sarılma gövdesi (Kucaklaşma)
    final hugBody = Path();
    hugBody.moveTo(w * 0.58, h * 0.58);
    hugBody.quadraticBezierTo(w * 0.74, h * 0.40, w * 0.90, h * 0.56);
    hugBody.lineTo(w * 0.90, h * 0.70);
    hugBody.lineTo(w * 0.58, h * 0.70);
    hugBody.close();

    canvas.drawPath(hugBody, personPaint);
    canvas.drawPath(hugBody, personBorder);

    // Alttan Destek Veren El 🤲
    final handPath = Path();
    handPath.moveTo(w * 0.12, h * 0.70);
    handPath.lineTo(w * 0.28, h * 0.70);
    handPath.quadraticBezierTo(w * 0.44, h * 0.72, w * 0.58, h * 0.65);
    handPath.quadraticBezierTo(w * 0.48, h * 0.82, w * 0.28, h * 0.82);
    handPath.lineTo(w * 0.12, h * 0.82);
    handPath.close();

    final handPaint = Paint()..color = const Color(0xFFFED7AA);
    canvas.drawPath(handPath, handPaint);

    final handBorder = Paint()
      ..color = const Color(0xFFC2410C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(handPath, handBorder);

    // Kol bandı
    final sleevePaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.68, w * 0.08, h * 0.16), sleevePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
