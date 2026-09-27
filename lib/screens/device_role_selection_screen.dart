import 'package:flutter/material.dart';
import '../services/parent_child_sync_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'parent_dashboard_screen.dart';

/// Cihaz Rolü Seçim Ekranı:
/// Kullanıcının bu cihazı Çocuk İletişim Terminali mi yoksa Ebeveyn Refakatçi Paneli mi
/// olarak kullanacağını belirlemesini sağlar.
class DeviceRoleSelectionScreen extends StatefulWidget {
  final bool isFromSettings;

  const DeviceRoleSelectionScreen({super.key, this.isFromSettings = false});

  @override
  State<DeviceRoleSelectionScreen> createState() => _DeviceRoleSelectionScreenState();
}

class _DeviceRoleSelectionScreenState extends State<DeviceRoleSelectionScreen> {
  final syncService = ParentChildSyncService();

  void _selectRole(DeviceRole role) async {
    await syncService.setDeviceRole(role);

    if (!mounted) return;

    if (role == DeviceRole.parentCompanion) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isFromSettings
          ? AppBar(title: const Text('Cihaz Rolünü Değiştir'))
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.getGradient(0)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.buttonIndigo.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.devices_other_rounded,
                    size: 40,
                    color: AppColors.buttonIndigo,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bu Cihaz Nasıl Kullanılacak?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Özel eğitimde en sağlıklı deneyim için çocuk cihazı ile ebeveyn cihazı ayrı çalışabilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // 1. Seçenek: Çocuk İletişim Terminali
                _RoleCard(
                  icon: Icons.child_care_rounded,
                  iconColor: AppColors.buttonTeal,
                  title: '🧒 Çocuk İletişim Terminali',
                  subtitle:
                      'Bu cihazı çocuğun konuşma tableti yap. Dikkat dağıtıcı menüler gizlenir, sadece büyük iletişim kartları ve rutinler görünür.',
                  badgeText: 'Çocuk Tableti İçin Önerilir',
                  onTap: () => _selectRole(DeviceRole.childTerminal),
                ),
                const SizedBox(height: 16),

                // 2. Seçenek: Ebeveyn Refakatçi Paneli
                _RoleCard(
                  icon: Icons.family_restroom_rounded,
                  iconColor: AppColors.buttonPurple,
                  title: '👨‍👩‍👧 Ebeveyn Refakatçi Paneli',
                  subtitle:
                      'Bu cihazı anne/baba veya terapist telefonu yap. Çocuğun konuştuğu her kelimeyi canlı izle, uzaktan kart ve rutin ekle.',
                  badgeText: 'Ebeveyn Telefonu İçin Önerilir',
                  onTap: () => _selectRole(DeviceRole.parentCompanion),
                ),
                const SizedBox(height: 16),

                // 3. Seçenek: Klasik Tek Cihaz Modu
                _RoleCard(
                  icon: Icons.phonelink_setup_rounded,
                  iconColor: AppColors.buttonBlue,
                  title: '🔄 Tek Cihaz (Klasik Mod)',
                  subtitle:
                      'Hem çocuk iletişimini hem de ebeveyn araçlarını aynı cihazda bir arada kullanın. PIN ile ebeveyn alanına geçebilirsiniz.',
                  badgeText: 'Tek Tablet / Cihaz',
                  onTap: () => _selectRole(DeviceRole.standalone),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: Neu.elevated(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
