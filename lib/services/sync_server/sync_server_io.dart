import 'dart:convert';
import 'dart:io';

/// Windows, macOS, Linux, Android ve iOS için gerçek yerel ağ HTTP sunucusu.
class LocalSyncServer {
  HttpServer? _server;

  Future<void> start({
    required int port,
    required String familyCode,
    required String currentRole,
    required Function(Map<String, dynamic>) onEventReceived,
    List<Map<String, dynamic>> Function()? getRecentEvents,
  }) async {
    try {
      await stop();
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);

      _server?.listen((HttpRequest request) async {
        // CORS başlıkları (tarayıcıdan veya diğer cihazlardan erişim için)
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = 200;
          await request.response.close();
          return;
        }

        if (request.uri.path == '/api/events' && request.method == 'GET') {
          final events = getRecentEvents?.call() ?? [];
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'events': events}));
          await request.response.close();
        } else if (request.uri.path == '/api/sync' && request.method == 'POST') {
          final content = await utf8.decoder.bind(request).join();
          try {
            final json = jsonDecode(content) as Map<String, dynamic>;
            onEventReceived(json);

            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'status': 'ok'}));
          } catch (_) {
            request.response
              ..statusCode = 400
              ..write('Invalid JSON payload');
          }
          await request.response.close();
        } else if (request.uri.path == '/api/ping') {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'status': 'alive',
              'role': currentRole,
              'familyCode': familyCode,
            }));
          await request.response.close();
        } else {
          request.response
            ..statusCode = 404
            ..write('Not Found');
          await request.response.close();
        }
      });
    } catch (_) {
      // Port kullanımda ise veya ağ izin vermiyorsa sessizce devam eder
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      try {
        await _server?.close(force: true);
      } catch (_) {}
      _server = null;
    }
  }
}
