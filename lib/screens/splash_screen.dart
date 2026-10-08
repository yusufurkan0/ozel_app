import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../services/game_progress_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'parent_dashboard_screen.dart';
import '../services/auth_service.dart';
import '../services/parent_child_sync_service.dart';

/// Lottie animasyonlu açılış ekranı.
/// 3 saniye gösterilir, ardından profil durumuna göre yönlendirir.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );
    _fadeCtrl.forward();

    _navigate();
  }

  Future<void> _navigate() async {
    // Verileri ve kullanıcı oturumunu yükle
    final gameService =
        Provider.of<GameProgressService>(context, listen: false);
    await gameService.loadData();
    await AuthService().initialize();

    // 2 saniye bekle
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final nav = Navigator.of(context);
    final auth = AuthService();

    final Widget destination;
    if (auth.isLoggedIn && auth.currentUser!.isParent) {
      await ParentChildSyncService().setDeviceRole(DeviceRole.parentCompanion);
      destination = const ParentDashboardScreen();
    } else {
      if (auth.isLoggedIn) {
        final user = auth.currentUser!;
        await gameService.saveProfile(user.displayName, user.avatar);
      }
      await ParentChildSyncService().setDeviceRole(DeviceRole.childTerminal);
      destination = const HomeScreen();
    }

    nav.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondary) => destination,
        transitionsBuilder: (ctx2, anim, secondary2, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.lightBlue, AppColors.background],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animasyonu
              SizedBox(
                width: 220,
                height: 220,
                child: Lottie.asset(
                  'assets/lottie/splash.json',
                  repeat: true,
                  animate: true,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Özel İletişim',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 36,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Makaton ile İletişim Kur',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.buttonBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
