import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bar_chart.dart';
import '../services/ai_aac_service.dart';

/// Ebeveyn Gelişim Raporu Ekranı.
/// PIN korumalı, haftalık kullanım grafiği, en çok kullanılan semboller ve duygu dağılımı.
class ParentReportScreen extends StatefulWidget {
  const ParentReportScreen({super.key});

  @override
  State<ParentReportScreen> createState() => _ParentReportScreenState();
}

class _ParentReportScreenState extends State<ParentReportScreen> {
  bool _authenticated = false;
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin(String inputPin, String actualPin) {
    if (actualPin.isEmpty || inputPin == actualPin) {
      setState(() {
        _authenticated = true;
        _errorMessage = '';
      });
    } else {
      setState(() {
        _errorMessage = 'Hatalı PIN kodu! Lütfen tekrar deneyin.';
      });
      _pinController.clear();
    }
  }

  void _showShareReportModal(BuildContext context, GameProgressService game) {
    final now = DateTime.now();
    final dateStr = '${now.day}.${now.month}.${now.year}';
    final topListStr = game.topSymbols.map((e) => '• ${e.key}: ${e.value} kez').join('\n');

    final reportText = '''📋 ÖZEL İLETİŞİM GELİŞİM & KULLANIM RAPORU
Çocuk: ${game.childName.isNotEmpty ? game.childName : "Öğrenci"} ${game.age.isNotEmpty ? "(${game.age})" : ""}
Rapor Tarihi: $dateStr
Bakıcı / Veli: ${game.caregiverName} (${game.caregiverRole})
-----------------------------------------
📊 GENEL İSTATİSTİKLER:
• Toplam Sembol İletişimi: ${game.totalPresses} kez
• Aktif Gün Serisi: ${game.streak} gün
• Günlük Rutin Tamamlama Başarısı: %${(game.routineProgress * 100).toInt()}
• Kazanılan Başarı Rozetleri: ${game.earnedBadges.length} adet

⭐ EN SIK KULLANILAN İHTİYAÇ & EYLEMLER:
${topListStr.isNotEmpty ? topListStr : "• Henüz yeterli veri kaydedilmedi."}

😊 HAFTALIK DUYGU DURUMU:
${game.todayEmotion.isNotEmpty ? "• Bugünkü Duygu: ${game.todayEmotion}" : "• Bugün henüz duygu seçilmedi."}

💡 UZMAN & TERAPİST BİLGİLENDİRME NOTU:
Bu rapor alternatif ve destekleyici iletişim (AAC) kullanımını takip etmek amacıyla otomatik oluşturulmuştur.''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neumorphicDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.share_rounded, color: AppColors.buttonIndigo),
                SizedBox(width: 8),
                Text(
                  'Terapist Raporunu Paylaş',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 240,
              padding: const EdgeInsets.all(16),
              decoration: Neu.inset(radius: 16),
              child: SingleChildScrollView(
                child: Text(
                  reportText,
                  style: const TextStyle(fontSize: 13, height: 1.4, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: reportText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rapor panoya kopyalandı! WhatsApp veya mail ile paylaşabilirsiniz. 📋'),
                      backgroundColor: AppColors.positiveGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text(
                  'Rapor Metnini Kopyala',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();

    // Eğer PIN ayarlanmamışsa doğrudan erişim ver
    if (game.parentPin.isEmpty && !_authenticated) {
      _authenticated = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ebeveyn & Uzman Raporu'),
        elevation: 0,
        actions: [
          if (_authenticated) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Raporu Paylaş / Kopyala',
              onPressed: () => _showShareReportModal(context, game),
            ),
            IconButton(
              icon: const Icon(Icons.lock_outline_rounded),
              tooltip: 'Ekranı Kilitle',
              onPressed: () {
                setState(() {
                  _authenticated = false;
                  _pinController.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(game.themeIndex),
        ),
        child: SafeArea(
          child: _authenticated
              ? _buildReportContent(context, game)
              : _buildPinVerification(context, game),
        ),
      ),
    );
  }

  Widget _buildPinVerification(BuildContext context, GameProgressService game) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: Neu.elevated(radius: 28, blur: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 38,
                  color: AppColors.buttonIndigo,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ebeveyn Doğrulaması',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gelişim raporlarına ve analizlere erişmek için lütfen 4 haneli PIN kodunuzu girin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: Neu.inset(radius: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(letterSpacing: 8),
                  ),
                  onSubmitted: (v) => _verifyPin(v, game.parentPin),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _verifyPin(_pinController.text, game.parentPin),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, GameProgressService game) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Özet Kartları ───────────────────────
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Basım',
                  value: '${game.totalPresses}',
                  icon: Icons.touch_app_rounded,
                  color: AppColors.buttonIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Aktif Gün Serisi',
                  value: '${game.streak} Gün',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.buttonOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Rutin Uyumu',
                  value: '%${(game.routineProgress * 100).toInt()}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.buttonGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Kazanılan Rozet',
                  value: '${game.earnedBadges.length}',
                  icon: Icons.military_tech_rounded,
                  color: AppColors.buttonAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Haftalık Kullanım Grafiği ───────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: Neu.elevated(radius: 24, blur: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Haftalık İletişim Yoğunluğu',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.buttonBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Son 7 Gün',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.buttonBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SimpleBarChart(
                  data: game.last7DaysPresses,
                  labels: game.last7DaysLabels,
                  barColor: AppColors.buttonIndigo,
                  height: 180,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── En Çok Kullanılan Semboller ─────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: Neu.elevated(radius: 24, blur: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'En Sık İfade Edilen İhtiyaçlar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                if (game.topSymbols.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Henüz yeterli sembol kullanımı kaydedilmedi.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...game.topSymbols.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final makatonItem = MakatonItem.all().firstWhere(
                      (m) => m.id == item.key,
                      orElse: () => MakatonItem(
                        id: item.key,
                        label: item.key,
                        icon: Icons.star_rounded,
                        color: AppColors.buttonBlue,
                        category: MakatonCategory.needs,
                      ),
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: makatonItem.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(makatonItem.icon, color: makatonItem.color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  makatonItem.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  makatonItem.category.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: Neu.inset(radius: 12),
                            child: Text(
                              '${item.value} kez',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.buttonIndigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Duygu Dağılımı ──────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: Neu.elevated(radius: 24, blur: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Haftalık Duygu Durum Özeti',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                if (game.emotionDistribution.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Bu hafta duygu kaydı bulunamadı.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: game.emotionDistribution.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: Neu.inset(radius: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.key, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              '${e.value} Gün',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 🧠 AI Klinik Değerlendirmesi ──────────────
          _buildAiClinicalInsightsCard(context, game),
          const SizedBox(height: 24),

          // ─── Terapist İle Paylaş Butonu ──────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _showShareReportModal(context, game),
              icon: const Icon(Icons.share_rounded),
              label: const Text(
                'Terapist & Uzman İçin Raporu Paylaş',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Neu.elevated(radius: 20, blur: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiClinicalInsightsCard(BuildContext context, GameProgressService game) {
    final report = AiAacService().generateClinicalInsights(
      childName: game.childName,
      totalPresses: game.totalPresses,
      streak: game.streak,
      topSymbols: game.topSymbols,
      todayEmotion: game.todayEmotion,
      routineRate: game.routineProgress,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Neu.elevated(radius: 24, blur: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, color: AppColors.buttonIndigo, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Klinik Değerlendirme Özeti',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Yapay Zeka Pedagojik Analiz & Uzman Notu',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppColors.buttonIndigo, size: 20),
                tooltip: 'Özeti Kopyala',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: report));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI Klinik Değerlendirme özeti panoya kopyalandı! 📋'),
                      backgroundColor: AppColors.positiveGreen,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: Neu.inset(radius: 16),
            child: Text(
              report.trim(),
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
