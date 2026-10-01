import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_progress_service.dart';
import '../services/timer_service.dart';
import 'launcher/games_social_stories_screen.dart';

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
import 'launcher/support_contacts_screen.dart';
import 'register_screen.dart';

/// Her biri ayrı blok blok renkli, modern ve ergonomik 12 modüllü ana ekran.
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
              game.childName.isNotEmpty ? game.childName : 'Ali',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text('⭐ Günlük İlerleme: ${game.todaySteps.length}/${game.dailyGoal} Görev', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
                icon: const Icon(Icons.badge_rounded, size: 18),
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
    // 12 Temel Yaşam Modülü (Kullanıcının belirlediği sırada, her biri özel renk bloğuna sahip)
    final List<ColoredBlockItem> apps = [
      // ─── 1. SATIR ───
      ColoredBlockItem(
        title: 'Takvim',
        badge: 'Günün Planı',
        iconBuilder: () => _buildCalendarIcon(),
        destination: const CalendarScreen(),
        bgColors: const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        borderColor: const Color(0xFFFDA4AF),
        textColor: const Color(0xFFBE123C),
        badgeBg: const Color(0xFFFFD4D8),
      ),
      ColoredBlockItem(
        title: 'Kronometre',
        badge: 'Görsel Süre',
        iconBuilder: () => _buildTimerIcon(),
        destination: const VisualTimerScreen(),
        bgColors: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        borderColor: const Color(0xFFFDBA74),
        textColor: const Color(0xFFC2410C),
        badgeBg: const Color(0xFFFFDEC0),
      ),
      ColoredBlockItem(
        title: 'Görev Listesi',
        badge: 'Yapılacaklar',
        iconBuilder: () => _buildTaskIcon(),
        destination: const TaskChecklistScreen(),
        bgColors: const [Color(0xFFFEFCE8), Color(0xFFFEF08A)],
        borderColor: const Color(0xFFFACC15),
        textColor: const Color(0xFF854D0E),
        badgeBg: const Color(0xFFFDE68A),
      ),

      // ─── 2. SATIR ───
      ColoredBlockItem(
        title: 'Kendini\nDeğerlendirme',
        badge: 'Duygularım',
        iconBuilder: () => _buildSelfEvalIcon(),
        destination: const SelfEvaluationScreen(),
        bgColors: const [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
        borderColor: const Color(0xFF5EEAD4),
        textColor: const Color(0xFF0F766E),
        badgeBg: const Color(0xFF99F6E4),
      ),
      ColoredBlockItem(
        title: 'Nakit Para\nDefteri',
        badge: 'Nakit Cüzdan',
        iconBuilder: () => _buildCashBookIcon(),
        destination: const CashLedgerScreen(),
        bgColors: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        borderColor: const Color(0xFF86EFAC),
        textColor: const Color(0xFF15803D),
        badgeBg: const Color(0xFFBBF7D0),
      ),
      ColoredBlockItem(
        title: 'Kredi Kartı\nDefteri',
        badge: 'Kart Hesabı',
        iconBuilder: () => _buildCardBookIcon(),
        destination: const CardBudgetScreen(),
        bgColors: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        borderColor: const Color(0xFF93C5FD),
        textColor: const Color(0xFF1D4ED8),
        badgeBg: const Color(0xFFBFDBFE),
      ),

      // ─── 3. SATIR ───
      ColoredBlockItem(
        title: 'Kaybolma',
        badge: 'Acil Yardım',
        iconBuilder: () => _buildLostIcon(),
        destination: const LostSosScreen(),
        bgColors: const [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
        borderColor: const Color(0xFFFCA5A5),
        textColor: const Color(0xFFB91C1C),
        badgeBg: const Color(0xFFFECACA),
      ),
      ColoredBlockItem(
        title: 'Afet ve\nAcil Durum',
        badge: 'Deprem & Siren',
        iconBuilder: () => _buildEmergencyIcon(),
        destination: const DisasterEmergencyScreen(),
        bgColors: const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        borderColor: const Color(0xFFFB7185),
        textColor: const Color(0xFF9F1239),
        badgeBg: const Color(0xFFFECDD3),
      ),
      ColoredBlockItem(
        title: 'Serbest\nZaman Planı',
        badge: 'Mola & Hobi',
        iconBuilder: () => _buildFreeTimeIcon(),
        destination: const FreeTimePlannerScreen(),
        bgColors: const [Color(0xFFFFF7ED), Color(0xFFFFEAD5)],
        borderColor: const Color(0xFFFB923C),
        textColor: const Color(0xFF9A3412),
        badgeBg: const Color(0xFFFFD8B2),
      ),

      // ─── 4. SATIR ───
      ColoredBlockItem(
        title: 'Mutfak',
        badge: 'Yemek & Güvenlik',
        iconBuilder: () => _buildKitchenIcon(),
        destination: const KitchenSafetyScreen(),
        bgColors: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        borderColor: const Color(0xFFFCD34D),
        textColor: const Color(0xFFB45309),
        badgeBg: const Color(0xFFFDE68A),
      ),
      ColoredBlockItem(
        title: 'Oyun ve\nSosyal Öyküler',
        badge: 'Oyun & Eğlence',
        iconBuilder: () => _buildGamesStoriesIcon(),
        destination: const GamesSocialStoriesScreen(),
        bgColors: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
        borderColor: const Color(0xFFD8B4FE),
        textColor: const Color(0xFF7E22CE),
        badgeBg: const Color(0xFFE9D5FF),
      ),
      ColoredBlockItem(
        title: 'Destek\nKişilerim',
        badge: 'Rehber & Aile',
        iconBuilder: () => _buildSupportContactsIcon(),
        destination: const SupportContactsScreen(),
        bgColors: const [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
        borderColor: const Color(0xFFF472B6),
        textColor: const Color(0xFFBE185D),
        badgeBg: const Color(0xFFFBCFE8),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              // Masaüstü ve geniş ekranlarda dağılmayı önleyip kompakt tablet düzeninde tutar
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  // ─── Üst Başlık & Ebeveyn Barı ───
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Sol Profil Bilgisi
                          Expanded(
                            child: Consumer<GameProgressService>(
                              builder: (ctx, game, _) => GestureDetector(
                                onTap: () => _showStudentProfileDialog(context, game),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                                      ),
                                      child: Center(
                                        child: Text(game.avatar, style: const TextStyle(fontSize: 22)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            game.childName.isNotEmpty ? 'Merhaba, ${game.childName}' : 'Özel Yaşam Rehberi',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const Text(
                                            'Günlük Yaşam Modülleri',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
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
                          // Sağ: Genel Bilgiler Butonu
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.badge_rounded, size: 16, color: Color(0xFF1D4ED8)),
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

                  // ─── Aktif Kronometre / Alarm Bildirim Çubuğu ───
                  AnimatedBuilder(
                    animation: VisualTimerService.instance,
                    builder: (context, _) {
                      final timer = VisualTimerService.instance;
                      if (timer.isAlarmActive) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDC2626), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm_on_rounded, color: Color(0xFFDC2626), size: 28),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⏰ SÜRE DOLDU! ALARM ÇALIYOR',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF991B1B)),
                                    ),
                                    Text(
                                      'Cihaz titriyor ve ses çalıyor...',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  elevation: 2,
                                ),
                                onPressed: () => timer.stopAlarm(),
                                child: const Text('Durdur ⏹️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_top_rounded, color: Color(0xFF2563EB), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '⏳ Kronometre çalışıyor: ${timer.formattedTime}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
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

                  // ─── 12 Renkli Blok Izgarası (Ayrı Blok Blok Renk Düzeni) ───
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: apps.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.88,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return _buildColoredBlockCard(context, app);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Her Biri Kendine Ait Özel Renge ve Gölgelendirmeye Sahip Blok Kart
  Widget _buildColoredBlockCard(BuildContext context, ColoredBlockItem app) {
    return _PressableScaleCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => app.destination),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: app.bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: app.borderColor, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: app.borderColor.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Beyaz Squircle İkon Taşıyıcı
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: app.borderColor.withValues(alpha: 0.4), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: app.borderColor.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: app.iconBuilder()),
            ),
            const SizedBox(height: 6),

            // Kart Başlığı
            Text(
              app.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: app.textColor,
                height: 1.15,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 12 İkon Çizimleri ───

  /// 1. Takvim
  Widget _buildCalendarIcon() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dot(const Color(0xFF94A3B8)),
                _dot(const Color(0xFF94A3B8)),
                _dot(const Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dot(const Color(0xFF94A3B8)),
                _dot(const Color(0xFFEF4444)),
                _dot(const Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Kronometre
  Widget _buildTimerIcon() {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFC2410C), width: 2),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
              child: Container(
                width: 13,
                height: 13,
                color: const Color(0xFFEA580C),
              ),
            ),
          ),
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(color: Color(0xFF7C2D12), shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  /// 3. Görev Listesi
  Widget _buildTaskIcon() {
    return Container(
      width: 28,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF08A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCA8A04), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(width: 12, height: 3, decoration: BoxDecoration(color: const Color(0xFF854D0E), borderRadius: BorderRadius.circular(2))),
          _checkRow(const Color(0xFF16A34A)),
          _checkRow(const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  /// 4. Kendini Değerlendirme
  Widget _buildSelfEvalIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 28,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _checkRow(const Color(0xFF0D9488)),
              _checkRow(const Color(0xFF0D9488)),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Transform.rotate(
            angle: -0.6,
            child: const Icon(Icons.edit_rounded, color: Color(0xFFF59E0B), size: 18),
          ),
        ),
      ],
    );
  }

  /// 5. Nakit Para Defteri
  Widget _buildCashBookIcon() {
    return Container(
      width: 30,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF14532D), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(color: Color(0xFFFDE047), shape: BoxShape.circle),
          child: const Center(
            child: Text('₺', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF78350F))),
          ),
        ),
      ),
    );
  }

  /// 6. Kredi Kartı Defteri
  Widget _buildCardBookIcon() {
    return Container(
      width: 30,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 14,
          decoration: BoxDecoration(color: const Color(0xFF60A5FA), borderRadius: BorderRadius.circular(2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(height: 2, color: const Color(0xFF1E3A8A)),
              Container(width: 5, height: 2, margin: const EdgeInsets.only(left: 2), color: const Color(0xFFFBBF24)),
            ],
          ),
        ),
      ),
    );
  }

  /// 7. Kaybolma
  Widget _buildLostIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.map_rounded, color: Color(0xFF0D9488), size: 30),
        Positioned(
          top: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(4)),
            child: const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  /// 8. Afet ve Acil Durum
  Widget _buildEmergencyIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 24,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFFDC2626),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
        Positioned(
          bottom: 3,
          child: Container(width: 28, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
        ),
        const Positioned(top: 0, child: Icon(Icons.flare_rounded, color: Color(0xFFF59E0B), size: 12)),
      ],
    );
  }

  /// 9. Serbest Zaman Planı
  Widget _buildFreeTimeIcon() {
    return const Icon(Icons.beach_access_rounded, color: Color(0xFFEA580C), size: 30);
  }

  /// 10. Mutfak
  Widget _buildKitchenIcon() {
    return const Icon(Icons.restaurant_rounded, color: Color(0xFFD97706), size: 30);
  }

  /// 11. Oyun ve Sosyal Öyküler
  Widget _buildGamesStoriesIcon() {
    return const Icon(Icons.sports_esports_rounded, color: Color(0xFF9333EA), size: 32);
  }

  /// 12. Destek Kişilerim
  Widget _buildSupportContactsIcon() {
    return const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFE11D48), size: 28);
  }

  Widget _dot(Color color) {
    return Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _checkRow(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_rounded, color: color, size: 9),
        const SizedBox(width: 3),
        Container(width: 10, height: 2, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
      ],
    );
  }
}

/// Dokunulduğunda hafifçe küçülen etkileşimli kart widget'ı
class _PressableScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScaleCard({required this.child, required this.onTap});

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
  final String badge;
  final Widget Function() iconBuilder;
  final Widget destination;
  final List<Color> bgColors;
  final Color borderColor;
  final Color textColor;
  final Color badgeBg;

  ColoredBlockItem({
    required this.title,
    required this.badge,
    required this.iconBuilder,
    required this.destination,
    required this.bgColors,
    required this.borderColor,
    required this.textColor,
    required this.badgeBg,
  });
}
