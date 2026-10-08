import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_server/sync_server.dart';
import 'database/app_database_service.dart';

/// Cihaz Rolü: Çocuk Terminali, Ebeveyn Refakatçi Paneli veya Bağımsız Mod.
enum DeviceRole {
  /// Çocuk İletişim Terminali (Sadece AAC, rutin ve SOS odaklı, kilitli alan)
  childTerminal,

  /// Ebeveyn / Terapist Refakatçi Paneli (Canlı izleme, uzaktan yönetim, raporlar)
  parentCompanion,

  /// Tek Cihaz / Klasik Mod (İki rolü tek cihazda birleştiren hibrit mod)
  standalone;

  String get displayName {
    switch (this) {
      case DeviceRole.childTerminal:
        return 'Çocuk İletişim Terminali';
      case DeviceRole.parentCompanion:
        return 'Ebeveyn Refakatçi Paneli';
      case DeviceRole.standalone:
        return 'Tek Cihaz (Klasik Mod)';
    }
  }

  String get shortCode {
    switch (this) {
      case DeviceRole.childTerminal:
        return 'child';
      case DeviceRole.parentCompanion:
        return 'parent';
      case DeviceRole.standalone:
        return 'standalone';
    }
  }

  static DeviceRole fromString(String? val) {
    if (val == 'child' || val == 'childTerminal') return DeviceRole.childTerminal;
    if (val == 'parent' || val == 'parentCompanion') return DeviceRole.parentCompanion;
    return DeviceRole.standalone;
  }
}

/// Senkronize edilen olay türleri.
enum SyncEventType {
  speech,
  sos,
  emotion,
  routineCompleted,
  remoteCardPush,
  remoteCheer,
  ping,
  connectionStatus;

  static SyncEventType fromString(String val) {
    return SyncEventType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SyncEventType.ping,
    );
  }
}

/// İki cihaz arasında taşınan canlı olay paketi.
class SyncEvent {
  final String id;
  final SyncEventType type;
  final DateTime timestamp;
  final String childName;
  final Map<String, dynamic> data;
  final String displayMessage;

  SyncEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.childName,
    required this.data,
    required this.displayMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'childName': childName,
        'data': data,
        'displayMessage': displayMessage,
      };

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: SyncEventType.fromString(json['type'] as String? ?? 'ping'),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      childName: json['childName'] as String? ?? 'Öğrenci',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      displayMessage: json['displayMessage'] as String? ?? '',
    );
  }

  /// Konuşma olayı oluşturucu
  factory SyncEvent.speech({
    required String childName,
    required List<String> words,
    String? emoji,
    String? fullSentence,
  }) {
    final text = fullSentence ?? words.join(' ');
    final em = emoji ?? '🗣️';
    return SyncEvent(
      id: 'sp_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncEventType.speech,
      timestamp: DateTime.now(),
      childName: childName,
      data: {
        'words': words,
        'emoji': em,
        'fullSentence': text,
      },
      displayMessage: '$em "$text"',
    );
  }

  /// Acil SOS olayı oluşturucu
  factory SyncEvent.sos({
    required String childName,
    String? emergencyNote,
    String? caregiverPhone,
  }) {
    return SyncEvent(
      id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncEventType.sos,
      timestamp: DateTime.now(),
      childName: childName,
      data: {
        'emergencyNote': emergencyNote ?? 'Acil Durum Bildirimi',
        'caregiverPhone': caregiverPhone ?? '',
      },
      displayMessage: '🚨 ACİL DURUM (SOS) ÇAĞRISI!',
    );
  }

  /// Duygu seçimi olayı oluşturucu
  factory SyncEvent.emotion({
    required String childName,
    required String emoji,
    required String emotionTitle,
  }) {
    return SyncEvent(
      id: 'em_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncEventType.emotion,
      timestamp: DateTime.now(),
      childName: childName,
      data: {
        'emoji': emoji,
        'emotionTitle': emotionTitle,
      },
      displayMessage: 'Bugünkü Duygu: $emoji $emotionTitle',
    );
  }

  /// Rutin tamamlama olayı oluşturucu
  factory SyncEvent.routineCompleted({
    required String childName,
    required String stepId,
    required String stepTitle,
    required String emoji,
  }) {
    return SyncEvent(
      id: 'rt_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncEventType.routineCompleted,
      timestamp: DateTime.now(),
      childName: childName,
      data: {
        'stepId': stepId,
        'stepTitle': stepTitle,
        'emoji': emoji,
      },
      displayMessage: 'Görev Tamamlandı: $emoji $stepTitle ✅',
    );
  }

  /// Ebeveynden uzaktan tebrik/övgü gönderme
  factory SyncEvent.cheer({
    required String childName,
    required String cheerType,
    required String cheerMessage,
    String emoji = '🌟',
  }) {
    return SyncEvent(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncEventType.remoteCheer,
      timestamp: DateTime.now(),
      childName: childName,
      data: {
        'cheerType': cheerType,
        'cheerMessage': cheerMessage,
        'emoji': emoji,
      },
      displayMessage: '$emoji $cheerMessage',
    );
  }

  /// Ebeveynden uzaktan özel kart yollama
  factory SyncEvent.remoteCard({
    required String childName,
    required Map<String, dynamic> cardData,
  }) {
    return SyncEvent(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncEventType.remoteCardPush,
      timestamp: DateTime.now(),
      childName: childName,
      data: cardData,
      displayMessage: 'Yeni Kart Eklendi: ${cardData['label'] ?? "Özel Kart"}',
    );
  }
}

/// 🔗 Çocuk ve Ebeveyn Cihazları Arası Canlı Senkronizasyon Servisi
class ParentChildSyncService extends ChangeNotifier {
  static final ParentChildSyncService _instance = ParentChildSyncService._internal();
  factory ParentChildSyncService() => _instance;
  ParentChildSyncService._internal();

  static const String _prefRoleKey = 'app_device_role';
  static const String _prefFamilyCodeKey = 'app_family_sync_code';
  static const String _prefPairedHostKey = 'app_paired_host_ip';

  DeviceRole _currentRole = DeviceRole.standalone;
  String _familyCode = '';
  String _pairedHostIp = '127.0.0.1';
  bool _isConnected = false;
  final int _localPort = 8088;

  final List<SyncEvent> _recentEvents = [];
  final StreamController<SyncEvent> _eventStreamController = StreamController<SyncEvent>.broadcast();

  // Getters
  DeviceRole get currentRole => _currentRole;
  String get familyCode => _familyCode;
  String get pairedHostIp => _pairedHostIp;
  bool get isConnected => _isConnected;
  int get localPort => _localPort;
  List<SyncEvent> get recentEvents => List.unmodifiable(_recentEvents);
  Stream<SyncEvent> get eventStream => _eventStreamController.stream;

  bool get isChildTerminal => _currentRole == DeviceRole.childTerminal;
  bool get isParentCompanion => _currentRole == DeviceRole.parentCompanion;
  bool get isStandalone => _currentRole == DeviceRole.standalone;

  final LocalSyncServer _syncServer = LocalSyncServer();

  /// Servisi başlat ve ayarları yükle
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString(_prefRoleKey);
    _currentRole = DeviceRole.fromString(savedRole);

    _familyCode = prefs.getString(_prefFamilyCodeKey) ?? '';
    if (_familyCode.isEmpty) {
      _familyCode = _generateFamilyCode();
      await prefs.setString(_prefFamilyCodeKey, _familyCode);
    }

    _pairedHostIp = prefs.getString(_prefPairedHostKey) ?? '127.0.0.1';

    // Yerel ağ sunucusunu Windows ve masaüstünde her zaman başlat (dinleyici olarak)
    if (!kIsWeb) {
      await _startLocalServer();
    } else {
      _isConnected = true; // Web ortamı
      // Tarayıcıdaki pencereler/sekmeler arasında anlık canlı senkronizasyon
      Timer.periodic(const Duration(milliseconds: 800), (_) async {
        final p = await SharedPreferences.getInstance();
        final raw = p.getString('web_cross_tab_sync_event_v1');
        if (raw != null && raw.isNotEmpty) {
          try {
            final json = jsonDecode(raw) as Map<String, dynamic>;
            final event = SyncEvent.fromJson(json);
            if (!_recentEvents.any((e) => e.id == event.id)) {
              _broadcastLocalEvent(event, isRemote: true);
            }
          } catch (_) {}
        }
      });
    }

    // Web veya ebeveyn panelinde masaüstü sunucusundan olayları çekmek için periyodik polling
    Timer.periodic(const Duration(milliseconds: 3000), (_) async {
      await fetchRemoteEvents();
    });

    notifyListeners();
  }

  /// 6 Haneli Kolay Aile Kodu Üretir (Örn: OZEL-8421)
  String _generateFamilyCode() {
    final rand = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000));
    return 'OZEL-$rand';
  }

  /// Cihaz Rolünü Değiştir ve Kaydet
  Future<void> setDeviceRole(DeviceRole role) async {
    _currentRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRoleKey, role.shortCode);

    if (!kIsWeb) {
      await _startLocalServer();
    }

    _isConnected = true;
    notifyListeners();
  }

  /// Aile Kodunu Güncelle
  Future<void> setFamilyCode(String code) async {
    _familyCode = code.trim().toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefFamilyCodeKey, _familyCode);
    notifyListeners();
  }

  /// Ebeveyn: Çocuk Cihazına Bağlan
  Future<bool> connectToChildTerminal(String hostIp, String code) async {
    _pairedHostIp = hostIp.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPairedHostKey, _pairedHostIp);
    await setFamilyCode(code);

    _isConnected = true;
    _broadcastLocalEvent(
      SyncEvent(
        id: 'conn_${DateTime.now().millisecondsSinceEpoch}',
        type: SyncEventType.connectionStatus,
        timestamp: DateTime.now(),
        childName: 'Sistem',
        data: {'status': 'connected', 'ip': _pairedHostIp},
        displayMessage: '🟢 Çocuk Cihazı ile Canlı Bağlantı Kuruldu!',
      ),
    );

    notifyListeners();
    return true;
  }

  /// Çocuk: Konuşulan cümleyi veya basılan kartı ebeveyne fısılda
  void dispatchSpeechEvent({
    required String childName,
    required List<String> words,
    String? emoji,
    String? fullSentence,
  }) {
    final event = SyncEvent.speech(
      childName: childName,
      words: words,
      emoji: emoji,
      fullSentence: fullSentence,
    );
    _broadcastLocalEvent(event);
  }

  /// Çocuk: Acil Durum (SOS) çağrısını ebeveyne fısılda
  void dispatchSosEvent({
    required String childName,
    String? emergencyNote,
    String? caregiverPhone,
  }) {
    final event = SyncEvent.sos(
      childName: childName,
      emergencyNote: emergencyNote,
      caregiverPhone: caregiverPhone,
    );
    _broadcastLocalEvent(event);
  }

  /// Çocuk: Seçilen duyguyu ebeveyne ilet
  void dispatchEmotionEvent({
    required String childName,
    required String emoji,
    required String emotionTitle,
  }) {
    final event = SyncEvent.emotion(
      childName: childName,
      emoji: emoji,
      emotionTitle: emotionTitle,
    );
    _broadcastLocalEvent(event);
  }

  /// Çocuk: Tamamlanan rutini ebeveyne ilet
  void dispatchRoutineCompleted({
    required String childName,
    required String stepId,
    required String stepTitle,
    required String emoji,
  }) {
    final event = SyncEvent.routineCompleted(
      childName: childName,
      stepId: stepId,
      stepTitle: stepTitle,
      emoji: emoji,
    );
    _broadcastLocalEvent(event);
  }

  /// Ebeveyn: Çocuğa uzaktan tebrik / moral gönder
  void sendRemoteCheer({
    required String childName,
    required String cheerType,
    required String cheerMessage,
    String emoji = '🌟',
  }) {
    final event = SyncEvent.cheer(
      childName: childName,
      cheerType: cheerType,
      cheerMessage: cheerMessage,
      emoji: emoji,
    );
    _broadcastLocalEvent(event);
  }

  /// Ebeveyn: Çocuğun tabletine uzaktan özel kart yolla
  void sendRemoteCard({
    required String childName,
    required Map<String, dynamic> cardData,
  }) {
    final event = SyncEvent.remoteCard(
      childName: childName,
      cardData: cardData,
    );
    _broadcastLocalEvent(event);
  }

  /// Olayı hem yerel yayın akışına ekle hem de geçmiş listesinde tut
  void _broadcastLocalEvent(SyncEvent event, {bool isRemote = false}) {
    _recentEvents.insert(0, event);
    if (_recentEvents.length > 50) {
      _recentEvents.removeLast();
    }
    if (event.type == SyncEventType.speech) {
      AppDatabaseService().logSpeech(event);
    }
    _eventStreamController.add(event);
    notifyListeners();

    if (!isRemote) {
      if (kIsWeb) {
        SharedPreferences.getInstance().then((p) {
          p.setString('web_cross_tab_sync_event_v1', jsonEncode(event.toJson()));
        });
      }
      _sendToRemoteTarget(event);
    }
  }

  /// Olayı ağdaki diğer cihaza / aynı bilgisayardaki Windows/Chrome hedefine yolla
  Future<void> _sendToRemoteTarget(SyncEvent event) async {
    final targets = <String>{};
    targets.add('http://127.0.0.1:$_localPort/api/sync');
    if (_pairedHostIp.isNotEmpty && _pairedHostIp != '127.0.0.1') {
      targets.add('http://$_pairedHostIp:$_localPort/api/sync');
    }

    final body = jsonEncode(event.toJson());
    for (final target in targets) {
      try {
        await http
            .post(
              Uri.parse(target),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(milliseconds: 1500));
      } catch (_) {
        // Hedef o an açık değilse veya tek cihazdaysa sessizce yoksay
      }
    }
  }

  /// Uzak cihazdan (veya aynı bilgisayardaki Windows sunucusundan) son olayları çek
  Future<void> fetchRemoteEvents() async {
    // Çevrimdışı ve tekli (standalone) modda gereksiz ağ/soket sorgusu yapma
    if (_currentRole == DeviceRole.standalone || _pairedHostIp.isEmpty || _pairedHostIp == '127.0.0.1') {
      return;
    }
    final targets = <String>{};
    targets.add('http://127.0.0.1:$_localPort/api/events');
    if (_pairedHostIp.isNotEmpty && _pairedHostIp != '127.0.0.1') {
      targets.add('http://$_pairedHostIp:$_localPort/api/events');
    }

    for (final url in targets) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(milliseconds: 1200));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final eventsJson = data['events'] as List<dynamic>? ?? [];
          for (final ej in eventsJson.reversed) {
            try {
              final ev = SyncEvent.fromJson(Map<String, dynamic>.from(ej as Map));
              if (!_recentEvents.any((e) => e.id == ev.id)) {
                _broadcastLocalEvent(ev, isRemote: true);
              }
            } catch (_) {}
          }
          if (!_isConnected) {
            _isConnected = true;
            notifyListeners();
          }
        }
      } catch (_) {
        // Hedef o an kapalıysa sessizce devam
      }
    }
  }

  /// Yerel HTTP/WebSocket sunucusunu başlat (Cihazlar arası aynı ağ iletişimi)
  Future<void> _startLocalServer() async {
    await _syncServer.start(
      port: _localPort,
      familyCode: _familyCode,
      currentRole: _currentRole.shortCode,
      onEventReceived: (json) {
        final event = SyncEvent.fromJson(json);
        _broadcastLocalEvent(event, isRemote: true);
      },
      getRecentEvents: () => _recentEvents.map((e) => e.toJson()).toList(),
    );
    _isConnected = true;
  }

  Future<void> _stopLocalServer() async {
    await _syncServer.stop();
  }

  /// Canlı test için örnek konuşma simülasyonu
  void simulateDemoSpeech(String childName, String sentence, String emoji) {
    dispatchSpeechEvent(
      childName: childName,
      words: sentence.split(' '),
      emoji: emoji,
      fullSentence: sentence,
    );
  }

  @override
  void dispose() {
    _stopLocalServer();
    _eventStreamController.close();
    super.dispose();
  }
}
