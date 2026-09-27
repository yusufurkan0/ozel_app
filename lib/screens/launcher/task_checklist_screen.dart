import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';

class TaskChecklistScreen extends StatefulWidget {
  const TaskChecklistScreen({super.key});

  @override
  State<TaskChecklistScreen> createState() => _TaskChecklistScreenState();
}

class _TaskChecklistScreenState extends State<TaskChecklistScreen> {
  final FlutterTts _tts = FlutterTts();

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Yatağımı Toplamak',
      'icon': Icons.bed_rounded,
      'color': Colors.blue,
      'completed': true,
      'points': 10,
    },
    {
      'title': 'Dişlerimi Fırçalamak',
      'icon': Icons.cleaning_services_rounded,
      'color': Colors.teal,
      'completed': true,
      'points': 10,
    },
    {
      'title': 'Ellerimi Yıkamak',
      'icon': Icons.wash_rounded,
      'color': Colors.cyan,
      'completed': false,
      'points': 10,
    },
    {
      'title': 'Ödevimi & Çalışmamı Yapmak',
      'icon': Icons.edit_note_rounded,
      'color': Colors.indigo,
      'completed': false,
      'points': 15,
    },
    {
      'title': 'Oyuncaklarımı Sepete Koymak',
      'icon': Icons.toys_rounded,
      'color': Colors.orange,
      'completed': false,
      'points': 10,
    },
    {
      'title': 'Su İçmek (1 Bardak)',
      'icon': Icons.water_drop_rounded,
      'color': Colors.lightBlue,
      'completed': false,
      'points': 5,
    },
    {
      'title': 'Pijamalarımı Giymek',
      'icon': Icons.checkroom_rounded,
      'color': Colors.purple,
      'completed': false,
      'points': 10,
    },
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

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['completed'] = !_tasks[index]['completed'];
    });
    final task = _tasks[index];
    if (task['completed'] == true) {
      _speak('Tebrikler! ${task['title']} görevini başardın!');
    }
  }

  void _addNewTaskDialog() {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_task_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Yeni Görev Ekle'),
          ],
        ),
        content: TextField(
          controller: titleCtrl,
          decoration: InputDecoration(
            hintText: 'Görev adı (Örn: Çantamı hazırla)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final text = titleCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _tasks.add({
                    'title': text,
                    'icon': Icons.star_rounded,
                    'color': Colors.amber,
                    'completed': false,
                    'points': 10,
                  });
                });
                _speak('$text görevi listene eklendi.');
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle'),
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
    final completedCount = _tasks.where((t) => t['completed'] == true).length;
    final totalCount = _tasks.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final totalScore = _tasks.where((t) => t['completed'] == true).fold<int>(0, (sum, t) => sum + (t['points'] as int));

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
            Icon(Icons.checklist_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Görev Listem', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green, size: 28),
            tooltip: 'Yeni Görev Ekle',
            onPressed: _addNewTaskDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme ve Yıldız Kartı
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // İlerleme Yüzdesi
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedCount / $totalCount Görev Bitti',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          color: Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '⭐ Toplam $totalScore Puan Kazandın!',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Görev Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final isCompleted = task['completed'] as bool;
                final color = task['color'] as Color;

                return GestureDetector(
                  onTap: () => _toggleTask(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCompleted ? Colors.green.shade300 : Colors.grey.shade200,
                        width: isCompleted ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // İkon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.shade100 : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            task['icon'] as IconData,
                            color: isCompleted ? Colors.green.shade700 : color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Başlık & Puan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isCompleted ? Colors.green.shade900 : AppColors.textPrimary,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${task['points']} Puan',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        // Kontrol Kutucuğu
                        Checkbox(
                          value: isCompleted,
                          activeColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (_) => _toggleTask(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
