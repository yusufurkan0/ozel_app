import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_account.dart';
import '../services/auth_service.dart';
import '../services/game_progress_service.dart';
import '../services/parent_child_sync_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'parent_dashboard_screen.dart';
import 'register_screen.dart';

/// 🔐 Giriş Ekranı (LoginScreen)
/// Öğrenci ve Veli için ayrı sekmeli, şifreli, tek tıkla test demo hesaplı giriş ekranı.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _errorMessage = '';
        _usernameCtrl.clear();
        _passwordCtrl.clear();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameCtrl.text;
    final password = _passwordCtrl.text;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final res = await AuthService().login(
      username: username,
      password: password,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (!res.success) {
      setState(() => _errorMessage = res.error ?? 'Giriş başarısız oldu.');
    } else {
      final user = AuthService().currentUser!;
      if (user.isParent) {
        await ParentChildSyncService().setDeviceRole(DeviceRole.parentCompanion);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
        );
      } else {
        final game = Provider.of<GameProgressService>(context, listen: false);
        await game.saveProfile(user.displayName, user.avatar);
        await ParentChildSyncService().setDeviceRole(DeviceRole.childTerminal);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.getGradient(0)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / İkon
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      size: 46,
                      color: AppColors.buttonIndigo,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Özel İletişim Dünyası',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lütfen devam etmek için hesabınıza giriş yapın',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Sekmeler: Öğrenci vs Veli
                  Container(
                    decoration: Neu.inset(radius: 20),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.buttonIndigo,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.child_care_rounded, size: 20),
                          text: 'Öğrenci Girişi',
                        ),
                        Tab(
                          icon: Icon(Icons.family_restroom_rounded, size: 20),
                          text: 'Veli Girişi',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hata Mesajı Banner'ı
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Alanları Kartı
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: Neu.elevated(radius: 22),
                    child: Column(
                      children: [
                        // Kullanıcı Adı
                        Container(
                          decoration: Neu.inset(radius: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.alternate_email_rounded, color: AppColors.buttonIndigo, size: 20),
                              hintText: 'Kullanıcı Adı',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Şifre
                        Container(
                          decoration: Neu.inset(radius: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              icon: const Icon(Icons.lock_rounded, color: AppColors.buttonIndigo, size: 20),
                              hintText: 'Şifre',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Giriş Yap Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonIndigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : () => _handleLogin(),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Giriş Yap',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kayıt Ol Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Henüz bir hesabınız yok mu? ',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          final role = _tabController.index == 0 ? UserRole.student : UserRole.parent;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RegisterScreen(initialRole: role)),
                          );
                        },
                        child: const Text(
                          'Kayıt Olun',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonIndigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tüm Verileri Sıfırla (Temiz Başlangıç)
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(Icons.delete_forever_rounded, color: AppColors.accentRed),
                              SizedBox(width: 8),
                              Text('Verileri Sıfırla?'),
                            ],
                          ),
                          content: const Text(
                            'Tüm kayıtlı hesaplar, şifreler, öğrenci profilleri ve geçmiş konuşmalar silinecek.\n\nSıfırdan temiz bir başlangıç yapmak istiyor musunuz?',
                            style: TextStyle(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('İptal'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentRed,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await AuthService().resetAllData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tüm veriler başarıyla sıfırlandı! ✅'),
                                      backgroundColor: AppColors.positiveGreen,
                                    ),
                                  );
                                  setState(() {});
                                }
                              },
                              child: const Text('Evet, Sıfırla'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textSecondary),
                    label: const Text(
                      'Tüm Verileri Sıfırla (Temiz Başlangıç)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
}
