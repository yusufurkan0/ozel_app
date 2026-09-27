/// 📅 Günlük Rutin Adımı Modeli (Görsel Çizelge)
class RoutineStep {
  final String id;
  final String title;
  final String emoji;
  final String timeSlot; // 'sabah', 'okul', 'aksam'
  final int durationMinutes;
  bool isCompleted;
  final String? audioPrompt;

  RoutineStep({
    required this.id,
    required this.title,
    required this.emoji,
    required this.timeSlot,
    this.durationMinutes = 10,
    this.isCompleted = false,
    this.audioPrompt,
  });

  RoutineStep copyWith({
    String? id,
    String? title,
    String? emoji,
    String? timeSlot,
    int? durationMinutes,
    bool? isCompleted,
    String? audioPrompt,
  }) {
    return RoutineStep(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      timeSlot: timeSlot ?? this.timeSlot,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      audioPrompt: audioPrompt ?? this.audioPrompt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'timeSlot': timeSlot,
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'audioPrompt': audioPrompt,
    };
  }

  factory RoutineStep.fromJson(Map<String, dynamic> json) {
    return RoutineStep(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String? ?? '⭐',
      timeSlot: json['timeSlot'] as String? ?? 'sabah',
      durationMinutes: json['durationMinutes'] as int? ?? 10,
      isCompleted: json['isCompleted'] as bool? ?? false,
      audioPrompt: json['audioPrompt'] as String?,
    );
  }

  /// Özel eğitim standartlarında hazır zengin günlük rutin şablonu.
  static List<RoutineStep> defaultSteps() {
    return [
      // 🌅 SABAH RUTİNİ
      RoutineStep(
        id: 'sabah_1',
        title: 'Güne Merhaba & Uyanma',
        emoji: '☀️',
        timeSlot: 'sabah',
        durationMinutes: 5,
        audioPrompt: 'Günaydın! Harika bir gün başlıyor, haydi uyanalım.',
      ),
      RoutineStep(
        id: 'sabah_2',
        title: 'El ve Yüz Yıkama',
        emoji: '🧼',
        timeSlot: 'sabah',
        durationMinutes: 5,
        audioPrompt: 'Banyoya gidelim, ellerimizi sabunla tertemiz yıkayalım.',
      ),
      RoutineStep(
        id: 'sabah_3',
        title: 'Dişleri Fırçalama',
        emoji: '🪥',
        timeSlot: 'sabah',
        durationMinutes: 3,
        audioPrompt: 'Diş fırçamızı alalım ve pırıl pırıl fırçalayalım.',
      ),
      RoutineStep(
        id: 'sabah_4',
        title: 'Kıyafetleri Giyme',
        emoji: '👕',
        timeSlot: 'sabah',
        durationMinutes: 10,
        audioPrompt: 'Bugünkü temiz kıyafetlerimizi giyelim.',
      ),
      RoutineStep(
        id: 'sabah_5',
        title: 'Sağlıklı Kahvaltı',
        emoji: '🥞',
        timeSlot: 'sabah',
        durationMinutes: 20,
        audioPrompt: 'Enerji toplamak için kahvaltımızı yapalım.',
      ),
      RoutineStep(
        id: 'sabah_6',
        title: 'Çanta Hazırlama & Çıkış',
        emoji: '🎒',
        timeSlot: 'sabah',
        durationMinutes: 5,
        audioPrompt: 'Çantamızı kontrol edelim, okula veya etkinliğe hazırız.',
      ),

      // 🏫 OKUL & ETKİNLİK RUTİNİ
      RoutineStep(
        id: 'okul_1',
        title: 'Servis & Yolculuk',
        emoji: '🚌',
        timeSlot: 'okul',
        durationMinutes: 15,
        audioPrompt: 'Emniyet kemerimizi takalım ve güvenle gidelim.',
      ),
      RoutineStep(
        id: 'okul_2',
        title: 'Öğretmene ve Arkadaşlara Selam',
        emoji: '👋',
        timeSlot: 'okul',
        durationMinutes: 5,
        audioPrompt: 'Gülümseyerek arkadaşlarımıza merhaba diyelim.',
      ),
      RoutineStep(
        id: 'okul_3',
        title: 'Ders & Kitap Etkinliği',
        emoji: '✏️',
        timeSlot: 'okul',
        durationMinutes: 30,
        audioPrompt: 'Masamıza oturalım, birlikte öğrenme zamanı.',
      ),
      RoutineStep(
        id: 'okul_4',
        title: 'Beslenme & Meyve Saati',
        emoji: '🍎',
        timeSlot: 'okul',
        durationMinutes: 15,
        audioPrompt: 'Taze meyvemizi yiyelim ve suyumuzu içelim.',
      ),
      RoutineStep(
        id: 'okul_5',
        title: 'Bahçede Serbest Oyun',
        emoji: '🤹',
        timeSlot: 'okul',
        durationMinutes: 20,
        audioPrompt: 'Arkadaşlarınla parkta eğlenme zamanı.',
      ),

      // 🌙 AKŞAM RUTİNİ
      RoutineStep(
        id: 'aksam_1',
        title: 'Eve Dönüş & Rahatlama',
        emoji: '🛋️',
        timeSlot: 'aksam',
        durationMinutes: 15,
        audioPrompt: 'Evimize hoş geldik, ayakkabılarımızı çıkarıp dinlenelim.',
      ),
      RoutineStep(
        id: 'aksam_2',
        title: 'Akşam Yemeği',
        emoji: '🍲',
        timeSlot: 'aksam',
        durationMinutes: 25,
        audioPrompt: 'Ailemizle birlikte lezzetli akşam yemeği saati.',
      ),
      RoutineStep(
        id: 'aksam_3',
        title: 'Oyuncakları Toplama',
        emoji: '📦',
        timeSlot: 'aksam',
        durationMinutes: 10,
        audioPrompt: 'Odamızı düzenli tutmak için oyuncaklarımızı kutusuna koyalım.',
      ),
      RoutineStep(
        id: 'aksam_4',
        title: 'Pijama Giyme & Banyo',
        emoji: '🩳',
        timeSlot: 'aksam',
        durationMinutes: 15,
        audioPrompt: 'Ilık bir duş ve yumuşacık pijamalarımızı giyelim.',
      ),
      RoutineStep(
        id: 'aksam_5',
        title: 'Masal Dinleme & Uyku',
        emoji: '🌙',
        timeSlot: 'aksam',
        durationMinutes: 20,
        audioPrompt: 'Işıkları kısalım, güzel rüyalar dilerim.',
      ),
    ];
  }
}
