import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/makaton_item.dart';
import 'parent_child_sync_service.dart';
import 'database/app_database_service.dart';

/// Profil, streak, ayarlar, rozetler, favoriler, duygular, rutinler ve
/// günlük ilerlemeyi yöneten merkezi servis.
class GameProgressService extends ChangeNotifier {
  // ─── Cihaz Rolü & Senkronizasyon ─────────────
  DeviceRole get deviceRole => ParentChildSyncService().currentRole;
  bool get isChildTerminal => ParentChildSyncService().isChildTerminal;
  bool get isParentCompanion => ParentChildSyncService().isParentCompanion;
  StreamSubscription? _syncSub;

  // ─── Çocuk Profili ───────────────────────────
  String _childName = '';
  String _avatar = '🐻';
  String _birthDate = '';
  String _height = '';
  String _weight = '';
  bool get hasProfile => _childName.isNotEmpty;
  String get childName => _childName;
  String get avatar => _avatar;
  String get birthDate => _birthDate;
  String get height => _height;
  String get weight => _weight;

  String get age {
    if (_birthDate.isEmpty) return '';
    try {
      final parts = _birthDate.split('-');
      final birth = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      int years = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
      return '$years yaş';
    } catch (_) {
      return '';
    }
  }

  // ─── Ebeveyn / Bakıcı ───────────────────────
  String _caregiverName = '';
  String _caregiverRole = 'Anne';
  String get caregiverName => _caregiverName;
  String get caregiverRole => _caregiverRole;

  // ─── Streak ──────────────────────────────────
  int _streak = 0;
  int get streak => _streak;

  // ─── Ayarlar ─────────────────────────────────
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _dailyGoal = 10;
  int _buttonSize = 1;
  int _themeIndex = 0;
  String _parentPin = '';
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get dailyGoal => _dailyGoal;
  int get buttonSize => _buttonSize;
  int get themeIndex => _themeIndex;
  String get parentPin => _parentPin;
  bool get isPinSet => _parentPin.isNotEmpty;

  bool verifyPin(String pin) {
    if (_parentPin.isEmpty) return true;
    return _parentPin == pin;
  }

  Future<void> setPin(String pin) async {
    _parentPin = pin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_pin', pin);
    notifyListeners();
  }

  // ─── İstatistikler ──────────────────────────
  int _totalPresses = 0;
  int _totalDays = 0;
  int _gameScore = 0;
  Map<String, int> _itemPressHistory = {};
  int get totalPresses => _totalPresses;
  int get totalDays => _totalDays;
  int get totalScore => _gameScore;
  Map<String, int> get itemPressHistory => Map.unmodifiable(_itemPressHistory);

  void recordSuccess() {
    _gameScore += 10;
    _totalPresses++;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setInt('game_score', _gameScore));
  }

  List<MapEntry<String, int>> get topSymbols {
    final sorted = _itemPressHistory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  // ─── Haftalık Rapor Verisi ──────────────────
  Map<String, int> _weeklyPresses = {};
  Map<String, int> get weeklyPresses => Map.unmodifiable(_weeklyPresses);

  List<int> get last7DaysPresses {
    final result = <int>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = _dayKey(d);
      result.add(_weeklyPresses[key] ?? 0);
    }
    return result;
  }

  List<String> get last7DaysLabels {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final result = <String>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      result.add(days[d.weekday - 1]);
    }
    return result;
  }

  // ─── Favoriler ──────────────────────────────
  final Set<String> _favorites = {};
  Set<String> get favorites => Set.unmodifiable(_favorites);
  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
    notifyListeners();
  }

  List<MakatonItem> get favoriteItems {
    final all = allItems;
    if (_favorites.isEmpty) {
      const defaultIds = ['su', 'yemek', 'istiyorum', 'lutfen', 'oyun', 'yardim_et'];
      return all.where((i) => defaultIds.contains(i.id)).toList();
    }
    return all.where((i) => _favorites.contains(i.id)).toList();
  }

  // ─── Erişilebilirlik (Tarama & Titreme Koruması) ─────
  bool _scanModeEnabled = false;
  int _scanSpeedMs = 1500;
  int _holdDurationMs = 0;
  bool get scanModeEnabled => _scanModeEnabled;
  int get scanSpeedMs => _scanSpeedMs;
  int get holdDurationMs => _holdDurationMs;

  Future<void> saveAccessibilitySettings({
    required bool scanMode,
    required int scanSpeed,
    required int holdDuration,
  }) async {
    _scanModeEnabled = scanMode;
    _scanSpeedMs = scanSpeed;
    _holdDurationMs = holdDuration;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scan_mode', scanMode);
    await prefs.setInt('scan_speed', scanSpeed);
    await prefs.setInt('hold_duration', holdDuration);
    notifyListeners();
  }

  // ─── Özel Kartlar (Custom Items) ────────────────────
  final List<MakatonItem> _customItems = [];
  List<MakatonItem> get customItems => List.unmodifiable(_customItems);
  List<MakatonItem> get allItems => [...MakatonItem.all(), ..._customItems];

  Future<void> addCustomItem(MakatonItem item) async {
    _customItems.add(item);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customItems.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('custom_items_v1', jsonList);
    await AppDatabaseService().saveCustomCard(item);
    notifyListeners();
  }

  Future<void> removeCustomItem(String id) async {
    _customItems.removeWhere((i) => i.id == id);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customItems.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('custom_items_v1', jsonList);
    await AppDatabaseService().deleteCustomCard(id);
    notifyListeners();
  }

  // ─── Duygu Geçmişi ─────────────────────────
  String _todayEmotion = '';
  String get todayEmotion => _todayEmotion;
  Map<String, String> _emotionHistory = {};
  Map<String, String> get emotionHistory => Map.unmodifiable(_emotionHistory);

  Future<void> setEmotion(String emotionId) async {
    _todayEmotion = emotionId;
    final today = _todayKey();
    _emotionHistory[today] = emotionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emotion_$today', emotionId);
    await prefs.setString('today_emotion', emotionId);
    // Geçmiş kaydet
    await prefs.setStringList('emotion_dates', _emotionHistory.keys.toList());

    ParentChildSyncService().dispatchEmotionEvent(
      childName: _childName.isNotEmpty ? _childName : 'Öğrenci',
      emoji: '😊',
      emotionTitle: emotionId,
    );

    notifyListeners();
  }

  /// Son 7 günün duygu dağılımı.
  Map<String, int> get emotionDistribution {
    final dist = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final key = _dayKey(d);
      final e = _emotionHistory[key];
      if (e != null && e.isNotEmpty) {
        dist[e] = (dist[e] ?? 0) + 1;
      }
    }
    return dist;
  }

  // ─── Günlük Rutinler ───────────────────────
  final Map<String, RoutineItem> _routines = {};
  Map<String, RoutineItem> get routines => Map.unmodifiable(_routines);

  void initDefaultRoutines() {
    if (_routines.isEmpty) {
      final defaults = [
        RoutineItem(id: 'r1', title: 'Ellerimi yıkadım 🧼', period: 'Sabah', time: '07:30'),
        RoutineItem(id: 'r2', title: 'Dişlerimi fırçaladım 🪥', period: 'Sabah', time: '07:45'),
        RoutineItem(id: 'r3', title: 'Kahvaltı yaptım 🥞', period: 'Sabah', time: '08:00'),
        RoutineItem(id: 'r4', title: 'Kıyafetlerimi giydim 👕', period: 'Sabah', time: '08:30'),
        RoutineItem(id: 'r5', title: 'Oyun oynadım 🎮', period: 'Öğle', time: '10:00'),
        RoutineItem(id: 'r6', title: 'Öğle yemeği yedim 🍝', period: 'Öğle', time: '12:00'),
        RoutineItem(id: 'r7', title: 'Kitap okudum 📖', period: 'Öğle', time: '14:00'),
        RoutineItem(id: 'r8', title: 'Akşam yemeği yedim 🍽️', period: 'Akşam', time: '18:00'),
        RoutineItem(id: 'r9', title: 'Banyo yaptım 🛁', period: 'Akşam', time: '19:30'),
        RoutineItem(id: 'r10', title: 'Pijamalarımı giydim 🌙', period: 'Gece', time: '20:30'),
        RoutineItem(id: 'r11', title: 'Dişlerimi fırçaladım 🪥', period: 'Gece', time: '20:45'),
        RoutineItem(id: 'r12', title: 'Uyumaya hazırım 😴', period: 'Gece', time: '21:00'),
      ];
      for (final r in defaults) {
        _routines[r.id] = r;
      }
    }
  }

  Future<void> toggleRoutine(String routineId) async {
    final r = _routines[routineId];
    if (r == null) return;
    r.completed = !r.completed;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final completedIds = _routines.values
        .where((r) => r.completed)
        .map((r) => r.id)
        .toList();
    await prefs.setStringList('routines_done_$today', completedIds);

    if (r.completed) {
      ParentChildSyncService().dispatchRoutineCompleted(
        childName: _childName.isNotEmpty ? _childName : 'Öğrenci',
        stepId: routineId,
        stepTitle: r.title,
        emoji: '✅',
      );
    }

    notifyListeners();
  }

  int get completedRoutineCount =>
      _routines.values.where((r) => r.completed).length;
  double get routineProgress =>
      _routines.isEmpty ? 0 : completedRoutineCount / _routines.length;

  // ─── Rozetler ───────────────────────────────
  List<Badge> get earnedBadges {
    final badges = <Badge>[];
    if (_totalPresses >= 1) {
      badges.add(const Badge(id: 'first_press', title: 'İlk Adım', icon: '⭐', desc: 'İlk butonunu bastın!'));
    }
    if (_totalPresses >= 50) {
      badges.add(const Badge(id: 'press_50', title: 'İletişim Ustası', icon: '🏅', desc: '50 buton bastın!'));
    }
    if (_totalPresses >= 100) {
      badges.add(const Badge(id: 'press_100', title: 'Süper Konuşmacı', icon: '🏆', desc: '100 buton bastın!'));
    }
    if (_totalPresses >= 500) {
      badges.add(const Badge(id: 'press_500', title: 'Efsane', icon: '👑', desc: '500 buton bastın!'));
    }
    if (_streak >= 3) {
      badges.add(const Badge(id: 'streak_3', title: '3 Gün Serisi', icon: '🔥', desc: '3 gün üst üste!'));
    }
    if (_streak >= 7) {
      badges.add(const Badge(id: 'streak_7', title: 'Hafta Şampiyonu', icon: '💪', desc: '7 gün üst üste!'));
    }
    if (_streak >= 30) {
      badges.add(const Badge(id: 'streak_30', title: 'Ay Yıldızı', icon: '🌟', desc: '30 gün üst üste!'));
    }
    if (_totalDays >= 1) {
      badges.add(const Badge(id: 'day_1', title: 'Hoş Geldin', icon: '🎉', desc: 'İlk gün tamamlandı!'));
    }
    if (_totalDays >= 7) {
      badges.add(const Badge(id: 'day_7', title: 'Bir Hafta', icon: '📅', desc: '7 gün kullandın!'));
    }
    if (_favorites.length >= 3) {
      badges.add(const Badge(id: 'fav_3', title: 'Koleksiyoncu', icon: '💎', desc: '3 favori eklendi!'));
    }
    return badges;
  }

  // ─── Günlük İlerleme ────────────────────────
  final List<ProgressStep> _todaySteps = [];
  List<ProgressStep> get todaySteps => List.unmodifiable(_todaySteps);
  double get progress => (_todaySteps.length / _dailyGoal).clamp(0.0, 1.0);

  // ─── Maskot ─────────────────────────────────
  bool _mascotHappy = false;
  bool get mascotHappy => _mascotHappy;

  // ─── Öğrenme Modu Skoru ─────────────────────
  int _learningScore = 0;
  int _learningTotal = 0;
  int get learningScore => _learningScore;
  int get learningTotal => _learningTotal;

  Future<void> saveLearningResult(int correct, int total) async {
    _learningScore += correct;
    _learningTotal += total;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('learning_score', _learningScore);
    await prefs.setInt('learning_total', _learningTotal);
    notifyListeners();
  }

  // ═════════════════════════════════════════════
  // VERİ YÜKLEME / KAYDETME
  // ═════════════════════════════════════════════

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _childName = prefs.getString('child_name') ?? '';
    _avatar = prefs.getString('avatar') ?? '🐻';
    _birthDate = prefs.getString('birth_date') ?? '';
    _height = prefs.getString('child_height') ?? '';
    _weight = prefs.getString('child_weight') ?? '';
    _caregiverName = prefs.getString('caregiver_name') ?? '';
    _caregiverRole = prefs.getString('caregiver_role') ?? 'Anne';
    _streak = prefs.getInt('streak') ?? 0;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _dailyGoal = prefs.getInt('daily_goal') ?? 10;
    _buttonSize = prefs.getInt('button_size') ?? 1;
    _themeIndex = prefs.getInt('theme_index') ?? 0;
    _parentPin = prefs.getString('parent_pin') ?? '';
    _scanModeEnabled = prefs.getBool('scan_mode') ?? false;
    _scanSpeedMs = prefs.getInt('scan_speed') ?? 1500;
    _holdDurationMs = prefs.getInt('hold_duration') ?? 0;
    _totalPresses = prefs.getInt('total_presses') ?? 0;
    _totalDays = prefs.getInt('total_days') ?? 0;
    _learningScore = prefs.getInt('learning_score') ?? 0;
    _learningTotal = prefs.getInt('learning_total') ?? 0;

    // Özel Kartlar
    final customJsonList = prefs.getStringList('custom_items_v1') ?? [];
    _customItems.clear();
    for (final raw in customJsonList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _customItems.add(MakatonItem.fromJson(map));
      } catch (e) {
        debugPrint('Özel kart yükleme hatası: $e');
      }
    }
    try {
      final dbCards = await AppDatabaseService().getCustomCards();
      for (final card in dbCards) {
        if (!_customItems.any((c) => c.id == card.id)) {
          _customItems.add(card);
        }
      }
    } catch (_) {}

    // Sembol geçmişi
    final historyKeys = prefs.getStringList('press_history_keys') ?? [];
    _itemPressHistory = {};
    for (final key in historyKeys) {
      _itemPressHistory[key] = prefs.getInt('press_hist_$key') ?? 0;
    }

    // Haftalık veriler
    _weeklyPresses = {};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final key = _dayKey(d);
      _weeklyPresses[key] = prefs.getInt('presses_$key') ?? 0;
    }

    // Favoriler
    _favorites.clear();
    _favorites.addAll(prefs.getStringList('favorites') ?? []);

    // Duygu geçmişi
    _todayEmotion = prefs.getString('today_emotion') ?? '';
    final emotionDates = prefs.getStringList('emotion_dates') ?? [];
    _emotionHistory = {};
    for (final date in emotionDates) {
      _emotionHistory[date] = prefs.getString('emotion_$date') ?? '';
    }

    // Günlük basımlar
    final today = _todayKey();
    final todayIds = prefs.getStringList('press_ids_$today') ?? [];
    _todaySteps.clear();
    for (final id in todayIds) {
      _todaySteps.add(ProgressStep(itemId: id));
    }

    // Rutinler
    initDefaultRoutines();
    final completedIds = prefs.getStringList('routines_done_$today') ?? [];
    for (final r in _routines.values) {
      r.completed = completedIds.contains(r.id);
    }

    _checkStreak(prefs);
    _initSyncListener();
    ParentChildSyncService().initialize();
    notifyListeners();
  }

  void _initSyncListener() {
    _syncSub?.cancel();
    _syncSub = ParentChildSyncService().eventStream.listen((event) {
      if (event.type == SyncEventType.remoteCheer) {
        _mascotHappy = true;
        notifyListeners();
        Future.delayed(const Duration(seconds: 4), () {
          _mascotHappy = false;
          notifyListeners();
        });
      } else if (event.type == SyncEventType.remoteCardPush) {
        try {
          final item = MakatonItem.fromJson(event.data);
          if (!_customItems.any((c) => c.id == item.id)) {
            addCustomItem(item);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> saveProfile(String name, String avatar) async {
    _childName = name;
    _avatar = avatar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_name', name);
    await prefs.setString('avatar', avatar);
    notifyListeners();
  }

  Future<void> saveFullProfile({
    required String name,
    required String avatar,
    required String birthDate,
    required String height,
    required String weight,
    required String caregiverName,
    required String caregiverRole,
  }) async {
    _childName = name;
    _avatar = avatar;
    _birthDate = birthDate;
    _height = height;
    _weight = weight;
    _caregiverName = caregiverName;
    _caregiverRole = caregiverRole;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_name', name);
    await prefs.setString('avatar', avatar);
    await prefs.setString('birth_date', birthDate);
    await prefs.setString('child_height', height);
    await prefs.setString('child_weight', weight);
    await prefs.setString('caregiver_name', caregiverName);
    await prefs.setString('caregiver_role', caregiverRole);
    notifyListeners();
  }

  Future<void> saveSettings({
    required bool soundEnabled,
    required bool vibrationEnabled,
    required int dailyGoal,
    required int buttonSize,
    required int themeIndex,
  }) async {
    _soundEnabled = soundEnabled;
    _vibrationEnabled = vibrationEnabled;
    _dailyGoal = dailyGoal;
    _buttonSize = buttonSize;
    _themeIndex = themeIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', soundEnabled);
    await prefs.setBool('vibration_enabled', vibrationEnabled);
    await prefs.setInt('daily_goal', dailyGoal);
    await prefs.setInt('button_size', buttonSize);
    await prefs.setInt('theme_index', themeIndex);
    notifyListeners();
  }

  Future<void> setParentPin(String pin) async {
    _parentPin = pin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_pin', pin);
    notifyListeners();
  }

  Future<void> recordPress(String itemId) async {
    _todaySteps.add(ProgressStep(itemId: itemId));
    _totalPresses++;
    _itemPressHistory[itemId] = (_itemPressHistory[itemId] ?? 0) + 1;

    // Ebeveyn paneline anlık konuşma sinyali ilet
    final foundList = allItems.where((i) => i.id == itemId);
    if (foundList.isNotEmpty) {
      final foundItem = foundList.first;
      ParentChildSyncService().dispatchSpeechEvent(
        childName: _childName.isNotEmpty ? _childName : 'Öğrenci',
        words: [foundItem.label],
        emoji: foundItem.emoji,
      );
    }

    _mascotHappy = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _mascotHappy = false;
      notifyListeners();
    });

    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    await prefs.setInt('presses_$today', _todaySteps.length);
    await prefs.setStringList('press_ids_$today', _todaySteps.map((s) => s.itemId).toList());
    await prefs.setInt('total_presses', _totalPresses);
    await prefs.setStringList('press_history_keys', _itemPressHistory.keys.toList());
    for (final entry in _itemPressHistory.entries) {
      await prefs.setInt('press_hist_${entry.key}', entry.value);
    }
    if (_todaySteps.length == 1) {
      _totalDays++;
      await prefs.setInt('total_days', _totalDays);
      await _updateStreak(prefs);
    }
    notifyListeners();
  }

  void _checkStreak(SharedPreferences prefs) {
    final lastDate = prefs.getString('last_active_date') ?? '';
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final today = _todayKey();
    if (lastDate == today) {
    } else if (lastDate == yesterday) {
    } else if (lastDate.isNotEmpty) {
      _streak = 0;
      prefs.setInt('streak', 0);
    }
  }

  Future<void> _updateStreak(SharedPreferences prefs) async {
    final lastDate = prefs.getString('last_active_date') ?? '';
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final today = _todayKey();
    if (lastDate == yesterday || lastDate.isEmpty) {
      _streak++;
    } else if (lastDate != today) {
      _streak = 1;
    }
    await prefs.setInt('streak', _streak);
    await prefs.setString('last_active_date', today);
    notifyListeners();
  }

  String _todayKey() => _dayKey(DateTime.now());
  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─── Veri Yedekleme & Geri Yükleme (JSON) ─────────────────
  String exportBackupJson() {
    final map = {
      'app': 'ozel_app',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': {
        'childName': _childName,
        'avatar': _avatar,
        'birthDate': _birthDate,
        'height': _height,
        'weight': _weight,
        'caregiverName': _caregiverName,
        'caregiverRole': _caregiverRole,
      },
      'settings': {
        'soundEnabled': _soundEnabled,
        'vibrationEnabled': _vibrationEnabled,
        'dailyGoal': _dailyGoal,
        'buttonSize': _buttonSize,
        'themeIndex': _themeIndex,
        'scanModeEnabled': _scanModeEnabled,
        'scanSpeedMs': _scanSpeedMs,
        'holdDurationMs': _holdDurationMs,
      },
      'stats': {
        'totalPresses': _totalPresses,
        'streak': _streak,
        'totalDays': _totalDays,
        'itemPressHistory': _itemPressHistory,
        'favorites': _favorites.toList(),
      },
      'customCards': _customItems.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<void> _saveCustomItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customItems.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('custom_items_v1', jsonList);
  }

  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return false;

      final prefs = await SharedPreferences.getInstance();

      // Profil
      if (decoded['profile'] is Map) {
        final p = decoded['profile'] as Map;
        _childName = p['childName'] as String? ?? _childName;
        _avatar = p['avatar'] as String? ?? _avatar;
        _birthDate = p['birthDate'] as String? ?? _birthDate;
        _height = p['height'] as String? ?? _height;
        _weight = p['weight'] as String? ?? _weight;
        _caregiverName = p['caregiverName'] as String? ?? _caregiverName;
        _caregiverRole = p['caregiverRole'] as String? ?? _caregiverRole;

        await prefs.setString('child_name', _childName);
        await prefs.setString('avatar', _avatar);
        await prefs.setString('birth_date', _birthDate);
        await prefs.setString('height', _height);
        await prefs.setString('weight', _weight);
        await prefs.setString('caregiver_name', _caregiverName);
        await prefs.setString('caregiver_role', _caregiverRole);
      }

      // Ayarlar
      if (decoded['settings'] is Map) {
        final s = decoded['settings'] as Map;
        _soundEnabled = s['soundEnabled'] as bool? ?? _soundEnabled;
        _vibrationEnabled = s['vibrationEnabled'] as bool? ?? _vibrationEnabled;
        _dailyGoal = s['dailyGoal'] as int? ?? _dailyGoal;
        _buttonSize = s['buttonSize'] as int? ?? _buttonSize;
        _themeIndex = s['themeIndex'] as int? ?? _themeIndex;
        _scanModeEnabled = s['scanModeEnabled'] as bool? ?? _scanModeEnabled;
        _scanSpeedMs = s['scanSpeedMs'] as int? ?? _scanSpeedMs;
        _holdDurationMs = s['holdDurationMs'] as int? ?? _holdDurationMs;

        await prefs.setBool('sound_enabled', _soundEnabled);
        await prefs.setBool('vibration_enabled', _vibrationEnabled);
        await prefs.setInt('daily_goal', _dailyGoal);
        await prefs.setInt('button_size', _buttonSize);
        await prefs.setInt('theme_index', _themeIndex);
        await prefs.setBool('scan_mode', _scanModeEnabled);
        await prefs.setInt('scan_speed', _scanSpeedMs);
        await prefs.setInt('hold_duration', _holdDurationMs);
      }

      // İstatistikler
      if (decoded['stats'] is Map) {
        final st = decoded['stats'] as Map;
        _totalPresses = st['totalPresses'] as int? ?? _totalPresses;
        _streak = st['streak'] as int? ?? _streak;
        _totalDays = st['totalDays'] as int? ?? _totalDays;

        await prefs.setInt('total_presses', _totalPresses);
        await prefs.setInt('streak', _streak);
        await prefs.setInt('total_days', _totalDays);

        if (st['favorites'] is List) {
          _favorites.clear();
          _favorites.addAll((st['favorites'] as List).map((e) => e.toString()));
          await prefs.setStringList('favorites', _favorites.toList());
        }
      }

      // Özel Kartlar
      if (decoded['customCards'] is List) {
        _customItems.clear();
        for (final itemJson in decoded['customCards'] as List) {
          if (itemJson is Map<String, dynamic>) {
            _customItems.add(MakatonItem.fromJson(itemJson));
          } else if (itemJson is Map) {
            _customItems.add(MakatonItem.fromJson(Map<String, dynamic>.from(itemJson)));
          }
        }
        await _saveCustomItems();
      }

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ProgressStep {
  final String itemId;
  final DateTime timestamp;
  ProgressStep({required this.itemId}) : timestamp = DateTime.now();
}

class Badge {
  final String id;
  final String title;
  final String icon;
  final String desc;
  const Badge({required this.id, required this.title, required this.icon, required this.desc});
}

class RoutineItem {
  final String id;
  final String title;
  final String period;
  final String time;
  bool completed;
  RoutineItem({
    required this.id,
    required this.title,
    required this.period,
    required this.time,
    this.completed = false,
  });
}
