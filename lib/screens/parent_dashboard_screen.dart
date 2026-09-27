import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_progress_service.dart';
import '../services/parent_child_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bar_chart.dart';
import 'home_screen.dart';
import 'custom_card_creator_screen.dart';
import 'daily_routine_screen.dart';
import 'social_stories_screen.dart';
import 'pecs_printer_screen.dart';
import 'parent_report_screen.dart';
import 'visual_translator_screen.dart';
import 'profile_screen.dart';
import 'emergency_sos_screen.dart';
import 'profile_detail_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

/// 👨‍👩‍👧 Ebeveyn ve Terapist Refakatçi Paneli (Parent Companion Hub)
///
/// Özel gereksinimli çocuğun cihazından tamamen bağımsız çalışan, ancak canlı ağ
/// köprüsüyle bağlı; anlık konuşmaları izleyen, acil durumları yakalayan,
/// uzaktan kart ve rutin gönderen profesyonel yönetim masası.
class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<SyncEvent>? _syncSubscription;
  final syncService = ParentChildSyncService();

  SyncEvent? _activeSosAlert;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Canlı akış dinleyicisi
    _syncSubscription = syncService.eventStream.listen((event) {
      if (!mounted) return;
      if (event.type == SyncEventType.sos) {
        setState(() => _activeSosAlert = event);
        _showSosDialog(event);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _syncSubscription?.cancel();
    super.dispose();
  }

  void _showSosDialog(SyncEvent sosEvent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36),
            SizedBox(width: 10),
            Text(
              'ACİL DURUM ALARMI!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚨 ${sosEvent.childName} acil durum (SOS) butonunu tetikledi!',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sosEvent.data['emergencyNote'] ?? 'Özel gereksinimli birey yardıma ihtiyaç duyuyor.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _activeSosAlert = null);
            },
            child: const Text('Alarmı Kapat', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Acil durum notu onaylandı.')),
              );
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Anladım, İlgileniyorum'),
          ),
        ],
      ),
    );
  }

  void _switchToChildMode(BuildContext context, GameProgressService game) {
    if (game.isPinSet) {
      final pinCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.buttonIndigo),
              SizedBox(width: 8),
              Text('Çocuk Moduna Geçiş'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cihazı çocuk iletişim terminali olarak kilitlemek için PIN girin:'),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: '4 Haneli PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonIndigo, foregroundColor: Colors.white),
              onPressed: () {
                if (game.verifyPin(pinCtrl.text.trim())) {
                  Navigator.pop(ctx);
                  syncService.setDeviceRole(DeviceRole.childTerminal);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hatalı PIN!')),
                  );
                }
              },
              child: const Text('Çocuk Moduna Kilitle'),
            ),
          ],
        ),
      );
    } else {
      syncService.setDeviceRole(DeviceRole.childTerminal);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();
    final currentUser = AuthService().currentUser;
    final linkedStudentUsername = currentUser?.linkedStudentUsername;
    final linkedAccount = linkedStudentUsername != null ? AuthService().getAccount(linkedStudentUsername) : null;

    final childName = linkedAccount?.displayName ??
        (linkedStudentUsername != null && linkedStudentUsername.isNotEmpty
            ? linkedStudentUsername
            : (game.childName.isNotEmpty ? game.childName : 'Öğrenci'));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ebeveyn & Terapist Refakatçi Paneli',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  linkedStudentUsername != null && linkedStudentUsername.isNotEmpty
                      ? 'Bağlı Öğrenci: $childName (@$linkedStudentUsername)'
                      : 'Çocuk Terminali: $childName (${syncService.familyCode})',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Laptopta canlı test yapabilmek için pratik simülasyon butonu
          IconButton(
            icon: const Icon(Icons.touch_app_rounded, color: AppColors.buttonIndigo),
            tooltip: 'Örnek Çocuk Konuşması Simüle Et (Test)',
            onPressed: () {
              const testPhrases = [
                {'sentence': 'Su içmek istiyorum lütfen', 'emoji': '💧'},
                {'sentence': 'Karnım acıktı yemek yiyelim', 'emoji': '🍽️'},
                {'sentence': 'Bahçede oyun oynamak istiyorum', 'emoji': '🛝'},
                {'sentence': 'Yardım eder misin lütfen', 'emoji': '🤲'},
              ];
              final sample = (testPhrases..shuffle()).first;
              syncService.simulateDemoSpeech(
                childName,
                sample['sentence']!,
                sample['emoji']!,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Simüle Konuşma İletildi: "${sample['sentence']}"'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.buttonIndigo,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.child_care_rounded),
            tooltip: 'Çocuk İletişim Moduna Geç',
            onPressed: () => _switchToChildMode(context, game),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Çıkış Yap (@${AuthService().currentUser?.username ?? "veli"})',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.buttonIndigo),
                      SizedBox(width: 8),
                      Text('Çıkış Yapılsın mı?'),
                    ],
                  ),
                  content: const Text('Veli oturumunuz kapatılacak ve giriş ekranına dönülecektir.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonIndigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.buttonIndigo,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.buttonIndigo,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.stream_rounded), text: 'Canlı Akış'),
            Tab(icon: Icon(Icons.dashboard_customize_rounded), text: 'Uzaktan Yönetim'),
            Tab(icon: Icon(Icons.insights_rounded), text: 'Klinik Rapor'),
            Tab(icon: Icon(Icons.settings_input_antenna_rounded), text: 'Cihaz & Eşleşme'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(game.themeIndex)),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLiveActivityTab(context, game, childName),
            _buildRemoteManagementTab(context, game, childName),
            _buildClinicalReportTab(context, game, childName),
            _buildDeviceSyncTab(context, game, childName),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. CANLI AKIŞ & İZLEME SEKMESİ
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLiveActivityTab(BuildContext context, GameProgressService game, String childName) {
    final events = syncService.recentEvents;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aktif SOS Uyarısı Varsa En Üstte Göster
          if (_activeSosAlert != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade800,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🚨 ACİL SOS ÇAĞRISI AKTİF!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '$childName acil yardım çağrısında bulundu.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _activeSosAlert = null),
                    child: const Text('Kapat', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Çocuğun Günlük Durum Kartları
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  title: 'Bugünkü Duygu',
                  value: game.todayEmotion.isNotEmpty ? game.todayEmotion : 'Seçilmedi',
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  color: AppColors.buttonPink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusCard(
                  title: 'Tamamlanan Rutin',
                  value: '${game.completedRoutineCount} / ${game.routines.length}',
                  icon: Icons.checklist_rounded,
                  color: AppColors.buttonTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusCard(
                  title: 'Toplam İletişim',
                  value: '${game.totalPresses} kez',
                  icon: Icons.record_voice_over_rounded,
                  color: AppColors.buttonIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Uzaktan Anlık Moral / Övgü Gönderme Çubuğu
          Container(
            padding: const EdgeInsets.all(14),
            decoration: Neu.elevated(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.buttonPurple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$childName\'e Uzaktan Sevgi & Övgü Gönder:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CheerButton(
                      label: '🌟 Aferin Sana!',
                      onPressed: () => _sendCheer(childName, 'aferin', 'Aferin sana! Çok başarılıydın!', '🌟'),
                    ),
                    _CheerButton(
                      label: '❤️ Seni Seviyorum',
                      onPressed: () => _sendCheer(childName, 'sevgi', 'Seni çok seviyorum canım!', '❤️'),
                    ),
                    _CheerButton(
                      label: '👏 Harikasın!',
                      onPressed: () => _sendCheer(childName, 'harika', 'Harika gidiyorsun, tebrikler!', '👏'),
                    ),
                    _CheerButton(
                      label: '💧 Su İçelim',
                      onPressed: () => _sendCheer(childName, 'su', 'Bir yudum su içmeyi unutma tatlım!', '💧'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Canlı Konuşma ve Sinyal Akışı Başlığı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Canlı İletişim & Aktivite Akışı',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_tethering_rounded, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Canlı Dinleniyor', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Olaylar Listesi
          if (events.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: Neu.inset(radius: 16),
              child: const Column(
                children: [
                  Icon(Icons.hearing_rounded, size: 40, color: AppColors.textSecondary),
                  SizedBox(height: 10),
                  Text(
                    'Henüz bir konuşma veya aktivite sinyali gelmedi.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Çocuk tabletinden bir kart seçtiğinde veya cümle kurduğunda anında burada belirecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (ctx, idx) {
                final ev = events[idx];
                return _buildEventTile(ev);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventTile(SyncEvent ev) {
    IconData icon;
    Color color;

    switch (ev.type) {
      case SyncEventType.speech:
        icon = Icons.record_voice_over_rounded;
        color = AppColors.buttonIndigo;
        break;
      case SyncEventType.sos:
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case SyncEventType.emotion:
        icon = Icons.sentiment_satisfied_alt_rounded;
        color = AppColors.buttonPink;
        break;
      case SyncEventType.routineCompleted:
        icon = Icons.check_circle_rounded;
        color = AppColors.buttonTeal;
        break;
      case SyncEventType.remoteCheer:
        icon = Icons.favorite_rounded;
        color = AppColors.buttonPurple;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = Colors.blueGrey;
    }

    final timeStr = '${ev.timestamp.hour.toString().padLeft(2, '0')}:${ev.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: Neu.elevated(radius: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ev.displayMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${ev.childName} • $timeStr',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _sendCheer(String childName, String type, String msg, String emoji) {
    syncService.sendRemoteCheer(
      childName: childName,
      cheerType: type,
      cheerMessage: msg,
      emoji: emoji,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji Çocuğun tabletine moral ve maskot kutlaması yollandı!'),
        backgroundColor: AppColors.positiveGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. UZAKTAN YÖNETİM SEKMESİ
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRemoteManagementTab(BuildContext context, GameProgressService game, String childName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uzaktan Kart, Rutin & İçerik Yönetimi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Burada yapacağınız tüm eklemeler $childName\'in tabletine canlı olarak aktarılır.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          _ActionHubTile(
            icon: Icons.add_photo_alternate_rounded,
            color: AppColors.buttonPurple,
            title: 'Özel Kart Stüdyosu (Ses & Fotoğraf)',
            subtitle: 'Kamerayla evdeki nesneleri çekip ses kaydet ve çocuğun tabletine yolla',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomCardCreatorScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _ActionHubTile(
            icon: Icons.calendar_month_rounded,
            color: AppColors.buttonTeal,
            title: 'Günlük Rutin & Görev Planlayıcı',
            subtitle: 'Sabah, okul ve akşam adımlarını düzenle; tamamlanma bildirimlerini al',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyRoutineScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _ActionHubTile(
            icon: Icons.menu_book_rounded,
            color: AppColors.buttonBlue,
            title: 'Sosyal Hikayeler & Davranış Rehberleri',
            subtitle: 'Dişçi, kuaför ve park gibi durumlara hazırlayıcı öyküleri yapılandır',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SocialStoriesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _ActionHubTile(
            icon: Icons.print_rounded,
            color: AppColors.buttonIndigo,
            title: 'PECS & Makaton Fiziki Kart Yazdırıcı',
            subtitle: 'Sembolleri A4 boyutunda kesilebilir fiziki kartlar olarak PDF çıktısı al',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PecsPrinterScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _ActionHubTile(
            icon: Icons.document_scanner_rounded,
            color: AppColors.buttonPink,
            title: 'Görsel Çevirmen & Metin Okuyucu (OCR)',
            subtitle: 'Tabela, menü veya kitapları fotoğraflayıp Makaton kartlarına çevir',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VisualTranslatorScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. KLİNİK RAPOR & GELİŞİM SEKMESİ
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildClinicalReportTab(BuildContext context, GameProgressService game, String childName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Klinik Gelişim & Kullanım Grafiği',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ParentReportScreen()),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Tam Rapor Ekranı'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Haftalık Kullanım Grafiği
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Neu.elevated(radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Haftalık Sembol Basım Dağılımı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: SimpleBarChart(
                    data: game.last7DaysPresses,
                    labels: game.last7DaysLabels,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // En Sık Kullanılan İhtiyaçlar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Neu.elevated(radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'En Sık İfade Edilen İhtiyaç & Eylemler',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                if (game.topSymbols.isEmpty)
                  const Text('Henüz yeterli veri bulunmuyor.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                else
                  ...game.topSymbols.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          Text('${entry.value} kez', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. CİHAZ & EŞLEŞME AYARLARI SEKMESİ
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDeviceSyncTab(BuildContext context, GameProgressService game, String childName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cihazlar Arası Eşleşme & Güvenlik',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aynı ev Wi-Fi ağındaki çocuk tableti ile güvenli yerel bağlantı ayarları.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Aile Eşleşme Kodu Kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: Neu.elevated(radius: 20),
            child: Column(
              children: [
                const Text('AİLE EŞLEŞME KODU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  syncService.familyCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: AppColors.buttonIndigo,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: syncService.familyCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aile kodu panoya kopyalandı! 📋')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Kodu Kopyala'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Çocuk ve Aile Profilini Düzenle
          _ActionHubTile(
            icon: Icons.person_pin_rounded,
            color: AppColors.buttonIndigo,
            title: 'Çocuk & Veli Profil Bilgileri',
            subtitle: 'Çocuğun adı, avatarı, ebeveyn telefon numaraları ve acil durum adresi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen(isEditing: true)),
              );
            },
          ),
          const SizedBox(height: 12),

          // Öğrenci Hesabı Eşleştirme / Değiştirme
          _ActionHubTile(
            icon: Icons.link_rounded,
            color: AppColors.buttonTeal,
            title: 'Öğrenci Hesabı Bağla / Değiştir',
            subtitle: AuthService().currentUser?.linkedStudentUsername != null
                ? 'Şu an "@${AuthService().currentUser!.linkedStudentUsername}" öğrencisine bağlı. Değiştirmek için dokunun.'
                : 'Takip etmek istediğiniz öğrencinin kullanıcı adını yazarak hesabı bağlayın.',
            onTap: () {
              final currentUser = AuthService().currentUser;
              final ctrl = TextEditingController(text: currentUser?.linkedStudentUsername ?? '');
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Row(
                    children: [
                      Icon(Icons.link_rounded, color: AppColors.buttonIndigo),
                      SizedBox(width: 8),
                      Text('Öğrenci Hesabı Bağla'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Bağlamak istediğiniz öğrencinin kullanıcı adını girin (Örn: ali):'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ctrl,
                        decoration: InputDecoration(
                          hintText: 'Öğrenci Kullanıcı Adı',
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonIndigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (currentUser == null) return;
                        final res = await AuthService().linkStudentToParent(
                          parentUsername: currentUser.username,
                          studentUsername: ctrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.success
                                  ? 'Başarılı! "@${ctrl.text.trim()}" öğrencisi hesabınıza bağlandı.'
                                  : (res.error ?? 'Bağlama başarısız oldu.')),
                              backgroundColor: res.success ? AppColors.positiveGreen : Colors.red,
                            ),
                          );
                          setState(() {});
                        }
                      },
                      child: const Text('Bağla'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Özel Kart Stüdyosu
          _ActionHubTile(
            icon: Icons.add_photo_alternate_rounded,
            color: AppColors.buttonPurple,
            title: 'Özel Kart Stüdyosu (Fotoğraf & Ses)',
            subtitle: 'Kamerayla evdeki eşyaları çekin ve özel ses kaydı ekleyin',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomCardCreatorScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // PDF & PECS Kart Yazdırıcı
          _ActionHubTile(
            icon: Icons.print_rounded,
            color: AppColors.buttonIndigo,
            title: 'PDF & PECS Kart Yazdırıcı',
            subtitle: 'Sembolleri A4 boyutunda kesilebilir fiziki kart çıktısına dönüştürün',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PecsPrinterScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Sosyal Hikayeler & Rehberler
          _ActionHubTile(
            icon: Icons.menu_book_rounded,
            color: AppColors.buttonOrange,
            title: 'Sosyal Hikayeler & Rehberler',
            subtitle: 'Dişçi, okul, kuaför gibi sosyal durumlar için rehberler',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SocialStoriesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Acil Durum (SOS) Kartı & İletişim
          _ActionHubTile(
            icon: Icons.emergency_rounded,
            color: AppColors.accentRed,
            title: 'Acil Durum (SOS) Bilgileri & Kartı',
            subtitle: 'Çocuk kaybolduğunda görülecek veli telefon ve adres bilgileri',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Erişilebilirlik, Ses & JSON Yedekleme
          _ActionHubTile(
            icon: Icons.settings_accessibility_rounded,
            color: AppColors.buttonBlue,
            title: 'Erişilebilirlik, Ses & JSON Yedekleme',
            subtitle: 'Tarama modu, tremor filtresi, ses hızı ve veri yedekleme ayarları',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileDetailScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Mod Değiştirme / Çocuk Terminali Olarak Kilitle
          _ActionHubTile(
            icon: Icons.lock_outline_rounded,
            color: AppColors.buttonPurple,
            title: 'Bu Cihazı Çocuk Terminali Olarak Kilitle',
            subtitle: 'Ebeveyn panelini kapatıp cihazı çocuğun güvenli konuşma panosuna çevirir',
            onTap: () => _switchToChildMode(context, game),
          ),
        ],
      ),
    );
  }
}

// ─── Yardımcı Görsel Bileşenler ──────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: Neu.elevated(radius: 16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CheerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _CheerButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonPurple.withValues(alpha: 0.15),
        foregroundColor: AppColors.buttonPurple,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _ActionHubTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionHubTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: Neu.elevated(radius: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
