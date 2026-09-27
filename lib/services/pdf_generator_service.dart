import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/makaton_item.dart';

/// 📄 PECS / Makaton Fiziksel Kart PDF Üretim Servisi
class PdfGeneratorService {
  static final PdfGeneratorService _instance = PdfGeneratorService._internal();
  factory PdfGeneratorService() => _instance;
  PdfGeneratorService._internal();

  /// Seçilen Makaton sembollerinden A4 kesilebilir kart şablonu (PDF) oluşturur.
  Future<Uint8List> generatePecsPdf(
    List<MakatonItem> items, {
    String title = 'Özel Eğitim Makaton & PECS İletişim Kartları',
  }) async {
    final pdf = pw.Document();

    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      ttfRegular = await PdfGoogleFonts.robotoRegular();
      ttfBold = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      // Offline fallback
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: ttfRegular != null
          ? pw.ThemeData.withFont(
              base: ttfRegular,
              bold: ttfBold,
            )
          : pw.ThemeData.base(),
    );

    // Sayfa başına 12 kart (3 sütun x 4 satır)
    const cardsPerPage = 12;
    final totalPages = (items.length / cardsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < (totalPages == 0 ? 1 : totalPages); pageIndex++) {
      final startIndex = pageIndex * cardsPerPage;
      final endIndex = (startIndex + cardsPerPage) > items.length
          ? items.length
          : startIndex + cardsPerPage;
      final pageItems = items.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Başlık & Açıklama
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.Text(
                      'Sayfa ${pageIndex + 1} / $totalPages',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Kartları noktalı çizgilerden keserek iletişim panolarında veya cırt cırtlı şeritlerde kullanabilirsiniz.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 12),

                // Kartlar Izgarası
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: pageItems.map((item) {
                      return pw.Container(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                          border: pw.Border.all(
                            color: PdfColors.grey700,
                            width: 1.5,
                            style: pw.BorderStyle.dashed,
                          ),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                              ),
                              child: pw.Text(
                                item.category.name.toUpperCase(),
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            // Sembol/Emoji Metni
                            pw.Text(
                              item.emoji,
                              style: const pw.TextStyle(fontSize: 34),
                            ),
                            pw.SizedBox(height: 12),
                            // Büyük Türkçe Yazı
                            pw.Text(
                              item.label,
                              textAlign: pw.TextAlign.center,
                              maxLines: 2,
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Özel Eğitim & Makaton İletişim Destek Sistemi',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
