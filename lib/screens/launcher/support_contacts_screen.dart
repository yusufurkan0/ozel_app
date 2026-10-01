import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Kullanıcı desteği: Kişiler SharedPreferences 'user_support_contacts' altında saklanır.
  // Rol tipleri: 'Aile', 'İş Koçu', 'Öğretmen', 'Arkadaş'
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

  Future<void> _contactAction(Map<String, dynamic> c) async {
    final name = c['name'] ?? 'Destek Kişisi';
    final role = (c['role'] ?? 'Aile').toString().toLowerCase();
    final phone = (c['phone'] ?? '').toString().replaceAll(' ', '');

    if (role.contains('koç') || role.contains('koc') || role.contains('iş koçu')) {
      // İş Koçu -> WhatsApp Mesajı
      _speak('$name iş koçuna WhatsApp mesajı gönderiliyor.');
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      final formattedPhone = cleanPhone.startsWith('0') ? '9$cleanPhone' : (cleanPhone.startsWith('90') ? cleanPhone : '90$cleanPhone');
      final uri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent('Merhaba $name, uygulamada yardıma ihtiyacım var.')}');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnack('$name kişisine WhatsApp mesajı açılamadı ($phone)');
        }
      } catch (_) {
        _showSnack('$name kişisine WhatsApp mesajı açılamadı.');
      }
    } else {
      // Aile veya diğer -> Telefon Araması
      _speak('$name aranıyor. Telefon numarası: $phone');
      final uri = Uri.parse('tel:$phone');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showSnack('$name ($phone) aranıyor...');
        }
      } catch (_) {
        _showSnack('$name aranıyor...');
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.buttonIndigo,
        behavior: SnackBarBehavior.floating,
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
    final phoneCtrl = TextEditingController();
    String selectedRole = 'Aile'; // 'Aile', 'İş Koçu', 'Öğretmen', 'Diğer'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded, color: AppColors.buttonIndigo),
              SizedBox(width: 8),
              Text('Destek Kişisi Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kişinin Rolü / Görevi:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('👨‍👩‍👧 Aile (Telefon)'),
                      selected: selectedRole == 'Aile',
                      selectedColor: const Color(0xFFE0E7FF),
                      onSelected: (val) => setModalState(() => selectedRole = 'Aile'),
                    ),
                    ChoiceChip(
                      label: const Text('💼 İş Koçu (WhatsApp)'),
                      selected: selectedRole == 'İş Koçu',
                      selectedColor: const Color(0xFFDCFCE7),
                      onSelected: (val) => setModalState(() => selectedRole = 'İş Koçu'),
                    ),
                    ChoiceChip(
                      label: const Text('🧑‍🏫 Öğretmen'),
                      selected: selectedRole == 'Öğretmen',
                      selectedColor: const Color(0xFFFEF3C7),
                      onSelected: (val) => setModalState(() => selectedRole = 'Öğretmen'),
                    ),
                    ChoiceChip(
                      label: const Text('🌟 Diğer'),
                      selected: selectedRole == 'Diğer',
                      selectedColor: const Color(0xFFF1F5F9),
                      onSelected: (val) => setModalState(() => selectedRole = 'Diğer'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Adı Soyadı',
                    hintText: 'Örn: Annem, Ahmet Koç',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Telefon Numarası',
                    hintText: '05xx xxx xx xx',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selectedRole == 'İş Koçu' ? const Color(0xFFF0FDF4) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedRole == 'İş Koçu' ? Icons.chat_rounded : Icons.phone_forwarded_rounded,
                        color: selectedRole == 'İş Koçu' ? const Color(0xFF16A34A) : AppColors.buttonIndigo,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedRole == 'İş Koçu'
                              ? 'Yardım istendiğinde İş Koçuna WhatsApp mesajı gönderilir.'
                              : 'Yardım istendiğinde bu numara doğrudan aranır.',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedRole == 'İş Koçu' ? const Color(0xFF166534) : const Color(0xFF3730A3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  setState(() {
                    _contacts.add({
                      'name': name,
                      'role': selectedRole,
                      'phone': phone,
                      'avatar': selectedRole == 'İş Koçu' ? '💼' : (selectedRole == 'Aile' ? '👨‍👩‍👧' : '🤝'),
                      'isJobCoach': selectedRole == 'İş Koçu',
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contact_phone_rounded, color: AppColors.buttonIndigo),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Destek Kişilerim',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.buttonIndigo),
            tooltip: 'Yeni Destek Kişisi Ekle',
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
                          child: const Icon(Icons.support_agent_rounded, size: 40, color: AppColors.buttonIndigo),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Destek Kişisi Bulunmuyor',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Zorlandığında veya yardıma ihtiyaç duyduğunda sana destek olacak Aileni ve İş Koçunu ekle.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.person_add_rounded),
                          label: const Text('Destek Kişisi Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    final isJobCoach = (c['role'] ?? '').toString().toLowerCase().contains('koç') ||
                        (c['role'] ?? '').toString().toLowerCase().contains('koc') ||
                        c['isJobCoach'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isJobCoach ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  c['avatar'] ?? (isJobCoach ? '💼' : '👨‍👩‍👧'),
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isJobCoach ? const Color(0xFF22C55E).withValues(alpha: 0.15) : const Color(0xFF6366F1).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isJobCoach ? '💼 İş Koçu (WhatsApp)' : '👨‍👩‍👧 ${c['role'] ?? 'Aile'} (Arama)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isJobCoach ? const Color(0xFF15803D) : const Color(0xFF4338CA),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c['phone'] ?? '',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isJobCoach ? Icons.chat_rounded : Icons.phone_rounded,
                                color: isJobCoach ? const Color(0xFF16A34A) : AppColors.buttonIndigo,
                                size: 28,
                              ),
                              tooltip: isJobCoach ? 'WhatsApp Mesajı At' : 'Telefonla Ara',
                              onPressed: () => _contactAction(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                              tooltip: 'Sil',
                              onPressed: () => _deleteContact(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
