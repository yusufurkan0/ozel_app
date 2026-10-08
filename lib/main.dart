import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'services/game_progress_service.dart';
import 'services/predictive_engine.dart';
import 'services/timer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OzelApp());
}

class OzelApp extends StatelessWidget {
  const OzelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final service = GameProgressService();
          service.loadData();
          return service;
        }),
        ChangeNotifierProvider(create: (_) {
          final engine = PredictiveEngine();
          engine.initialize();
          return engine;
        }),
        ChangeNotifierProvider.value(value: VisualTimerService.instance),
      ],
      child: Selector<GameProgressService, ({int buttonSize, int themeIndex})>(
        selector: (_, s) => (buttonSize: s.buttonSize, themeIndex: s.themeIndex),
        builder: (context, settings, _) {
          // 0: Küçük (0.88), 1: Standart (1.05), 2: Büyük (1.25)
          final textScale = settings.buttonSize == 0
              ? 0.88
              : (settings.buttonSize == 2 ? 1.25 : 1.05);

          return MaterialApp(
            title: 'Özel İletişim & Yaşam Rehberi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(settings.themeIndex),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              );
            },
            home: const AppStartupGate(),
          );
        },
      ),
    );
  }
}

/// Uygulama ilk açıldığında bilgi doldurma formunun (Genel Bilgiler)
/// gerekip gerekmediğini kontrol eder; doldurulmamışsa formu getirir.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _loading = true;
  bool _needsInfoFilling = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isRegistered = prefs.getBool('is_registered') ?? false;
    final infoCompleted = prefs.getBool('initial_info_completed') ?? false;
    final childName = prefs.getString('child_name') ??
        prefs.getString('sos_child_name') ??
        prefs.getString('user_emergency_name') ??
        '';

    if (mounted) {
      setState(() {
        _needsInfoFilling = !infoCompleted && (!isRegistered || childName.trim().isEmpty);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: SizedBox.shrink(),
      );
    }

    if (_needsInfoFilling) {
      return const RegisterScreen(
        isEditing: true,
        isOnboarding: true,
      );
    }

    return const HomeScreen();
  }
}
