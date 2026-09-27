import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/makaton_item.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';

/// Profil ve Ayarlar ekranı.
///
/// 6 bölüm:
/// 1. Çocuk Bilgileri (ad, avatar, yaş, boy, kilo)
/// 2. Ebeveyn/Bakıcı Bilgisi
/// 3. İstatistikler (toplam gün, basım, en çok kullanılanlar)
/// 4. Başarı Rozetleri
/// 5. Ayarlar (ses, titreşim, günlük hedef, buton boyutu)
/// 6. Tema Tercihi
class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});
  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _birthCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _caregiverCtrl;
  late String _avatar;
  late String _caregiverRole;
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late int _dailyGoal;
  late int _buttonSize;
  late int _themeIndex;
  late bool _scanModeEnabled;
  late int _scanSpeedMs;
  late int _holdDurationMs;
  bool _initialized = false;

  static const List<String> _avatars = [
    '🐻', '🐰', '🦊', '🐱', '🐶', '🦁',
    '🐼', '🐨', '🦋', '🌟', '🐢', '🐙',
  ];
  static const List<String> _roles = [
    'Anne', 'Baba', 'Öğretmen', 'Terapist', 'Bakıcı', 'Diğer',
  ];
  static const List<Map<String, dynamic>> _themes = [
    {'name': 'Mavi', 'color': AppColors.buttonBlue, 'emoji': '🔵'},
    {'name': 'Yeşil', 'color': AppColors.buttonGreen, 'emoji': '🟢'},
    {'name': 'Pembe', 'color': AppColors.buttonPink, 'emoji': '🩷'},
    {'name': 'Turuncu', 'color': AppColors.buttonOrange, 'emoji': '🟠'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final game = context.read<GameProgressService>();
      _nameCtrl = TextEditingController(text: game.childName);
      _birthCtrl = TextEditingController(text: game.birthDate);
      _heightCtrl = TextEditingController(text: game.height);
      _weightCtrl = TextEditingController(text: game.weight);
      _caregiverCtrl = TextEditingController(text: game.caregiverName);
      _avatar = game.avatar;
      _caregiverRole = game.caregiverRole;
      _soundEnabled = game.soundEnabled;
      _vibrationEnabled = game.vibrationEnabled;
      _dailyGoal = game.dailyGoal;
      _buttonSize = game.buttonSize;
      _themeIndex = game.themeIndex;
      _scanModeEnabled = game.scanModeEnabled;
      _scanSpeedMs = game.scanSpeedMs;
      _holdDurationMs = game.holdDurationMs;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _caregiverCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final game = context.read<GameProgressService>();
    await game.saveFullProfile(
      name: _nameCtrl.text.trim(),
      avatar: _avatar,
      birthDate: _birthCtrl.text.trim(),
      height: _heightCtrl.text.trim(),
      weight: _weightCtrl.text.trim(),
      caregiverName: _caregiverCtrl.text.trim(),
      caregiverRole: _caregiverRole,
    );
    await game.saveSettings(
      soundEnabled: _soundEnabled,
      vibrationEnabled: _vibrationEnabled,
      dailyGoal: _dailyGoal,
      buttonSize: _buttonSize,
      themeIndex: _themeIndex,
    );
    await game.saveAccessibilitySettings(
      scanMode: _scanModeEnabled,
      scanSpeed: _scanSpeedMs,
      holdDuration: _holdDurationMs,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text('Kaydedildi ✅',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppColors.positiveGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportBackup(BuildContext context) {
    final game = context.read<GameProgressService>();
    final jsonStr = game.exportBackupJson();
    Clipboard.setData(ClipboardData(text: jsonStr));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppColors.buttonBlue),
            SizedBox(width: 8),
            Text('Yedek Panoya Kopyalandı! 📋'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tüm profil bilgileri, ayarlar ve oluşturduğunuz özel Makaton kartları JSON formatında panoya kopyalandı.',
            ),
            SizedBox(height: 8),
            Text(
              'Bu metni WhatsApp, E-posta veya Not Defterinize yapıştırarak güvenle saklayabilirsiniz.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _importBackup(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore_page_rounded, color: AppColors.buttonTeal),
            SizedBox(width: 8),
            Text('Yedekten Geri Yükle'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daha önce kopyaladığınız JSON yedek metnini buraya yapıştırın:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '{"app": "ozel_app", ...}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.03),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;

              final game = context.read<GameProgressService>();
              final success = await game.importBackupJson(text);

              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();

              if (success) {
                setState(() {
                  _nameCtrl.text = game.childName;
                  _birthCtrl.text = game.birthDate;
                  _heightCtrl.text = game.height;
                  _weightCtrl.text = game.weight;
                  _caregiverCtrl.text = game.caregiverName;
                  _avatar = game.avatar;
                  _caregiverRole = game.caregiverRole;
                  _soundEnabled = game.soundEnabled;
                  _vibrationEnabled = game.vibrationEnabled;
                  _dailyGoal = game.dailyGoal;
                  _buttonSize = game.buttonSize;
                  _themeIndex = game.themeIndex;
                  _scanModeEnabled = game.scanModeEnabled;
                  _scanSpeedMs = game.scanSpeedMs;
                  _holdDurationMs = game.holdDurationMs;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yedek başarıyla yüklendi ve uygulandı! ✅'),
                    backgroundColor: AppColors.positiveGreen,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hata: Geçersiz yedek JSON metni!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profil & Ayarlar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded, size: 22),
            label: const Text('Kaydet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(_themeIndex),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // ═══════════════════════════════════════
              // 1. ÇOCUK BİLGİLERİ
              // ═══════════════════════════════════════
              _SectionCard(
                title: '👶 Çocuk Bilgileri',
                child: Column(
                  children: [
                    // Avatar seçimi
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_avatar),
                        width: 90,
                        height: 90,
                        decoration: Neu.elevated(radius: 45, blur: 12),
                        child: Center(
                          child: Text(_avatar, style: const TextStyle(fontSize: 48)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _avatars.length,
                        separatorBuilder: (ctx, index) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final a = _avatars[i];
                          final sel = a == _avatar;
                          return GestureDetector(
                            onTap: () => setState(() => _avatar = a),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.buttonBlue.withValues(alpha: 0.2)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: sel
                                    ? Border.all(color: AppColors.buttonBlue, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(a, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _NeuTextField(ctrl: _nameCtrl, hint: 'Çocuğun adı', icon: Icons.child_care_rounded),
                    const SizedBox(height: 12),
                    _NeuTextField(ctrl: _birthCtrl, hint: 'Doğum tarihi (YYYY-AA-GG)', icon: Icons.cake_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _NeuTextField(ctrl: _heightCtrl, hint: 'Boy (cm)', icon: Icons.straighten_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _NeuTextField(ctrl: _weightCtrl, hint: 'Kilo (kg)', icon: Icons.monitor_weight_rounded)),
                      ],
                    ),
                    if (game.age.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.buttonBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('🎂 ${game.age}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.buttonBlue)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ═══════════════════════════════════════
              // 2. EBEVEYN / BAKICI
              // ═══════════════════════════════════════
              _SectionCard(
                title: '👨‍👩‍👧 Ebeveyn / Bakıcı',
                child: Column(
                  children: [
                    _NeuTextField(ctrl: _caregiverCtrl, hint: 'Ad Soyad', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _roles.length,
                        separatorBuilder: (ctx, index) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final role = _roles[i];
                          final sel = role == _caregiverRole;
                          return GestureDetector(
                            onTap: () => setState(() => _caregiverRole = role),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: sel
                                  ? Neu.colored(color: AppColors.buttonIndigo, radius: 16)
                                  : Neu.elevated(radius: 16, blur: 6),
                              child: Center(
                                child: Text(role,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : AppColors.textPrimary,
                                    )),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ═══════════════════════════════════════
              // 3. İSTATİSTİKLER
              // ═══════════════════════════════════════
              _SectionCard(
                title: '📊 İstatistikler',
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatBox(label: 'Toplam Gün', value: '${game.totalDays}', icon: '📅'),
                        const SizedBox(width: 12),
                        _StatBox(label: 'Toplam Basım', value: '${game.totalPresses}', icon: '👆'),
                        const SizedBox(width: 12),
                        _StatBox(label: 'Streak', value: '${game.streak}', icon: '🔥'),
                      ],
                    ),
                    if (game.topSymbols.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('En Çok Kullanılan Semboller',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 8),
                      ...game.topSymbols.map((entry) {
                        final allItems = MakatonItem.all();
                        final item = allItems.firstWhere(
                          (m) => m.id == entry.key,
                          orElse: () => allItems.first,
                        );
                        final maxCount = game.topSymbols.first.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(item.icon, size: 20, color: item.color),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.label,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 3),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: maxCount > 0 ? entry.value / maxCount : 0,
                                        minHeight: 6,
                                        backgroundColor: AppColors.neumorphicDark.withValues(alpha: 0.15),
                                        color: item.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${entry.value}×',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: item.color)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ═══════════════════════════════════════
              // 4. BAŞARI ROZETLERİ
              // ═══════════════════════════════════════
              _SectionCard(
                title: '🏆 Başarı Rozetleri',
                child: game.earnedBadges.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Henüz rozet kazanılmadı.\nButonlara basarak rozet kazan! 🎯',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: game.earnedBadges.map((b) {
                          return Container(
                            width: (MediaQuery.of(context).size.width - 80) / 2,
                            padding: const EdgeInsets.all(12),
                            decoration: Neu.elevated(radius: 16, blur: 8),
                            child: Column(
                              children: [
                                Text(b.icon, style: const TextStyle(fontSize: 32)),
                                const SizedBox(height: 6),
                                Text(b.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 3),
                                Text(b.desc,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),

              // ═══════════════════════════════════════
              // 5. AYARLAR
              // ═══════════════════════════════════════
              _SectionCard(
                title: '⚙️ Ayarlar',
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.volume_up_rounded,
                      label: 'Ses Efektleri',
                      trailing: Switch(
                        value: _soundEnabled,
                        onChanged: (v) => setState(() => _soundEnabled = v),
                        activeThumbColor: AppColors.buttonBlue,
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.vibration_rounded,
                      label: 'Titreşim',
                      trailing: Switch(
                        value: _vibrationEnabled,
                        onChanged: (v) => setState(() => _vibrationEnabled = v),
                        activeThumbColor: AppColors.buttonBlue,
                      ),
                    ),
                    const Divider(height: 24),
                    // Günlük hedef
                    Row(
                      children: [
                        const Icon(Icons.flag_rounded, color: AppColors.buttonOrange, size: 22),
                        const SizedBox(width: 10),
                        const Text('Günlük Hedef',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        IconButton(
                          onPressed: _dailyGoal > 3
                              ? () => setState(() => _dailyGoal--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: Neu.elevated(radius: 12, blur: 4),
                          child: Text('$_dailyGoal',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          onPressed: _dailyGoal < 30
                              ? () => setState(() => _dailyGoal++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Buton ve Yazı Puntosu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_size_rounded, color: AppColors.buttonPurple, size: 22),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Yazı & Buton Boyutu (Punto)',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('Uygulama genelindeki yazı büyüklüğü',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ...[
                              {'size': 0, 'code': 'S', 'desc': 'Küçük'},
                              {'size': 1, 'code': 'M', 'desc': 'Standart'},
                              {'size': 2, 'code': 'L', 'desc': 'Büyük'},
                            ].map((item) {
                              final size = item['size'] as int;
                              final code = item['code'] as String;
                              final desc = item['desc'] as String;
                              final sel = _buttonSize == size;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _buttonSize = size);
                                      context.read<GameProgressService>().saveSettings(
                                        soundEnabled: _soundEnabled,
                                        vibrationEnabled: _vibrationEnabled,
                                        dailyGoal: _dailyGoal,
                                        buttonSize: size,
                                        themeIndex: _themeIndex,
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 52,
                                      decoration: sel
                                          ? Neu.colored(color: AppColors.buttonPurple, radius: 14)
                                          : Neu.elevated(radius: 14, blur: 4),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(code,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: sel ? Colors.white : AppColors.textPrimary,
                                              )),
                                          Text(desc,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: sel ? Colors.white70 : AppColors.textSecondary,
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ═══════════════════════════════════════
              // 6. TEMA TERCİHİ
              // ═══════════════════════════════════════
              _SectionCard(
                title: '🎨 Tema Tercihi (Canlı Değişim)',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_themes.length, (i) {
                    final t = _themes[i];
                    final sel = _themeIndex == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _themeIndex = i);
                        context.read<GameProgressService>().saveSettings(
                          soundEnabled: _soundEnabled,
                          vibrationEnabled: _vibrationEnabled,
                          dailyGoal: _dailyGoal,
                          buttonSize: _buttonSize,
                          themeIndex: i,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72, height: 84,
                        decoration: sel
                            ? Neu.colored(color: t['color'] as Color, radius: 16)
                            : Neu.elevated(radius: 16, blur: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t['emoji'] as String, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(t['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : AppColors.textPrimary,
                                )),
                            if (sel)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // ── 7. İleri Düzey Erişilebilirlik ─────────────────────────
              _SectionCard(
                title: '♿ İleri Düzey Erişilebilirlik',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingRow(
                      icon: Icons.sync_rounded,
                      label: 'Otomatik Sıralı Tarama (Switch)',
                      trailing: Switch.adaptive(
                        value: _scanModeEnabled,
                        activeTrackColor: AppColors.buttonBlue,
                        onChanged: (v) => setState(() => _scanModeEnabled = v),
                      ),
                    ),
                    if (_scanModeEnabled) ...[
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Tarama Hızı',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final speed in [
                            {'ms': 1000, 'label': '1.0 sn'},
                            {'ms': 1500, 'label': '1.5 sn'},
                            {'ms': 2000, 'label': '2.0 sn'},
                          ])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: GestureDetector(
                                  onTap: () => setState(() => _scanSpeedMs = speed['ms'] as int),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: _scanSpeedMs == speed['ms']
                                        ? Neu.colored(color: AppColors.buttonBlue, radius: 12)
                                        : Neu.elevated(radius: 12, blur: 4),
                                    child: Center(
                                      child: Text(
                                        speed['label'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _scanSpeedMs == speed['ms'] ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const Divider(height: 28),
                    const Text(
                      'İstemsiz Basma Koruması (Tremor Filtresi)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Elin butona istemeden temas etmesi durumunda yanlış basımı engellemek için dokunma süresi şartı koyar.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final hold in [
                          {'ms': 0, 'label': 'Anında'},
                          {'ms': 300, 'label': '0.3 sn'},
                          {'ms': 500, 'label': '0.5 sn'},
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () => setState(() => _holdDurationMs = hold['ms'] as int),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: _holdDurationMs == hold['ms']
                                      ? Neu.colored(color: AppColors.buttonGreen, radius: 12)
                                      : Neu.elevated(radius: 12, blur: 4),
                                  child: Center(
                                    child: Text(
                                      hold['label'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: _holdDurationMs == hold['ms'] ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 8. Veri Yedekleme & Aktarma ─────────────────────────
              _SectionCard(
                title: '💾 Veri Yedekleme & Aktarma',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cihaz değişimi veya tablet geçişlerinde çocuğunuzun özel kartları ve kayıtları kaybolmaz.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _exportBackup(context),
                            icon: const Icon(Icons.copy_all_rounded, size: 18),
                            label: const Text('Yedeği Kopyala', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _importBackup(context),
                            icon: const Icon(Icons.restore_rounded, size: 18),
                            label: const Text('Geri Yükle', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Kaydet butonu (alt)
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: Neu.colored(color: AppColors.positiveGreen),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text('Değişiklikleri Kaydet',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Yardımcı Widget'lar ────────────────────────────────────

/// Neumorphic metin giriş alanı.
class _NeuTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;

  const _NeuTextField({
    required this.ctrl,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: Neu.elevated(radius: 16, blur: 6),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.buttonBlue, size: 22),
          isDense: true,
        ),
      ),
    );
  }
}

/// Bölüm kartı.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: Neu.elevated(radius: 24, blur: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// İstatistik kutusu.
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: Neu.elevated(radius: 16, blur: 6),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Ayar satırı.
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingRow({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.buttonBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          trailing,
        ],
      ),
    );
  }
}
