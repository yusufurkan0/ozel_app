import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FreeTimePlan {
  final String id;
  final String activityTitle;
  final String activityEmoji;
  final String dayTitle;
  final Map<int, String> answers; // 1..13 soru yanıtları
  final DateTime createdAt;
  bool isCompleted;

  FreeTimePlan({
    required this.id,
    required this.activityTitle,
    required this.activityEmoji,
    required this.dayTitle,
    required this.answers,
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'activityTitle': activityTitle,
        'activityEmoji': activityEmoji,
        'dayTitle': dayTitle,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
        'createdAt': createdAt.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory FreeTimePlan.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final parsedAnswers = rawAnswers.map((k, v) => MapEntry(int.tryParse(k) ?? 1, v.toString()));

    return FreeTimePlan(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      activityTitle: json['activityTitle'] ?? 'Serbest Zaman Etkinliği',
      activityEmoji: json['activityEmoji'] ?? '🎉',
      dayTitle: json['dayTitle'] ?? '',
      answers: parsedAnswers,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isCompleted: json['isCompleted'] == true,
    );
  }

  /// Kullanıcının yüklediği çalışma kağıdındaki BİREBİR 13 SORU:
  /// "Aşağıdaki sorulara cevap ver kendi planını hazırla."
  static const List<Map<String, dynamic>> questions = [
    {
      'step': 1,
      'question': '1. Nereye gideceğim?',
      'icon': '📍',
      'hint': 'Etkinliği yapacağın mekan veya yer',
      'options': [
        'Yakındaki Sinema Salonu 🎬',
        'Şehir Parkı / Doğa Alanı 🌳',
        'Merkezdeki Kafe ☕',
        'Kültür Merkezi / Müze 🏛️',
        'Alışveriş Merkezi (AVM) 🛍️',
        'Bowling Salonu 🎳',
      ],
    },
    {
      'step': 2,
      'question': '2. Neden gideceğim?',
      'icon': '❓',
      'hint': 'Bu etkinliği yapma amacın',
      'options': [
        'Film izleyip eğlenmek için 🍿',
        'Arkadaşlarımla sohbet edip vakit geçirmek için 💬',
        'Yeni şeyler öğrenip keşfetmek için 🔍',
        'Temiz hava alıp dinlenmek için 🌿',
        'Oyun oynayıp spor yapmak için 🎳',
      ],
    },
    {
      'step': 3,
      'question': '3. Haftalık programımda serbest zamanlarım ne zaman?',
      'icon': '🗓️',
      'hint': 'Haftalık takvimindeki uygun boşluklar',
      'options': [
        'Hafta sonu öğleden sonra serbest zamanım 🕒',
        'Hafta içi okul / iş çıkışı serbest zamanım 🌅',
        'Hafta sonu sabah serbest zamanım ☀️',
        'Takvimimde yeşil işaretli serbest zaman dilimi 🟢',
      ],
    },
    {
      'step': 4,
      'question': '4. Ne zaman gideceğim? Hangi gün? Hangi saat?',
      'icon': '⏰',
      'hint': 'Gidiş günün ve buluşma saatin',
      'options': [
        'Cumartesi günü saat 14:00\'te 🕑',
        'Pazar günü saat 15:30\'da 🕒',
        'Hafta içi saat 17:00\'de 🕔',
        'Sabah saat 10:30\'da 🕙',
      ],
    },
    {
      'step': 5,
      'question': '5. Kimlerle gideceğim? Kimleri davet edeceğim?',
      'icon': '👫',
      'hint': 'Yanında kim olacak, kimi çağıracaksın?',
      'options': [
        'Kendi başıma gideceğim 🚶',
        'Ailemle (annem/babam/kardeşim) gideceğim 👨‍👩‍👧',
        'En yakın arkadaşımı davet edeceğim 🧑‍🤝‍🧑',
        'İş Koçum / Eğitmenim ile gideceğim 💼',
      ],
    },
    {
      'step': 6,
      'question': '6. Hazırlık olarak ne yapacağım? Bilet almak, rezervasyon yaptırmak, arkadaşlarını aramak gibi.',
      'icon': '📞',
      'hint': 'Gitmeden önce yapılması gereken hazırlıklar',
      'options': [
        'Sinema / etkinlik bileti alacağım 🎟️',
        'Arkadaşımı telefonla arayıp haber vereceğim 📞',
        'Gideceğimiz yeri arayıp rezervasyon yaptıracağım 📅',
        'Ailemden izin alıp saatimi ayarlayacağım ⏰',
      ],
    },
    {
      'step': 7,
      'question': '7. Nasıl gideceğim?',
      'icon': '🚌',
      'hint': 'Kullanacağın ulaşım aracı',
      'options': [
        'Yürüyerek gideceğim 🚶',
        'Otobüs veya dolmuş ile gideceğim 🚌',
        'Metro veya Marmaray ile gideceğim 🚇',
        'Ailemin arabasıyla gideceğim 🚗',
        'Taksi ile gideceğim 🚕',
      ],
    },
    {
      'step': 8,
      'question': '8. Ne kadar paraya ihtiyacım var?',
      'icon': '💵',
      'hint': 'Tahmini harcama bütçen',
      'options': [
        '0 TL (Ücretsiz etkinlik) 🆓',
        '50 - 100 TL arası (Ulaşım ve su) 🪙',
        '100 - 250 TL arası (Bilet ve içecek) 💵',
        '250 - 500 TL arası (Yemek ve etkinlik) 💳',
      ],
    },
    {
      'step': 9,
      'question': '9. Çantamda neler olmalı?',
      'icon': '🎒',
      'hint': 'Yanına alman gereken eşyalar',
      'options': [
        'Cüzdanım, İstanbulkartım ve cep telefonum 💳📱',
        'Ev anahtarım, kimlik kartım ve su şişem 🔑🪪💧',
        'Etkinlik biletim veya rezervasyon kodum 🎟️',
        'Tam donanımlı çanta (Cüzdan, telefon, anahtar, su, bilet) 🎒',
      ],
    },
    {
      'step': 10,
      'question': '10. Nasıl giyinmeliyim?',
      'icon': '👔',
      'hint': 'Hava durumuna ve mekana uygun kıyafet seçimi',
      'options': [
        'Rahat spor kıyafetler ve spor ayakkabı 👟',
        'Hava serinse mont, ceket veya hırka 🧥',
        'Mekana uygun şık ve temiz günlük kıyafet 👔',
        'Güneşliyse şapka ve hafif tişört 🧢',
      ],
    },
    {
      'step': 11,
      'question': '11. Gittiğim yerde nasıl davranmalıyım?',
      'icon': '👥',
      'hint': 'Toplumsal kurallar ve nezaket',
      'options': [
        'Sessiz ve nazik olacağım, sıramı bekleyeceğim 🤫',
        'Görevlilerin uyarılarına ve kurallara uyacağım 🫡',
        'Telefonumu sessize alıp diğer insanları rahatsız etmeyeceğim 🔕',
        'Çevremi temiz tutacağım ve teşekkür edeceğim ✨',
      ],
    },
    {
      'step': 12,
      'question': '12. Eve nasıl döneceğim?',
      'icon': '🏠',
      'hint': 'Dönüş planın ve zamanın',
      'options': [
        'Geldiğim gibi otobüs / metro ile döneceğim 🚌',
        'Etkinlik biter bitmez ailem gelip beni alacak 🚗',
        'Arkadaşımla birlikte yürüyerek döneceğim 🚶',
        'En geç saat 18:00\'de evde olacak şekilde yola çıkacağım 🕕',
      ],
    },
    {
      'step': 13,
      'question': '13. Kim yardım edebilir?',
      'icon': '🤝',
      'hint': 'Bir sorun çıkarsa veya kaybolursan destek alacağın kişiler',
      'options': [
        'Destek Kişim (Ailem / İlgili Yakınım) - Hemen arayacağım 📞',
        'İş Koçum - WhatsApp\'tan mesaj atacağım 💬',
        'Mekandaki güvenlik görevlisi veya yetkili personel 👮',
        'Uygulamadaki "Kayboldum! / Destek" butonu 🆘',
      ],
    },
  ];

  static Future<List<FreeTimePlan>> loadSavedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('user_free_time_plans');
    if (savedJson == null || savedJson.isEmpty) return [];
    try {
      final list = jsonDecode(savedJson) as List;
      return list.map((item) => FreeTimePlan.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePlans(List<FreeTimePlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(plans.map((p) => p.toJson()).toList());
    await prefs.setString('user_free_time_plans', jsonStr);
  }
}
