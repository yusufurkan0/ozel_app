import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_progress_service.dart';
import '../services/timer_service.dart';
import '../widgets/launcher_screen_icons.dart';

// 12 Temel Yaşam ve Destek Modülleri
import 'launcher/calendar_screen.dart';
import 'launcher/visual_timer_screen.dart';
import 'launcher/task_checklist_screen.dart';
import 'launcher/self_evaluation_screen.dart';
import 'launcher/cash_ledger_screen.dart';
import 'launcher/card_budget_screen.dart';
import 'launcher/lost_sos_screen.dart';
import 'launcher/disaster_emergency_screen.dart';
import 'launcher/free_time_planner_screen.dart';
import 'launcher/kitchen_safety_screen.dart';
import 'launcher/games_social_stories_screen.dart';
import 'launcher/support_contacts_screen.dart';
import 'register_screen.dart';

/// Ekran görüntüsündeki pastel ve sevimli 12 modüllü ana ekran.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showStudentProfileDialog(BuildContext context, GameProgressService game) {
    final avatars = ['🐻', '🦁', '🐼', '🐰', '🦊', '⭐', '🚀', '🐬'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Öğrenci Profilim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(game.avatar, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 6),
            Text(
              game.childName.isNotEmpty ? game.childName : 'Öğrenci Profilim',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (game.childName.isEmpty) ...[
              const SizedBox(height: 2),
              const Text(
                '(İsim tanımlamak için aşağıdaki butona dokunun)',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '⭐ Günlük İlerleme: ${game.todaySteps.length}/${game.dailyGoal} Görev',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Avatarını Değiştir:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: avatars.map((av) => GestureDetector(
                onTap: () {
                  game.saveProfile(game.childName, av);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: game.avatar == av ? Colors.blue.shade50 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: game.avatar == av ? Colors.blue : Colors.transparent),
                  ),
                  child: Text(av, style: const TextStyle(fontSize: 22)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D4ED8),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.info_rounded, size: 18),
                label: const Text('Genel Bilgileri Düzenle (Acil Durum & Veli)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(isEditing: true),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekran görüntüsüyle birebir 12 Modül listesi (Renkler, illüstrasyonlar ve tipografi)
    final List<ColoredBlockItem> apps = [
      // ─── 1. SATIR ───
      ColoredBlockItem(
        title: 'Takvim',
        iconBuilder: () => const CalendarIllustrationIcon(),
        destination: const CalendarScreen(),
        bgColor: const Color(0xFFFFD7D9),
        borderColor: const Color(0xFFFCA5A5),
        textColor: const Color(0xFF7F1D1D),
      ),
      ColoredBlockItem(
        title: 'Kronometre',
        iconBuilder: () => const TimerIllustrationIcon(),
        destination: const VisualTimerScreen(),
        bgColor: const Color(0xFFFED7AA),
        borderColor: const Color(0xFFFB923C),
        textColor: const Color(0xFF7C2D12),
      ),
      ColoredBlockItem(
        title: 'Görev Listesi',
        iconBuilder: () => const TaskListIllustrationIcon(),
        destination: const TaskChecklistScreen(),
        bgColor: const Color(0xFFFEF08A),
        borderColor: const Color(0xFFFACC15),
        textColor: const Color(0xFF713F12),
      ),

      // ─── 2. SATIR ───
      ColoredBlockItem(
        title: 'Kendini\nDeğerlendirme',
        iconBuilder: () => const SelfEvalIllustrationIcon(),
        destination: const SelfEvaluationScreen(),
        bgColor: const Color(0xFF99F6E4),
        borderColor: const Color(0xFF2DD4BF),
        textColor: const Color(0xFF115E59),
      ),
      ColoredBlockItem(
        title: 'Nakit Para\nDefteri',
        iconBuilder: () => const CashLedgerIllustrationIcon(),
        destination: const CashLedgerScreen(),
        bgColor: const Color(0xFF86EFAC),
        borderColor: const Color(0xFF4ADE80),
        textColor: const Color(0xFF14532D),
      ),
      ColoredBlockItem(
        title: 'Kredi Kartı\nDefteri',
        iconBuilder: () => const CardBudgetIllustrationIcon(),
        destination: const CardBudgetScreen(),
        bgColor: const Color(0xFFBFDBFE),
        borderColor: const Color(0xFF60A5FA),
        textColor: const Color(0xFF1E3A8A),
      ),

      // ─── 3. SATIR ───
      ColoredBlockItem(
        title: 'Kaybolma',
        iconBuilder: () => const LostSosIllustrationIcon(),
        destination: const LostSosScreen(),
        bgColor: const Color(0xFFFECACA),
        borderColor: const Color(0xFFF87171),
        textColor: const Color(0xFF7F1D1D),
      ),
      ColoredBlockItem(
        title: 'Afet ve\nAcil Durum',
        iconBuilder: () => const DisasterIllustrationIcon(),
        destination: const DisasterEmergencyScreen(),
        bgColor: const Color(0xFFFDA4AF),
        borderColor: const Color(0xFFF43F5E),
        textColor: const Color(0xFF881337),
      ),
      ColoredBlockItem(
        title: 'Serbest\nZaman Planı',
        iconBuilder: () => const FreeTimeIllustrationIcon(),
        destination: const FreeTimePlannerScreen(),
        bgColor: const Color(0xFFFED7AA),
        borderColor: const Color(0xFFFB923C),
        textColor: const Color(0xFF7C2D12),
      ),

      // ─── 4. SATIR ───
      ColoredBlockItem(
        title: 'Mutfak',
        iconBuilder: () => const KitchenIllustrationIcon(),
        destination: const KitchenSafetyScreen(),
        bgColor: const Color(0xFFFDE68A),
        borderColor: const Color(0xFFFCD34D),
        textColor: const Color(0xFF78350F),
      ),
      ColoredBlockItem(
        title: 'Oyun ve\nSosyal Öyküler',
        iconBuilder: () => const GamesStoriesIllustrationIcon(),
        destination: const GamesSocialStoriesScreen(),
        bgColor: const Color(0xFFDDD6FE),
        borderColor: const Color(0xFFC084FC),
        textColor: const Color(0xFF581C87),
      ),
      ColoredBlockItem(
        title: 'Destek\nKişilerim',
        iconBuilder: () => const SupportContactsIllustrationIcon(),
        destination: const SupportContactsScreen(),
        bgColor: const Color(0xFFFBCFE8),
        borderColor: const Color(0xFFF472B6),
        textColor: const Color(0xFF831843),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF4FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                // ─── ÜST BAŞLIK & GENEL BİLGİLER BARI (Ekran Görüntüsüyle Birebir) ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C0F172A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sol Taraf: Ayıcık Avatarı, Başlık ve Alt Başlık
                        Expanded(
                          child: Consumer<GameProgressService>(
                            builder: (ctx, game, _) => GestureDetector(
                              onTap: () => _showStudentProfileDialog(context, game),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        game.avatar.isNotEmpty ? game.avatar : '🐻',
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Özel Yaşam Rehberi',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16.5,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        SizedBox(height: 1),
                                        Text(
                                          'Günlük Yaşam Modülleri',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Sağ Taraf: "ℹ Genel Bilgiler" Hap Butonu
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(isEditing: true),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF93C5FD), width: 1.3),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                SizedBox(width: 5),
                                Text(
                                  'Genel Bilgiler',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Aktif Kronometre / Alarm Bildirim Çubuğu (Varsa) ───
                AnimatedBuilder(
                  animation: VisualTimerService.instance,
                  builder: (context, _) {
                    final timer = VisualTimerService.instance;
                    if (timer.isAlarmActive) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDC2626), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm_on_rounded, color: Color(0xFFDC2626), size: 26),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⏰ SÜRE DOLDU! ALARM ÇALIYOR',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF991B1B)),
                                  ),
                                  Text(
                                    'Durdurmak için butona basınız...',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: () => timer.stopAlarm(),
                              child: const Text('Durdur ⏹️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            ),
                          ],
                        ),
                      );
                    } else if (timer.isRunning) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VisualTimerScreen()),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded, color: Color(0xFF2563EB), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⏳ Kronometre çalışıyor: ${timer.formattedTime}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1E40AF)),
                                ),
                              ),
                              const Text(
                                'Aç ➜',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // ─── 12 PASTEL MODÜL IZGARASI (3 Sütun x 4 Satır) ───
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Hücre oranını ekran yüksekliğine göre mükemmel oranda hesaplar
                        final itemHeight = (constraints.maxHeight - (3 * 11)) / 4;
                        final itemWidth = (constraints.maxWidth - (2 * 11)) / 3;
                        final computedRatio = (itemWidth / itemHeight).clamp(0.74, 0.90);

                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: apps.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: computedRatio,
                            crossAxisSpacing: 11,
                            mainAxisSpacing: 11,
                          ),
                          itemBuilder: (context, index) {
                            final app = apps[index];
                            return _buildClaymorphicCard(context, app);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ekran görüntüsündeki yumuşak gölgeli, pastel renkli ve sevimli blok kart
  Widget _buildClaymorphicCard(BuildContext context, ColoredBlockItem app) {
    return _PressableScaleCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => app.destination),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: app.bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: app.borderColor, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: app.borderColor.withValues(alpha: 0.32),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon doğrudan kart üstüne oturur (arkasında beyaz kutu olmadan)
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: Center(child: app.iconBuilder()),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Kart Başlığı
            Text(
              app.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: app.textColor,
                height: 1.15,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

/// Dokunulduğunda yumuşak yaylanma animasyonu veren mikro-etkileşim widget'ı
class _PressableScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScaleCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressableScaleCard> createState() => _PressableScaleCardState();
}

class _PressableScaleCardState extends State<_PressableScaleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class ColoredBlockItem {
  final String title;
  final Widget Function() iconBuilder;
  final Widget destination;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  ColoredBlockItem({
    required this.title,
    required this.iconBuilder,
    required this.destination,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}
