import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';

class SelfEvaluationScreen extends StatefulWidget {
  const SelfEvaluationScreen({super.key});

  @override
  State<SelfEvaluationScreen> createState() => _SelfEvaluationScreenState();
}

class _SelfEvaluationScreenState extends State<SelfEvaluationScreen> {
  final FlutterTts _tts = FlutterTts();
  String? _selectedMood;

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Çok Mutlu', 'emoji': '😄', 'color': Colors.amber},
    {'label': 'Sakin & Huzurlu', 'emoji': '😌', 'color': Colors.green},
    {'label': 'Heyecanlı', 'emoji': '🤩', 'color': Colors.orange},
    {'label': 'Yorgun', 'emoji': '🥱', 'color': Colors.blueGrey},
    {'label': 'Biraz Üzgün', 'emoji': '🥺', 'color': Colors.blue},
    {'label': 'Kızgın / Gergin', 'emoji': '😠', 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _questions = [
    {'q': 'Bugün güzel beslendim ve suyumu içtim mi?', 'ans': null},
    {'q': 'Öğretmenimi veya ailemi dikkatle dinledim mi?', 'ans': null},
    {'q': 'Zorlandığımda kibarca yardım istedim mi?', 'ans': null},
    {'q': 'Bugün kendimle gurur duyuyor muyum?', 'ans': null},
  ];

  @override
  void initState() {
    super.initState();
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

  void _saveEvaluation() {
    _speak('Kendini değerlendirme formun kaydedildi. Sen çok değerlisin ve harika bir gün geçirdin!');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text('Harikasın! 🌟'),
          ],
        ),
        content: const Text(
          'Duygularını ve gününü bizimle paylaştığın için teşekkür ederiz. Her gün yeni bir güzelliktir!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Tamamla'),
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
            Icon(Icons.rate_review_rounded, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Kendini Değerlendirme', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Duygu Durumu Seçimi
            const Text(
              'Bugün Kendini Nasıl Hissediyorsun?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _moods.length,
              itemBuilder: (context, index) {
                final m = _moods[index];
                final isSelected = (_selectedMood == m['label']);
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMood = m['label']);
                    _speak('Bugün ${m['label']} hissediyorsun.');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? (m['color'] as Color).withValues(alpha: 0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (m['color'] as Color) : Colors.grey.shade200,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(m['emoji'] as String, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 6),
                        Text(
                          m['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? (m['color'] as Color) : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // 2. Günün Değerlendirme Soruları
            const Text(
              'Günün Soruları:',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...List.generate(_questions.length, (index) {
              final q = _questions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            q['q'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo, size: 20),
                          onPressed: () => _speak(q['q'] as String),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: q['ans'] == true ? Colors.green : Colors.grey.shade100,
                              foregroundColor: q['ans'] == true ? Colors.white : Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                            label: const Text('Evet 👍'),
                            onPressed: () {
                              setState(() => q['ans'] = true);
                              _speak('Evet.');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: q['ans'] == false ? Colors.orange : Colors.grey.shade100,
                              foregroundColor: q['ans'] == false ? Colors.white : Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.thumb_down_alt_rounded, size: 16),
                            label: const Text('Biraz 🤏'),
                            onPressed: () {
                              setState(() => q['ans'] = false);
                              _speak('Biraz.');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Değerlendirmemi Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _saveEvaluation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
