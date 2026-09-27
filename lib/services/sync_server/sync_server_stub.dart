/// Web / Desteklenmeyen platformlar için boş (stub) yerel sunucu.
class LocalSyncServer {
  Future<void> start({
    required int port,
    required String familyCode,
    required String currentRole,
    required Function(Map<String, dynamic>) onEventReceived,
    List<Map<String, dynamic>> Function()? getRecentEvents,
  }) async {
    // Web ortamında tarayıcı güvenlik kısıtlaması gereği raw TCP HttpServer açılamaz.
    // In-memory event bus ve HTTP client kullanılır.
  }

  Future<void> stop() async {}
}
