import 'package:flutter/material.dart';

class CalendarActivity {
  final String id;
  final String title;
  final String group; // EĞ, İŞ, KG, SĞ, EV, SZ
  final String groupName;
  final String emoji;
  final IconData icon;
  final Color color;

  const CalendarActivity({
    required this.id,
    required this.title,
    required this.group,
    required this.groupName,
    required this.emoji,
    required this.icon,
    required this.color,
  });

  bool get isFreeTime => group == 'SZ';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'group': group,
        'groupName': groupName,
        'emoji': emoji,
      };

  factory CalendarActivity.fromJson(Map<String, dynamic> json) {
    final act = predefinedActivities.firstWhere(
      (a) => a.id == json['id'] || a.title == json['title'],
      orElse: () => CalendarActivity(
        id: json['id'] ?? 'custom',
        title: json['title'] ?? '',
        group: json['group'] ?? 'EV',
        groupName: json['groupName'] ?? 'Ev',
        emoji: json['emoji'] ?? '📌',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF64748B),
      ),
    );
    return act;
  }

  // Kullanıcının verdiği 29 etkinlik tam listesi ve tam sırası:
  static const List<CalendarActivity> predefinedActivities = [
    // 1-3: EĞİTİM (EĞ)
    CalendarActivity(
      id: 'okula_gidecegim',
      title: 'Okula gideceğim',
      group: 'EĞ',
      groupName: 'Eğitim',
      emoji: '🎒',
      icon: Icons.school_rounded,
      color: Color(0xFF2563EB),
    ),
    CalendarActivity(
      id: 'rehabilitasyona_gidecegim',
      title: 'Rehabilitasyona gideceğim',
      group: 'EĞ',
      groupName: 'Eğitim',
      emoji: '🏥',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFF3B82F6),
    ),
    CalendarActivity(
      id: 'ders_calisacagim',
      title: 'Ders çalışacağım',
      group: 'EĞ',
      groupName: 'Eğitim',
      emoji: '📚',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF1D4ED8),
    ),

    // 4-5: İŞ (İŞ)
    CalendarActivity(
      id: 'ise_gidecegim',
      title: 'İşe gideceğim',
      group: 'İŞ',
      groupName: 'İş',
      emoji: '💼',
      icon: Icons.work_rounded,
      color: Color(0xFF0F766E),
    ),
    CalendarActivity(
      id: 'is_gorusmesine_gidecegim',
      title: 'İş görüşmesine gideceğim',
      group: 'İŞ',
      groupName: 'İş',
      emoji: '🤝',
      icon: Icons.handshake_rounded,
      color: Color(0xFF0D9488),
    ),

    // 6-8: KİŞİSEL GELİŞİM (KG)
    CalendarActivity(
      id: 'spora_gidecegim',
      title: 'Spora gideceğim',
      group: 'KG',
      groupName: 'Kişisel Gelişim',
      emoji: '🏃',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFD97706),
    ),
    CalendarActivity(
      id: 'dernege_gidecegim',
      title: 'Derneğe gideceğim',
      group: 'KG',
      groupName: 'Kişisel Gelişim',
      emoji: '🏛️',
      icon: Icons.account_balance_rounded,
      color: Color(0xFFB45309),
    ),
    CalendarActivity(
      id: 'kursa_gidecegim',
      title: 'Kursa gideceğim',
      group: 'KG',
      groupName: 'Kişisel Gelişim',
      emoji: '🎨',
      icon: Icons.palette_rounded,
      color: Color(0xFFF59E0B),
    ),

    // 9: SAĞLIK (SĞ)
    CalendarActivity(
      id: 'doktora_discive_gidecegim',
      title: 'Doktora/Dişçiye gideceğim',
      group: 'SĞ',
      groupName: 'Sağlık',
      emoji: '🩺',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFDC2626),
    ),

    // 10-17: EV (EV)
    CalendarActivity(
      id: 'evde_vakit_gecirecegim',
      title: 'Evde vakit geçireceğim',
      group: 'EV',
      groupName: 'Ev',
      emoji: '🏠',
      icon: Icons.home_rounded,
      color: Color(0xFF475569),
    ),
    CalendarActivity(
      id: 'temizlik_yapacagim',
      title: 'Temizlik yapacağım',
      group: 'EV',
      groupName: 'Ev',
      emoji: '🧹',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF64748B),
    ),
    CalendarActivity(
      id: 'yemek_yapacagim',
      title: 'Yemek yapacağım',
      group: 'EV',
      groupName: 'Ev',
      emoji: '🍳',
      icon: Icons.soup_kitchen_rounded,
      color: Color(0xFFEA580C),
    ),
    CalendarActivity(
      id: 'camasir_yikayacagim',
      title: 'Çamaşır yıkayacağım',
      group: 'EV',
      groupName: 'Ev',
      emoji: '🧺',
      icon: Icons.local_laundry_service_rounded,
      color: Color(0xFF0284C7),
    ),
    CalendarActivity(
      id: 'bulasik_yikayacagim',
      title: 'Bulaşık yıkayacağım',
      group: 'EV',
      groupName: 'Ev',
      emoji: '🍽️',
      icon: Icons.countertops_rounded,
      color: Color(0xFF0891B2),
    ),
    CalendarActivity(
      id: 'odami_evi_toplayacagim',
      title: 'Odamı/evi toplayacağım',
      group: 'EV',
      groupName: 'Ev',
      emoji: '🛏️',
      icon: Icons.bed_rounded,
      color: Color(0xFF4B5563),
    ),
    CalendarActivity(
      id: 'copleri_atacagim',
      title: 'Çöpleri atacağım',
      group: 'EV',
      groupName: 'Ev',
      emoji: '🗑️',
      icon: Icons.delete_outline_rounded,
      color: Color(0xFF334155),
    ),
    CalendarActivity(
      id: 'banyo_yapacagim',
      title: 'Banyo yapacağım',
      group: 'EV',
      groupName: 'Ev',
      emoji: '🚿',
      icon: Icons.shower_rounded,
      color: Color(0xFF0284C7),
    ),

    // 18-29: SERBEST ZAMAN (SZ)
    CalendarActivity(
      id: 'sinemaya_gidecegim',
      title: 'Sinemaya gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🎬',
      icon: Icons.movie_rounded,
      color: Color(0xFF7C3AED),
    ),
    CalendarActivity(
      id: 'tiyatroya_gidecegim',
      title: 'Tiyatroya gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🎭',
      icon: Icons.theater_comedy_rounded,
      color: Color(0xFF9333EA),
    ),
    CalendarActivity(
      id: 'kafeye_gidecegim',
      title: 'Kafeye gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '☕',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF854D0E),
    ),
    CalendarActivity(
      id: 'konsere_gidecegim',
      title: 'Konsere gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🎵',
      icon: Icons.music_note_rounded,
      color: Color(0xFFC026D3),
    ),
    CalendarActivity(
      id: 'muzeye_gidecegim',
      title: 'Müzeye gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🏛️',
      icon: Icons.museum_rounded,
      color: Color(0xFF4338CA),
    ),
    CalendarActivity(
      id: 'alisverise_gidecegim',
      title: 'Alışverişe gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🛍️',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFDB2777),
    ),
    CalendarActivity(
      id: 'bowlinge_gidecegim',
      title: 'Bowlinge gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🎳',
      icon: Icons.sports_tennis_rounded,
      color: Color(0xFFE11D48),
    ),
    CalendarActivity(
      id: 'kuaföre_berbere_gidecegim',
      title: 'Kuaföre/berbere gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '💇',
      icon: Icons.content_cut_rounded,
      color: Color(0xFFBE185D),
    ),
    CalendarActivity(
      id: 'piknige_gidecegim',
      title: 'Pikniğe gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🧺',
      icon: Icons.park_rounded,
      color: Color(0xFF16A34A),
    ),
    CalendarActivity(
      id: 'maca_gidecegim',
      title: 'Maça gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '⚽',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF059669),
    ),
    CalendarActivity(
      id: 'parti_kutlamaya_gidecegim',
      title: 'Parti ve kutlamaya gideceğim',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🎉',
      icon: Icons.celebration_rounded,
      color: Color(0xFFD946EF),
    ),
    CalendarActivity(
      id: 'misafir_agirlayacagim',
      title: 'Misafir ağırlayacağım',
      group: 'SZ',
      groupName: 'Serbest Zaman',
      emoji: '🫖',
      icon: Icons.emoji_people_rounded,
      color: Color(0xFF4F46E5),
    ),
  ];
}
