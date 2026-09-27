import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_progress_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

import '../services/ai_aac_service.dart';

class SocialStory {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final Color color;
  final List<StoryStep> steps;

  const SocialStory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.color,
    required this.steps,
  });
}

class StoryStep {
  final String title;
  final String text;
  final String emoji;
  final IconData icon;

  const StoryStep({
    required this.title,
    required this.text,
    required this.emoji,
    required this.icon,
  });
}

/// Özel gereksinimli çocuklar için pedagojik Sosyal Hikayeler ve Görsel Rehberler.
class SocialStoriesScreen extends StatefulWidget {
  const SocialStoriesScreen({super.key});

  @override
  State<SocialStoriesScreen> createState() => _SocialStoriesScreenState();
}

class _SocialStoriesScreenState extends State<SocialStoriesScreen> {
  SocialStory? _activeStory;
  int _currentStepIndex = 0;
  final List<SocialStory> _customStories = [];

  List<SocialStory> get _allStories => [..._customStories, ..._stories];

  static const List<SocialStory> _stories = [
    SocialStory(
      id: 'dentist',
      title: 'Diş Hekimine Gidiyorum',
      emoji: '🦷',
      description: 'Diş kontrolü sakin ve güvenli bir süreçtir.',
      color: AppColors.buttonBlue,
      steps: [
        StoryStep(
          title: 'Kliniğe Giriş',
          text: 'Diş hekiminin kliniğine giriyoruz ve bekleme odasında sakince oturuyoruz.',
          emoji: '🏥',
          icon: Icons.local_hospital_rounded,
        ),
        StoryStep(
          title: 'Özel Koltuk',
          text: 'Doktorumuz bizi çağırıyor. Yukarı aşağı hareket eden yumuşak koltuğa oturuyoruz.',
          emoji: '💺',
          icon: Icons.airline_seat_recline_extra_rounded,
        ),
        StoryStep(
          title: 'Işık ve Kontrol',
          text: 'Doktorumuz küçük bir ışık açıyor ve ağzımızı açmamızı istiyor. Hiçbir acı hissetmeyiz.',
          emoji: '💡',
          icon: Icons.lightbulb_rounded,
        ),
        StoryStep(
          title: 'Minik Ayna',
          text: 'Küçük bir ayna ile dişlerimizi sayıyor ve temizliyor.',
          emoji: '🪞',
          icon: Icons.search_rounded,
        ),
        StoryStep(
          title: 'Harika Başardın!',
          text: 'Muayene bitti! Dişlerimiz pırıl pırıl parlıyor, sen çok cesursun!',
          emoji: '⭐',
          icon: Icons.emoji_events_rounded,
        ),
      ],
    ),
    SocialStory(
      id: 'barber',
      title: 'Berbere Gidiyorum',
      emoji: '✂️',
      description: 'Saç kestirmek kolay ve eğlenceli bir bakımdır.',
      color: AppColors.buttonAmber,
      steps: [
        StoryStep(
          title: 'Berbere Giriş',
          text: 'Berbere gidiyoruz ve büyük döner koltuğa oturuyoruz.',
          emoji: '🪑',
          icon: Icons.chair_rounded,
        ),
        StoryStep(
          title: 'Süper Kahraman Pelerini',
          text: 'Saçlarımızın üzerimize dökülmemesi için boynumuza koruyucu bir önlük takılır.',
          emoji: '🦸',
          icon: Icons.shield_rounded,
        ),
        StoryStep(
          title: 'Su ve Tarama',
          text: 'Saçlarımız su spreyiyle hafifçe nemlendirilir ve taranır.',
          emoji: '💧',
          icon: Icons.water_drop_rounded,
        ),
        StoryStep(
          title: 'Kıtır Kıtır Makas',
          text: 'Makas saçlarımızın ucunu keserken tatlı bir ses çıkarır, canımız hiç yanmaz.',
          emoji: '✂️',
          icon: Icons.content_cut_rounded,
        ),
        StoryStep(
          title: 'Aynaya Bakıyoruz',
          text: 'Saçlarımız harika oldu! Aynada kendimize gülümsüyoruz.',
          emoji: '🌟',
          icon: Icons.face_retouching_natural_rounded,
        ),
      ],
    ),
    SocialStory(
      id: 'school',
      title: 'Okulda Bir Günüm',
      emoji: '🎒',
      description: 'Okulda yeni şeyler öğrenip arkadaşlarımızla oynarız.',
      color: AppColors.buttonTeal,
      steps: [
        StoryStep(
          title: 'Okula Varış',
          text: 'Sabah çantamızı alıp okula geliyoruz ve sınıfımıza giriyoruz.',
          emoji: '🏫',
          icon: Icons.school_rounded,
        ),
        StoryStep(
          title: 'Arkadaşlar ve Selam',
          text: 'Öğretmenimize ve arkadaşlarımıza neşeyle "Merhaba" diyoruz.',
          emoji: '👋',
          icon: Icons.waving_hand_rounded,
        ),
        StoryStep(
          title: 'Etkinlik ve Oyun',
          text: 'Birlikte resim yapıyor, şarkı söylüyor ve eğlenceli oyunlar oynuyoruz.',
          emoji: '🎨',
          icon: Icons.palette_rounded,
        ),
        StoryStep(
          title: 'Beslenme Saati',
          text: 'Ellerimizi yıkayıp yemeğimizi yiyor ve suyumuzu içiyoruz.',
          emoji: '🥪',
          icon: Icons.lunch_dining_rounded,
        ),
        StoryStep(
          title: 'Eve Dönüş',
          text: 'Dersler bittiğinde eşyalarımızı topluyoruz ve mutlu bir şekilde eve dönüyoruz.',
          emoji: '🏠',
          icon: Icons.home_rounded,
        ),
      ],
    ),
    SocialStory(
      id: 'park',
      title: 'Parkta Sıramı Bekliyorum',
      emoji: '🛝',
      description: 'Sıra beklemek oyunları herkes için daha keyifli yapar.',
      color: AppColors.buttonGreen,
      steps: [
        StoryStep(
          title: 'Parka Geldik',
          text: 'Parka geliyoruz ve kaydırağa doğru yürüyoruz.',
          emoji: '🛝',
          icon: Icons.park_rounded,
        ),
        StoryStep(
          title: 'Sıra Bekleme',
          text: 'Önümüzde bir arkadaşımız varsa sakince bekliyoruz. Sıra çok çabuk gelecek.',
          emoji: '⏳',
          icon: Icons.hourglass_top_rounded,
        ),
        StoryStep(
          title: 'Sıra Bizde!',
          text: 'Arkadaşımız kaydı, şimdi sıra bize geldi!',
          emoji: '🙋',
          icon: Icons.check_circle_rounded,
        ),
        StoryStep(
          title: 'Rüzgar Gibi Kayıyoruz',
          text: 'Merdivenleri çıkıyoruz ve gülümseyerek kaydıraktan kayıyoruz!',
          emoji: '🚀',
          icon: Icons.directions_run_rounded,
        ),
        StoryStep(
          title: 'Tebrikler!',
          text: 'Sabırla bekledin ve harika eğlendin. Sen harika bir arkadaşsın!',
          emoji: '👏',
          icon: Icons.thumb_up_alt_rounded,
        ),
      ],
    ),
  ];

  void _startStory(SocialStory story) {
    setState(() {
      _activeStory = story;
      _currentStepIndex = 0;
    });
    _speakCurrentStep();
  }

  void _speakCurrentStep() {
    if (_activeStory == null) return;
    final step = _activeStory!.steps[_currentStepIndex];
    TtsService().speak('${step.title}. ${step.text}');
  }

  void _nextStep() {
    if (_activeStory == null) return;
    if (_currentStepIndex + 1 < _activeStory!.steps.length) {
      setState(() => _currentStepIndex++);
      _speakCurrentStep();
    } else {
      TtsService().speak('Tebrikler, bu hikayeyi başarıyla tamamladın!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tebrikler! Hikayeyi başarıyla tamamladın 🎉'),
          backgroundColor: AppColors.positiveGreen,
        ),
      );
      setState(() => _activeStory = null);
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
      _speakCurrentStep();
    }
  }

  void _showAiStoryGeneratorDialog() {
    final topicCtrl = TextEditingController();
    final game = context.read<GameProgressService>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.buttonIndigo),
              SizedBox(width: 8),
              Text('AI İle Özel Hikaye Yaz 🤖'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çocuğunuzun yaşayacağı yeni veya kaygı verici bir durumu yazın. Yapay zeka adım adım pedagojik bir öykü oluştursun:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicCtrl,
                  decoration: InputDecoration(
                    hintText: 'Örn: Aşı Olma, Uçak, Yüzme, Düğün...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.03),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hızlı Konu Önerileri:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    '💉 Aşı Olma',
                    '✈️ Uçağa Binme',
                    '🏊‍♂️ Yüzme Havuzu',
                    '🚌 Okul Servisi',
                    '🎂 Doğum Günü',
                  ].map((preset) {
                    return ActionChip(
                      label: Text(preset, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        final clean = preset.replaceAll(RegExp(r'[^\w\sğüşöçıİĞÜŞÖÇ]'), '').trim();
                        topicCtrl.text = clean;
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final topic = topicCtrl.text.trim();
                if (topic.isEmpty) return;

                Navigator.pop(ctx);

                // AI Hikaye Üretimi
                final aiStory = AiAacService().generateSocialStory(
                  topic: topic,
                  childName: game.childName,
                );

                final newStory = SocialStory(
                  id: aiStory.id,
                  title: aiStory.title,
                  emoji: aiStory.emoji,
                  description: aiStory.description,
                  color: aiStory.color,
                  steps: aiStory.steps
                      .map((s) => StoryStep(
                            title: s.title,
                            text: s.text,
                            emoji: s.emoji,
                            icon: s.icon,
                          ))
                      .toList(),
                );

                setState(() {
                  _customStories.insert(0, newStory);
                });

                _startStory(newStory);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${newStory.title}" hikayesi yapay zeka ile oluşturuldu! ✨'),
                    backgroundColor: AppColors.positiveGreen,
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Hikayeyi Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProgressService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_activeStory == null ? 'Sosyal Hikayeler' : _activeStory!.title),
        elevation: 0,
        leading: _activeStory != null
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  TtsService().stop();
                  setState(() => _activeStory = null);
                },
              )
            : null,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(game.themeIndex),
        ),
        child: SafeArea(
          child: _activeStory == null
              ? _buildStoryList()
              : _buildStoryViewer(_activeStory!),
        ),
      ),
    );
  }

  Widget _buildStoryList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const Text(
          'Görsel Yaşam Rehberleri',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Yeni ortamlara alışmayı kolaylaştıran, kaygıyı azaltan adım adım görsel öyküler.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // ─── AI Özel Hikaye Yazma Butonu ─────────────────────────
        GestureDetector(
          onTap: _showAiStoryGeneratorDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: Neu.colored(color: AppColors.buttonIndigo, radius: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI İle Özel Hikaye Yaz 🤖',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Aşı, uçak, düğün veya istediğin bir duruma özel rehber üret.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        ..._allStories.map((story) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => _startStory(story),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: Neu.elevated(radius: 24, blur: 10),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: story.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(story.emoji, style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            story.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.format_list_numbered_rounded,
                                  size: 14, color: story.color),
                              const SizedBox(width: 4),
                              Text(
                                '${story.steps.length} Adım',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: story.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStoryViewer(SocialStory story) {
    final step = story.steps[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / story.steps.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // İlerleme çubuğu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adım ${_currentStepIndex + 1} / ${story.steps.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo, size: 28),
                onPressed: _speakCurrentStep,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(story.color),
            ),
          ),
          const SizedBox(height: 28),

          // Hikaye Kartı
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: Neu.elevated(radius: 32, blur: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: story.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(step.emoji, style: const TextStyle(fontSize: 52)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    step.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Navigasyon Butonları
          Row(
            children: [
              if (_currentStepIndex > 0)
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Geri', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_currentStepIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: Icon(_currentStepIndex + 1 == story.steps.length
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(
                      _currentStepIndex + 1 == story.steps.length
                          ? 'Hikayeyi Tamamla'
                          : 'Sonraki Adım',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: story.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
