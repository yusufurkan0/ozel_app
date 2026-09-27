import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Günün zaman dilimleri.
enum TimeSlot { morning, midday, afternoon, evening, night }

/// Makaton kategorileri.
enum MakatonCategory {
  actions('Eylemler & Fiiller', '⚡', AppColors.buttonPurple),
  social('Sosyal & Nezaket', '🤝', AppColors.buttonTeal),
  food('Yiyecekler', '🍽️', AppColors.buttonOrange),
  people('Kişiler', '👨‍👩‍👧', AppColors.buttonPink),
  emotions('Duygular', '😊', AppColors.buttonAmber),
  activities('Aktiviteler', '🎮', AppColors.buttonTeal),
  places('Yerler', '🏠', AppColors.buttonIndigo),
  needs('İhtiyaçlar', '🚿', AppColors.buttonGreen),
  emergency('Acil', '🆘', Color(0xFFE57373));

  final String label;
  final String emoji;
  final Color color;
  const MakatonCategory(this.label, this.emoji, this.color);
}

/// Makaton iletişim öğesi modeli.
class MakatonItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String? soundPath;
  final String? imagePath;
  final String? customAudioPath;
  final List<TimeSlot> preferredSlots;
  final MakatonCategory category;
  final bool isEmergency;
  int tapCount;

  MakatonItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.soundPath,
    this.imagePath,
    this.customAudioPath,
    this.preferredSlots = const [],
    required this.category,
    this.isEmergency = false,
    this.tapCount = 0,
  });

  String get emoji {
    const map = {
      'su': '💧',
      'yemek': '🍲',
      'tuvalet': '🚽',
      'park': '🏞️',
      'anne': '👩',
      'baba': '👨',
      'kardes': '👧',
      'ogretmen': '👩‍🏫',
      'arkadas': '🤝',
      'ben': '🙋‍♂️',
      'sen': '👉',
      'istiyorum': '🤲',
      'istemiyorum': '🙅',
      'ver': '🤲',
      'al': '🎁',
      'gidelim': '🚶',
      'gel': '👋',
      'oyun': '⚽',
      'bak': '👀',
      'seviyorum': '❤️',
      'bitti': '✨',
      'yardim': '🆘',
      'yardim_et': '🆘',
      'dur': '🛑',
      'lutfen': '🙏',
      'tesekkurler': '💐',
      'evet': '✅',
      'hayir': '❌',
      'merhaba': '👋',
      'sut': '🥛',
      'meyve': '🍎',
      'ekmek': '🍞',
      'cikolata': '🍫',
      'mutlu': '😊',
      'uzgun': '😢',
      'kizgin': '😠',
      'korkuyorum': '😨',
      'yorgun': '🥱',
      'saskin': '😲',
      'okul': '🏫',
      'kitap': '📖',
      'muzik': '🎵',
      'resim': '🎨',
      'uyku': '🌙',
      'doktor': '🩺',
      'hastane': '🏥',
      'ilac': '💊',
      'dis': '🪥',
      'banyo': '🛁',
      'giyin': '👕',
      'daha_fazla': '➕',
      'tekrar': '🔁',
      'oynamak_istiyorum': '🎮',
      'yemek_istiyorum': '🍽️',
      'icmek_istiyorum': '🥤',
      'ev': '🏠',
      'oda': '🚪',
      'bahce': '🌳',
      'araba': '🚗',
      'otobus': '🚌',
    };
    return map[id] ?? category.emoji;
  }

  /// Eğer kelimenin özel bir Makaton illüstrasyon görseli varsa yolunu döner
  String? get resolvedImagePath {
    if (imagePath != null && imagePath!.isNotEmpty) return imagePath;
    const signMap = {
      'su': 'assets/images/makaton_water_sign.jpg',
      'yemek': 'assets/images/makaton_food_sign.jpg',
      'tuvalet': 'assets/images/makaton_toilet_sign.jpg',
      'uyku': 'assets/images/makaton_sleep_sign.jpg',
      'lutfen': 'assets/images/makaton_please_sign.jpg',
      'merhaba': 'assets/images/makaton_hello_sign.jpg',
      'yardim': 'assets/images/makaton_help_sign.jpg',
      'yardim_et': 'assets/images/makaton_help_sign.jpg',
      'bitti': 'assets/images/makaton_finished_sign.jpg',
    };
    return signMap[id];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'iconCode': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'colorValue': color.toARGB32(),
        'category': category.name,
        'isEmergency': isEmergency,
        'soundPath': soundPath,
        'imagePath': imagePath,
        'customAudioPath': customAudioPath,
      };

  factory MakatonItem.fromJson(Map<String, dynamic> json) {
    return MakatonItem(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: IconData(
        json['iconCode'] as int? ?? Icons.star.codePoint,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      ),
      color: Color(json['colorValue'] as int? ?? 0xFF7EB8E0),
      category: MakatonCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => MakatonCategory.activities,
      ),
      isEmergency: json['isEmergency'] as bool? ?? false,
      soundPath: json['soundPath'] as String?,
      imagePath: json['imagePath'] as String?,
      customAudioPath: json['customAudioPath'] as String?,
    );
  }

  static TimeSlot getCurrentSlot() {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 11) return TimeSlot.morning;
    if (h >= 11 && h < 15) return TimeSlot.midday;
    if (h >= 15 && h < 18) return TimeSlot.afternoon;
    if (h >= 18 && h < 21) return TimeSlot.evening;
    return TimeSlot.night;
  }

  /// Kategoriye göre filtrele.
  static List<MakatonItem> byCategory(MakatonCategory cat) =>
      all().where((i) => i.category == cat).toList();

  /// Acil durum öğeleri.
  static List<MakatonItem> emergencyItems() =>
      all().where((i) => i.isEmergency).toList();

  /// Tüm Makaton öğeleri — 50+ öğe, 9 kategori.
  static List<MakatonItem> all() => [
        // ═══════════════════════════════════════
        // ⚡ EYLEMLER & FİİLLER (Cümle Kurma Öbekleri)
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'istiyorum',
          label: 'İstiyorum',
          icon: Icons.front_hand_rounded,
          color: AppColors.buttonPurple,
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'istemiyorum',
          label: 'İstemiyorum',
          icon: Icons.pan_tool_alt_rounded,
          color: const Color(0xFFE57373),
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'ver',
          label: 'Ver',
          icon: Icons.volunteer_activism_rounded,
          color: const Color(0xFF81C784),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'al',
          label: 'Al',
          icon: Icons.shopping_basket_rounded,
          color: const Color(0xFF64B5F6),
          soundPath: 'sounds/baba.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'gidelim',
          label: 'Gidelim',
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFFFFB74D),
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'gel',
          label: 'Gel',
          icon: Icons.follow_the_signs_rounded,
          color: const Color(0xFF4DB6AC),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'oynamak_istiyorum',
          label: 'Oynamak İstiyorum',
          icon: Icons.sports_esports_rounded,
          color: AppColors.buttonTeal,
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'yemek_istiyorum',
          label: 'Yemek İstiyorum',
          icon: Icons.restaurant_rounded,
          color: AppColors.buttonOrange,
          soundPath: 'sounds/yemek.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'icmek_istiyorum',
          label: 'İçmek İstiyorum',
          icon: Icons.local_drink_rounded,
          color: AppColors.buttonBlue,
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'bak',
          label: 'Bak',
          icon: Icons.visibility_rounded,
          color: const Color(0xFFBA68C8),
          soundPath: 'sounds/muzik.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'seviyorum',
          label: 'Seviyorum',
          icon: Icons.favorite_rounded,
          color: AppColors.buttonPink,
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'bitti',
          label: 'Bitti',
          icon: Icons.flag_circle_rounded,
          color: const Color(0xFF90A4AE),
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'yardim_et',
          label: 'Yardım Et',
          icon: Icons.handshake_rounded,
          color: const Color(0xFFFF8A65),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'dur',
          label: 'Dur',
          icon: Icons.stop_circle_rounded,
          color: const Color(0xFFE53935),
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.actions,
          preferredSlots: TimeSlot.values,
        ),

        // ═══════════════════════════════════════
        // 🤝 SOSYAL & NEZAKET & ZAMİRLER
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'ben',
          label: 'Ben',
          icon: Icons.person_pin_circle_rounded,
          color: AppColors.buttonIndigo,
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.social,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'sen',
          label: 'Sen',
          icon: Icons.person_rounded,
          color: const Color(0xFF5C6BC0),
          soundPath: 'sounds/baba.wav',
          category: MakatonCategory.social,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'lutfen',
          label: 'Lütfen',
          icon: Icons.spa_rounded,
          color: const Color(0xFF81C784),
          soundPath: 'sounds/muzik.wav',
          category: MakatonCategory.social,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'tesekkurler',
          label: 'Teşekkür Ederim',
          icon: Icons.thumb_up_rounded,
          color: AppColors.buttonAmber,
          soundPath: 'sounds/muzik.wav',
          category: MakatonCategory.social,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'evet',
          label: 'Evet',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.positiveGreen,
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.social,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'hayir',
          label: 'Hayır',
          icon: Icons.cancel_outlined,
          color: const Color(0xFFEF5350),
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.social,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'merhaba',
          label: 'Merhaba',
          icon: Icons.waving_hand_rounded,
          color: AppColors.buttonOrange,
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.social,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon],
        ),
        MakatonItem(
          id: 'daha_fazla',
          label: 'Daha Fazla',
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFF26A69A),
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.social,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'tekrar',
          label: 'Tekrar',
          icon: Icons.replay_rounded,
          color: const Color(0xFF7E57C2),
          soundPath: 'sounds/muzik.wav',
          category: MakatonCategory.social,
          preferredSlots: TimeSlot.values,
        ),
        // ═══════════════════════════════════════
        // 🍽️ YİYECEKLER
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'su',
          label: 'Su',
          icon: Icons.water_drop_rounded,
          color: AppColors.buttonBlue,
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.food,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon, TimeSlot.evening],
        ),
        MakatonItem(
          id: 'yemek',
          label: 'Yemek',
          icon: Icons.restaurant_rounded,
          color: AppColors.buttonOrange,
          soundPath: 'sounds/yemek.wav',
          category: MakatonCategory.food,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.evening],
        ),
        MakatonItem(
          id: 'sut',
          label: 'Süt',
          icon: Icons.local_cafe_rounded,
          color: const Color(0xFFF5F5DC),
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.food,
          preferredSlots: [TimeSlot.morning, TimeSlot.evening],
        ),
        MakatonItem(
          id: 'meyve',
          label: 'Meyve',
          icon: Icons.eco_rounded,
          color: const Color(0xFFE8A87C),
          soundPath: 'sounds/yemek.wav',
          category: MakatonCategory.food,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon],
        ),
        MakatonItem(
          id: 'ekmek',
          label: 'Ekmek',
          icon: Icons.bakery_dining_rounded,
          color: const Color(0xFFDEB887),
          soundPath: 'sounds/yemek.wav',
          category: MakatonCategory.food,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.evening],
        ),
        MakatonItem(
          id: 'cikolata',
          label: 'Çikolata',
          icon: Icons.cookie_rounded,
          color: const Color(0xFFA0522D),
          soundPath: 'sounds/yemek.wav',
          category: MakatonCategory.food,
          preferredSlots: [TimeSlot.midday, TimeSlot.afternoon],
        ),

        // ═══════════════════════════════════════
        // 👨‍👩‍👧 KİŞİLER
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'anne',
          label: 'Anne',
          icon: Icons.favorite_rounded,
          color: AppColors.buttonPink,
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.people,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'baba',
          label: 'Baba',
          icon: Icons.person_rounded,
          color: AppColors.buttonIndigo,
          soundPath: 'sounds/baba.wav',
          category: MakatonCategory.people,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'kardes',
          label: 'Kardeş',
          icon: Icons.people_rounded,
          color: const Color(0xFF9DC183),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.people,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'ogretmen',
          label: 'Öğretmen',
          icon: Icons.school_rounded,
          color: const Color(0xFF7986CB),
          soundPath: 'sounds/baba.wav',
          category: MakatonCategory.people,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon],
        ),
        MakatonItem(
          id: 'arkadas',
          label: 'Arkadaş',
          icon: Icons.group_rounded,
          color: const Color(0xFF4DB6AC),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.people,
          preferredSlots: TimeSlot.values,
        ),

        // ═══════════════════════════════════════
        // 😊 DUYGULAR
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'mutlu',
          label: 'Mutlu',
          icon: Icons.sentiment_very_satisfied_rounded,
          color: const Color(0xFFFFD54F),
          soundPath: 'sounds/muzik.wav',
          category: MakatonCategory.emotions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'uzgun',
          label: 'Üzgün',
          icon: Icons.sentiment_dissatisfied_rounded,
          color: const Color(0xFF90CAF9),
          soundPath: 'sounds/uyku.wav',
          category: MakatonCategory.emotions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'kizgin',
          label: 'Kızgın',
          icon: Icons.sentiment_very_dissatisfied_rounded,
          color: const Color(0xFFEF9A9A),
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.emotions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'korkmus',
          label: 'Korkmuş',
          icon: Icons.sentiment_neutral_rounded,
          color: const Color(0xFFCE93D8),
          soundPath: 'sounds/uyku.wav',
          category: MakatonCategory.emotions,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'yorgun',
          label: 'Yorgun',
          icon: Icons.nights_stay_rounded,
          color: const Color(0xFFB0BEC5),
          soundPath: 'sounds/uyku.wav',
          category: MakatonCategory.emotions,
          preferredSlots: [TimeSlot.afternoon, TimeSlot.evening, TimeSlot.night],
        ),
        MakatonItem(
          id: 'saskin',
          label: 'Şaşkın',
          icon: Icons.psychology_rounded,
          color: const Color(0xFFFFAB91),
          soundPath: 'sounds/muzik.wav',
          category: MakatonCategory.emotions,
          preferredSlots: TimeSlot.values,
        ),

        // ═══════════════════════════════════════
        // 🎮 AKTİVİTELER
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'oyun',
          label: 'Oyun',
          icon: Icons.sports_esports_rounded,
          color: AppColors.buttonTeal,
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.activities,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon],
        ),
        MakatonItem(
          id: 'muzik',
          label: 'Müzik',
          icon: Icons.music_note_rounded,
          color: AppColors.buttonAmber,
          soundPath: 'sounds/muzik.wav',
          category: MakatonCategory.activities,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon, TimeSlot.evening],
        ),
        MakatonItem(
          id: 'kitap',
          label: 'Kitap',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF8D6E63),
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.activities,
          preferredSlots: [TimeSlot.morning, TimeSlot.afternoon, TimeSlot.evening],
        ),
        MakatonItem(
          id: 'park',
          label: 'Park',
          icon: Icons.park_rounded,
          color: const Color(0xFF66BB6A),
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.activities,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon],
        ),
        MakatonItem(
          id: 'cizim',
          label: 'Çizim',
          icon: Icons.brush_rounded,
          color: const Color(0xFFBA68C8),
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.activities,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon],
        ),
        MakatonItem(
          id: 'dans',
          label: 'Dans',
          icon: Icons.directions_run_rounded,
          color: const Color(0xFFFF8A65),
          soundPath: 'sounds/muzik.wav',
          category: MakatonCategory.activities,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon],
        ),

        // ═══════════════════════════════════════
        // 🏠 YERLER
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'ev',
          label: 'Ev',
          icon: Icons.home_rounded,
          color: const Color(0xFFA1887F),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.places,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'okul',
          label: 'Okul',
          icon: Icons.school_rounded,
          color: const Color(0xFF5C6BC0),
          soundPath: 'sounds/baba.wav',
          category: MakatonCategory.places,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday],
        ),
        MakatonItem(
          id: 'hastane',
          label: 'Hastane',
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFFE57373),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.places,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'market',
          label: 'Market',
          icon: Icons.shopping_cart_rounded,
          color: const Color(0xFF4CAF50),
          soundPath: 'sounds/yemek.wav',
          category: MakatonCategory.places,
          preferredSlots: [TimeSlot.morning, TimeSlot.midday, TimeSlot.afternoon],
        ),

        // ═══════════════════════════════════════
        // 🚿 İHTİYAÇLAR
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'tuvalet',
          label: 'Tuvalet',
          icon: Icons.bathroom_rounded,
          color: AppColors.buttonGreen,
          soundPath: 'sounds/tuvalet.wav',
          category: MakatonCategory.needs,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'uyku',
          label: 'Uyku',
          icon: Icons.bedtime_rounded,
          color: AppColors.buttonPurple,
          soundPath: 'sounds/uyku.wav',
          category: MakatonCategory.needs,
          preferredSlots: [TimeSlot.evening, TimeSlot.night],
        ),
        MakatonItem(
          id: 'banyo',
          label: 'Banyo',
          icon: Icons.bathtub_rounded,
          color: const Color(0xFF80DEEA),
          soundPath: 'sounds/su.wav',
          category: MakatonCategory.needs,
          preferredSlots: [TimeSlot.morning, TimeSlot.evening],
        ),
        MakatonItem(
          id: 'kiyafet',
          label: 'Kıyafet',
          icon: Icons.checkroom_rounded,
          color: const Color(0xFFFFCC80),
          soundPath: 'sounds/oyun.wav',
          category: MakatonCategory.needs,
          preferredSlots: [TimeSlot.morning],
        ),

        // ═══════════════════════════════════════
        // 🆘 ACİL DURUM
        // ═══════════════════════════════════════
        MakatonItem(
          id: 'agri',
          label: 'Ağrım Var',
          icon: Icons.healing_rounded,
          color: const Color(0xFFEF5350),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.emergency,
          isEmergency: true,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'yardim',
          label: 'Yardım',
          icon: Icons.sos_rounded,
          color: const Color(0xFFFF7043),
          soundPath: 'sounds/anne.wav',
          category: MakatonCategory.emergency,
          isEmergency: true,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'korkuyorum',
          label: 'Korkuyorum',
          icon: Icons.shield_rounded,
          color: const Color(0xFFFFB74D),
          soundPath: 'sounds/uyku.wav',
          category: MakatonCategory.emergency,
          isEmergency: true,
          preferredSlots: TimeSlot.values,
        ),
        MakatonItem(
          id: 'iyi_degilim',
          label: 'İyi Değilim',
          icon: Icons.sick_rounded,
          color: const Color(0xFFE0A07A),
          soundPath: 'sounds/uyku.wav',
          category: MakatonCategory.emergency,
          isEmergency: true,
          preferredSlots: TimeSlot.values,
        ),
      ];
}
