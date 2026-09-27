import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class SupportContactsScreen extends StatefulWidget {
  const SupportContactsScreen({super.key});

  @override
  State<SupportContactsScreen> createState() => _SupportContactsScreenState();
}

class _SupportContactsScreenState extends State<SupportContactsScreen> {
  final FlutterTts _tts = FlutterTts();
  SharedPreferences? _prefs;
  bool _isLoading = true;

  // Kullanıcı isteği: Kesinlikle otomatik/sahte kişi eklenmez, tamamen boş başlar.
  final List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedStr = _prefs?.getString('user_support_contacts');
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr) as List;
        _contacts.clear();
        for (final item in decoded) {
          _contacts.add(Map<String, dynamic>.from(item as Map));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveContacts() async {
    try {
      final encoded = jsonEncode(_contacts);
      await _prefs?.setString('user_support_contacts', encoded);
    } catch (_) {}
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

  void _callContact(Map<String, dynamic> c) {
    _speak('${c['name']} aranıyor. Telefon: ${c['phone']}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${c['name']} (${c['phone']}) aranıyor...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteContact(int index) async {
    final removed = _contacts[index]['name'];
    setState(() {
      _contacts.removeAt(index);
    });
    await _saveContacts();
    _speak('$removed rehberden silindi.');
  }

  void _addContactDialog() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Yeni Destek Kişisi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Adı Soyadı (Örn: Annem, Babam, Öğretmenim)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(
                hintText: 'Yakınlığı (Örn: Aile, Öğretmen, Doktor)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Telefon Numarası (Örn: 05xx xxx xx xx)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonIndigo, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              final role = roleCtrl.text.trim().isEmpty ? 'Destek Kişim' : roleCtrl.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty) {
                setState(() {
                  _contacts.add({
                    'name': name,
                    'role': role,
                    'phone': phone,
                    'avatar': '🤝',
                    'colorValue': Colors.indigo.toARGB32(),
                  });
                });
                await _saveContacts();
                _speak('$name rehbere eklendi.');
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.contact_phone_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Destek Kişilerim', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.buttonIndigo),
            tooltip: 'Yeni Kişi Ekle',
            onPressed: _addContactDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.contacts_rounded, size: 40, color: Colors.indigo),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Rehberiniz Henüz Boş',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ailenizi veya destek aldığınız kişileri eklemek için aşağıdaki butona dokunun.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.person_add_rounded, size: 20),
                          label: const Text('Yeni Kişi Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _addContactDialog,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final c = _contacts[index];
                    final color = Colors.indigo;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F172A),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(c['avatar'] as String? ?? '🤝', style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Bilgiler
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(c['role'] as String? ?? '', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(c['phone'] as String? ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          // Sil Butonu
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                            tooltip: 'Sil',
                            onPressed: () => _deleteContact(index),
                          ),
                          const SizedBox(width: 4),
                          // Ara Butonu
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                              elevation: 2,
                            ),
                            onPressed: () => _callContact(c),
                            child: const Icon(Icons.phone_rounded, size: 22),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

