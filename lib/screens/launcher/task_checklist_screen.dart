import 'package:shared_preferences/shared_preferences.dart';
import '../../services/teacher_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import 'social_story_library_screen.dart';

class TaskChecklistScreen extends StatefulWidget {
  const TaskChecklistScreen({super.key});

  @override
  State<TaskChecklistScreen> createState() => _TaskChecklistScreenState();
}

class _TaskChecklistScreenState extends State<TaskChecklistScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _teacherTasks = [];
  bool _isLoadingTeacherTasks = false;

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
    _tabCtrl = TabController(length: 2, vsync: this);
    _initTts();
    _loadTeacherTasks();
  }

  Future<void> _loadTeacherTasks() async {
    setState(() => _isLoadingTeacherTasks = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final childName = prefs.getString('child_name') ??
          prefs.getString('sos_child_name') ??
          prefs.getString('user_emergency_name') ??
          '';

      final tasks = await TeacherSyncService.instance.fetchTasksForStudent(studentName: childName);

      if (mounted) {
        setState(() {
          _teacherTasks = tasks.map((t) {
            return {
              'id': t['id'] ?? 'tsk_${DateTime.now().millisecondsSinceEpoch}',
              'title': t['title'] ?? 'Öğretmen Görevi',
              'icon': _parseTaskIcon(t['icon']),
              'color': _parseTaskColor(t['priority']),
              'completed': t['isCompleted'] == true,
              'points': (t['points'] is int) ? t['points'] : int.tryParse(t['points']?.toString() ?? '15') ?? 15,
              'isTeacherTask': true,
              'dueDate': t['dueDate'] ?? 'Bugün',
              'category': t['category'] ?? 'Genel',
            };
          }).toList();
          _isLoadingTeacherTasks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTeacherTasks = false);
    }
  }

  IconData _parseTaskIcon(dynamic iconStr) {
    final s = (iconStr ?? '').toString().toLowerCase();
    if (s.contains('kitap') || s.contains('book')) return Icons.menu_book_rounded;
    if (s.contains('spor') || s.contains('sport')) return Icons.fitness_center_rounded;
    if (s.contains('yemek') || s.contains('food')) return Icons.restaurant_rounded;
    if (s.contains('temiz') || s.contains('clean')) return Icons.cleaning_services_rounded;
    if (s.contains('yatak') || s.contains('bed')) return Icons.bed_rounded;
    return Icons.assignment_rounded;
  }

  Color _parseTaskColor(dynamic priority) {
    final p = (priority ?? '').toString().toLowerCase();
    if (p.contains('yüksek') || p.contains('high')) return Colors.orange;
    if (p.contains('acil') || p.contains('urgent')) return Colors.red;
    return Colors.indigo;
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

  void _toggleTask(int index, List<Map<String, dynamic>> allTasks) {
    final task = allTasks[index];
    final newCompleted = !(task['completed'] == true);

    setState(() {
      task['completed'] = newCompleted;
    });

    if (task['isTeacherTask'] == true && task['id'] != null) {
      TeacherSyncService.instance.toggleTaskCompletion(
        taskId: task['id'],
        isCompleted: newCompleted,
      );
    }

    if (newCompleted) {
      if (task['isTeacherTask'] == true) {
        _speak('Harika! Öğretmeninin verdiği ${task['title']} görevini başardın!');
      } else {
        _speak('Tebrikler! ${task['title']} görevini başardın!');
      }
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
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Görev adı (Örn: Çantamı hazırlamak)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
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
    _tabCtrl.dispose();
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
            Icon(Icons.checklist_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Görev Listesi', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: _isLoadingTeacherTasks
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                : const Icon(Icons.refresh_rounded, color: Colors.green),
            tooltip: 'Görevleri Yenile',
            onPressed: _loadTeacherTasks,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.green.shade800,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.green.shade700,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories_rounded), text: 'Görev Kitaplarım'),
            Tab(icon: Icon(Icons.check_circle_outline_rounded), text: 'Hızlı Liste'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ─── 1. Görev Kitapları (Kullanıcı İsteği: "Sosyal öykülerdeki yapının aynısı kullanılacak") ───
          const SocialStoryLibraryScreen(type: 'task_list', isEmbedded: true),

          // ─── 2. Hızlı Görev Kontrol Listesi ───
          _buildQuickChecklist(),
        ],
      ),
    );
  }

  Widget _buildQuickChecklist() {
    final allTasks = [..._teacherTasks, ..._tasks];
    final completedCount = allTasks.where((t) => t['completed'] == true).length;
    final totalCount = allTasks.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final totalScore = allTasks.where((t) => t['completed'] == true).fold<int>(0, (sum, t) => sum + ((t['points'] as int?) ?? 10));

    return Column(
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
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Puan Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade400,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$totalScore',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Hızlı Görev Ekleme Butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Hızlı Görev Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _addNewTaskDialog,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Görevler Listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: allTasks.length,
            itemBuilder: (context, index) {
              final task = allTasks[index];
              final completed = task['completed'] == true;
              final color = (task['color'] as Color?) ?? Colors.green;
              final isTeacherTask = task['isTeacherTask'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: completed
                        ? Colors.green.shade300
                        : (isTeacherTask ? Colors.indigo.shade300 : Colors.grey.shade200),
                    width: (completed || isTeacherTask) ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: GestureDetector(
                    onTap: () => _toggleTask(index, allTasks),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: completed ? Colors.green.shade500 : color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completed ? Icons.check_rounded : (task['icon'] as IconData? ?? Icons.assignment_rounded),
                        color: completed ? Colors.white : color,
                        size: 24,
                      ),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isTeacherTask) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🧑‍🏫 Öğretmenden Görev', style: TextStyle(fontSize: 10.5, color: Colors.indigo, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        task['title'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: completed ? TextDecoration.lineThrough : null,
                          color: completed ? Colors.grey : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: isTeacherTask && task['dueDate'] != null
                      ? Text('⏰ Bitiş: ${task['dueDate']}', style: const TextStyle(fontSize: 12, color: Colors.grey))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo),
                        tooltip: 'Sesli Dinle',
                        onPressed: () => _speak(task['title'] as String? ?? ''),
                      ),
                      Checkbox(
                        value: completed,
                        activeColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (_) => _toggleTask(index, allTasks),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
