import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// 1 Dakikalık Bekleme & Destek Kişisi Yardım Yardımcısı
/// Kullanıcı bir adımda veya ekranda 1 dakikadan uzun süre işlem yapmadığında:
/// - "Yardım ister misin?" uyarısı gösterilir ve seslendirilir.
/// - Evet denirse Destek Kişisi listesi gelir:
///   - Aileden biri seçilirse telefon araması yapar.
///   - İş koçu seçilirse WhatsApp mesajı atar.
/// - Hayır denirse kaldığı yerden devam eder.
class InactivityHelpService {
  Timer? _inactivityTimer;
  final Duration timeoutDuration;
  final FlutterTts _tts = FlutterTts();
  bool _isDialogOpen = false;

  InactivityHelpService({this.timeoutDuration = const Duration(seconds: 60)}) {
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.5);
    } catch (_) {}
  }

  void _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  void start(BuildContext context) {
    reset(context);
  }

  void reset(BuildContext context) {
    _inactivityTimer?.cancel();
    if (_isDialogOpen) return;

    _inactivityTimer = Timer(timeoutDuration, () {
      if (context.mounted && !_isDialogOpen) {
        showHelpPrompt(context);
      }
    });
  }

  void stop() {
    _inactivityTimer?.cancel();
  }

  void showHelpPrompt(BuildContext context) {
    if (!context.mounted || _isDialogOpen) return;
    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.live_help_rounded, color: AppColors.buttonIndigo, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Yardım İster Misin?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bir dakikadır burada bekliyorsun. Yardıma ihtiyacın varsa destek kişilerini arayabilir veya mesaj atabiliriz.',
              style: TextStyle(fontSize: 14.5, height: 1.4, color: Color(0xFF334155)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isDialogOpen = false;
              Navigator.pop(ctx);
              reset(context);
            },
            child: const Text('Hayır, Devam Edeceğim', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            icon: const Icon(Icons.people_rounded),
            label: const Text('Evet, Yardım İste', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              _selectSupportContact(context);
            },
          ),
        ],
      ),
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  void _selectSupportContact(BuildContext context) async {
    List<Map<String, dynamic>> contacts = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('user_support_contacts');
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr) as List;
        for (final item in decoded) {
          contacts.add(Map<String, dynamic>.from(item as Map));
        }
      }
      if (contacts.isEmpty) {
        final parentName = prefs.getString('sos_parent_name') ?? prefs.getString('user_emergency_name') ?? 'Ailem';
        final parentPhone = prefs.getString('sos_parent_phone') ?? prefs.getString('user_emergency_phone');
        if (parentPhone != null && parentPhone.isNotEmpty) {
          contacts.add({
            'name': parentName,
            'role': 'Aile',
            'phone': parentPhone,
            'avatar': '👨‍👩‍👧',
            'isJobCoach': false,
          });
        }
      }
    } catch (_) {}

    if (!context.mounted) return;

    _speak('Kimi aramak veya mesaj göndermek istersin? Destek kişini seç.');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.contact_support_rounded, color: AppColors.buttonIndigo, size: 28),
            SizedBox(width: 8),
            Text('Destek Kişini Seç', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: contacts.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Kayıtlı destek kişisi bulunamadı.\nAcil durumlarda 112\'yi arayabilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                      icon: const Icon(Icons.phone_rounded),
                      label: const Text('112 Acil Yardım Ara'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          final uri = Uri.parse('tel:112');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        } catch (_) {}
                      },
                    ),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  itemBuilder: (context, idx) {
                    final c = contacts[idx];
                    final name = c['name'] ?? 'Kişi';
                    final role = (c['role'] ?? 'Aile').toString();
                    final phone = (c['phone'] ?? '').toString();
                    final isJobCoach = role.toLowerCase().contains('koç') ||
                        role.toLowerCase().contains('koc') ||
                        c['isJobCoach'] == true;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      leading: CircleAvatar(
                        backgroundColor: isJobCoach ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                        child: Text(isJobCoach ? '💼' : '👨‍👩‍👧', style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(isJobCoach ? 'İş Koçu (WhatsApp Mesajı)' : '$role (Telefon Araması)'),
                      trailing: Icon(
                        isJobCoach ? Icons.chat_rounded : Icons.phone_rounded,
                        color: isJobCoach ? const Color(0xFF16A34A) : AppColors.buttonIndigo,
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          if (isJobCoach) {
                            _speak('$name iş koçuna WhatsApp mesajı gönderiliyor.');
                            final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
                            final formatted = clean.startsWith('0') ? '9$clean' : (clean.startsWith('90') ? clean : '90$clean');
                            final uri = Uri.parse('https://wa.me/$formatted?text=${Uri.encodeComponent('Merhaba $name, uygulamada desteğe ihtiyacım var.')}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } else {
                            _speak('$name aranıyor.');
                            final uri = Uri.parse('tel:$phone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        } catch (_) {}
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              reset(context);
            },
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
