import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/makaton_item.dart';
import '../services/predictive_engine.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_makaton_button.dart';
import '../widgets/category_tab_bar.dart';

/// Akıllı Makaton İletişim Panosu.
///
/// Cihaz saatine göre butonları otomatik sıralar.
/// Her basış GameProgressService'e kaydedilir.
/// Otomatik sıralı tarama (Switch Access) ve Çocuk Kilidi (Kiosk) desteği içerir.
class MakatonBoardScreen extends StatefulWidget {
  const MakatonBoardScreen({super.key});

  @override
  State<MakatonBoardScreen> createState() => _MakatonBoardScreenState();
}

class _MakatonBoardScreenState extends State<MakatonBoardScreen> {
  Timer? _scanTimer;
  int _scannedIndex = 0;
  bool _customItemsSynced = false;
  bool _childLockEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.watch<GameProgressService>();
    final engine = context.read<PredictiveEngine>();

    if (!_customItemsSynced) {
      _customItemsSynced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          engine.syncCustomItems(game.customItems);
        }
      });
    }

    _setupScanTimer(game.scanModeEnabled, game.scanSpeedMs);
  }

  void _setupScanTimer(bool enabled, int speedMs) {
    _scanTimer?.cancel();
    if (!enabled) return;

    _scanTimer = Timer.periodic(Duration(milliseconds: speedMs), (_) {
      final engine = context.read<PredictiveEngine>();
      final count = engine.filteredItems.length;
      if (count == 0) return;
      if (mounted) {
        setState(() {
          _scannedIndex = (_scannedIndex + 1) % count;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  void _triggerItem(BuildContext context, MakatonItem item) {
    final engine = context.read<PredictiveEngine>();
    final game = context.read<GameProgressService>();
    engine.recordTap(item.id);
    game.recordPress(item.id);
    _showFeedback(context, item);
  }

  void _showFeedback(BuildContext context, MakatonItem item) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Text(
              '${item.label} 👍',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: item.color.withValues(alpha: 0.85),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      ),
    );
  }

  // ─── Çocuk Kilidi (Kiosk Modu) ──────────────────────────────
  void _toggleLock() {
    if (!_childLockEnabled) {
      setState(() => _childLockEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🔒 Çocuk Kilidi Aktif! Panodan çıkış kilitlendi. Açmak için kilide dokunun veya 3 sn basılı tutun.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.buttonIndigo,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      _showUnlockDialog();
    }
  }

  void _showUnlockDialog() {
    final game = context.read<GameProgressService>();

    if (game.isPinSet) {
      final pinCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_open_rounded, color: AppColors.buttonBlue),
              SizedBox(width: 8),
              Text('Kilidi Aç'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Panodan çıkmak için ebeveyn PIN kodunu girin:'),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                backgroundColor: AppColors.positiveGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (game.verifyPin(pinCtrl.text.trim())) {
                  Navigator.of(ctx).pop();
                  setState(() => _childLockEnabled = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🔓 Çocuk Kilidi Açıldı')),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Hatalı PIN!')),
                  );
                }
              },
              child: const Text('Aç'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_open_rounded, color: AppColors.buttonIndigo),
              SizedBox(width: 8),
              Text('Kilidi Kaldır?'),
            ],
          ),
          content: const Text(
            'Çocuk kilidini kaldırıp panodan çıkışa izin vermek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kilitli Kalsın'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.positiveGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _childLockEnabled = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔓 Çocuk Kilidi Açıldı')),
                );
              },
              child: const Text('Kilidi Aç'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<PredictiveEngine>();
    final game = context.watch<GameProgressService>();
    final items = engine.filteredItems;

    // Tarama indeksi sınır kontrolü
    if (items.isNotEmpty && _scannedIndex >= items.length) {
      _scannedIndex = 0;
    }

    return PopScope(
      canPop: !_childLockEnabled,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showUnlockDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              _childLockEnabled ? Icons.lock_rounded : Icons.arrow_back_rounded,
              size: 28,
              color: _childLockEnabled ? Colors.amber.shade700 : null,
            ),
            onPressed: () {
              if (_childLockEnabled) {
                _showUnlockDialog();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            _childLockEnabled ? 'İletişim Panosu (Kilitli)' : 'İletişim Panosu',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            // Çocuk Kilidi Butonu
            Tooltip(
              message: _childLockEnabled ? 'Kilidi Aç' : 'Çocuk Kilidi (Kiosk)',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onLongPress: () {
                  if (_childLockEnabled) {
                    setState(() => _childLockEnabled = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🔓 Çocuk Kilidi Açıldı')),
                    );
                  }
                },
                onTap: _toggleLock,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: _childLockEnabled
                      ? Neu.colored(color: Colors.amber.shade800, radius: 14)
                      : Neu.elevated(radius: 14, blur: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _childLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                        size: 18,
                        color: _childLockEnabled ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _childLockEnabled ? 'Kilitli' : 'Kilit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _childLockEnabled ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Zaman dilimi göstergesi
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: Neu.elevated(radius: 14, blur: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      engine.currentSlotLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.mintGreen,
                AppColors.background,
                AppColors.lavender,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Başlık
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Text(
                    'Ne istediğini seç 💬',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                // Kategori Sekmeleri
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CategoryTabBar(
                    selected: engine.activeCategory,
                    onSelected: (cat) {
                      setState(() => _scannedIndex = 0);
                      engine.setCategory(cat);
                    },
                  ),
                ),
                // Makaton butonları grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: game.buttonSize == 0
                          ? 0.95
                          : (game.buttonSize == 2 ? 0.76 : 0.86),
                    ),
                    itemCount: items.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isScanned = game.scanModeEnabled && _scannedIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: isScanned
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFFFB300),
                                  width: 5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              )
                            : null,
                        child: SmartMakatonButton(
                          item: item,
                          onTap: () => _triggerItem(context, item),
                        ),
                      );
                    },
                  ),
                ),

                // Switch Tarama Modu Aktifse: Büyük Seçim Butonu
                if (game.scanModeEnabled && items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GestureDetector(
                      onTap: () => _triggerItem(context, items[_scannedIndex]),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: Neu.colored(
                          color: const Color(0xFFFFB300),
                          radius: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.touch_app_rounded, color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              'SEÇ: ${items[_scannedIndex].label}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
}
