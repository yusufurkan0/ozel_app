import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
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
      child: Consumer<GameProgressService>(
        builder: (context, game, _) {
          // 0: Küçük (0.88), 1: Standart (1.05), 2: Büyük (1.25)
          final textScale = game.buttonSize == 0
              ? 0.88
              : (game.buttonSize == 2 ? 1.25 : 1.05);

          return MaterialApp(
            title: 'Özel İletişim & Yaşam Rehberi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(game.themeIndex),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
